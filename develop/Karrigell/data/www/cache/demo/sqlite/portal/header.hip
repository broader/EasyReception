[]
# Header script
# Tests if authenticated user and sets layout accordingly

table = Import("portalDb",REL=REL).table

so=Session()
user=None
if hasattr(so,"user") and so.user is not None:
    try:
        user = table['users'][so.user]
    except IndexError:
        user = None

SET_UNICODE_OUT("iso-8859-1")


PRINT( '<head>')
PRINT( '<title>%s</title>' %_("Karrigell portal demo"))
PRINT( '<link rel="Stylesheet" href="anonymousStyleSheet.css"></link>')
if user:
    PRINT( '<style type="text/css">')
    PRINT( 'body {background-color :%s; font-family :%s; }' %(user["bgcolor"],user["fontfamily"]))
    PRINT( '</style>')

PRINT( '</head>')


PRINT( """
<body>
<table width="100%">
<tr>
<td>
<a href="/"><img src="/doc/images/karrigell.jpg" border="0" width="100"></a>
</td>
<td class="header">""")
PRINT( '<h2>%s</h2>' %_("Karrigell portal demo"))
PRINT( '</td>')

if user is None:
    PRINT( '<td>')
    PRINT( '<a href="login.pih?user=old">%s</a>' %_("Login"))
    PRINT( '<br><a href="login.pih?user=new">%s</a>' %_("New user"))
    PRINT( '</td>')
else:
    PRINT( '<td><b class="login">%s</b>' %user["login"])
    PRINT( '<br><font size="-1"><a href="editPreferences.pih">%s</a>' %_("Preferences"))
    PRINT( '<br><a href="publishNews.pih">%s</a>' %_("Publish news"))
    PRINT( '<br><a href="logout.py">%s</a>' %_("Logout"))
    PRINT( '</font></td>')

PRINT( """
</td>
</tr>
</table>
""")

