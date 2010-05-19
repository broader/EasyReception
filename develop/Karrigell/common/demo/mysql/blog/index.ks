import os
import datetime
import calendar
import locale

locale.setlocale(locale.LC_ALL,'')
locale_encoding = locale.getlocale()[1]
if locale_encoding is None:
    import sys
    locale_encoding = sys.getdefaultencoding()

import settings
from HTMLTags import *

SET_UNICODE_OUT('utf-8')

# this script is called by url /blogs/mysql/(blog_id)
blog_id = THIS.script_url.split('/')[3]

# dir for all blogs
blogs_dir = os.path.join(CONFIG.data_dir,'blogs')
if not os.path.exists(blogs_dir):
    os.mkdir(blogs_dir)

if Role() is None:
    login_link = A(_('Login'),href='login')
else:
    login_link = COOKIE['login'].value+'&nbsp;'
    login_link += A(_('Logout'),href='logout')

# search box XXX
search_box = ''
"""search_box = FORM(action="search")
search_box <= INPUT(name="key")+BR()+\
    INPUT(Type="submit",value=_('Search'))"""

# admin links if user is logged in
admin = ''
if Role()=='admin':
    admin = P()+DIV(_('Administration'),Class="admin")
    admin += A(_('Settings'),href="manage_settings")+BR()
    admin += A(_('New entry'),href="new_blog_entry")+BR()
    admin += A(_('Create a new blog'),href="create_new_blog")

# ========
# database
import k_databases

MySQLdb = k_databases.get_engines()['MySQL'] # MySQL module

db_settings = k_databases.mysql_settings(CONFIG)
if db_settings is None:
    print 'No connection info for MySQL database'
    print BR()+A(_('Set it'),href='/admin/databases.ks')
    raise SCRIPT_END

db = MySQLdb.connect(db_settings['host'],db_settings['user'],
    db_settings['password'])    
cursor = db.cursor()
try:
    cursor.execute('USE karrigell_blog_%s' %blog_id)
except MySQLdb.OperationalError:
    pass

# default values
default_conf = {
    'blog_name' : 'My blog',
    'blog_css' : '../blog.css',
    'title_line1' : 'My personal blog',
    'title_line2' : 'Powered by Karrigell',

    'links' : [('Karrigell','http://karrigell.sourceforge.net')]
}

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
            href="index?year=%s&month=%s"%(d.year,d.month))+BR()
    return dates

def _get_threads():
    # get all threads
    cursor.execute("USE karrigell_blog_%s" %blog_id)
    cursor.execute("SELECT * FROM blog")
    threads = [_make_dict('blog',row) for row in cursor.fetchall()]
    return threads

def _get_links():
    links = A('Karrigell',href='http://karrigell.sourceforge.net')
    return links

def index(year=None,month=None):
    if year is None:
        today = datetime.date.today()
        year,month = today.year,today.month
    else:
        year,month = int(year),int(month)
    Session().year = year
    Session().month = month

    # dir for this blog
    settings_file = os.path.join(blogs_dir,'%s_settings.py' %blog_id)
    if not os.path.exists(settings_file):
        result = "Blog %s does not exist" %blog_id
        if Role()=="admin":
            result += BR()+A(_('Create it...'),href="make_new_blog?blog_id=%s" %blog_id)
        return result

    conf = settings.Settings(settings_file).load()

    try:
        cursor.execute('USE karrigell_blog_%s' %blog_id)
    except MySQLdb.OperationalError:
        if blog_id == 'blog':
            raise HTTP_REDIRECTION,'make_new_blog?blog_id=%s' %blog_id
        else:
            return 'no blog called %s' %blog_id

    # get all threads
    threads = _get_threads()
    # sort by date
    threads.sort(lambda t1,t2:cmp(t2["date"],t1["date"]))

    dates= _dates(year,month,threads)
    
    # threads for current month
    messages = ''
    for r in threads:
        # comments
        cursor.execute("SELECT * FROM comments WHERE parent = %s" %r['recid'])
        nb_comments = len(cursor.fetchall())
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
    anchors = Sum([A(link[0],href=link[1])+BR()
        for link in conf['links']])
 
    return KT('blog_template.kt',blog_name=conf['blog_name'],
        blog_css=conf['blog_css'],
        login_link=login_link,
        title_line1=conf['title_line1'],
        title_line2=conf['title_line2'],
        search_box=search_box,
        admin=admin,
        **locals())

def login():
    Login(role=["admin"],redir_to=THIS.script_url,valid_in='/')

def logout():
    Logout(valid_in='/')

def showComments(parent):
    parent = int(parent)
    cursor.execute("SELECT * FROM blog WHERE recid=%s" %parent)
    r = _make_dict('blog',cursor.fetchone())
    p_date = r["date"]

    # original message
    messages = DIV(r["title"],Class="title")
    messages += DIV('Posted by %s - %s' 
        %(r["author"],r["date"].strftime('%x %H:%M:%S')),
        Class="posted")
    messages += P()+DIV(r["text"],Class="text")+P()
    messages += P()+HR()

    # comments        
    cursor.execute("SELECT * FROM comments WHERE parent=%s" %r["recid"])
    messages += B(_('Comments'))+P()
    comments = [ _make_dict('comments',row) for row in cursor.fetchall() ]
    for comment in comments:
        messages += P()+DIV('Posted by %s %s' %(comment["author"],
            comment["date"].strftime('%x at %H:%M:%S')),
            Class="posted")
        messages += P()+DIV(comment["text"],Class="text")
        if Role()=="admin":
            messages += A(_('Delete'),href='delete_comment?recid=%s&parent=%s' 
                %(comment["recid"],parent))

    messages += HR()+B(_('Your comment'))+P()
    messages += _comment_form(r['recid'])

    settings_file = os.path.join(blogs_dir,'%s_settings.py' %blog_id)
    conf = settings.Settings(settings_file).load()
    conf.update(locals())
    anchors = Sum([A(link[0],href=link[1])+BR()
        for link in conf['links']])

    print KT('blog_template.kt',login_link=login_link,
        search_box=search_box,
        dates = _dates(Session().year,Session().month),
        admin=admin,anchors=anchors,
        **conf)

