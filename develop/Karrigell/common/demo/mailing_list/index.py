from HTMLTags import *

head = HEAD(TITLE(_("Mailing list - index"))+LINK(rel="stylesheet",href="../karrigell.css"))
body  = A(_("Home"),href="/") + BR() + BR()
body += H1(_("Simple mailing list management example :")) + BR()
body += A(_("Subscribe to mailing list"), href='mailing/subscribe') + BR()
body += A(_("Unsubscribe from mailing list"), href='mailing/unsubscribe') + BR() + BR()
body += A(_("Send e-mail to mailing list"), href='mailing/send_email_to_mailing_list') + BR() + BR()
body += A(_("Set/Change smtp server address"), href='mailing/SetSmtpServer?redir_to=%s'%THIS.url) + BR()
body += A(_("Set/Change timeouts"), href='mailing/SetTimeouts?redir_to=%s'%THIS.url) + BR()
#body += A(_("List management"), href='mailing_management/management?redir_to=%s'%THIS.url) + BR()

print HTML(head+BODY(body))
