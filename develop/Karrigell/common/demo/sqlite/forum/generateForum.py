import os
import random
import datetime
import string

from PyDbLite import SQLite

def word(m):
    res = ''
    ln = random.randint(1,m)
    for i in range(ln):
        res += random.choice(string.letters)
    return res

def sentence(n,m):
    ln = random.randint(1,n)
    res = []
    for i in range(ln):
        res.append(word(m))
    return ' '.join(res)

test_dir = os.path.join(os.getcwd(),'test')
if not os.path.exists(test_dir):
    os.mkdir(test_dir)
    
db_path = os.path.join(test_dir,"forum_test.sqlite")
db = SQLite.Database(db_path)

authors = 'pierre','jean','simon','philippe','claire','muriele'

table = SQLite.Table("forum",db)
table.create(('recid','INTEGER PRIMARY KEY AUTOINCREMENT'),
    ('parent','INTEGER'),
    ('thread','INTEGER'),
    ('author','TEXT'),
    ('title','TEXT'),
    ('content','TEXT'),
    ('date','BLOB'),
    ('lastDate','BLOB'),
    ('numChildren','INTEGER'),
    mode="override")
table.is_datetime('date')
table.is_datetime('lastDate')

thread_table = SQLite.Table("threads",db)
thread_table.create(('recid','INTEGER PRIMARY KEY AUTOINCREMENT'),
    ('author','TEXT'),
    ('title','TEXT'),
    ('date','BLOB'),
    ('lastDate','BLOB'),
    ('numChildren','INTEGER'),
    mode="override")
thread_table.is_datetime('date')
thread_table.is_datetime('lastDate')

nbthreads = 200
for i in range(nbthreads):
    # generate thread
    author = random.choice(authors)
    title = sentence(10,10)
    content = sentence(100,10)
    thread_date = datetime.datetime(random.randint(2006,2008),random.randint(1,12),
        random.randint(1,28),random.randint(0,23),random.randint(0,59),
        random.randint(0,59))
    # save in threads table
    thread_id = thread_table.insert(
        author=author,
        title=title,
        date=thread_date,
        lastDate=thread_date,
        numChildren=0)
    # save in forum table
    rec_id=table.insert(parent=-1,
        thread=thread_id,
        author=author,
        title=title,
        content=content,
        date=thread_date,
        lastDate=thread_date,
        numChildren=0)

    # generate comments
    nbanswers = random.randint(0,10)
    oldest = datetime.datetime(2000,1,1,0,0,0)
    for i in range(nbanswers):
        author = random.choice(authors)
        content = sentence(50,10)
        tdelta = datetime.datetime(2009,1,1,0,0,0) - thread_date
        c_date = thread_date + datetime.timedelta(random.randint(1,tdelta.days))
        c_date = datetime.datetime(c_date.year,c_date.month,c_date.day,
          random.randint(0,23),random.randint(0,59),random.randint(0,59))
        if c_date > oldest:
            oldest = c_date
        #print "inserting child of thread %s" %thread_id
        new_id = table.insert(parent=rec_id,
            thread=thread_id,
            author=author,
            title=title,
            content=content,
            date=c_date,
            lastDate=c_date,
            numChildren=0)
        #print "new id",new_id
        #print table[new_id]
        #raw_input()
    # increment number of children
    rec = thread_table[thread_id]
    thread_table.update(rec,lastDate=oldest,numChildren=nbanswers)
table.commit()

# test

table.cursor.execute("SELECT * FROM threads")
rec = table.cursor.fetchone()
print rec
thread = rec[0]
print "thread",thread
table.cursor.execute("SELECT * FROM forum WHERE thread=%s" %thread)
for rec in table.cursor.fetchall():
    print rec

thread_table.cursor.execute("SELECT numChildren FROM threads WHERE recid=%s" %thread)
num_children = thread_table.cursor.fetchone()[0]
print "children",num_children,num_children.__class__

