import os
import urllib
import datetime

import k_users_db
from HTMLTags import *

def index(url):

    if k_users_db.has_admin(CONFIG):
        print "Administrator login / password already set"
        raise SCRIPT_END
    head = HEAD(LINK(rel="stylesheet",href="../karrigell.css"))
    body = H3(_('Create a login/password for host "%s" administrator'
        %ENVIRON["REMOTE_HOST"]))
    body += FORM(INPUT(Type="hidden",name="url",value=url)+
        TABLE(
        TR(TD(_("Login"))+TD(INPUT(name="login")))+
        TR(TD(_("Password"))+TD(INPUT(name="passwd1",Type="password")))+
        TR(TD(_("Confirm password"))+TD(INPUT(name="passwd2",Type="password")))+
        TR(TD(INPUT(Type="submit",value="Ok"),colspan=2))
        ),action="set_admin_info",method="post")
    print HTML(head+body)

def _error(msg):
    print msg
    link = "go back."
    # because variable "link" is not defined here,when I input a login name less than 6 characters,it throws exception
    print BR(A(link,href="javascript:history.back()"))

def set_admin_info(url,login,passwd1,passwd2):

    if k_users_db.has_admin(CONFIG):
        print _("Administrator login / password already set")
        raise SCRIPT_END

    if passwd1 != passwd2:
        _error(_("Password mismatch"))
    elif len(login)<6:
        _error(_("Login must have at least 6 characters"))
    elif len(passwd1)<6:
        _error(_("Password must have at least 6 characters"))
    else:
        # create users database
        db = k_users_db.get_db(CONFIG)
        if not CONFIG.sqlite:
            db.create("host","login","password","role","session_key",
                "nb_visits","last_visit",mode="open")
        else:
            db.create(("host","TEXT"),
                ("login","TEXT"),("password","TEXT"),
                ("role","TEXT"),("session_key","TEXT"),
                ("nb_visits","INTEGER"),
                ("last_visit","BLOB"),
                mode="open")
            db.is_datetime('last_visit')
        # remove existing admin if any
        db.delete(db(role="admin"))
        # insert new admin
        # store md5 hash of password
        try:
            import hashlib
            pw_hash = hashlib.sha1(passwd1).hexdigest()
        except ImportError:
            import sha # deprecated in Python 2.5
            pw_hash = sha.new(passwd1).hexdigest()
        db.insert(login=login,password=pw_hash,role="admin",nb_visits=0,
            last_visit = datetime.datetime.now())
        db.commit()

        raise HTTP_REDIRECTION,urllib.unquote_plus(url)
