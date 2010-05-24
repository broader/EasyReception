import os
import datetime
import calendar
import locale

locale.setlocale(locale.LC_ALL,'')
locale_encoding = locale.getlocale()[1]
if locale_encoding is None:
    import sys
    locale_encoding = sys.getdefaultencoding()

from HTMLTags import *

SET_UNICODE_OUT('utf-8')

# this script is called by url /blogs/sqlite/(blog_id)
blog_id = THIS.script_url.split('/')[3]

# dir for all blogs
blogs_dir = os.path.join(CONFIG.data_dir,'blogs')
if not os.path.exists(blogs_dir):
    os.mkdir(blogs_dir)

# dir for this blog
blog_dir = os.path.join(blogs_dir,blog_id)
if not os.path.exists(blog_dir):
    if blog_id == "blog":
        os.mkdir(blog_dir)
    else:
        print "Blog %s does not exist" %blog_id
        raise SCRIPT_END

settings_file = os.path.join(blog_dir,'blog_settings.py')
if not os.path.exists(settings_file):
    import shutil
    shutil.copyfile(REL('default_blog_settings.py'),settings_file)

exec(open(settings_file).read())

if Role() is None:
    login_link = A(_('Login'),href='login')
else:
    login_link = COOKIE['login'].value+'&nbsp;'
    login_link += A(_('Logout'),href='logout')

# search box
search_box = FORM(action="search")
search_box <= INPUT(name="key")+BR()+\
    INPUT(Type="submit",value=_('Search'))

# admin links if user is logged in
admin = ''
if Role()=='admin':
    admin = P()+DIV(_('Administration'),Class="admin")
    admin += A(_('Settings'),href="settings")+BR()
    admin += A(_('New entry'),href="new_blog_entry")+BR()
    admin += A(_('Create a new blog'),href="create_new_blog")

# ========
# database
import k_databases

sqlite = k_databases.get_engines()['SQLite'] # sqlite module

db_path = os.path.join(blog_dir,"blog.sqlite")
db = sqlite.connect(db_path)
cursor = db.cursor()
cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
flag = False
for table_info in cursor.fetchall():
    if table_info[0] == "blog":
        flag = True
        break

if not flag:
    cursor.execute("CREATE TABLE blog (recid INTEGER PRIMARY KEY AUTOINCREMENT, \
        title TEXT, author TEXT, text TEXT, date BLOB)")
    cursor.execute("CREATE TABLE comments (recid INTEGER PRIMARY KEY AUTOINCREMENT, \
        parent INTEGER, \
        author TEXT, text TEXT, date BLOB)")

fields = {'blog':['recid','title','author','text','date'],
    'comments':['recid','parent','author','text','date']
    }
# ===========

is_logged = Role() == "admin"

try:
    set([])
except NameError:
    from sets import Set as set
    
def _make_dict(table,row):
    res = {}
    for field,item in zip(fields[table],row):
        if field == 'date':
            y = int(item[:4])
            m = int(item[5:7])
            d = int(item[8:10])
            H = int(item[11:13])
            M = int(item[14:16])
            S = int(item[17:19])
            res[field] = datetime.datetime(y,m,d,H,M,S)
        else:
            res[field] = item
            if isinstance(item,unicode):
                res[field] = item.encode('utf-8')
    return res

def _dates(year,month,threads=None):

    if threads is None:
        threads = _get_threads()
    # months with at least one thread
    months = set([(t["date"].year,t["date"].month) for t in threads ])

    # only threads for specified year / month
    threads = [ t for t in threads if t["date"].year == year
        and t["date"].month == month ]
    # days of this month with at least one thread
    days = set([t["date"].day for t in threads ])

    # current month calendar
    m_str = datetime.date(year,month,1).strftime('%B %Y').capitalize()
    if locale_encoding is not None:
        m_str = unicode(m_str,locale_encoding).encode('utf-8')
    cal = TR(TD(m_str,colspan="7"))
    cal += TR(TD(calendar.weekheader(3),colspan=7))
    for week in calendar.monthcalendar(year,month):
        week_row = TR()
        for day in week:
            if day == 0:
                week_row <= TD('&nbsp;')
            elif day in days:
                week_row <= TD(A('%3s' %day,href="#msg%s" %day,Class="days"))
            else:
                week_row <= TD('%3s '%day)
        cal += week_row
    dates = TABLE(cal)
    for item in dates.get_by_tag('TD'):
        item.attrs['Class'] = 'calendar'
    dates += DIV('Archives',Class="admin")
    arch = list(months)
    arch.sort()
    for line in arch:
        d = datetime.date(line[0],line[1],1)
        if locale_encoding is not None:
            m_str = unicode(d.strftime('%B %Y'),locale_encoding).encode('utf-8')
        dates += A(m_str,Class="archive",
            href="index?year=%s&month=%s"%(d.year,d.month))
    return dates

def _get_threads():
    # get all threads
    res = cursor.execute("SELECT * FROM blog")
    threads = [_make_dict('blog',row) for row in res.fetchall()]
    return threads

