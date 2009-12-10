"""
The module for registration application. 
"""

from HTMLTags import *

# 'THIS.script_url' is a global variable in Karrigell system
#APPATH = THIS.script_url[1:]
RELPATH = (lambda p : p.split('/')[0])(THIS.baseurl)

#model = Import( '/'.join((RELPATH, 'model.py')))

modules = {'pagefn' : 'pagefn.py',  'JSON' : 'demjson.py', 'formFn':'form.py'}
[locals().update({k : Import('/'.join(('',v)))}) for k,v in modules.items() ]
 

# ********************************************************************************************
# Page Variables
# ********************************************************************************************
# the session object for this page
SO = Session()
# config data object
CONFIG = Import( '/'.join((RELPATH, 'config.py')), rootdir=CONFIG.root_dir)
# account information fields' names in CONFIG file
ACCOUNTFIELDS = 'userAccountInfo'
# base information fields' names in CONFIG file
BASEINFOFIELDS = 'userBaseInfo'
# the id for the SPAN component in the form page which holds buttons 
FORMBNS = 'baseInfoBns'

# End*****************************************************************************************

# ********************************************************************************************
# The page functions begining 
# ********************************************************************************************

def index(**args):
	render = CONFIG.getData(BASEINFOFIELDS)
	print render	