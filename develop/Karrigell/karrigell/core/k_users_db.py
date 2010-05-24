"""Get database object for users management"""
import os
import k_databases

def has_db_settings(config):
    db_settings = os.path.join(config.data_dir,'users_db.py')
    return os.path.exists(db_settings)

def set_db_settings(config,db_engine,**kw):
    db_settings = os.path.join(config.data_dir,'users_db.py')
    out = open(db_settings,'w')
    out.write('engine="%s"\n' %db_engine)
    for (k,v) in kw.iteritems():
        out.write('%s="%s"\n' %(k,v))
    out.close()

def exists(config):
    if not has_db_settings(config):
        return False
    db = get_db(config)
    return len(db)>0

def get_db_engine(config):
    if not has_db_settings(config):
        return None
    db_settings = os.path.join(config.data_dir,'users_db.py')
    exec(open(db_settings).read())
    return engine
    
def get_db(config):
    engine = get_db_engine(config)
    if engine == 'MySQL':
        # put host, user and password in local namespace
        db_settings = os.path.join(config.data_dir,'users_db.py')
        exec(open(db_settings).read())

        from PyDbLite import MySQL
        connection = MySQL.Connection(host,user,password)
        database = connection.create("karrigell_users",mode="open")
        table = MySQL.Table("users",database)
        table.create(("__id__","INTEGER PRIMARY KEY AUTO_INCREMENT"),
            ("host","TEXT"),
            ("login","TEXT"),("email","TEXT"),("password","TEXT"),
            ("role","TEXT"),("session_key","BLOB"),
            ("nb_visits","INTEGER"),
            ("last_visit","TIMESTAMP"),
            mode="open")
        return table
    elif engine == 'SQLite':
        from PyDbLite import SQLite
        conn = SQLite.Database(os.path.join(config.data_dir,
            "users.sqlite"))
        table = SQLite.Table("users",conn)
        table.create(("host","TEXT"),
            ("login","TEXT"),("email","TEXT"),("password","TEXT"),
            ("role","TEXT"),("session_key","BLOB"),
            ("nb_visits","INTEGER"),
            ("last_visit","BLOB"),
            mode="open")
        table.is_datetime('last_visit')
        return table
    elif engine == 'PyDbLite':
        # if nothing else works, use PyDbLite
        from PyDbLite import Base
        db = Base(os.path.join(config.data_dir,"users.pdl"))
        db.create("host","login","email","password","role","session_key",
            "nb_visits","last_visit",mode="open")
        return db

def has_admin(config):
    if not exists(config):
        return False
    db = get_db(config)
    return len(db(role="admin"))

def is_logged(handler):
    if not exists(handler.config):
        return False
    try:
        db = get_db(handler.config)
    except:
        return False
    cookie = handler.COOKIE
    for k in "skey","login","role":
        if not k in cookie.keys():
            return False
    rec = db(login=cookie["login"].value,
        session_key = cookie["skey"].value)
    if rec:
        return True,cookie["role"].value
    else:
        return False

