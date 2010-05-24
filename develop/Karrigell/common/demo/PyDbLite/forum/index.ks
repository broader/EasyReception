import os
import time
import locale
import datetime
from HTMLTags import *

import PyDbLite
db = PyDbLite.Base(os.path.join(CONFIG.data_dir,'forum.pdl'))

db.create('parent','thread','author','title','content','date',
    'lastDate','numChildren',mode="open")
db.create_index('parent','thread')

SET_UNICODE_OUT('utf-8')


# config
import cPickle
conf_path = os.path.join(CONFIG.data_dir,'forum.dat')
if os.path.exists(conf_path):
    conf = cPickle.load(open(conf_path,'rb'))
else:
    conf = {'title':_("Karrigell forum demo")}
    out = open(conf_path,'wb')
    cPickle.dump(conf,out,cPickle.HIGHEST_PROTOCOL)
    out.close()

try:
    locale.setlocale(locale.LC_ALL,'')
except:
    pass

print HEAD(TITLE(conf["title"])+
    META(http_equiv="Content-Type",content="text/html; charset=utf-8")+
    LINK(rel="stylesheet",Type="text/css",href="../forum.css")+
    SCRIPT(src="../forum.js"))

def display(i,msg):
    title = A(msg["title"],href="thread_frame?thread=%s" %msg["__id__"])
    line2 = _("By")+" "+msg["author"]
    line2 += ' - '+msg["lastDate"].strftime('%x')
    line2 += " - %s %s" %(msg["numChildren"],_('answers'))
    line2 = TEXT(line2)
    if Role()=="admin":
        line2 += SMALL(TEXT(" (")+
            A(_("Remove"),href="remove_thread?thread_id=%s" %msg["thread"])
            +TEXT(")"))
    print DL(DT(title)+DL(line2))

def login():
    Login(redir_to=THIS.script_url,add_user="edit",valid_in='/')

def index():
    print '<body>'
    threads=db._parent[-1]
            
    threads.sort(lambda x,y: cmp(y["lastDate"],x["lastDate"]))

    print A(IMG('',src="/doc/images/karrigell.jpg", border="0", width="100"),
        href="/")
    if Role():
        link = TEXT(COOKIE["login"].value+"&nbsp;")
        link += A(SMALL(_("Logout")),href="logout")
    else:
        link = A(SMALL(_("Login")),href="login")
    print TABLE(TR(TD(H3(conf["title"]))+
        TD(link,align="right")),
        width="75%")

    print TABLE(TR(TD(H4(_("Threads")))+
        TD(A(_("Start new thread"), href='new_thread'),align="right")),
        width="75%")

    for i,msg in enumerate(threads):
        display(i,msg)

    print P()
    if Role() is not None:
        print '<a href="logout"><small>Logout</small></a>'
    print '</body>'

def logout():
    Logout(valid_in='/')

def new_thread():
    Login(role=["admin","edit"],add_user=True)
    print '<body>'
    print H3(_("New message"))
    print '<table>'
    author = COOKIE["login"].value
    print FORM(INPUT(Type="hidden",name="parent",value="-1")+
        INPUT(Type="hidden",name="author",value=author)+
        TR(TD(_("Author"))+
            TD(author))+
        TR(TD(_("Title"))+TD(INPUT(name="title",size="80")))+
        TR(TD(_("Your message"),valign="top")+
            TD(TEXTAREA(name="content",rows="20",cols="80")))+
        TR(TD(INPUT(Type="submit",value="Ok"),colspan="2")+
           TD(INPUT(Type="button",value=_("Cancel"),
                onClick="location.href='index';"),align="right")
        ),
        action="save_message",method="post")
    print '</table></body>'

def save_message(parent,author,title,content):
    parent=int(_parent)
    # what thread does this message belong to ?
    if parent!=-1:
        thread=db[parent]["thread"]
    else:
        thread=-1

    # insert the message, return its id
    date=datetime.datetime.today()
    new_id = db.insert(parent=parent,thread=thread,author=_author,
        title=_title,content=_content,date=date,lastDate=date,
        numChildren=0)

    # increment number of children of all the parents of this message
    msg = None
    while parent!=-1:
        msg=db[parent]
        db.update(msg,numChildren = msg["numChildren"]+1)
        parent=msg["parent"]

    if thread == -1:
        db.update(db[new_id],thread=new_id)
    else:
        # update lastDate of the first message in the thread
        db.update(msg,lastDate=date)

    db.commit()
    raise HTTP_REDIRECTION,"index"

def thread_frame(thread):
    print FRAMESET(FRAME(name="left",src="thread_menu?thread=%s" %thread)+
            FRAME(name="right",src="../showThreadMessages.pih?thread=%s" %thread),
        cols="25%,*")

def thread_menu(thread):
    print SCRIPT("selectedMsg = null")

    def display_line(msg,indent):
        print '<br>%s<a class="msg" href="../showThreadMessages.pih?thread=%s#%s" target="right">%s</a>' \
            %("&nbsp;"*indent*2,thread,msg["__id__"],msg["author"])
        print '<small> %s</small>' %msg["date"].strftime('%x')
        if Role()=="admin" and msg["parent"] != -1:
            print '<a href="remove_msg?msgid=%s&thread=%s" target="_top">' \
                %(msg["__id__"],_thread)
            print '<small>Remove</small></a>'

    def compDate(msg1,msg2):
        return cmp(msg1["date"],msg2["date"])

    def showThread(msg,indent):
        # shows the thread beginning at msg
        # only one line per message, indented
        #global indent
        display_line(msg,indent)
        res=[]
        res=[ m for m in threadMsgs if m["parent"]==msg["__id__"] ]
        res.sort(compDate)
        for childmsg in res:
            showThread(childmsg,indent+1)

    # retrieves all messages of the thread
    threadMsgs=db._thread[int(_thread)]

    # root of the thread
    for msg in threadMsgs:
        if msg["parent"]==-1:
            break

    rootMsg=msg

    print A(_("Back to forum"),href="index",target="_top")
    print P()+B(rootMsg["title"])
    showThread(rootMsg,1)

answers = 0
def remove_msg(msgid,thread):
    def removeChildren(msg):
        global answers
        children = db._parent[msg["__id__"]]
        del db[msg["__id__"]]
        answers += 1
        for child in children:
            removeChildren(child)

    msg = db[int(_msgid)]
    removeChildren(msg)

    # decrement number of replies
    while True:
        parent = msg["parent"]
        if parent == -1:
            break
        p = db[parent]
        new_nc = p["numChildren"] - answers
        db.update(p,numChildren=new_nc)
        msg = p

    db.commit()
    raise HTTP_REDIRECTION,'thread_frame?thread=%s' %thread

def remove_thread(thread_id):
    db.delete(db(thread=int(thread_id)))
    db.commit()

    raise HTTP_REDIRECTION,'index'