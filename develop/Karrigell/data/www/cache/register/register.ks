['index', 'tabs']
"""
The module for registration application.
"""

from HTMLTags import *

# 'THIS.script_url' is a global variable in Karrigell system
#APPATH = THIS.script_url[1:]
RELPATH = (lambda p : p.split('/')[0])(THIS.baseurl)
config = Import( '/'.join((RELPATH, 'config.py')), rootdir=CONFIG.root_dir)


#modules = {'pagefn' : 'pagefn.py',  'JSON' : 'demjson.py', 'form':'form.py'}
modules = {'pagefn' : 'pagefn.py', }
[locals().update({k : Import('/'.join(('',v)))}) for k,v in modules.items() ]


# ********************************************************************************************
# Page Variables
# ********************************************************************************************

# get the relative url slice as the application name
#APP = pagefn.getApp(THIS.baseurl,1)

# End*****************************************************************************************

# ********************************************************************************************
# The page functions begining
# ********************************************************************************************

def index(**args):
	""" Show the tabs widget frame. """
	PRINT( H2('Registeration Dialog'))
	return

def tabs(**args):
	""" Show tabs in dialog's toolbar. """
	li = [ LI(A(tab.get('title'))) for tab in pagefn.REGISTERTABS ]
	ul = UL(Sum(li), **{'class':'tab-menu', 'id':pagefn.REGISTERTABSID})
	content = [ ul, DIV(**{'class':'clear'}) ]
	PRINT( DIV( Sum(content), **{'class':'toolBarTabs'} ))
	return


