import os

from HTMLTags import *
import k_databases
import k_users_db

db_engines = k_databases.get_engines()
engines = db_engines.keys()

Login(role=["admin"],valid_in='/')

SET_UNICODE_OUT('utf-8')

header = HEAD(TITLE("Databases management")+
        LINK(rel="stylesheet",href="../karrigell.css"))

def index():
    body = A(_("Home"),href="/")+BR()
    body += H2("Databases")

    body += "Available Python modules"
    engine_list = UL()
    for engine in engines:
        line = B(engine)
        if engine == 'MySQL':
            line += A('Connection information...',href='mysql_settings')
        engine_list <= LI(line)
    body += engine_list
    
    print HTML(header+BODY(body))

def mysql_settings():
    body = H2('Settings for MySQL connection')
    mysql_settings_file = os.path.join(CONFIG.data_dir,'mysql_settings.py')
    try:
        mysql_settings = open(mysql_settings_file).read()
        exec(mysql_settings)
    except:
        host,user,password='','',''
    
    table = TABLE()
    table <= TR(TD('Host')+TD(INPUT(name='host',value=host)))
    table <= TR(TD('User')+TD(INPUT(name='user',value=user)))
    table <= TR(TD('Password')+
        TD(INPUT(Type='password',name='password',value=password)))
    table += INPUT(Type="submit",value=_("Update"))
    body += FORM(table,action="save_mysql_settings",method="post")
    print HTML(header+BODY(body))

def save_mysql_settings(**kw):
    for key in 'host','user','password':
        if not kw[key]:
            print 'No value for %s' %key
            raise SCRIPT_END
    import MySQLdb
    try:
        MySQLdb.connect(kw['host'],kw['user'],kw['password'])
        mysql_settings_file = os.path.join(CONFIG.data_dir,'mysql_settings.py')
        out = open(mysql_settings_file,'w')
        out.write('#MySQL settings file\n')
        for key in 'host','user','password':
            out.write("%s='%s'\n" %(key,kw[key]))
        out.close()
        body = A(_("Home"),href="/")+BR()
        body += H3('Changes saved')
        body += A(_('Back to configuration'),href='index')
        print HTML(header+BODY(body))
    except MySQLdb.OperationalError:
        print "Can't connect to a MySQL database with these values",BR()
        print A(_('Back'),href='index')
        raise SCRIPT_END
        