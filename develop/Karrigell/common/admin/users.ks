import os

import k_databases
import k_users_db
from HTMLTags import *

Login(role=["admin"],valid_in='/')

db = k_users_db.get_db(CONFIG)

roles = ["admin","edit","visit"]
roles_file = os.path.join(CONFIG.data_dir,'roles.txt')
if os.path.exists(roles_file):
    roles += [line.strip() for line in open(roles_file)]

SET_UNICODE_OUT('utf-8')

def _header(title,src):
    return HEAD(TITLE("title")+
        LINK(rel="stylesheet",href=src))

def index():

    Login(role=["admin"])

    print _header("Users management",src="../users.css")

    t = H2("Users")

    lines = TR(TH("Host")+TH("Login")+TH("E-mail")+TH("Password hash")
        +TH("Role")+TH("Session key")+TH("Nb visits")+TH("Last visit")
        +TD("&nbsp;"))

    fields = ["host","login","email","password","role","session_key",
            "nb_visits","last_visit"]
    for r in db:
        lines += TR(Sum([TD(r.get(k)) for k in fields]) +
            TD(A("Edit",href="edit?recid=%s" %r["__id__"]))
            )
    engines = dict(k_databases.get_engines())
    
    db_engine = k_users_db.get_db_engine(CONFIG)

    print BODY(A(_("Home"),href="/")+
        t+TABLE(lines)+P()+A("New user",href="edit")+
        P(SMALL("DB engine : %s" %db_engine))+
        P(SMALL(A(_('Logout'),href="logout"))))

def edit(recid=-1):
    recid = int(recid)
    if recid>=0:
        r = db[int(recid)]
        print _header("Edition",src="../users.css")
        print H2("Edition")
    else:
        r = {"role":"visit"}
        print _header("New user",src="../users.css")
        print H2("New user")
    print "<table>"
    print '<form action="insert" method="post">'
    print INPUT(name="recid",Type="hidden",value=recid)
    print TR(TD("Login")+
        TD(INPUT(name="login",value=r.get("login",""))))
    print TR(TD("Password")+
        TD(INPUT(name="password",Type="password")))
    print TR(TD("E-mail")+
        TD(INPUT(name="email",value=r.get("email",""))))

    print TD("Role")
    croles = Sum([INPUT(name="role",Type="radio",value=role,
            checked = r.get("role","")==role)+TEXT(role) for role in roles])
    print TD(croles)

    print TR(TD(INPUT(Type="submit",value="Ok"),colspan="2"))
    print '</form></table>'
    if recid>=0:
        print P()+A("Delete",href="delete?recid=%s" %r["__id__"])

def delete(recid):
    print _header("Delete",src="../users.css")
    print "Delete %s ?" %db[int(recid)]["login"]
    print A("Yes",href="confirm_delete?recid=%s" %recid)
    print A("No",href="index")

def confirm_delete(recid):
    del db[int(recid)]
    db.commit()
    raise HTTP_REDIRECTION,"index"

def insert(**kw):
    recid = int(kw["recid"])
    del kw["recid"]
    # store password's sha hash (not in clear)
    password = kw["password"]
    try:
        import hashlib
        pw_hash = hashlib.sha1(password).hexdigest()
    except ImportError:
        import sha # deprecated in Python 2.5
        pw_hash = sha.new(password).hexdigest()
    kw["password"] = pw_hash
    if recid >= 0:
        r = db[recid]
        db.update(r,**kw)
    else:
        kw["nb_visits"] = 0
        db.insert(**kw)
    db.commit()
    raise HTTP_REDIRECTION,"index"

def logout():
    Logout(valid_in='/',redir_to='/')
