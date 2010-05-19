['bla']
import os

import k_target
from HTMLTags import *

def _exists(url):
    try:
        k_target.Target(REQUEST_HANDLER,url)
        return True
    except k_target.Redir:
        return True
    except:
        return False

head = TITLE("Karrigell")
head += META(http_equiv="Content-Type",content="text/html; charset=utf-8")
head += LINK(rel="SHORTCUT ICON",href="/doc/images/karrigellfav.gif")
head += LINK(rel="stylesheet",href="karrigell.css")

body = CENTER(H1("Karrigell"))

line = ''

# lines are added only if components are present at default places
# this may depend on the distribution
for (name,href) in [("Documentation","/doc")]:
    if _exists(href):
        line = A(name,href=href)+P()
if line:
    body += line

if _exists("/admin"):
    body += A("Administration",href="/admin")

sqlalchemy = []
for (name,href) in [
    ("Blog","/demo/sqlite/blog")
    ]:
    if _exists(href):
        sqlalchemy.append(A(name,href=href))
if sqlalchemy:
    body += P("Applications using SQLite")
    body += BLOCKQUOTE(Sum([line+BR() for line in sqlalchemy]))


lines = []
for (name,href) in [("Wiki","/demo/wiki"),
    ("Blog","/demo/blog"),
    ("Forum","/demo/forum"),
    (_("Portal"),"/demo/portal"),
    (_("Calendar"),"/demo/calendar"),
    (_("E-business"),"/demo/business"),
    (_("Mailing list"),"/demo/mailing_list")
    ]:
    if _exists(href):
        lines.append(A(name,href=href))

if lines:
    body += P("Applications using PyDbLite")
    body += BLOCKQUOTE(Sum([line+BR() for line in lines]))


et_ok = True
try :
    import xml.etree.ElementTree as ET
except ImportError :
    try :
        import elementtree.ElementTree as ET
    except ImportError :
        et_ok = False

if lines:
    body += P("Others")
    if et_ok == True :
        body += BLOCKQUOTE(A(_("RSS stream generator"),href="/demo/rss/rss.py")+BR())
    else :
        body += BLOCKQUOTE(TEXT("RSS stream generator (needs Python 2.5 or above, or elementTree package)")+BR())

body += HR()+I("Version 3.0")+BR()
body += I(_("Karrigell is an Open Source software, published under the BSD licence"))
body += P()+TEXT(_("Developed in"))+TEXT(" ")
body += A("Python",href="http://www.python.org/")+BR()
body += TEXT(_("Project hosted by"))+TEXT(" ")
body += A("Sourceforge",href="http://sourceforge.net")

table = TABLE(TR(TD("&nbsp;",width="25%")+
                 TD(body,width="50%")+
                 TD("&nbsp;",width="25%")),
                 width="100%")

PRINT( HTML(head+table))


def bla():
    PRINT( "blabla")


