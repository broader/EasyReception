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
APP = pagefn.getApp(THIS.baseurl)

# the javascript lib name for tabs widget
#REGJSLIB = 'ertabs'

# the id of the 'DIV' component which holds the tabs widget in the page
#REGTABS = 'ertabs'

# the name of the instance of the tabs class
#TABSINSTANCE = 'tabsContainer'

# The id for the 'Account' form
#ACCOUNTFORM = 'AccountForm'
# the id for the SPAN component in the account form page which holds buttons 
#ACCOUNTFORMBNS = 'accountBns'



# End*****************************************************************************************

# ********************************************************************************************
# The page functions begining 
# ********************************************************************************************

def index(**args):
	""" Show the tabs widget frame. """
	print H2('Registeration Dialog')	
	return
	
def tabs(**args):
	""" Show tabs in dialog's toolbar. """
	li = [ LI(A(tab.get('title'))) for tab in pagefn.REGISTERTABS ]
	ul = UL(Sum(li), **{'class':'tab-menu', 'id':pagefn.REGISTERTABSID})
	content = [ ul, DIV(**{'class':'clear'}) ]
	print DIV( Sum(content), **{'class':'toolBarTabs'} )
	return
	