# -*- coding: iso-8859-1 -*-

import sys
import os
import re
import datetime
import locale
import shutil
import cStringIO

from HTMLTags import *

langs = {'en':{'rep':'en','title':'Karrigell manual','release':'Release'},
    #'fr':{'rep':r'fr','title':"Manuel Karrigell",'release':"Version"}
    }
version = "3.0"

dico = {"version":version}
head = open("head.html").read()

previous = """<img src='../images/previous.png'  border='0' height='32'  
    alt='Previous Page.0' width='32' />"""
previous1 = '<li><a rel="prev" title="%s" href="%s">'

up = """<img src='../images/up.png' border='0' height='32'  
    alt='Niveau supérieur' width='32' />"""
up1 = '<li><a rel="up" title="%s" href="%s">'

next = """<img src='../images/next.png'
  border='0' height='32'  alt='Next Page' width='32' />"""
next1 = '<li><a rel="next" title="%s" href="%s">'

previous2 = '<b class="navlabel">Previous:</b>'
previous2 += '<a class="sectref" rel="prev" href="%s">'
previous2 += '%s. %s</A>'

up2 = '<b class="navlabel">Up:</b>'
up2 += '<a class="sectref" rel="parent" href="../reference.ks">Contents</A>'

next2 = '<b class="navlabel">Next:</b>'
next2 += '<a class="sectref" rel="next" href="%s">'
next2 += '%s. %s</A>'

content_page_header = """
    <table id="header">
        <tr>
        <td id="headercontent">
            <h1>Karrigell<sup>3.0</sup></h1>
            <h2>A pythonic web framework</h2>
        </td>

        <td id="section">
            <h1>Reference Manual</h1>

        </td>

    </table>
        <div id="menu">
            <ul>
                <li><a href="/doc">Documentation</a></li>
                <li><a href="http://sourceforge.net/project/showfiles.php?group_id=67940">Downloads</a></li>
                <li><a href="/doc/en/tour/tour_en.pih">Getting Started</a></li>
                <li><a href="../../reference.ks" class="active">Reference</a></li>
                <li><a href="../migration_2_to_3.html">Migration from 2.x</a></li>
                <li><a href="http://groups.google.com/group/karrigell">Community</a></li>
            </ul>
        </div>
        <div id="menubottom"></div>

"""

page_header = """
    <table id="header">
        <tr>
        <td id="headercontent">
            <h1>Karrigell<sup>3.0</sup></h1>
            <h2>A pythonic web framework</h2>
        </td>

        <td id="section">
            <h1>Reference Manual</h1>

        </td>

    </table>

"""

def _make_menu(lang):
    rep = REL(langs[lang]['rep'])
    num = [0]
    cur_nb = 0
    res = '<div id="upbg"></div>\n'
    res += '<div id="outer">\n'
    res += content_page_header
    res += '<div id="content"><div id="contentarea">'
    res += '<div class="normalcontent"><p>'
    chapters = []
    for num_line,line in enumerate(open(os.path.join(rep,"chapitres.txt"))):
        nb = 0
        while line[0]==" ":
            nb += 1
            line = line[1:]
        if nb == cur_nb:
            num[cur_nb] += 1
        elif nb > cur_nb:
            if len(num)<=nb:
                num.append(1)
                res +="<UL>\n"
        elif nb < cur_nb:
            num[nb] += 1
            num = num[:nb+1]
            res += "</UL>\n"
        cur_nb = nb
        ref = ".".join([str(x) for x in num[:cur_nb+1]])
        name,title = line.strip().split("#")
        res += '<LI><A href="show?page_num=%s&ref=%s&lang=%s">%s. %s</a>\n' \
                %(num_line,ref,lang,ref,title)
        chapters.append((ref,name,title))
    res += '</div></div></div></div>'

    return res,chapters