def _get_links():
    links = A('Karrigell',href='http://karrigell.sourceforge.net')
    return links

def index(year=None,month=None):
    """Print all the threads for specified month"""
    if year is None:
        today = datetime.date.today()
        year,month = today.year,today.month
    else:
        year,month = int(year),int(month)
    Session().year = year
    Session().month = month
    # get all threads
    threads = _get_threads()
    # sort by date
    threads.sort(lambda t1,t2:cmp(t2["date"],t1["date"]))

    dates= _dates(year,month,threads)
    
    # threads for current month
    messages = ''
    for r in threads:
        # comments
        res = cursor.execute("SELECT * FROM comments WHERE parent = %s" %r['recid'])
        nb_comments = len(res.fetchall())
        messages += A(name="msg%s" %r["date"].day)
        messages += DIV(r["title"],Class="title")
        messages += DIV('Posted by %s - %s' 
            %(r["author"],r["date"].strftime('%x %H:%M')),
            Class="posted")
        messages += P()+DIV(r["text"],Class="text")+P()
        messages += P()
        links = A('%s comments' %nb_comments,
            href="showComments?parent=%s" %r["recid"])
        if Role()=='admin':
            links += '&nbsp;'
            links += A(_('Edit'),href='edit_blog_entry?recid=%s' %r["recid"])
            links += '&nbsp;'
            links += A(_('Delete'),href='delete_blog_entry?recid=%s' %r["recid"])
        for item in links.get_by_tag('A'):
            item.attrs['style']='font-size:12'
        messages += DIV(links,Class="posted")
    
    # links
    links = _get_links()
 
    print KT('blog_template.kt',blog_name=blog_name,
        blog_css=blog_css,login_link=login_link,
        title_line1=title_line1,title_line2=title_line2,
        search_box=search_box,
        admin=admin,
        **locals())

def login():
    Login(role=["admin"],redir_to=THIS.script_url,valid_in='/')

def logout():
    Logout(valid_in='/')

def showComments(parent):
    parent = int(parent)
    res = cursor.execute("SELECT * FROM blog WHERE recid=%s" %parent)
    r = _make_dict('blog',res.fetchone())
    p_date = r["date"]

    # original message
    messages = DIV(r["title"],Class="title")
    messages += DIV('Posted by %s - %s' 
        %(r["author"],r["date"].strftime('%x %H:%M:%S')),
        Class="posted")
    messages += P()+DIV(r["text"],Class="text")+P()
    messages += P()+HR()

    # comments        
    res = cursor.execute("SELECT * FROM comments WHERE parent=%s" %r["recid"])
    messages += B(_('Comments'))+P()
    comments = [ _make_dict('comments',row) for row in res.fetchall() ]
    for comment in comments:
        messages += P()+DIV('Posted by %s %s' %(comment["author"],
            comment["date"].strftime('%x at %H:%M:%S')),
            Class="posted")
        messages += P()+DIV(comment["text"],Class="text")
    messages += HR()+B(_('Your comment'))+P()
    messages += _comment_form(r['recid'])

    print KT('blog_template.kt',blog_name=blog_name,
        blog_css=blog_css,login_link=login_link,
        title_line1=title_line1,title_line2=title_line2,
        search_box=search_box,
        dates = _dates(Session().year,Session().month),
        links=_get_links(),
        admin=admin,
        **locals())

def new_blog_entry():
    Login(role=['admin'])
    dates = _dates(Session().year,Session().month)
    messages = _blog_entry_form()
    links = _get_links()
    print KT('blog_template.kt',blog_name=blog_name,
        blog_css=blog_css,login_link=login_link,
        title_line1=title_line1,title_line2=title_line2,
        search_box=search_box,
        admin=admin,
        **locals())

def create_new_blog():
    Login(role=['admin'])
    dates = _dates(Session().year,Session().month)
    form = FORM(action="make_new_blog",method="post")
    table = TABLE()
    table <= TR(TD('Blog identifier')+TD(INPUT(name="blog_id")))
    form <= table
    form <= INPUT(Type="submit",value="Ok")
    print KT('settings_template.kt',blog_name=blog_name,
        blog_css=blog_css,login_link=login_link,
        **locals())

def make_new_blog(blog_id):
    blog_dir = os.path.join(blogs_dir,blog_id)
    if os.path.exists(blog_dir):
        message = H4("This blog already exists")
        message += A(_('Back'),href="create_new_blog")
        print KT('msg_template.kt',blog_css=blog_css,login_link=login_link,
            **locals())
    else:
        os.mkdir(blog_dir)
        raise HTTP_REDIRECTION,'../../%s' %blog_id

# =============
# forms for blog entry or comment

# buttons for the whizzywig textarea
ww_buttons ='bold italic underline | left center right justify | '
ww_buttons += 'number bullet indent outdent | undo redo | color hilite rule | '
ww_buttons += 'link image';

