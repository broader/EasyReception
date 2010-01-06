# karrigell modules
from HTMLTags import *

# some global variables stored in Session object of Karrigell
SOINFO = {'userinfo':'portfolio',}

# a function to return the applicaiton name
getApp = lambda p,i : p.split('/')[i]

##
# some global variables for /lib/formcheck/js/formcheck.js lib
#--------------------------------------------------------------------------------------
FORMERRCLASS = 'fc-tbx'
ACCOUNTERR = _('This account has been used, please input other name.')
PWDERR = _('The input password is wrong, please input the valid password!') 
#--------------------------------------------------------------------------------------

 
##
# the register dialog
#--------------------------------------------------------------------------------------
REGISTERDIALOG = 'registerDialog'
REGISTERTABSID = 'registerTabs'
REGISTERAPPPATH = 'register'
# Tabs properties
REGISTERTABS = \
[ 
	{'title':'Account', 'url':'/'.join(( REGISTERAPPPATH, 'accountForm.ks/index'))},\
	{'title':'Portfolio', 'url':'/'.join(( REGISTERAPPPATH, 'portfolioForm.ks/index'))},\
	{'title':'Registration End', 'url':'/'.join(( REGISTERAPPPATH, 'registerEnd.ks/index'))}\
]
#--------------------------------------------------------------------------------------


# login area on the top and right corner of the screen 
LOGINPANEL = 'topNav'

##
# the normal user's menus 
#--------------------------------------------------------------------------------------
USERMENUS = \
( 
	{ 'text':_("Portal"), 'function':'test'},\
	{ 'text':_("Accommodation Service"), 'function':'test'},\       
	{ 'text':_("Travel Service"), 'function':'test'},\
	{ 'text':_("Service"), 'function':'test'},\
	{ 'text':_("Need Help"), 'function':'test'},\
	{ 'text':_("Portfolio"), 'function':'test'}\          
)

MENUCONTAINER = 'desktopNavbar'

#--------------------------------------------------------------------------------------


##
# Web Icons
#---------------------------------------------------------------------------
_relPath = lambda p : '/'.join(('images/icons', p))
ICONS = {'edit' : _relPath('edit.png'), 'delete' : _relPath('delete.png')}
#---------------------------------------------------------------------------


# #
#International Words
#---------------------------------------------------------------------------
WEEKDAYS = ( _('Monday'), _('Tuesday'), _('Wednesday'), _('Thursday'), _('Friday'), _('Saturday'), _('Sunday') )
HALFDAY = {'AM' : _('AM'), 'PM': _('PM')}

# form confirm buttons and its css sytle 
FORM_BNS = [_("OK"), _("Cancel")]
BUTTON_CSS = {'float':'center',\
				  'width':'7.5em',\
				  'height':'2.6em',\
				  'color': 'white',\
				  'font-weight':'bold',\
				  'border-style':'none',\
				  'background-color': 'transparent',\
				  'background-image': 'url(images/buttons/button_s.png)'}

# Some services' name
SERVICENAMES = {'Hotel' : _('Hotel'), 'Travel' : _('Travel')}
#--------------------------------------------------------------------------

##
# Some  liberary path
#--------------------------------------------------------------------------

#JSLIBS = {'treeTable': {'js' : 'lib/treeTable/jquery.treeTable.js', 'css' : ' lib/treeTable/jquery.treeTable.css'}}

#--------------------------------------------------------------------------

# the waiting image for ajax action
AJAXLOADING = 'images/ajax_loading.gif'

# the css style for 'select' tag in page's form 
SELECT_CSS = 'height: 1.5em;\
			 line-height: 15px;\
			 border: 1px solid #CCCCCC;\
			 background-color: #FFF;\
			 overflow:hidden;\
			 z-index:100;\
			 font-size: 1.2em;\
			 text-align: left;'
			 

def css(src):
	''' Load a external css file
	'''
	d = { 'rel' : 'stylesheet', 'type' : 'text/css', 'href': src, 'media' : 'screen' }
	html = LINK(**d)
	return html 
			 
def script(src, link=True):
	''' A function to import javascript slice in a html page.
	'''
	if not src:
		return ''
	
	if not link:		
		script = SCRIPT(src, type='text/javascript')
	else:
		script =  SCRIPT(type='text/javascript', src=src)
	return script
	