def index(lang='en'):
    if not lang in langs:
        lang = 'en'
    rep = REL(langs[lang]['rep'])

    chapters = open(os.path.join(rep,"chapitres.txt")).readlines()

    out = cStringIO.StringIO()
    first = """<div id="header">
    <div id='headercontent'>
    <h1>%s</h1>
    <p><b><font size="+2">Pierre Quentel</font></b></p>
    <p><strong>%s %s</strong><br />
    <strong>%s</strong></p>
    <p></p>
    </div>
    </div>""" %(langs[lang]["title"],langs[lang]["release"],
        version,datetime.date.today().strftime("%x"))

    navig = open(os.path.join(rep,"navig.html")).read()
    dico_navig={"previous1":previous,"previous2":"","next2":"","up2":""}
    anchor = up1 %("Home","/")
    dico_navig["up1"] = anchor+up+"</a>"

    href_next,title_next = chapters[0].strip().split('#')
    anchor = next1 %(title_next,href_next+".html")
    dico_navig["next1"] = anchor+next+"</a>"
    for key in dico_navig:
        navig = navig.replace("[[%s]]" %key,dico_navig[key])

    dico_head={"title":langs[lang]["title"]}
    this_head = head %dico_head
    body,chapters = _make_menu(lang)
    res = this_head+"<body>"+body+"</body>\n</html>"
    out.write(res)
    print out.getvalue()

def _page(page_num,ref,lang):
    rep = REL(langs[lang]['rep'])
    menu,chapters = _make_menu(lang)
    num = int(page_num)
    ref,name,title = chapters[num]
    
    if not name: # generate list of subsections
        content = TEXT('')
        snum = num
        while snum<len(chapters):
            snum += 1
            sref,sname,stitle = chapters[snum]
            if sref.startswith(ref):
                content += LI(A("%s. %s" %(sref,stitle),
                    href="show?page_num=%s&ref=%s&lang=%s"  %(snum,sref,lang)))
            else:
                break
        content = str(H1("%s. %s" %(ref,title))+P()+UL(content))
    else:
        
        content = open(os.path.join(rep,name+".pih")).read()
        head_ptn = re.compile("<head>.*?</head>",re.S)
        content = head_ptn.sub("",content)
        content = re.sub("<.*html>","",content)
        content = re.sub("<.*body>","",content)

    navig = open(os.path.join(rep,"navig.html")).read()
    dico_navig = {"up1":up1%("Contents","../reference.ks")+up+'</a>',
        "up2":up2}
    if num>0:
        ref_prev,href_prev,title_prev = chapters[num-1]
        href_prev = "show?page_num=%s&ref=%s&lang=%s" %(num-1,ref_prev,lang)
        anchor = previous1 %(title_prev,href_prev)
        dico_navig["previous1"] = anchor+previous+"</a>"
        dico_navig["previous2"] = previous2 %(href_prev,ref_prev,title_prev)
    else:
        dico_navig["previous1"] = previous
        dico_navig["previous2"] = ""

    if num<len(chapters)-1:
        ref_next,href_next,title_next = chapters[num+1]
        href_next = "show?page_num=%s&ref=%s&lang=%s" %(num+1,ref_next,lang)
        anchor = next1 %(title_next,href_next)
        dico_navig["next1"] = anchor+next+"</a>"
        dico_navig["next2"] = next2 %(href_next,ref_next,title_next)
    else:
        dico_navig["next1"] = next
        dico_navig["next2"] = ""

    for key in dico_navig:
        navig = navig.replace("[[%s]]" %key,dico_navig[key])

    top = '<body>\n<div id="upbg"></div>\n'
    top += '<div id="outer">\n'+page_header+navig
    top += '<div id="menubottom"></div>'
    
    ct_hdr = '<div id="content"><div id="contentarea">'
    ct_hdr += '<div class="normalcontent"><p>'
    content = ct_hdr + content + '</div></div></div>'
    
    res = top+content+"<hr>"+navig+"</div>\n</body>"

    dico_head={"title":title,"prev":"prev","parent":"parent","next":"next"}
    this_head = head %dico_head
    res = this_head+res+"</html>"
    out = cStringIO.StringIO()
    out.write(res)
    return out.getvalue()

def show(page_num,ref,lang):
    pih_code = _page(page_num,ref,lang)
    import python_code
    src,line_mapping = python_code.get_py_code_from_string(pih_code,".pih")
    THIS.namespace.update({"chapter":ref,"make_link":make_link})
    exec src in THIS.namespace
    Session().lang = lang

def make_link(text,page_name):
    so = Session()
    if not hasattr(so,'lang'):
        so.lang = 'en'
    lang = so.lang
    rep = REL(langs[lang]['rep'])
    menu,chapters = _make_menu(lang)
    page_num = None
    num = 0
    while num<len(chapters):
        ref,name,title = chapters[num]
        if name == page_name:
            page_num = num
            break
        num += 1
    if page_num is None:
        return "No page has name",page_name
    else:
        return A(text,href="show?page_num=%s&ref=%s&lang=%s" \
            %(page_num,ref,lang))
        