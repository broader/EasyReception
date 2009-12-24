"""Get database object for users management"""
import os

def exists(config):
    if not config.sqlite:
        return os.path.exists(os.path.join(config.data_dir,"users.pdl"))
    else:
        return os.path.exists(os.path.join(config.data_dir,
            "users.sqlite"))

def get_db(config):
    if not config.sqlite:
        from PyDbLite import Base
        db = Base(os.path.join(config.data_dir,"users.pdl"))
    else:
        from PyDbLite.SQLite import Base
        conn = config.sqlite.connect(os.path.join(config.data_dir,
            "users.sqlite"))
        db = Base("users",conn)
    return db

def open_db(config):
    db = get_db(config)
    db.open()
    return db

def has_admin(config):
    if not exists(config):
        return False
    db = open_db(config)
    return len(db(role="admin"))

def is_logged(handler):
    if not exists(handler.config):
        return False
    db = open_db(handler.config)
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

