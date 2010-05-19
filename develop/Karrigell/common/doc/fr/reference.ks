# -*- coding: iso-8859-1 -*-

import sys
import os
import re
import datetime
import locale
import shutil
import cStringIO

from HTMLTags import *

names = Import("names")
version = "3.0"

dico = {"version":version}
head = open("head.html").read()

def _make_menu():
    num = [0]
    cur_nb = 0
    res = '<div id="upbg"></div>\n'
    res += '<div id="outer">\n'
    res += names.CONTENT_PAGE_HEADER %{'version':REQUEST_HANDLER.version}
    res += '<div id="content"><div id="contentarea">'
    res += '<div class="normalcontent"><p>'
    chapters = []
    for num_line,line in enumerate(open(REL("chapitres.txt"))):
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
        res += '<LI><A href="show?page_num=%s&ref=%s">%s. %s</a>\n' \
                %(num_line,ref,ref,title)
        chapters.append((ref,name,title))
    res += '</div></div></div></div>'

    return res,chapters

def index():

    chapters = open(REL("chapitres.txt")).readlines()

    out = cStringIO.StringIO()
    first = """<div id="header">
    <div id='headercontent'>
    <h1>%s</h1>
    <p><b><font size="+2">Pierre Quentel</font></b></p>
    <p><strong>%s %s</strong><br />
    <strong>%s</strong></p>
    <p></p>
    </div>
    </div>""" %(names.TITLE,names.RELEASE,
        version,datetime.date.today().strftime("%x"))

    navig = open(REL("navig.html")).read()
    dico_navig={"previous1":names.previous,
        "names.previous2":"","next2":"","up2":""}
    anchor = names.up1 %("Home","/")
    dico_navig["names.up1"] = anchor+names.up+"</a>"

    href_next,title_next = chapters[0].strip().split('#')
    anchor = names.next1 %(title_next,href_next+".html")
    dico_navig["names.next1"] = anchor+names.next+"</a>"
    for key in dico_navig:
        navig = navig.replace("[[%s]]" %key,dico_navig[key])

    dico_head={"title":names.TITLE}
    this_head = head %dico_head
    body,chapters = _make_menu()
    res = this_head+"<body>"+body+"</body>\n</html>"
    out.write(res)
    print out.getvalue()

def _page(page_num,ref):
    menu,chapters = _make_menu()
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
                    href="show?page_num=%s&ref=%s"  %(snum,sref)))
            else:
                break
        content = str(H1("%s. %s" %(ref,title))+P()+UL(content))
    else:
        
        content = open(REL(name+".pih")).read()
        head_ptn = re.compile("<head>.*?</head>",re.S)
        content = head_ptn.sub("",content)
        content = re.sub("<.*html>","",content)
        content = re.sub("<.*body>","",content)

    navig = open(REL("navig.html")).read()
    dico_navig = {"up1":names.up1%("Contents","../reference.ks")+names.up+'</a>',
        "up2":names.up2}
    if num>0:
        ref_prev,href_prev,title_prev = chapters[num-1]
        href_prev = "show?page_num=%s&ref=%s" %(num-1,ref_prev)
        anchor = names.previous1 %(title_prev,href_prev)
        dico_navig["previous1"] = anchor+names.previous+"</a>"
        dico_navig["previous2"] = names.previous2 %(href_prev,ref_prev,title_prev)
    else:
        dico_navig["previous1"] = names.previous
        dico_navig["previous2"] = ""

    if num<len(chapters)-1:
        ref_next,href_next,title_next = chapters[num+1]
        href_next = "show?page_num=%s&ref=%s" %(num+1,ref_next)
        anchor = names.next1 %(title_next,href_next)
        dico_navig["next1"] = anchor+names.next+"</a>"
        dico_navig["next2"] = names.next2 %(href_next,ref_next,title_next)
    else:
        dico_navig["next1"] = names.next
        dico_navig["next2"] = ""

    for key in dico_navig:
        navig = navig.replace("[[%s]]" %key,dico_navig[key])

    top = '<body>\n<div id="upbg"></div>\n'
    top += '<div id="outer">\n'
    top += names.PAGE_HEADER %{'version':REQUEST_HANDLER.version}
    top += navig
    top += '<div id="menubottom"></div>'
    
    ct_hdr = '<div id="content"><div id="contentarea">'
    ct_hdr += '<div class="normalcontent"><p>'
    content = ct_hdr + content + '</div></div></div>'
    
    res = top+content+"<hr>"+navig+"</div>\n</body>"

    dico_head={"title":title,"prev":"prev","parent":"parent","names.next":"names.next"}
    this_head = head %dico_head
    res = this_head+res+"</html>"
    out = cStringIO.StringIO()
    out.write(res)
    return out.getvalue()

def show(page_num,ref):
    pih_code = _page(page_num,ref)
    import python_code
    src,line_mapping = python_code.get_py_code_from_string(pih_code,".pih")
    THIS.namespace.update({"chapter":ref,"make_link":make_link})
    exec src in THIS.namespace

def make_link(text,page_name):
    menu,chapters = _make_menu()
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
        return A(text,href="show?page_num=%s&ref=%s" %(page_num,ref))
        