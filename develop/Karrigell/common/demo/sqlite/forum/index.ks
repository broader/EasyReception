import os
import time
import locale
import datetime
import textwrap

from HTMLTags import *
from PyDbLite import SQLite
import k_databases
sqlite = k_databases.get_engines()['SQLite'] # sqlite module

db_dir = os.path.join(CONFIG.data_dir,"forum")
if not os.path.exists(db_dir):
    os.mkdir(db_dir)

def _get_db(group):
    db_path = os.path.join(db_dir,"%s.sqlite" %group)
    db = sqlite.connect(db_path,isolation_level=None)
    cursor = db.cursor()
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
    flag = False
    for table_info in cursor.fetchall():
        if table_info[0] == "forum":
            flag = True
            break

    if not flag:
        cursor.execute("CREATE TABLE forum (recid INTEGER PRIMARY KEY AUTOINCREMENT, \
            parent INTEGER, thread INTEGER, author TEXT, title TEXT, \
            content TEXT, date BLOB, lastDate BLOB, numChildren INTEGER)")
        cursor.execute("CREATE TABLE threads (recid INTEGER PRIMARY KEY AUTOINCREMENT, \
            author TEXT, title TEXT, \
            date BLOB, lastDate BLOB, numChildren INTEGER)")
    return db

forum_fields = ['recid','parent','thread','author','title','content',
            'date','lastDate','numChildren']
thread_fields = ['recid','author','title','date','lastDate','numChildren']

threads_per_page = 20

try:
    set([])
except NameError:
    from sets import Set as set
    
utils = Import("utils")
_make_dict = utils._make_dict

# config
conf = {'title':_("Karrigell forums")}

try:
    locale.setlocale(locale.LC_ALL,'')
except:
    pass

SET_UNICODE_OUT('utf-8')

head = HEAD(TITLE(conf["title"])+
    LINK(rel="stylesheet",Type="text/css",href="../forum.css")+
    SCRIPT(src="../forum.js"))

def dump():
    lines = [TR(Sum([TD(f) for f in utils.fields]))]
    for row in cursor.execute("SELECT * FROM forum").fetchall():
        elts = []
        for item in row:
            if isinstance(item,unicode):
                elts.append(item.encode("iso-8859-1"))
            else:
                elts.append(item)
        lines.append(TR(Sum([TD(item) for item in elts])))
    print TABLE(Sum(lines),border=1)

def _display(i,msg,group):
    line = TR()
    link = A(msg["title"],
        href=THIS.rel("show_thread?group=%s&thread=%s") %(group,msg["recid"]),
        Class='msg')
    if Role()=="admin":
        link += ' '+SMALL(TEXT(" (")+
            A(_("Remove"),
                href="remove_thread?group=%s&thread_id=%s" %(group,msg["recid"]))
            +TEXT(")"))
    line <= TD(link)
    line <= TD(msg["author"],align="center")
    line <= TD(msg["lastDate"].strftime('%x'),align="center")
    line <= TD(str(msg["numChildren"]),align="center")
    if i%2:
        for item in line.get_by_tag('TD'):
            item.attrs['Class'] = 'msg_list_odd'
    else:
        for item in line.get_by_tag('TD'):
            item.attrs['Class'] = 'msg_list_even'

    return line

def login():
    Login(role=["admin","edit"],add_user="edit",redir_to=THIS.script_url)

def _header(title=None):
    if title is None:
        title = conf["title"]
    header = TR()
    header <= TD() <= A(href='/') <= \
        IMG('',src="/doc/images/karrigell.jpg", border="0", width="100")
    header <= TD(A(H3(title),href="index"))
    if Role():
        link = TEXT(COOKIE["login"].value+"&nbsp;")
        link += A(SMALL(_("Logout")),href="logout")
    else:
        link = A(SMALL(_("Login")),href="login")
    header <= TD(link,align="right")

    return TABLE(header,width="100%")

def index():
    body = BODY()
    body <= _header()

    db_path = os.path.join(db_dir,'forums.sqlite')
    forums = SQLite.Table('forums',db_path)
    forums.create(('name','TEXT'),('owner','TEXT'),mode="open")
    
    table = TABLE()
    for rec in forums:
        table <= TR(TD(A(rec['name'],href='view?group='+rec['name']))+TD(rec['owner']))
    body <= table

    if Role():
        form = FORM(action="create_forum",method="post")
        form <= INPUT(name="forum_name")
        form <= INPUT(Type="submit",value="Create forum")
        body <= form
    
    print HTML(head + body)

def create_forum(forum_name):
    if not Role():
        raise SCRIPT_END
    if forum_name == 'forums':
        print HTML(head+BODY(_header()+'Name "forums" is reserved'))
        raise SCRIPT_END
    import re
    if not re.match('^[a-zA-Z]\w*$',forum_name):
        print HTML(head+BODY(_header()+'Invalid name "%s"' %forum_name))
        raise SCRIPT_END

    # add forum in table forums
    db_path = os.path.join(db_dir,'forums.sqlite')
    forums = SQLite.Table('forums',db_path).open()
    forums.insert(forum_name,COOKIE['login'].value)
    forums.commit()

    # create database for this forum
    _get_db(forum_name)
    raise HTTP_REDIRECTION,'index'

