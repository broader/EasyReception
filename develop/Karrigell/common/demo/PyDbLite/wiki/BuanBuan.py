"""BuanBuan, simple implementation of Wiki"""

import cStringIO,string,os,re,sys,time,cPickle,cgi
import sets

bolds=re.compile("'''(.+?)'''")
italics=re.compile("''(.+?)''")
superscripts=re.compile(r"\^(.+?)\^")  # caret for superscripted
hr = re.compile("^[\-]+.*",re.MULTILINE)
header = re.compile("^(!+)(.*)",re.MULTILINE)
wikiLink=re.compile(r"\b[A-Z][a-z]+[A-Z][a-z]+.*?\b")
noWikiLink=re.compile(r"\b_[A-Z][a-z]+[A-Z]+[a-z]+.*?\b")
anchor = re.compile(r'\[(.+)\|(.+)\]')
image = re.compile(r'\bimg([lcr]?):(\S*)\b')
href_patt = re.compile('<\s*?[Aa]\s+?')
style = re.compile('^\{\s*(\w*)')
line = re.compile('(^.*)',re.MULTILINE)
list_ = re.compile('^([#*]+) (.*)')
tableopts = re.compile(r'^\|\|\{\s*(.*?)\s*\}\|\|')
protocols=["http:","ftp:","mailto:"]

def isLinkName(word):
    """Returns true if word is a valid Wiki link"""
    return wikiLink.match(word)

class BuanDoc:

    def __init__(self, name, text):
        self.wikiNames = sets.Set() # new pages (words as valid Wiki names)
        self.pageName = name
        self.text = cgi.escape(text)
        self.listqueue = []
        self.intable = False
        self.make_html()
    
    def make_html(self):
        # wiki names
        self.text = wikiLink.sub(self.handle_wikiLink,self.text)
        # anchors
        self.text = anchor.sub(self.handle_anchor,self.text)
        # images
        self.text = image.sub(self.handle_image,self.text)
        # non wiki names : remove first character _
        self.text = noWikiLink.sub(self.handle_nowiki,self.text)
        # bold, italic, superscript
        self.text=bolds.sub(self.handle_bold,self.text)
        self.text=italics.sub(self.handle_italic,self.text)
        self.text=superscripts.sub(self.handle_superscript,self.text)
        # horizontal rule, header
        self.text = hr.sub(self.handle_hr,self.text)
        self.text = header.sub(self.handle_header,self.text)
        # css style
        self.in_style = False
        #self.text = style.sub(self.handle_style,self.text)
        # ordered and unordered lists
        self.ol_depth = 0
        self.ul_depth = 0
        self.text = line.sub(self.handle_line,self.text)
    
    def handle_wikiLink(self,mo):
        link = mo.group()
        self.wikiNames.add(link)
        return '<a href="BuanShow.pih?pageName=%s">%s</a>' % (link,link)

    def handle_nowiki(self,mo):
        link = mo.group()
        return link[1:]

    def handle_anchor(self,mo):
        txt,href = mo.groups()
        if href.startswith('<a href="BuanShow.pih?pageName'):
            href = href[:href[:-4].rfind('>')+1]
            return href + txt + '</a>'
        else:
            return '<a href="%s">%s</a>' %(href,txt)
            
    def handle_image(self,mo):
        a, src = mo.groups()
        align = ''
        if a == 'l':
            align = ' align="left"'
        elif a == 'r':
            align = ' align="right"'
        res = '<img src="%s" %s>' % (src, align)
        if a == 'c':
            res = '\n<p align="center">%s</p>\r' % res
        return res

    def handle_style(self,mo):
        style = mo.groups()[0]
        text = mo.groups()[1].lstrip()
        return '<pre class = "%s">%s</pre>' %(style,text)

    def handle_hr(self,mo):
        return '<hr>\n'

    def handle_header(self,mo):
        level = len(mo.groups()[0])
        return '<h%s>%s</h%s>' %(level,mo.groups()[1].rstrip(),level)

    def handle_line(self,mo):
        text = mo.groups()[0]
        res = ''
        
        # List?
        #if self.toggles['pre']: return s
        mo = list_.match(text)
        if mo:
            tag, text = mo.groups()
            listtype = {'*': 'ul', '#': 'ol'}[tag[0]]
            depth = len(tag)
            oldlistlevel = len(self.listqueue)            
            for i in range(depth, oldlistlevel): #if indent<oldlistlevel
                res += '%s</%s>\n' % (' ' * i, self.listqueue.pop())
            for i in range(oldlistlevel, depth): #if indent>oldlistlevel
                res += '%s<%s>\n' % (' ' * i, listtype); self.listqueue.append(listtype)
            if listtype != self.listqueue[-1]:   #same indent but different flavour list
                res += '%s</%s>%s<%s>\n' % (' ' * depth, self.listqueue.pop(), ' ' * depth, listtype)
                self.listqueue.append(listtype)
            res += '%s<li>' % (' ' * depth)
        else:
            # No longer in a list, so dedent
            while self.listqueue:
                res += ' ' * (len(self.listqueue)-1) + '</%s>\n' % self.listqueue.pop()
        # table ?
        sym = text[:2]
        if sym == '||' :
            if not self.intable:
                self.intable = True
                opts = 'border="1" cellspacing="0"'
                mo = tableopts.match(text)
                if mo:
                    opts = mo.groups()[0]
                    text = ''
                res += '<table %s>\n' % opts
        else:
            if self.intable:
                res +=  "\n</table>\n"
                self.intable = False
        if self.intable and text:
            tag1 = '<td valign="top">'
            tag2 = "</td>"
            cells = ('&nbsp;%s%s' % (tag2, tag1)).join(text.split(sym)[1:-1])
            res += '<tr>%s%s&nbsp;%s</tr>' % (tag1, cells, tag2)
            text = ''
        # style ?
        mo = style.match(text)
        if mo:
            stylename = mo.groups()[0]
            res = '<pre class = "%s">' %stylename
            text = text[mo.end():].lstrip()
            self.in_style = True
        # end of style ?
        if text.startswith('}'):
            res = '</pre>'
            text = text[1:]
            self.in_style = False
        br = ''
        if not res and not self.in_style:
            br = '<p>'
        return br + res + text

    def handle_bold(self,mo):
        return "<b>%s</b>" %mo.groups()[0]

    def handle_italic(self,mo):
        return "<i>%s</i>" %mo.groups()[0]

    def handle_superscript(self,mo):
        return "<sup>%s</sup>" %mo.groups()[0]

def test():
    txt = """[prvious|blabla.pih?jjj]
!!!New features
1. refactoring of the Template module : execution of scripts is passed to modules mod_(extension)
1.a new option if .ini file specifies the supported extensions
1. added ^Cheetah^ support
1. replaced gadfly by [_KirbyBase|http://www.netpromi.com/kirbybase.html], removed dbStorage
2. exception '''SCRIPT_ERROR''' : raise SCRIPT_ERROR,msg prints the message msg and stops the script execution
{ python print
}
WiKi _NoWiKi
!!!To do
* document ''virtual'' hosts
** first
** second
* other point
--
!!! salut
1. ca va etre dur
2. de trouver
2. quelque chose
1. de special
{ html <br>
<ll>
}
* a dire
[essai de lien|AvecLienWiki]
"""
    b = BuanDoc('test',txt)
    print b.text

if __name__=="__main__":
    test()
    print isLinkName('LineWiki')
    print isLinkName('_LienWiki')