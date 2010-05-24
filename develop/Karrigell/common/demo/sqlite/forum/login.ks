import os
import urllib

import k_users_db
from HTMLTags import *

def index(valid_in,redir_to,role="admin"):
    # check if users database initialized
    if not k_users_db.exists(CONFIG):
        print "Users database doesn't exist. You must "
        print A("set admin login and password",href="/admin/set_admin.ks?url=%s" %redir_to)
        raise SCRIPT_END
    # check if user session valid
    print HEAD(TITLE(_("Authentication"))+LINK(rel="stylesheet",href="../karrigell.css"))
    print H2(_("Authentication"))
    f = INPUT(Type="hidden",name="valid_in",value=valid_in)
    f += INPUT(Type="hidden",name="redir_to",value=redir_to)
    f += INPUT(Type="hidden",name="role",value=role)
    lines = TR(TD(_("Login"))+TD(INPUT(name="login")))
    lines += TR(TD(_("Password"))+TD(INPUT(name="passwd",Type="password")))
    lines += TR(TD(INPUT(Type="submit",value="Ok"),colspan="2"))
    print BODY(FORM(f+TABLE(lines),action="check_login",method="post"))

def check_login(valid_in,redir_to,login,passwd,role="admin,edit"):

    db = k_users_db.open_db(CONFIG)

    # check password hash
    try:
        import hashlib
        passwd = hashlib.sha1(passwd).hexdigest()
    except ImportError:
        import sha # deprecated in Python 2.5
        passwd = sha.new(passwd).hexdigest()

    # make session key
    import string, random
    chars = string.ascii_letters + string.digits
    key = ""
    for i in range(16):
        key += random.choice(chars)

    admin = db(login=login,password=passwd)
    if admin and (not role.strip() or admin[0]["role"] in role.split(",")):
        r = admin[0]
        import datetime
        db.update(r,session_key=key,nb_visits=r["nb_visits"]+1,
            last_visit=datetime.datetime.now())
    else:
        # if user doesn't exist, create it
        if db(login=login):
            print _("Wrong password")
            raise SCRIPT_END
        recid = db.insert(login=login,password=passwd,role="edit",
            session_key=key,nb_visits=0)
        r = db[recid]
    db.commit()

    # set cookies
    SET_COOKIE["role"] = r["role"]
    SET_COOKIE["role"]["path"] = valid_in
    SET_COOKIE["login"] = r["login"]
    SET_COOKIE["login"]["path"] = valid_in
    SET_COOKIE["skey"] = key
    SET_COOKIE["skey"]["path"] = valid_in
    #print "ready to raise redir to %s" %path
    #raise SCRIPT_END
    raise HTTP_REDIRECTION,urllib.unquote_plus(redir_to)

def logout(valid_in,redir_to):
    for cookie_name in "role","login","skey":
        SET_COOKIE[cookie_name] = ""
        SET_COOKIE[cookie_name]["path"] = valid_in
        SET_COOKIE[cookie_name]["expires"] = 0
    raise HTTP_REDIRECTION,urllib.unquote_plus(redir_to)

def change_pw():
    db = PyDbLite.Base(db_path).open()
    if not "role" in COOKIE.keys():
        raise HTTP_REDIRECTION,"../"
    print header(_("Change password"))
    print H3(_("Change password"))
    user = db(login=COOKIE["login"].value)
    if not user:
        print _("Unknown user"),COOKIE["login"].value
        raise SCRIPT_END
    user = user[0]
    print B(_("User")),user["login"]
    f = TR(TD(_("Old password"))+TD(INPUT(Type="password",name="old_pw")))
    f += TR(TD(_("New password"))+TD(INPUT(Type="password",name="new_pw1")))
    f += TR(TD(_("Confirm"))+TD(INPUT(Type="password",name="new_pw2")))
    f += TR(TD(INPUT(Type="submit",value="Ok"),colspan="2"))
    print FORM(TABLE(f),action="check_new_pw",method="post")
    print FORM(INPUT(Type="submit",value=_("Cancel")),action="../")

def check_new_pw(old_pw,new_pw1,new_pw2):
    db = PyDbLite.Base(db_path).open()
    if not "role" in COOKIE.keys():
        raise HTTP_REDIRECTION,"../"
    user = db(login=COOKIE["login"].value)
    if not user:
        print _("Unknown user"),COOKIE["login"].value
        raise SCRIPT_END
    user = user[0]
    if not user["passwd"] == old_pw:
        print _("Wrong password")
        print A(_("Back"),href="change_pw")
        raise SCRIPT_END
    if not new_pw1 == new_pw2:
        print _("You didn't enter twice the same password")
        print A(_("Back"),href="change_pw")
        raise SCRIPT_END
    db.update(user,passwd=new_pw1)
    db.commit()
    raise HTTP_REDIRECTION,"../index2.html"

def _error(msg):
    print msg
    print BR(A(link,href="javascript:history.back()"))

