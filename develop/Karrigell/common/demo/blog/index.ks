import os
import datetime
import calendar
import locale
locale.setlocale(locale.LC_ALL,'')

print '<html><head>'
print '<title>Blog</title>'
print '<link rel="stylesheet" type="text/css" href="../blog.css">'
print '<meta http_equiv="Content-Type" content="text/html; charset=utf-8">'
print '</head><body>'
print '<a href="/">'
print '<img src="/doc/images/karrigell.jpg" border="0" width="100">'
print '</a>'
print '<form action = "new_entry"><input type="submit" value="New">'
print '</form>'
print '<p>'
print '<div class="header">'
print '<div class="blogtitle">Karrigell Blog Demo</div></div>'

sqlite = CONFIG.sqlite # sqlite module

db_path = os.path.join(CONFIG.data_dir,"blog.sqlite")
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
        parent TEXT, title TEXT, \
        author TEXT, text TEXT, date TEXT)")
fields = ['recid','parent','title','author','text','date']
is_logged = Role() == "admin"

try:
    set([])
except NameError:
    from sets import Set as set
    
def _make_dict(row):
    res = {}
    for field,item in zip(fields,row):
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
    res = cursor.execute("SELECT * FROM blog WHERE parent=-1")
    threads = [_make_dict(row) for row in res.fetchall()]
    months = set([(t["date"].year,t["date"].month) for t in threads ])
    # only threads for current month
    threads = [ t for t in threads if t["date"].year == year
        and t["date"].month == month ]
    # sort by date
    threads.sort(lambda t1,t2:cmp(t2["date"],t1["date"]))
    days = set([t["date"].day for t in threads ])

    # print current month calendar
    print '<table cellspacing="10">'
    print '<tr><td valign="top">'
    print datetime.date(year,month,1).strftime('%B %Y')+'<br>'
    print '<pre>'
    print calendar.weekheader(3)
    for week in calendar.monthcalendar(year,month):
        ws = ''
        for day in week:
            if day == 0:
                ws += '    '
            elif day in days:
                ws += '<a class="days" href="#msg%s">%3s</a> ' %(day,day)
            else:
                ws += '%3s '%day
        print ws
    print '</pre>'
    
    print '<p>Archives'
    arch = list(months)
    arch.sort()
    for line in arch:
        d = datetime.date(line[0],line[1],1)
        print '<br><a class="archive" href="index?year=%s&month=%s">%s</a>' %(d.year,
            d.month,d.strftime('%B %Y'))
    # admin
    if is_logged:
        print '<p><small><a href="logout">Logout</a></small>'    
    else:
        print '<p><small><a href="login">Admin</a></small>'
    print '</td>'
    
    # print threads for current month
    print '<td valign="top">'
    for r in threads:
        res = cursor.execute("SELECT * FROM blog WHERE parent = %s" %r['recid'])
        comments = [ _make_dict(row) for row in res.fetchall() ]
        print '<a name="msg%s">' %r["date"].day
        print '<div class="day">%s</div>' %r["date"].strftime('%x')
        print '<div class="title">%s</div>' %r["title"]
        print '<p><div class="text">',r["text"],'</div>'
        print '<p><div class="posted">Posted by %s at %s' \
            %(r["author"],r["date"].strftime('%H:%M:%S'))
        if is_logged:
            print '<small><a href="remove?rec_id=%s">Remove</a></small>' %r["recid"]
        print '</div><p><div class="posted">'
        print '<a class="comments" href="showComments?parent=%s">' \
            '%s comments</a></div><p>' %(r["recid"],len(comments))
    print '</td></tr></table>'
    print '</body></html>'

def login():
    Login(role=["admin"])

def logout():
    Logout()

def showComments(parent):
    parent = int(parent)
    res = cursor.execute("SELECT * FROM blog WHERE recid=%s" %parent)
    r_parent = _make_dict(res.fetchone())
    p_date = r_parent["date"]
    
    res = cursor.execute("SELECT * FROM blog WHERE parent=%s" %r_parent["recid"])
    comments = [ _make_dict(row) for row in res.fetchall() ]
    for comment in comments:
        print '<div class="title">'+comment["title"]+'</div>'
        print '<p><div class="text">'+comment["text"]+'</div>'
        print '<p><div class="posted">Posted by %s %s</div><p>' %(comment["author"],
            comment["date"].strftime('%x at %H:%M:%S'))
        if is_logged:
            print '<p><small><a href="remove?rec_id=%s">Remove</a></small>' \
                %comment["recid"]
    print '<hr>'
    new_entry(title=r_parent["title"],parent=parent)
    print '<a href="index?year=%s&month=%s">' %(p_date.year,p_date.month)
    print 'Cancel</a>'

def new_entry(title='',parent=-1):
    print '<form action="insert_entry" method="post">'
    print '<input type="hidden" name="parent" value="%s">' %parent
    print '<table>'
    print '<tr><td>Name</td><td><input name="author"></tr>'
    print '<tr><td>Title</td><td><input name="title" size="50" value="%s"></tr>' %title
    print '<tr><td>Text</td>'
    print '<td><textarea name="text" rows="20" cols="50"></textarea></td></tr>'
    print '</table>'
    print '<input type="submit" value="Ok"></form>'

def insert_entry(**kw):
    kw['parent'] = int(kw['parent'])
    if kw['parent'] == -1:
        t_date = datetime.date.today()
    else:
        res = cursor.execute("SELECT * FROM blog WHERE recid=%s" %kw["parent"])
        r_parent = _make_dict(res.fetchone())
        t_date = r_parent["date"]
    kw['date'] = datetime.datetime.now()
    # replace blank lines by <p>
    kw["text"] = kw["text"].replace("\r\n\r\n","<p>")
    # replace singlequotes by 2 single quotes
    for field in ["title","author","text"]:
        kw[field]=kw[field].replace("'","''")
    values = "%s,'%s','%s','%s','%s'" %(kw["parent"],kw["title"],
        kw["author"],kw["text"],kw["date"])
    cursor.execute("INSERT INTO blog (parent,title,author,text,date) \
        VALUES (%s)" %values)
    db.commit()
    raise HTTP_REDIRECTION,"index?year=%s&month=%s" %(t_date.year,t_date.month)

def remove(rec_id):
    if is_logged:
        rec_id = int(rec_id)
        del db[rec_id]
        db.delete([r for r in db._parent[rec_id]])
        db.commit()
    raise HTTP_REDIRECTION,"index?year=%s&month=%s" \
        %(Session().year,Session().month)