def _blog_entry_form(recid=-1,title='',text=''):
    entry = FORM(action="insert_blog_entry",method="post")
    entry <= INPUT(Type="hidden",name="recid",value=recid)
    table = TABLE()
    table <= TR(TD('Title')+TD(INPUT(name="title",size="50",value=title)))
    script = 'btn._f="/whizzywig/WhizzywigToolbar.png";\n'
    script += 'makeWhizzyWig("blog_text","%s")' %ww_buttons
    table <= TR(TD('Text',valign="top")+
        TD(TEXTAREA(text,Id="blog_text",name="text",rows="20",cols="50")+
            SCRIPT(script,Type="text/javascript")))
    table <= TR(TD('&nbsp;')+
        TD(INPUT(Type="submit",name="subm",value="Ok")+
        INPUT(Type="submit",name="subm",value=_("Cancel"))))
    entry <= table
    return entry

def _comment_form(parent):
    entry = FORM(action="insert_comment",method="post")
    entry <= INPUT(Type="hidden",name="parent",value=parent)
    table = TABLE()
    table <= TR(TD(_('Author'))+TD(INPUT(name="author",size="50")))
    script = 'btn._f="/whizzywig/WhizzywigToolbar.png";\n'
    script += 'makeWhizzyWig("comment_text","%s")' %ww_buttons
    table <= TR(TD(_('Text'),valign="top")+
        TD(TEXTAREA(name="text",id="comment_text",rows="20",cols="50")+
           SCRIPT(script,Type="text/javascript")))
    table <= TR(TD('&nbsp;')+
        TD(INPUT(Type="submit",name="subm",value="Ok")+
        INPUT(Type="submit",name="subm",value=_("Cancel"))))
    entry <= table
    return entry

def _settings_table(blog_name='',title_line1='',title_line2=''):
    table = TABLE()
    table <= TR(TD('Blog name')+
                TD(INPUT(name='blog_name',value=blog_name)))
    table <= TR(TD('Title line 1')+
                TD(INPUT(name='title_line1',value=title_line1,size=50)))
    table <= TR(TD('Title line 2')+
                TD(INPUT(name='title_line2',value=title_line2,size=50)))
    return table

def settings():
    form = FORM(action="update_settings",method="post")
    table = _settings_table(blog_name,title_line1,title_line2)
    form <= table+INPUT(Type="submit",value="Ok")

    print KT('settings_template.kt',blog_name=blog_name,
        blog_css=blog_css,login_link=login_link,
        **locals())

def update_settings(**kw):
    settings = {}
    settings_file = os.path.join(blog_dir,'blog_settings.py')
    exec open(settings_file).read() in settings
    settings.update(kw)
    out = open(settings_file,"w")
    # encoding must be specified
    out.write('# -*- coding: utf-8 -*-\n')
    for k,v in settings.iteritems():
        if not k.startswith('_'):
            out.write('%s="%s"\n' %(k,v))
    out.close()
    raise HTTP_REDIRECTION,'index'

def insert_blog_entry(subm,recid,title,text):
    if subm != 'Ok':
        raise HTTP_REDIRECTION,'index'
    recid = int(recid)
    # replace blank lines by <p>
    t_date = datetime.datetime.now()
    text = text.replace("\r\n\r\n","<p>")
    author = COOKIE['login'].value
    if recid == -1:
        # new entry
        cursor.execute("INSERT INTO blog (title,author,text,date) \
            VALUES (?,?,?,?)",(title,author,text,t_date))
    else:
        # existing entry ; don't change the date
        sql = "UPDATE blog SET title=?,author=?,text=?"
        sql += " WHERE recid=?"
        cursor.execute(sql,(title,author,text,recid))
    db.commit()
    raise HTTP_REDIRECTION,"index?year=%s&month=%s" %(t_date.year,t_date.month)

def insert_comment(subm,parent,author,text):
    if subm=="Ok":
        if not author.strip() or not text.strip():
            message = "Please enter the author name and a text"
            print KT('blog_template.kt',locals()())
        parent = int(parent)
        t_date = datetime.datetime.now()
        # replace blank lines by <p>
        text = text.replace("\r\n\r\n","<p>")
        cursor.execute("INSERT INTO comments (parent,author,text,date) \
            VALUES (?,?,?,?)",(parent,author,text,t_date))
        db.commit()
        raise HTTP_REDIRECTION,"index?year=%s&month=%s" %(t_date.year,t_date.month)
    else:
        raise HTTP_REDIRECTION,"index"

def edit_blog_entry(recid):
    res = cursor.execute("SELECT * FROM blog WHERE recid=%s" %recid)
    r = _make_dict('blog',res.fetchone())
    import cgi
    
    form = _blog_entry_form(r['recid'],r['title'],cgi.escape(r['text']))

    print KT('settings_template.kt',blog_name=blog_name,
        blog_css=blog_css,login_link=login_link,
        **locals())

def search(key):
    print 'not implemented'

def delete_blog_entry(recid):
    if Role()=="admin":
        recid = int(recid)
        cursor.execute("DELETE FROM blog WHERE recid=%s" %recid)
        # delete comments
        cursor.execute("DELETE FROM comments WHERE parent=%s" %recid)
        db.commit()
    raise HTTP_REDIRECTION,"index?year=%s&month=%s" \
        %(Session().year,Session().month)