"""
Simple example using k_email module to manage a mailing list.

CAUTION : 
    Do not use the following code in production.
    Security is an issue.
"""

import os
import datetime
from HTMLTags import *
import k_email
import k_sessions
import PyDbLite
import k_app_config



_TIMEOUT = datetime.timedelta(2, 0, 0)  # 2 days
#_TIMEOUT = datetime.timedelta(0, 20, 0)  # 20 seconds for tests


db = PyDbLite.Base(os.path.join(CONFIG.data_dir,"mailing.pdl"))
db.create("email_address","status","rand_key","date_time",mode="open")


def subscribe():
    smtp_server, smtp_user_name, smtp_password = _GetSmtpServer()
    head = HEAD(TITLE(_("Mailing list - subscribe"))+LINK(rel="stylesheet",href="../karrigell.css"))
    body = H1("Subscribe to mailing list")+BR()+BR()
    body += FORM(
        TABLE(
        TR(TD(_("e-mail address :"))+TD(INPUT(name="email", type="text", value=_("your.e.mail@address.com"))))+
        TR(TD()+TD(INPUT(Type="submit",value=_("Submit"))))
        ), enctype="multipart/form-data", action="subscribe_",method="post")
    print HTML(head+body)

def subscribe_(email):
    smtp_server, smtp_user_name, smtp_password = _GetSmtpServer()

    request = False
    rec_list = db(email_address=email)
    if len(rec_list) :
        rec = rec_list[0]
        if rec['status']=="validated" or rec['status']=="wait_unsubscribe" :
            print _("e-mail address allready registered")
        elif rec['status']=="wait_validation" :
            db.delete(rec)
            db.commit()
            request = True
    else :
        request = True
           
    if request :
        request_id=k_sessions.generate_random(10)
        # Create and send e-mail for validation
        msg = k_email.SendMail("Karrigell mailing list", smtp_server)
        msg.set_smtp_username_and_password(smtp_user_name, smtp_password)
        msg.set_from("Karrigell mailing list", "")
        msg.set_message("""
        Welcome to karrigell mailing list.
        Please click on the following link to validate your subscription.
        """)
        msg.message_append("http://")
        msg.message_append(ENVIRON["REMOTE_HOST"])
        msg.message_append(REL_I("subscribe_validation"))
        msg.message_append("?email=%s&req_id=%s" % (email, request_id))
        msg.add_recipient("", email)
        d = msg.send()
        if not d :
            db.insert(email_address=email, status="wait_validation", 
                       date_time=datetime.datetime.now(), rand_key=request_id)
            db.commit()
            print "You will receive an e-mail shortly." 
            print "<BR>Please follow inscructions inside e-mail to validate your subscription"
        else :
            print "Invalid e-mail address."       

    
def subscribe_validation(email, req_id):
    smtp_server, smtp_user_name, smtp_password = _GetSmtpServer()
    _delete_old_requests()
    rec_list = db(email_address=email, status="wait_validation", rand_key=req_id)
    if len(rec_list) :
        rec=rec_list[0]
        db.update(rec, status="validated", rand_key=k_sessions.generate_random(10))
        db.commit()
        print _("Validation ok")
    else:
        print _("No record found.")
        
        
    
def unsubscribe():
    smtp_server, smtp_user_name, smtp_password = _GetSmtpServer()
    head = HEAD(TITLE(_("Mailing list - unsubscribe"))+LINK(rel="stylesheet",href="../karrigell.css"))
    body = H1("Unsubscribe from mailing list")+BR()+BR()
    body += FORM(
        TABLE(
        TR(TD(_("e-mail address :"))+TD(INPUT(name="email", type="text", value=_("your.e.mail@address.com"))))+
        TR(TD()+TD(INPUT(Type="submit",value=_("Submit"))))
        ), enctype="multipart/form-data", action="unsubscribe_",method="post")
    print HTML(head+body)

