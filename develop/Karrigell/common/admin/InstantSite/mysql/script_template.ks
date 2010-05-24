import os
import settings
from HTMLTags import *

# unicode
SET_UNICODE_OUT('utf-8')

# file with MySQL connection info : host,user,password
mysql_settings_file = os.path.join(CONFIG.data_dir,'mysql_settings.py')

mgmt = Import('management')

db_name = "$db_name"
table_name = "$table_name"

def _header():
    if Role():
        cell = COOKIE['login'].value
        cell += A(_('Logout'),href='logout')
    else:
        cell = A(_('Login'),href='login')
    return TABLE(TR(TD(cell,align="right")),width="100%")

def index():
    exec(open(mysql_settings_file).read())
    settings_file = os.path.join(CONFIG.data_dir,'mysql_admin',
        host,user,db_name,table_name,'settings.py')
    conf = settings.Settings(settings_file).load()
    
    content = H3('views')
    for view in conf['views']:
        content += A(view,href="show?view=%s" %view)+BR()
    content += H3('Edit forms')
    for form in conf['edit_forms']:
        content += A(view,href="edit?form=%s" %form)+BR()
        
    header = _header()
    add_record = ''
    print KT('appli_template.kt',**locals())

def show(view,start=0,**kw):
    header = _header()
    content = mgmt.browse_table(db_name,table_name,view,start,Role(),**kw)
    add_record = ''
    if Role()=='admin':
        add_record = A(_('New record'),href="edit?form=default")

    print KT('appli_template.kt',**locals())

def edit(form,field=None,value=None):
    # restrict access to administrator
    Login(role=["admin"],valid_in='/')
    header = _header()
    content = mgmt.edit_record(db_name,table_name,form,field,value)
    add_record = ''
    print KT('appli_template.kt',**locals())

def update_record(**kw):
    # restrict access to administrator
    Login(role=["admin"],valid_in='/')
    mgmt.update_record(db_name,table_name,**kw)
    raise HTTP_REDIRECTION,'index'

def delete_record(field,value):
    # restrict access to administrator
    Login(role=["admin"],valid_in='/')
    mgmt.delete_record(db_name,table_name,field,value)
    raise HTTP_REDIRECTION,'index'

def login():
    Login(role=['admin'],valid_in='/',redir_to=THIS.script_url)

def logout():
    Logout(valid_in='/',redir_to=THIS.script_url)
    