# karrigell modules
from HTMLTags import *

# session object config
SOINFO = {'user':'userinfo',}

# a function to return the applicaiton name
getApp = lambda p,i : p.split('/')[i]

##
# Some global variables for /lib/formcheck/js/formcheck.js lib
#--------------------------------------------------------------------------------------
FORMERRCLASS = 'fc-tbx'
ACCOUNTERR = _('This account has been used, please input other name.')
PWDERR = _('The input password is wrong, please input the valid password!') 
FCLIBFILES = \
['/'.join(( 'lib', 'formcheck', name )) \
for name in ('css/hack.css', 'theme/red/formcheck.css', 'lang.js.pih', 'formcheck.js')]
#--------------------------------------------------------------------------------------


##
# Datagrid Plugin Files
#--------------------------------------------------------------------------------------
GRIDFILES = \
['/'.join(( 'lib', 'grid', name )) \
for name in ('omnigrid.css', 'gridSupplement.css','omnigrid.js')]
#---End--------------------------------------------------------------------------------

 
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

##
# Layout setup
#---------------------------------------------------------------------------------------
# login area on the top and right corner of the screen
LOGINAPPNAME = 'loginApp' 
LOGINFORM = '/'.join(('layout.ks', 'page_loginForm'))
LOGINPANEL = 'topNav'
LAYOUTURLS = \
[ '/'.join(('layout.ks', url)) \
  for url in ('page_welcomeInfo', 'page_menu', 'page_sideBarPanels', 'page_closeSession') ] 

# The normal user's role 
USEROLE = 'User'

# The normal user's menus 
USERMENUS = \
{
'data': 
	( 
		{ 'id':'00', 'text':_("Setting"), 'function':'test' },\				
		{ 'id':'01', 'text':_("Logout"), 'function':'logout'}\          
	),
'js': 'js/userMenus.js'
}

ADMINMENUS = \
{
'data':
	(
		{ 'id':'00', 'text':_("Setting"), 'function':'test' },\				
		{ 'id':'01', 'text':_("Logout"), 'function':'logout'}\  
	),
'js': 'js/adminMenus.js'
}


MENUCONTAINER = 'desktopNavbar'

SIDEPANELPREFIX = 'sidebar'

USERSIDEBARPANELS = \
{
'data': 
	( 
		{ 'id':'00', 'text':_("Portal"), 'onExpand':'portalPanel',\
		  'onCollapse':'sidePanelCollapse', 'contentURL':'portal/portal.ks/page_info' },
		
		{ 'id':'01', 'text':_("Accommodation Service"), 'onExpand':'hotelPanel',\
		  'onCollapse':'sidePanelCollapse' },
		       
		{ 'id':'02', 'text':_("Travel Service"), 'onExpand':'travelPanel',\
		  'onCollapse':'sidePanelCollapse' },
		
		{ 'id':'03', 'text':_("Service"), 'onExpand':'servicePanel',\
		  'onCollapse':'sidePanelCollapse' },
		
		{ 'id':'04', 'text':_("Need Help"), 'onExpand':'issuePanel',\
		  'onCollapse':'sidePanelCollapse' },
		
		{ 'id':'05', 'text':_("Portfolio"), 'onExpand':'portfolioPanel',\
		  'onCollapse':'sidePanelCollapse', 'contentURL':'portfolio/portfolio.ks/page_info' },
       
	),
	
'js': 'js/userSidePanels.js.pih'
}


ADMINSIDEBARPANELS = \
{
'data': 
	( 
		{ 'id':'00', 'text':_("Portal"), 'onExpand':'portalPanel',\
		  'onCollapse':'sidePanelCollapse', 'contentURL':'portal/portal4admin.ks/page_info' },
		
		{ 'id':'01', 'text':_("Users' List"), 'onExpand':'userManagementPanel',\
		  'onCollapse':'sidePanelCollapse', 'contentURL':'user/userManagement.ks/page_info' },
		       
		{ 'id':'02', 'text':_("Issues"), 'onExpand':'issuePanel',\
		  'onCollapse':'sidePanelCollapse' },
		
		{ 'id':'03', 'text':_("News"), 'onExpand':'newsPanel',\
		  'onCollapse':'sidePanelCollapse' },
		
		{ 'id':'04', 'text':_("Agenda"), 'onExpand':'agendaPanel',\
		  'onCollapse':'sidePanelCollapse' },
		
		{ 'id':'05', 'text':_("Service Management"), 'onExpand':'servicePanel',\
		  'onCollapse':'sidePanelCollapse', 'contentURL':'service/service.ks/page_info' },
       
	),
	
'js': 'js/adminSidePanels.js.pih'
}


# the main panel's id
MAINPANEL = 'mainPanel'

#--------------------------------------------------------------------------------------


##
# Columns in main window setting up
#--------------------------------------------------------------------------------------
COLUMNS = ('leftColumn', 'mainColumn')
#--------------------------------------------------------------------------------------

##
# Portfolio module
#--------------------------------------------------------------------------------------
PORTFOLIO = {'panelsId':('editPortfolioPanel','editAccountPanel'),}
#---End--------------------------------------------------------------------------------

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
GENDER = (_('Male'),_('Female'))

# form confirm buttons and its css sytle 
BUTTONSTYLE = 'MooTrans'
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

#-----New added functins -----------------------------------------------------------------

# some global variables stored in Session object of Karrigell
COOKIENAME = "sessionId"
def setCookie(setCookie,requestHandler):
	""" Set cookie info in the header of a html page. """	
	sname = COOKIENAME
	# setCookie is the Karrigell's global variable "SET_COOKIE",
	# which is a instance of Cookie.SimpleCookie.
	# When a new key is set for a SimpleCookie object, a Morsel instance is created.
	setCookie[sname]=getattr(requestHandler, sname)
	# set cookie path
	setCookie[sname]['path'] = '/'
	return