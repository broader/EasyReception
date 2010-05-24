import os
from datetime import date, datetime
from HTMLTags import *

import MySQLdb

# restrict access to administrator
Login(role=["admin"],valid_in='/')
user = COOKIE['login'].value

if not os.path.exists(REL(user)):
    # new user
    os.mkdir(REL(user))
    os.mkdir(REL(user,'images'))

import shutil
for fname in os.listdir(REL("applications")):
    if os.path.isfile(REL("applications",fname)):
        if fname.startswith('.'):
            continue
        shutil.copyfile(REL("applications",fname),REL(user,fname))
for fname in os.listdir(REL("applications","images")):
    if os.path.isfile(REL("applications","images",fname)):
        if fname.startswith('.'):
            continue
        shutil.copyfile(REL("applications","images",fname),
            REL(user,"images",fname))

# unicode
SET_UNICODE_OUT('utf-8')

# file with MySQL connection info : host,user,password
mysql_settings_file = os.path.join(CONFIG.data_dir,'mysql_settings.py')

def _hidden(**kw):
    return Sum([INPUT(Type="hidden",name=key,value=value)
        for (key,value) in kw.iteritems()])

def _actions(db_name,table_name):
    links = []
    for icon,title,href in [
        ('b_props',_('Settings'),'../table.ks/table_structure'),
        ('b_drop',_('Drop'),'drop_table')]:

        pic = IMG(src='../images/%s.png' %icon,border=0)
        links.append(A(pic,
            href='%s?db_name=%s&table_name=%s' %(href,db_name,table_name),
            title=title))
    return TABLE(TR(Sum([TD(link,Class='tb_table') for link in links])))

def index(db_name=None,table_name=None):
    try:
        exec(open(mysql_settings_file).read())
    except:
        content = A(_('Home'),href='/')
        content += H1('MySQL database management')
        content += "Connection information (host,user,password) is not available. "
        content += BR()+A("Set it",href='/admin/databases')
        print KT('msg_template.kt',**locals())
        raise SCRIPT_END
    frameset = FRAMESET(cols="200,*")
    if db_name is not None:
        frameset <= FRAME(src="menu?db_name=%s" %db_name)
        if table_name is None:
            frameset <= FRAME(name="right",src="show_db?db_name=%s" %db_name)
        else:
            frameset <= FRAME(name="right",
                src="../table.ks/table_structure?db_name=%s&table_name=%s" 
                %(db_name,table_name))
    else:
        frameset <= FRAME(src="menu")
        frameset <= FRAME(name="right",src="show_db")
    print frameset

def _connection():
    exec(open(mysql_settings_file).read())
    return MySQLdb.connect(host=host,user=user,
        passwd=password)
    
def _cursor():
    exec(open(mysql_settings_file).read())
    connection = MySQLdb.connect(host=host,user=user,
        passwd=password)
    return connection.cursor()

def menu(db_name=None):
    cursor = _cursor()
    cursor.execute("SHOW DATABASES")
    dbs = [ db[0] for db in cursor.fetchall()
            if not db[0] in ['information_schema','mysql'] ]

    if db_name is None:
        res = ''
        for db in dbs:
            res += A(db,href="index?db_name=%s" %db,target="_top")+BR()
    else:
        form = FORM(Id="home",action='index',target="_top")
        options = [ OPTION(db,value=db,selected=db==db_name)
            for db in dbs]
        form <= SELECT(Sum(options),name="db_name",
            onChange="document.getElementById('home').submit()")
        res = form
        res += A(B(db_name),href='show_db?db_name=%s' %db_name,target="right")
        res += UL(_show_tables(db_name))

    print KT('menu_template.kt',stylesheet='../menu.css',
        content=res)

def _show_tables(db):
    cursor = _cursor()
    cursor.execute('USE %s' %db)
    cursor.execute('SHOW TABLES')
    res = ''
    for table_info in cursor.fetchall():
        tname = table_info[0]
        res += LI(A(tname,
            href="../table.ks/table_structure?db_name=%s&table_name=%s"
                %(db,tname),target="right"))+'\n'
    return res

