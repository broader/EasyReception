# -*- coding: iso-8859-1 -*-

import sys
import os
import re
import datetime
import locale
import shutil

import tkFileDialog

langs = {'en':{'rep':r'..\doc_en','title':'Karrigell manual','release':'Release'},
    'fr':{'rep':r'..\doc_fr','title':"Manuel Karrigell",'release':"Version"}}

version = raw_input("Version : ")
if not version:
    sys.exit()

try:
    _dir = open("k_path.txt").read().strip()
except IOError:
    _dir = os.getcwd()

k_path = tkFileDialog.askdirectory(initialdir = _dir)
if k_path:
    out = open("k_path.txt","w")
    out.write(k_path)
    out.close()

def make_menu(rep):
    num = [0]
    cur_nb = 0
    res = ""
    chapters = []
    for line in open(os.path.join(rep,"chapitres.txt")):
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
        if name:
            res += '<LI><A href="%s">%s. %s</a>\n' %(name+".html",ref,title)
            chapters.append((ref,name,title))
        else:
            res += '<LI>%s. %s\n' %(ref,title)
    return res,chapters

for lang in langs:

    locale.setlocale(locale.LC_ALL,lang)
    rep = langs[lang]['rep']
    dest_rep = os.path.join(k_path,"common","doc",lang)
    if not os.path.exists(dest_rep):
        os.mkdir(dest_rep)

    # remove files from destination folder    
    for path in os.listdir(dest_rep):
        try:
            os.remove(os.path.join(dest_rep,path))
        except WindowsError:
            print "windows error",path
            if not path == ".svn":
                print "Permission refusée - le serveur doit être en route"
                sys.exit()

    # copy style sheet and images
    def _copy(path):
        shutil.copyfile(os.path.join(rep,path),os.path.join(dest_rep,path))
    
    _copy("karrigell_doc.css")
    images = [ path for path in os.listdir(rep) if os.path.splitext(path)[1]==".png"]
    for path in images:
        _copy(path)
    
    chapters = open(os.path.join(rep,"chapitres.txt")).readlines()

    dico = {"version":version}
    head = open("head.html").read()

    previous = """<img src='previous.png'  border='0' height='32'  
        alt='Previous Page.0' width='32' />"""
    previous1 = '<a rel="prev" title="%s" href="%s">'

    up = """<img src='up.png' border='0' height='32'  
        alt='Niveau supérieur' width='32' />"""
    up1 = '<a rel="up" title="%s" href="%s">'

    next = """<img src='next.png'
      border='0' height='32'  alt='Next Page' width='32' />"""
    next1 = '<a rel="next" title="%s" href="%s">'

    # import previous2,up2,next2
    execfile(os.path.join(rep,"links2.py"))

    out = open(os.path.join(dest_rep,"contents.html"),"w")
    first = """<div class="titlepage">
    <div class='center'>
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
    body = '<UL CLASS="ChildLinks">'
    menu,chapters = make_menu(rep)
    body += menu
    """for num,chapter in enumerate(chapters):
        name,title=chapter.strip().split('#')
        body += '<LI><A href="%s">%s. %s</a>\n' %(name+".html",num+1,title)"""
    res = "<html>\n<head>\n"+this_head+"</head>"
    res +="<body>"+navig+first+'<hr>'+body+"</body>\n</html>"
    out.write(res)
    out.close()

    for num,(ref,name,title) in enumerate(chapters):
        res = open(os.path.join(rep,name+".pih")).read()
        head_ptn = re.compile("<head>.*?</head>",re.S)
        res = head_ptn.sub("",res)
        res = re.sub("<.*html>","",res)

        navig = open(os.path.join(rep,"navig.html")).read()
        dico_navig = {"up1":up1%("Contents","contents.html")+up+'</a>',
            "up2":up2}
        if num>0:
            ref_prev,href_prev,title_prev = chapters[num-1]
            anchor = previous1 %(title_prev,href_prev+".html")
            dico_navig["previous1"] = anchor+previous+"</a>"
            dico_navig["previous2"] = previous2 %(href_prev+".html",ref_prev,title_prev)
        else:
            dico_navig["previous1"] = previous
            dico_navig["previous2"] = ""

        if num<len(chapters)-1:
            ref_next,href_next,title_next = chapters[num+1]
            anchor = next1 %(title_next,href_next+".html")
            dico_navig["next1"] = anchor+next+"</a>"
            dico_navig["next2"] = next2 %(href_next+".html",ref_next,title_next)
        else:
            dico_navig["next1"] = next
            dico_navig["next2"] = ""

        for key in dico_navig:
            navig = navig.replace("[[%s]]" %key,dico_navig[key])

        res = res.replace("<body>","<body>\n"+navig+"<hr>",1)
        res += "<hr>"+navig+"</body>\n</html>"
        dico["chapter"]=ref
        for key in dico:
            res = re.sub("<%=\s*"+key+"\s*%>",str(dico[key]),res)

        dico_head={"title":title,"prev":"prev","parent":"parent","next":"next"}
        this_head = head %dico_head
        res = "<html>\n<head>\n"+this_head+"</head>"+res+"</html>"
        out = open(os.path.join(dest_rep,name+".html"),"w")
        out.write(res)
        out.close()
    
