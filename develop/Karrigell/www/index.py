import os

import k_target
import k_databases
import k_users_db
from HTMLTags import *

def _exists(url):
    try:
        k_target.Target(REQUEST_HANDLER,url)
        return True
    except k_target.Redir:
        return True
    except:
        return False

SET_UNICODE_OUT("utf-8")

head = TITLE("Karrigell")
head += LINK(rel="SHORTCUT ICON",href="/doc/images/karrigellfav.gif")
head += LINK(rel="stylesheet",href="../karrigell.css")

table = TABLE(width='100%')
if k_users_db.has_db_settings(CONFIG):
    if Role():
        login = COOKIE["login"].value + '&nbsp;'
        login += A(_("Logout"),href="/login/logout")
    else:
        login = A(_("Login"),href="/login/login")
    table <= TR(TD(login,align="right"))
body = table

body += CENTER(H1("Karrigell"))

line = ''

# lines are added only if components are present at default places
# this may depend on the distribution

row1 = []

docs = []
for (name,href) in [("English","/doc/en"),
    (u"Français".encode('utf-8'),"/doc/fr")]:
    if _exists(href):
        docs.append(A(name,href=href))
if docs:
    doc_cell = "Documentation"
    doc_cell += BLOCKQUOTE(Sum([line+BR() for line in docs]))
    row1.append(TD(doc_cell,valign="top"))

if not k_users_db.has_db_settings(CONFIG):
    admin_cell = _('No users database')
    admin_cell += BLOCKQUOTE(A('Create it',href='/admin/create_users_db.ks'))
    row1.append(TD(admin_cell,valign="top"))

elif _exists("/admin/config.ks"):
    admin_cell = "Administration"

    if Role()=='admin':

        admin_menu =  A(_("Configure"),href="/admin/config.ks")+ \
            BR()+A(_("Databases"),href="/admin/databases")+ \
            BR()+A(_("Script editor"),href="/admin/editor")+ \
            BR()+A(_("Translations"),href="/admin/translation")+ \
            BR()+A(_("Users management"),href="/admin/users.ks")
        import k_utils
        if k_utils.is_default_host(REQUEST_HANDLER.host):
            admin_menu += BR() + A(_("Virtual hosts management"),
                href="/admin/vh_manager.ks")

    else:
        admin_menu = I(_('You are not logged in as administrator'))

    admin_cell += BLOCKQUOTE(admin_menu)
    row1.append(TD(admin_cell,valign="top"))

body += TABLE(TR(Sum(row1)),width="100%")

body += P("Demos")

demo_hdr = []
demo_cells = []

db_engines = dict(k_databases.get_engines())

if 'MySQL' in db_engines:
    lines = []
    for (name,href) in [
        (_("Database management"),"/admin/InstantSite/mysql"),
        ("Blog","/blogs/mysql/blog"),
        (_("Calendar"),"/demo/mysql/calendar"),
        (_("E-business"),"/demo/mysql/business"),
        ]:
        if _exists(href):
            lines.append(A(name,href=href))

    if lines:
        demo_hdr.append(TD(_("Using MySQL")))
        cell = TD(Sum([line+BR() for line in lines]),valign="top")
        demo_cells.append(cell)

if 'SQLite' in db_engines:
    sqlite = []
    for (name,href) in [
        (_("Database management"),"/admin/InstantSite/SQLite"),
        ("Blog","/blogs/sqlite/blog"),
        (_("Calendar"),"/demo/sqlite/calendar"),
        (_("E-business"),"/demo/sqlite/business"),
        ("Forum","/demo/sqlite/forum"),
        (_('Portal'),"/demo/sqlite/portal"),
        ("Wiki","/demo/sqlite/wiki")
        ]:
        if _exists(href):
            sqlite.append(A(name,href=href))
    if sqlite:
        demo_hdr.append(TD(_("Using SQLite")))
        cell = TD(Sum([line+BR() for line in sqlite]))
        demo_cells.append(cell)

lines = []
for (name,href) in [
    (_("Database management"),"/admin/InstantSite/PyDbLite"),
    ("Blog","/demo/PyDbLite/blog"),
    (_("Calendar"),"/demo/PyDbLite/calendar"),
    (_("E-business"),"/demo/PyDbLite/business"),
    ("Forum","/demo/PyDbLite/forum"),
    (_("Mailing list"),"/demo/mailing_list"),
    (_("Portal"),"/demo/PyDbLite/portal"),
    ("Wiki","/demo/PyDbLite/wiki")
    ]:
    if _exists(href):
        lines.append(A(name,href=href))

if lines:
    demo_hdr.append(TD(_("Using PyDbLite")))
    cell = TD(Sum([line+BR() for line in lines]))
    demo_cells.append(cell)

body += BLOCKQUOTE(TABLE(TR(Sum(demo_hdr))+TR(Sum(demo_cells)),width="100%"))

et_ok = True
try :
    import xml.etree.ElementTree as ET
except ImportError :
    try :
        import elementtree.ElementTree as ET
    except ImportError :
        et_ok = False

if lines:
    body += P(_("Others"))
    if et_ok == True :
        body += BLOCKQUOTE(A(_("RSS stream generator"),href="/demo/rss/rss.py")+BR())
    else :
        body += BLOCKQUOTE(TEXT("RSS stream generator (needs Python 2.5 or above, or elementTree package)")+BR())

body += HR()+I("Version %s" %REQUEST_HANDLER.version)+BR()
body += I(_("Karrigell is an Open Source software, published under the BSD licence"))
body += P()+TEXT(_("Developed in"))+TEXT(" ")
body += A("Python",href="http://www.python.org/")+BR()
body += TEXT(_("Project hosted by"))+TEXT(" ")
body += A("Sourceforge",href="http://sourceforge.net")

table = TABLE(TR(TD("&nbsp;",width="15%")+
                 TD(body,width="70%")+
                 TD("&nbsp;",width="15%")),
                 width="100%")

print HTML(head+BODY(table))