def unsubscribe_(email):
    smtp_server, smtp_user_name, smtp_password = _GetSmtpServer()
    rec_list = db(email_address=email)
    if len(rec_list) :
        rec = rec_list[0]
        request_id=k_sessions.generate_random(10)
        # Create and send e-mail for validation
        msg = k_email.SendMail("Karrigell mailing list", smtp_server)
        msg.set_smtp_username_and_password(smtp_user_name, smtp_password)
        msg.set_from("Karrigell mailing list", "")
        msg.set_message("""
        This is a message from the karrigell mailing list.
        Please click on the following link to confirm you want to unsubscribe.
        """)
        msg.message_append("http://")
        msg.message_append(ENVIRON["REMOTE_HOST"])
        msg.message_append(REL_I("unsubscribe_validation"))
        msg.message_append("?email=%s&req_id=%s" % (email, request_id))
        msg.add_recipient("", email)
        d = msg.send()
        if not d :
            db.update(rec, status="wait_unsubscribe", 
                       date_time=datetime.datetime.now(), rand_key=request_id)
            db.commit()
            print "You will receive an e-mail shortly." 
            print "<BR>Please follow inscructions inside e-mail to validate your request."
        else :
            print "Invalid e-mail address."       
    else :
        print "e-mail not found in base"


def unsubscribe_validation(email, req_id):
    smtp_server, smtp_user_name, smtp_password = _GetSmtpServer()
    _delete_old_requests()
    rec_list = db(email_address=email, status="wait_unsubscribe", rand_key=req_id)
    if len(rec_list) :
        rec=rec_list[0]
        db.delete(rec)
        db.commit()
        print "You will not receive e-mails any more."
    else:
        print "No record found."
        
        
def send_email_to_mailing_list():
    Login(role=["admin"])
    smtp_server, smtp_user_name, smtp_password = _GetSmtpServer()
    head = HEAD(TITLE(_("Mailing list - send e-mail to mailing list"))+LINK(rel="stylesheet",href="../karrigell.css"))
    body = H1("Send e-mail to mailing list")+BR()+BR()
    body += FORM(
        TABLE(
        TR(TD(_("Text :"), valign="top")+TD(TEXTAREA(_("Enter the text to send to the mailing list here."), name="email_txt", type="text", value=_("your message"), rows=20, cols=40)))+
        TR(TD()+TD(INPUT(Type="submit",value=_("Send"))))
        ), enctype="multipart/form-data", action="send_email_to_mailing_list_",method="post")
    print HTML(head+body)
    
def send_email_to_mailing_list_(email_txt):
    Login(role=["admin"])
    smtp_server, smtp_user_name, smtp_password = _GetSmtpServer()

    _delete_old_requests()
    addr_list = [ r for r in db if r['status']=="validated" or r['status']=="wait_unsubscribe"]
    if addr_list :
        # Create and send e-mail
        msg = k_email.SendMail("Karrigell mailing list", smtp_server)
        msg.set_smtp_username_and_password(smtp_user_name, smtp_password)
        msg.set_from("Karrigell mailing list", "")
        msg.set_message(email_txt)
        msg.add_recipient("Karrigell mailing list", "", True, False) # Add fake address
        for addr in addr_list :
            msg.add_recipient("", addr["email_address"], False, True)    # Add hidden actual addresses
        d = msg.send()
        print "Message sent.<br>"
        print "Refused addresses :",
    else :
        print "No subscriber found."
    
    
def _delete_old_requests(verbose=True):
    #Login(role=["admin"])
    commit_requested = False
    addr_list = [ addr for addr in db if addr['status']=="wait_validation" or addr['status']=="wait_unsubscribe"]
    for addr in addr_list:
        if (datetime.datetime.now() - addr["date_time"]) >= _GetTimeout(addr['status']=="wait_validation"):
            if addr["status"] == "wait_validation" :
                if verbose :
                    print "Record deleted :", addr, "<BR>"
                db.delete(addr)
                commit_requested = True
            if addr["status"] == "wait_unsubscribe" :
                if verbose :
                    print "Record reseted :", addr, "<BR>"
                db.update(addr, status="validated", rand_key=k_sessions.generate_random(10))
                commit_requested = True
    if commit_requested :
        db.commit()
        
        
        
def _GetSmtpServer ():
    app_config = k_app_config.AppConfig ("mailing list")
    try :
        return app_config.smtp_server, app_config.smtp_user_name, app_config.smtp_password
    except AttributeError :
        raise HTTP_REDIRECTION, "SetSmtpServer?redir_to=%s" % THIS.url

    
