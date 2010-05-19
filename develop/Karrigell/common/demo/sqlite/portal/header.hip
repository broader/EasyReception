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


'<head>'
'<title>%s</title>' %_("Karrigell portal demo")
'<link rel="Stylesheet" href="anonymousStyleSheet.css"></link>'
if user:
    '<style type="text/css">'
    'body {background-color :%s; font-family :%s; }' %(user["bgcolor"],user["fontfamily"])
    '</style>'

'</head>'


"""
<body>
<table width="100%">
<tr>
<td>
<a href="/"><img src="/doc/images/karrigell.jpg" border="0" width="100"></a>
</td>
<td class="header">"""
'<h2>%s</h2>' %_("Karrigell portal demo")
'</td>'

if user is None:
    '<td>'
    '<a href="login.pih?user=old">%s</a>' %_("Login")
    '<br><a href="login.pih?user=new">%s</a>' %_("New user")
    '</td>'
else:
    '<td><b class="login">%s</b>' %user["login"]
    '<br><font size="-1"><a href="editPreferences.pih">%s</a>' %_("Preferences")
    '<br><a href="publishNews.pih">%s</a>' %_("Publish news")
    '<br><a href="logout.py">%s</a>' %_("Logout")
    '</font></td>'

"""
</td>
</tr>
</table>
"""