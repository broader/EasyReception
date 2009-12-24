import os

from HTMLTags import *

def index():
    print HEAD(TITLE(_("Administration"))+
        META(http_equiv="Content-Type",content="text/html; charset=utf-8")+
        LINK(rel="stylesheet",href="../admin.css"))
    # if admin not set, initialize it
    redir_script = "/admin/set_admin.ks"
    if not CONFIG.show_script_extensions:
        redir_script = "/admin/set_admin"
    import k_users_db
    if not k_users_db.has_admin(CONFIG):
        raise HTTP_REDIRECTION,redir_script + "/index?url=%s" %THIS.url 

    # check if user is the host administrator
    # login is valid for the whole admin folder
    Login(role=["admin"],valid_in="/")

    # menu
    menu = (A(_("Home"),href="/")+
        H2(_("Administration"))+
        A(_("Configure"),href="../config.ks")+
        BR()+A(_("Script editor"),href="../editor")+
        BR()+A(_("Translations"),href="../translation")+
        BR()+A(_("Users management"),href="../users.ks")+
        BR()+A(_("Database management"),href="../InstantSite"))

    import k_utils
    if k_utils.is_default_host(REQUEST_HANDLER.host):
        menu += BR() + A(_("Virtual hosts management"),href="../vh_manager.ks")

    print BODY(menu + BR()+BR()+A(_("Logout"),href="logout"))


def logout():
    Logout(valid_in="/")