def _detailed_tables(db_name):
    cursor = _cursor()
    cursor.execute('USE %s' %db_name)
    cursor.execute('SHOW TABLES')
    table = TABLE(Class="db_tables")
    table <= TR(TH(_('Name'))+TH(_('Fields'))+TH(_('Records'))+TH(_('Actions')))
    for table_info in cursor.fetchall():
        table_name = table_info[0]
        cells = TD(table_name,Class='db_table')
        cursor.execute('DESCRIBE %s' %table_name)
        fields = [row[0] for row in cursor.fetchall()]
        cells += TD(SELECT().from_list(fields),Class='db_table')
        cursor.execute('SELECT COUNT(*) FROM %s' %table_name)
        cells += TD(cursor.fetchone()[0],Class='rec_num')
        cells += TD(_actions(db_name,table_name))
        table <= TR(cells)
    return table

def show_db(db_name=None):
    exec(open(mysql_settings_file).read())
    stylesheet = '../manage.css'
    cursor = _cursor()
    if db_name:
        cursor.execute('USE %s' %db_name)
        cursor.execute('SHOW TABLES')
        table_info = cursor.fetchall()
        if table_info:
            content = H4(_("Structure"))
            content += _detailed_tables(db_name)
            drop = ''
        else:
            content = _('This database has no table')
            drop = FORM(action='drop_db')
            drop <= INPUT(Type="hidden",name="db_name",value=db_name)
            drop <= INPUT(Type="submit",value="Drop database")
            content += drop
        create = TD(H5(_("New table")))
        form = FORM(action="../table.ks/table_structure")
        form <= _hidden(db_name=db_name,new=1)
        form <= INPUT(name="table_name")+INPUT(Type="submit",value=_('Create'))
        create += TD(form)
        content += P()+TABLE(TR(create))
        print KT('db_template.kt',**locals())
    else:
        cursor.execute('SHOW DATABASES')
        content = _('%s databases') %(len(cursor.fetchall())-2)

        create = TD(H5(_("New database")))
        form = FORM(action="create_db",target="_top")
        form <= INPUT(name="db_name")+INPUT(Type="submit",value=_('Create'))
        create += TD(form)

        content += create
        print KT('home_template.kt',**locals())

def create_db(db_name):
    cursor = _cursor()
    cursor.execute('CREATE DATABASE IF NOT EXISTS %s' %db_name)
    raise HTTP_REDIRECTION,'index?db_name=%s' %db_name

def drop_db(db_name):
    exec(open(mysql_settings_file).read())
    cursor = _cursor()
    cursor.execute('USE %s' %db_name)
    cursor.execute('SHOW TABLES')
    if len(cursor.fetchall()):
        content = "Can't drop database %s " %db_name
        content += "; all tables must be dropped first"
    else:
        content = "Are you sure you want to delete database %s ?" %db_name
        content += P()+FORM(INPUT(Type="hidden",name="db_name",value=db_name)+
            INPUT(Type="submit",value="Drop database"),
            action="drop_db_confirm",target="_top")
        content += INPUT(Type="button",value="Cancel",onClick="javascript:back()")

    print KT('db_template.kt',**locals())
    
def drop_db_confirm(db_name):
    _cursor().execute('DROP DATABASE %s' %db_name)
    raise HTTP_REDIRECTION,'index'

def drop_table(db_name,table_name):
    exec(open(mysql_settings_file).read())
    content = P()+"Are you sure you want to delete table %s" %table_name
    content += "? This will erase all data"
    row = TR()
    row <= TD(FORM(_hidden(db_name=db_name,table_name=table_name)+
        INPUT(Type="submit",value=_("Drop table")),
        action="drop_table_confirm",target="_top"))
    row <= TD(FORM(_hidden(db_name=db_name)+
        INPUT(Type="submit",value=_("Cancel")),
        action="show_db"))
    content += P()+TABLE(row)
    print KT('db_template.kt',**locals())

def drop_table_confirm(db_name,table_name):
    cursor = _cursor()
    cursor.execute('USE %s' %db_name)
    cursor.execute('DROP TABLE %s' %table_name)
    raise HTTP_REDIRECTION,"../index.ks/index?db_name=%s" %db_name