def SetSmtpServer (redir_to):
    Login(role=["admin"])
    app_config = k_app_config.AppConfig ("mailing list")
    try :
        smtp_server = app_config.smtp_server
        smtp_user_name = app_config.smtp_user_name
        smtp_password = app_config.smtp_password
    except AttributeError :
        smtp_server = ""
        smtp_user_name = ""
        smtp_password = ""
    head = HEAD(TITLE(_("Mailing list - set smtp_server address"))+LINK(rel="stylesheet",href="../karrigell.css"))
    body = H1("Set SMTP server address for mailing list service")+BR()+BR()
    body += FORM(
        TABLE(
        TR(TD("SMTP server :")+TD(INPUT(name="smtp_server", type="text", value=smtp_server)))+
        TR(TD("")+TD(INPUT(name="redir_to", type="hidden", value=redir_to)))+
        TR(TD(height="20", colspan=2))+
        TR(TD("Leave following fields blank if you don't want to use SMTP authentication.", height="20", colspan=2))+
        TR(TD("user name :")+TD(INPUT(name="smtp_user_name", type="text", value=smtp_user_name)))+
        TR(TD("password :")+TD(INPUT(name="smtp_password", type="password", value=smtp_password)))+
        TR(TD()+TD(INPUT(Type="submit",value="Validate")))
        ), enctype="multipart/form-data", action="SetSmtpServer_",method="post")
    print HTML(head+body)
    
def SetSmtpServer_ (smtp_server, smtp_user_name, smtp_password, redir_to):
    Login(role=["admin"])
    app_config = k_app_config.AppConfig ("mailing list")
    app_config.smtp_server = smtp_server
    app_config.smtp_user_name = smtp_user_name
    app_config.smtp_password = smtp_password
    raise HTTP_REDIRECTION, redir_to



def _GetTimeout (subscribe=True):
    app_config = k_app_config.AppConfig ("mailing list")
    try :
        if subscribe == True :
            timeout = app_config.subscribe_timeout
        else :
            timeout = app_config.unsubscribe_timeout
    except AttributeError :
        if subscribe == True :
            timeout = _TIMEOUT
            app_config.subscribe_timeout = timeout
        else :
            timeout = _TIMEOUT
            app_config.unsubscribe_timeout = timeout
    return timeout
    
def SetTimeouts (redir_to, s_err=None, u_err=None):
    Login(role=["admin"])
    app_config = k_app_config.AppConfig ("mailing list")
    
    try :
        st = app_config.subscribe_timeout
    except AttributeError :
        st = _TIMEOUT
    if st.days != 0 :
        st_text = str(st.days)
    else :
        st_text = "1"
        
    try :
        ut = app_config.unsubscribe_timeout
    except AttributeError :
        ut = _TIMEOUT
    if ut.days != 0 :
        ut_text = str(ut.days)
    else :
        ut_text = "1"

    head = HEAD(TITLE(_("Mailing list - set timeouts"))+LINK(rel="stylesheet",href="../karrigell.css"))
    body = H1("Set timeouts for mailing list service")+BR()+BR()
    if s_err=='True' :
        table_content = TR(TD(FONT(_("You have entered an invalid value. Current/default value is shown."), color="red"), 
                               height="20", colspan=3))
    else :
        table_content = TEXT("")
    table_content += TR(TD(_("Subscribe timeout :"))+
                        TD(INPUT(name="st", type="text", value=st_text)))
    if u_err=='True' :
        table_content += TR(TD("", span=2), height=10)
        table_content += TR(TD(FONT(_("You have entered an invalid value. Current/default value is shown."), color="red"), 
                               height="20", colspan=3))
    table_content += TR(TD(_("Unsubscribe timeout :"))+
                        TD(INPUT(name="ut", type="text", value=ut_text)))
    table_content += TR(TD("")+
                        TD(INPUT(name="redir_to", type="hidden", value=redir_to)))
    table_content += TR(TD(height="20", colspan=2))
    table_content += TR(TD()+
                        TD(INPUT(Type="submit",value=_("Validate"))))
    body += FORM(TABLE(table_content), enctype="multipart/form-data", action="SetTimeouts_",method="post")
    print HTML(head+body)
    
def SetTimeouts_ (st, ut, redir_to):
    Login(role=["admin"])
    app_config = k_app_config.AppConfig ("mailing list")

    s_error = False
    try :
        app_config.subscribe_timeout = datetime.timedelta(int(st), 0, 0)
    except ValueError :
        s_error = True
    
    u_error = False
    try :
        app_config.unsubscribe_timeout = datetime.timedelta(int(ut), 0, 0)
    except ValueError :
        u_error = True
     
    if s_error or u_error :
        raise HTTP_REDIRECTION, 'SetTimeouts?redir_to=%s&s_err=%s&u_err=%s' % (redir_to, s_error, u_error)
    else :
        raise HTTP_REDIRECTION, redir_to