def delete_comment(parent,recid):
    cursor.execute('DELETE FROM comments WHERE recid=%s',(recid,))
    db.commit()
    raise HTTP_REDIRECTION,"showComments?parent=%s" %parent

def new_blog_entry():
    Login(role=['admin'])
    settings_file = os.path.join(blogs_dir,'%s_settings.py' %blog_id)
    conf = settings.Settings(settings_file).load()
    anchors = Sum([A(link[0],href=link[1])+BR()
        for link in conf['links']])
    print KT('blog_template.kt',
        login_link=login_link,
        search_box=search_box,
        admin=admin,
        dates=_dates(Session().year,Session().month),
        messages=_blog_entry_form(),
        anchors=anchors,
        **conf)

def create_new_blog():
    Login(role=['admin'])
    dates = _dates(Session().year,Session().month)
    form = FORM(action="make_new_blog",method="post")
    table = TABLE()
    table <= TR(TD('Blog identifier')+TD(INPUT(name="blog_id")))
    form <= table
    form <= INPUT(Type="submit",value="Ok")
    print KT('settings_template.kt',blog_name=default_conf['blog_name'],
        blog_css=default_conf['blog_css'],login_link=login_link,
        **locals())

def make_new_blog(blog_id):
    settings_file = os.path.join(blogs_dir,'%s_settings.py' %blog_id)
    try:
        cursor.execute('USE karrigell_blog_%s' %blog_id)
        message = H4("This blog already exists")
        message += A(_('Back'),href="create_new_blog")
        try:
            conf = settings.Settings(settings_file).load()
        except IOError:
            conf = default_conf
            settings.Settings(settings_file).save(default_conf)
        print KT('msg_template.kt',blog_css=conf['blog_css'],
            login_link=login_link,**locals())
    except MySQLdb.OperationalError:
        # create settings file
        settings_file = os.path.join(blogs_dir,'%s_settings.py' %blog_id)
        default = settings.Settings(REL('default_blog_settings.py')).load()
        settings.Settings(settings_file).save(default)

        cursor.execute('CREATE DATABASE karrigell_blog_%s' %blog_id)
        cursor.execute('USE karrigell_blog_%s' %blog_id)
        # create tables
        sql = "CREATE TABLE blog (recid INTEGER PRIMARY KEY AUTO_INCREMENT,"
        sql += "title TEXT, author TEXT, text TEXT, date TIMESTAMP)"
        cursor.execute(sql)
        sql = "CREATE TABLE comments (recid INTEGER PRIMARY KEY AUTO_INCREMENT,"
        sql += "parent INTEGER,author TEXT, text TEXT, date TIMESTAMP)"
        cursor.execute(sql)
        raise HTTP_REDIRECTION,'/blogs/mysql/%s' %blog_id

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

def _settings_table(conf):
    table = TABLE()
    table <= TR(TD('Blog name')+
                TD(INPUT(name='blog_name',value=conf['blog_name'])))
    table <= TR(TD('Title line 1')+
                TD(INPUT(name='title_line1',value=conf['title_line1'],size=50)))
    table <= TR(TD('Title line 2')+
                TD(INPUT(name='title_line2',value=conf['title_line2'],size=50)))
    return table

def manage_settings():
    form = FORM(action="update_settings",method="post")
    settings_file = os.path.join(blogs_dir,'%s_settings.py' %blog_id)
    conf = settings.Settings(settings_file).load()
    table = _settings_table(conf)
    form <= table+INPUT(Type="submit",value="Ok")

    print KT('settings_template.kt',form=form,**conf)

def update_settings(**kw):
    settings_file = os.path.join(blogs_dir,'%s_settings.py' %blog_id)
    conf = settings.Settings(settings_file).load()
    conf.update(kw)
    settings.Settings(settings_file).save(conf)
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
            VALUES (%s,%s,%s,%s)",(title,author,text,t_date))
    else:
        # existing entry ; don't change the date
        sql = "UPDATE blog SET title=%s,author=%s,text=%s"
        sql += " WHERE recid=%s"
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
            VALUES (%s,%s,%s,%s)",(parent,author,text,t_date))
        db.commit()
        raise HTTP_REDIRECTION,"index?year=%s&month=%s" %(t_date.year,t_date.month)
    else:
        raise HTTP_REDIRECTION,"index"

def edit_blog_entry(recid):
    cursor.execute("SELECT * FROM blog WHERE recid=%s" %recid)
    r = _make_dict('blog',cursor.fetchone())
    import cgi
    
    form = _blog_entry_form(r['recid'],r['title'],cgi.escape(r['text']))
    settings_file = os.path.join(blogs_dir,'%s_settings.py' %blog_id)
    conf = settings.Settings(settings_file).load()

    print KT('settings_template.kt',form=form,
        login_link=login_link,
        **conf)

def search(key):
    print 'Sorry, search is not implemented yet'

def delete_blog_entry(recid):
    if Role()=="admin":
        recid = int(recid)
        cursor.execute("DELETE FROM blog WHERE recid=%s" %recid)
        # delete comments
        cursor.execute("DELETE FROM comments WHERE parent=%s" %recid)
        db.commit()
    raise HTTP_REDIRECTION,"index?year=%s&month=%s" \
        %(Session().year,Session().month)