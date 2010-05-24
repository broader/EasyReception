['index', 'profile']
from HTMLTags import *

def _get_user( ):
	so = Session()
	if not hasattr(so, 'user'):
		so.user = None
	return so

def _login( ):
	login = True
	so = _get_user()
	if not so.user :
		script = '$(document).ready(function(){'
    		script += '$.prompt("%s", { opacity: 0.9, prefix: "cleanblue", buttons:{%s : true} });\
					$("#main").load("%s");' %(_("Not Login!"), _("OK"), 'home.pih')
		script += '});'
		PRINT( SCRIPT(script, type='text/javascript'))
		login = False
	return login

#DEFAULTPAGE = 'portal/portal.ks'
DEFAULTPAGE = 'home.pih'
def index(**args):
	if _login():
		Include(DEFAULTPAGE)

def profile(**args):
	subpath = args.get('path')
	if _login() and subpath:
		Include(subpath)
	else:
		Include(DEFAULTPAGE)