def view(group,start=0):

    cursor = _get_db(group).cursor()

    start = int(start)
    body = BODY()

    cursor.execute('SELECT rowid FROM threads')
    nb_threads = len(cursor.fetchall())

    cursor.execute("SELECT * FROM threads ORDER BY lastDate DESC")
    result = cursor.fetchall()[start:start+threads_per_page]
    threads = [_make_dict(thread_fields,res) for res in result]

    body <= _header(group)
    
    row = TR()
    row <= TD(B(_("Threads")),width="30%",align="center")
    previous = TD(width="10%")
    if start > 0:
        previous <= A("< "+_("Previous"),href="index?start=%s" %(start-threads_per_page))
    else:
        previous <= '&nbsp'

    stat = _("Messages %s-%s of %s")
    stat = TD(stat %(start,min(start+threads_per_page,nb_threads),nb_threads),
        width="20%")

    next = TD(width="10%")
    if start+threads_per_page < nb_threads:
        next <= A(_("Next")+' >',href="index?start=%s" %(start+threads_per_page))
    else:
        next <= '&nbsp;'
    row <= previous + stat + next
    row <= TD(A(_("Start new thread"), href='new_thread?group=%s' %group),
        align="right",width="30%")

    body <= TABLE(row,Class="header")+P()

    table = TABLE(Class="forum",cellspacing=0,cellpadding=3)

    row1 = TR()
    row1 <= TH(_('Title'))
    row1 <= TH(_('Author'))
    row1 <= TH(_('Date'))
    row1 <= TH(_('Answers'))
    table <= row1
    
    for i,msg in enumerate(threads):
        table <= _display(i,msg,group)

    body <= table

    print HTML(head+body)

def logout():
    Logout(valid_in='/')

def new_thread(group):
    Login(role=["admin","edit"],add_user=True)

    body = BODY()
    body <= _header(group)
    body <= H3(_("New message"))
    author = COOKIE["login"].value
    form = FORM(action=THIS.rel("save_message"),method="post")
    form <= INPUT(Type="hidden",name="group",value=group)
    form <= INPUT(Type="hidden",name="parent",value="-1")
    form <= INPUT(Type="hidden",name="author",value=author)
    form <= TR(TD(_("Title")))+TR(TD(INPUT(name="title",size="80")))
    form <= TR(TD(_("Your message"),valign="top"))
    form <= TR(TD(TEXTAREA(name="content",rows="20",cols="80")))
    form <= TR(TD(
        INPUT(Type="submit",value=_("Send message"))+
        INPUT(Type="button",value=_("Cancel"),onClick="location.href='index';")
        ,align="left"))
    
    body <= TABLE(form)
    print HTML(head + body)

def save_message(**kw):
    group = kw["group"]
    db = _get_db(group)
    cursor = db.cursor()

    parent=int(kw["parent"])
    # what thread does this message belong to ?
    if parent!=-1:
        cursor.execute("SELECT * FROM forum WHERE recid=%s" %parent)
        thread = _make_dict(forum_fields,cursor.fetchone())["thread"]
        kw["thread"] = thread

    date=datetime.datetime.now()
    kw["date"] = date
    kw["lastDate"] = date
    kw["numChildren"] = 0
    kw["author"] = COOKIE['login'].value

    if parent == -1:
        # create thread
        t = (kw["author"],kw["title"],date,date,0)
        sql = 'INSERT INTO threads (%s) VALUES(?,?,?,?,?)' \
            %','.join(thread_fields[1:])
        cursor.execute(sql,t)
        kw['thread'] = cursor.lastrowid

    t = (kw["parent"],kw["thread"],
        kw["author"],kw["title"],kw["content"],
        kw["date"],kw["lastDate"],kw["numChildren"])
    sql = 'INSERT INTO forum (%s) VALUES(?,?,?,?,?,?,?,?)' \
        %','.join(forum_fields[1:])
    cursor.execute(sql,t)

    new_id = cursor.lastrowid

    # increment number of children of all the parents of this message
    msg = None
    _parent = parent
    while _parent!=-1:
        res = cursor.execute("SELECT * FROM forum WHERE recid=?",(_parent,)).fetchone()
        if res:
            msg=_make_dict(forum_fields,res)
            cursor.execute("UPDATE forum SET numChildren=? WHERE recid=?",
                (msg["numChildren"]+1,msg["recid"]))
            _parent=msg["parent"]
        else:
            break

    if parent != -1:
        # update lastDate and nbChildren of the thread record
        cursor.execute("SELECT numChildren FROM threads WHERE recid=?",(thread,))
        num_children = cursor.fetchone()[0]
        sql = "UPDATE threads SET lastDate=?,numChildren=?"
        sql += " WHERE recid=?"
        cursor.execute(sql,(date,num_children+1,thread))

    db.commit()
    raise HTTP_REDIRECTION,"view?group=%s" %group

