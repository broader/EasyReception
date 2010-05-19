import os

import k_users_db
import k_databases

from HTMLTags import *

db_engines = k_databases.get_engines()
engines = db_engines.keys()

header = HEAD()
header <= TITLE(_("Users database"))
header <= LINK(rel="stylesheet",href="../karrigell.css")

logo = A(IMG('',src="/doc/images/karrigell.jpg", border="0", width="100"),
        href="/")

SET_UNICODE_OUT('utf-8')

def index():
    # check if users database initialized
    if k_users_db.has_db_settings(CONFIG):
        body = "Users database already exists"
        print HTML(head+BODY(logo+P()+body))
        raise SCRIPT_END

    body = BODY()
    body <= logo+P()

    form = FORM(action="set_users_engine")
    table = TABLE()
    radio = RADIO(engines,name="engine")
    for engine,tag in radio:
        table <= TR(TD(tag)+TD(engine))
    form <= table
    form <= INPUT(Type="submit",value="Select users database engine")
    
    body += form
            
    print HTML(header+BODY(body))

def set_users_engine(engine):
    if k_users_db.has_db_settings(CONFIG):
        body = "Users database already exists"
        print HTML(head+BODY(logo+P()+body))
        raise SCRIPT_END

    db_engine = engines[int(engine)]
    body = logo
    body += H4('Engine for users database %s' %db_engine)
    if db_engine == 'MySQL':
        body += _mysql_settings_form(engine)
        print HTML(header+BODY(body))
        raise SCRIPT_END

    k_users_db.set_db_settings(CONFIG,db_engine)
    body += 'Users database engine set to %s' %db_engine
    body += BR()+A(_('Set administrator information'),
        href='/admin/login.ks/create_admin')
    body += BR()+A(_('Home'),href='/')
    print HTML(header+BODY(body))
        
def _mysql_settings_form(engine):
    table = TABLE()
    table <= TR(TD('Host')+TD(INPUT(name='host')))
    table <= TR(TD('User')+TD(INPUT(name='user')))
    table <= TR(TD('Password')+
        TD(INPUT(Type='password',name='password')))
    table += INPUT(Type="submit",value=_("Ok"))
    return FORM(table,action="save_mysql_settings",method="post")

def save_mysql_settings(**kw):
    for key in 'host','user','password':
        if not kw[key]:
            print 'No value for %s' %key
            raise SCRIPT_END
    import MySQLdb
    try:
        conn = MySQLdb.connect(kw['host'],kw['user'],kw['password'])
        k_users_db.set_db_settings(CONFIG,'MySQL',**kw)
        body = logo
        body += 'Users database engine set to MySQL'

    except MySQLdb.OperationalError:
        print "Can't connect to a MySQL database with these values",BR()
        print A(_('Back'),href='index')
        raise SCRIPT_END

    # check if a database karrigell_users exists, has a table users,
    # and a record with role = admin
    has_admin = False
    cursor = conn.cursor()
    try:
        cursor.execute('USE karrigell_users')
        cursor.execute('SELECT * FROM users WHERE role="admin"')
        if len(cursor.fetchall())>0:
            has_admin = True
    except:
        pass
    if not has_admin:
        body += BR()+A(_('Set administrator information'),
            href='/admin/login.ks/create_admin')
    else:
        body += BR()+'An administrator is already defined'
    body += BR()+A(_('Home'),href='/')
    print HTML(header+BODY(body))
