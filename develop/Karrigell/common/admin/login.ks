import os
import urllib
import datetime
import time

import k_users_db
from HTMLTags import *

head = HEAD()
head <= TITLE(_("Authentication"))
head <= LINK(rel="stylesheet",href="../karrigell.css")

logo = A(IMG('',src="/doc/images/karrigell.jpg", border="0", width="100"),
        href="/")

# database config file
db_settings = os.path.join(CONFIG.data_dir,'database.py')

SET_UNICODE_OUT('utf-8')

def login(valid_in,redir_to,role="admin",add_user=False):

    # hidden fields
    hidden = INPUT(Type="hidden",name="valid_in",value=valid_in)
    hidden += INPUT(Type="hidden",name="redir_to",value=redir_to)
        
    # check if users database initialized
    if not k_users_db.has_db_settings(CONFIG):
        body = logo+P()+H3('No users database')
        body += BR()+A('Create it',href='/admin/create_users_db')
        print HTML(head+BODY(body))
        raise SCRIPT_END

    if not k_users_db.has_admin(CONFIG):
        body = logo+P()+H3('No administrator')
        body += BR()+A('Create it',href='create_admin')
        print HTML(head+BODY(body))
        raise SCRIPT_END

    body = BODY()
    body <= logo+P()
    existing_user = H2(_("Authentication"))
    form = FORM(action="check_login",method="post")
    form <= hidden
    form <= INPUT(Type="hidden",name="role",value=role)
    lines = TR(TD(_("Login"))+TD(INPUT(name="login")))
    lines += TR(TD(_("Password"))+TD(INPUT(name="passwd",Type="password")))
    lines += TR(TD(INPUT(Type="submit",value="Ok"),colspan="2",align="center"))
    for tag in lines.get_by_tag('TD'):
        tag.attrs['Class'] = "login"
    form <= TABLE(lines)

    body <= DIV(existing_user+form,Class='login')
    
    # form for new user
    if add_user:
        form = FORM(action="create_account",method="post")
        # add_user is the role for a new user
        form <= hidden
        form <= INPUT(Type="hidden",name="role",value=add_user)
        form <= INPUT(Type="submit",value=_("Create account"))

        new_user = H2(_("Create an account"))
        body <= P()+DIV(new_user+form,Class='login')
    
    print HTML(head+body)

def _make_session_key(length=16):
    # make session key
    import string, random
    chars = string.ascii_letters + string.digits
    key = ""
    for i in range(length):
        key += random.choice(chars)
    return key

def _hash(passwd):
    # check password hash
    try:
        import hashlib
        return hashlib.sha1(passwd).hexdigest()
    except ImportError:
        import sha # deprecated in Python 2.5
        return sha.new(passwd).hexdigest()

def check_login(valid_in,redir_to,login,passwd,role):

    db = k_users_db.get_db(CONFIG)
    passwd = _hash(passwd)
    try:
        user = db(login=login,password=passwd)
    except ValueError:
        # in Karrigell <3.0.3 problem with field last_date, stored
        # as date, not datetime
        db.cursor.execute('SELECT rowid,last_visit FROM users')
        for rowid,last_visit in db.cursor.fetchall():
            if last_visit is not None:
                sql = 'UPDATE users SET last_visit=? WHERE rowid=?'
                last_visit += ' 00:00:00'
                db.cursor.execute(sql,(last_visit,rowid))
        # if field email not present, add it
        if not 'email' in db.fields:
            db.add_field(('email','TEXT'))
        # try again
        user = db(login=login,password=passwd)
    
    if user and (not role.strip() or user[0]["role"] in role.split(",")):
        r = user[0]
        key = _make_session_key()
        db.update(r,session_key=key,nb_visits=r["nb_visits"]+1,
            last_visit=datetime.datetime.now())
        db.commit()
    else:
        print "Authentication failed"
        return

    # set cookies
    SET_COOKIE["role"] = r["role"]
    SET_COOKIE["role"]["path"] = valid_in
    SET_COOKIE["login"] = r["login"]
    SET_COOKIE["login"]["path"] = valid_in
    SET_COOKIE["skey"] = key
    SET_COOKIE["skey"]["path"] = valid_in
    raise HTTP_REDIRECTION,urllib.unquote_plus(redir_to)