def show_thread(group,thread):

    cursor = _get_db(group).cursor()

    script = SCRIPT("""selectedMsg = null\nsave_html = ''\ntitle = ''""")

    def display_leaf(msg,indent):
        line = BR()+"&nbsp;"*indent*2
        line += A(msg['author'],Class="msg",
            href='#%s' %msg["recid"])
        line += '&nbsp;'+SMALL(msg["date"].strftime('%x'))
        if Role()=="admin" and msg["parent"] != -1:
            link = "remove_msg?group=%s&msgid=%s&thread=%s" \
                %(group,msg["recid"],thread)
            line += A(SMALL(_('Remove')),href=link)
        return line

    def display_msg(msg):
        raw_content = msg["content"]
        paragraphs = raw_content.split('\n')
        text = ''
        for p in paragraphs:
            text += '\n'+'\n'.join(textwrap.wrap(p,80))
        res = DIV(Id="msg%s" %msg['recid'])
        res <= A(name=msg['recid']) 
        content = B(msg['title'])+BR()
        content += msg['author']+'&nbsp;'
        content += msg["date"].strftime('%x %H:%M')
        res <= DIV(content,style="background-color:#F0F0F0")
        res <= P()+PRE(text)
        if Role():
            author = COOKIE["login"].value
            params = "%s,'%s','%s'" %(msg["recid"],
                group,msg["title"].replace("'"," "))
            res <= '<a href="javascript:writeAnswer('+params+')">%s</a><p>\n' \
                %(_("Answer"))

        return res

        return msg['content']

    def compDate(msg1,msg2):
        return cmp(msg1["date"],msg2["date"])

    def show_tree(msg,indent):
        # shows the thread beginning at msg
        # only one line per message, indented
        leaf = display_leaf(msg,indent)
        msg_list = display_msg(msg)
        res=[]
        res=[ m for m in threadMsgs if m["parent"]==msg["recid"] ]
        res.sort(compDate)
        for childmsg in res:
            childleaves,childmsgs = show_tree(childmsg,indent+1)
            leaf += childleaves
            msg_list += childmsgs
        return leaf,msg_list

    # root of the thread
    cursor.execute("SELECT * FROM forum WHERE parent=? AND thread=?",(-1,thread))
    rootMsg = _make_dict(forum_fields,cursor.fetchone())

    # retrieves all messages of the thread
    cursor.execute("SELECT * FROM forum WHERE thread=?",(thread,))
    threadMsgs= [_make_dict(forum_fields,res) for res in cursor.fetchall()]
    
    body = BODY()
    body <= script
    body <= _header(group)
    body <= A(_("Back to forum"),href="view?group=%s" %group)
    body <= P()+B(rootMsg["title"])

    tree,msg_list = show_tree(rootMsg,1)
    
    body <= TABLE(TR(TD(tree,Class="msg_tree")+TD(msg_list)),Class="forum")

    print HTML(head+body)

answers = 0

def remove_msg(group,msgid,thread):

    db = _get_db(group)
    cursor = db.cursor()

    thread = int(thread)

    def removeChildren(msg):
        global answers
        children = cursor.execute("SELECT * FROM forum WHERE parent=?",(msg["recid"],))
        cursor.execute("DELETE FROM forum WHERE recid=?",(msg["recid"],))
        answers += 1
        for child in [_make_dict(forum_fields,res) for res in children.fetchall()]:
            removeChildren(child)

    msg = _make_dict(forum_fields,
        cursor.execute("SELECT * FROM forum WHERE recid=?",(msgid,)).fetchone())
    removeChildren(msg)

    # decrement number of replies
    while True:
        parent = msg["parent"]
        if parent == -1:
            break
        p = _make_dict(forum_fields,
            cursor.execute("SELECT * FROM forum WHERE recid=?",(parent,)).fetchone())
        new_nc = p["numChildren"] - answers
        cursor.execute("UPDATE forum SET numChildren=? WHERE recid=?",
            (new_nc,parent))
        msg = p

    # idem in threads
    cursor.execute('SELECT numChildren FROM threads WHERE recid=?',(thread,))
    numChildren = cursor.fetchone()[0]
    cursor.execute('UPDATE threads SET numChildren=? WHERE recid=?',
        (numChildren-1,thread))

    db.commit()
    raise HTTP_REDIRECTION,'show_thread?group=%s&thread=%s' %(group,thread)

def remove_thread(group,thread_id):
    db = _get_db(group)
    cursor = db.cursor()
    thread_id = int(thread_id)
    cursor.execute("DELETE FROM threads WHERE recid=?" ,(thread_id,))
    cursor.execute("DELETE FROM forum WHERE thread=?" ,(thread_id,))
    db.commit()
    raise HTTP_REDIRECTION,'view?group=%s' %group