def create_account(valid_in,redir_to,role,token=''):

    form = FORM(action="register",method="post")
    hidden = INPUT(Type="hidden",name="valid_in",value=valid_in)
    hidden += INPUT(Type="hidden",name="redir_to",value=redir_to)
    hidden += INPUT(Type="hidden",name="role",value=role)
    hidden += INPUT(Type="hidden",name="token",value=token)
    form <= hidden
    lines = TR(TD(_('Login'))+TD(INPUT(name="login")))
    lines += TR(TD(_('E-mail address'))+TD(INPUT(name="email",size=40)))
    lines += TR(TD(_('Password'))+TD(INPUT(name="pw1",Type="password")))
    lines += TR(TD(_('Confirm password'))+TD(INPUT(name="pw2",Type="password")))
    if token:
        lines += TR(TD(_('Copy token'+' : '+B(token)))+TD(INPUT(name="token1")))
    lines += TR(TD(INPUT(Type="submit",value="Ok"),colspan="2"))
    form <= lines
    print HTML(head+BODY(logo+frame+TABLE(form)))

def create_admin():
    if k_users_db.has_admin(CONFIG):
        print 'admin exists'
        raise SCRIPT_END

    body = logo
    body += H3(_('Administrator information'))
    form = FORM(action="save_admin",method="post")
    lines = TR(TD(_('Login'))+TD(INPUT(name="login")))
    lines += TR(TD(_('E-mail address'))+TD(INPUT(name="email",size=40)))
    lines += TR(TD(_('Password'))+TD(INPUT(name="pw1",Type="password")))
    lines += TR(TD(_('Confirm password'))+TD(INPUT(name="pw2",Type="password")))
    lines += TR(TD(INPUT(Type="submit",value="Ok"),colspan="2"))
    form <= lines
    body += TABLE(form)
    print HTML(head+BODY(body))

def save_admin(login,email,pw1,pw2):
    if k_users_db.exists(CONFIG):
        print 'admin exists'
        raise SCRIPT_END

    # new user registration
    body = BODY()
    body <= logo + P()
    error = None
    if not pw1==pw2:
        error = _('Password mismatch')
    elif len(pw1)<6:
        error = _('Password must be at least 6 characters long')
    if error:
        print HTML(head+BODY(logo+P()+error))
    else:
        db = k_users_db.get_db(CONFIG)
        key = _make_session_key()
        if db(login=login):
            print _("Wrong password")
            raise SCRIPT_END
        recid = db.insert(login=login,
            email=email,
            password=_hash(pw1),
            role='admin',
            session_key=key,
            last_visit=datetime.datetime.now(),
            nb_visits=0)
        db.commit()
        r = db[recid]

        # set cookies
        SET_COOKIE["role"] = 'admin'
        SET_COOKIE["role"]["path"] = '/'
        SET_COOKIE["login"] = login
        SET_COOKIE["login"]["path"] = '/'
        SET_COOKIE["skey"] = key
        SET_COOKIE["skey"]["path"] = '/'
        raise HTTP_REDIRECTION,'/'

def register(login,email,pw1,pw2,valid_in,redir_to,role,token=None,token1=None):
    # new user registration
    body = BODY()
    body <= logo + P()
    error = None
    if not pw1==pw2:
        error = _('Password mismatch')
    elif len(pw1)<6:
        error = _('Password must be at least 6 characters long')
    elif token and token != token1:
        error = _('Error in token')+'token [%s]'%token+' token1 [%s]' %token1
    if error:
        print HTML(head+BODY(logo+P()+error))
    else:
        db = k_users_db.get_db(CONFIG)
        key = _make_session_key()
        if db(login=login):
            print _("Wrong password")
            raise SCRIPT_END
        recid = db.insert(login=login,
            email=email,
            password=_hash(pw1),
            role=role,
            session_key=key,
            last_visit=datetime.datetime.now(),
            nb_visits=0)
        db.commit()
        r = db[recid]

        # set cookies
        SET_COOKIE["role"] = role
        SET_COOKIE["role"]["path"] = valid_in
        SET_COOKIE["login"] = login
        SET_COOKIE["login"]["path"] = valid_in
        SET_COOKIE["skey"] = key
        SET_COOKIE["skey"]["path"] = valid_in
        raise HTTP_REDIRECTION,urllib.unquote_plus(redir_to)

def logout(valid_in,redir_to):
    for cookie_name in "role","login","skey":
        SET_COOKIE[cookie_name] = ""
        SET_COOKIE[cookie_name]["path"] = valid_in
        SET_COOKIE[cookie_name]["max-age"] = 0
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

