# karrigell modules
from HTMLTags import *

# config data object
#RELPATH = (lambda p : p.split('/')[0])(THIS.baseurl)
#INITCONFIG = Import('./config.py', rootdir=CONFIG.root_dir)
INITCONFIG = Import( '/'.join(('', 'config.py')), rootdir=CONFIG.root_dir)

# session object config
SOINFO = {'user':'userinfo',}

# a function to return the applicaiton name
getApp = lambda p,i : p.split('/')[i]


#######################################################################################
# Some global javascript liberies #####################################################
#######################################################################################
JSLIB = {}

# form validation lib
JSLIB['formValid'] = \
{
	'files': ['/'.join(( 'lib', 'formcheck', name )) for name in ('css/hack.css', 'theme/red/formcheck.css', 'lang.js.pih', 'formcheck.js')],
}


# treeTable lib
JSLIB['treeTable'] = \
{'files':['/'.join(('lib','treeTable',name)) for name in ('treeTable.css','treeTable.js',)],
}

# dataGrid lib
JSLIB['dataGrid'] = \
{
	'files':['/'.join(('lib','grid',name)) for name in ('omnigrid.css','gridSupplement.css', 'omnigrid.js')],
	'filter': {'labels':{'action':_('Filter'), 'clear': _('Clear')}},
	'sorTag': {'sortOn':'SORTON', 'sortBy':'SORTBY'}	
}

# textMultiCheckbox
JSLIB['textMultiCheckbox'] = \
{'files':['/'.join(('lib','textMultiCheckbox',name)) for name in ('TextMultiCheckbox.css','TextMultiCheckbox.js')],
}

# inlineEdit
JSLIB['inlineEdit'] = \
{'files':['/'.join(('lib','inlineEdit',name)) for name in ('InlineEdit.css','InlineEdit.js')],
}

# multiful select
JSLIB['multiSelect'] = \
{'files':['/'.join(('lib','multiSelect',name)) for name in ('MTMultiSelect.css','MTMultiSelect.js')],
}

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



#########################################################################################
# Layout setup
#########################################################################################

# the texts for the buttons in confirm window
#---------------------------------------------------------------------------------------
BUTTONLABELS = {\
	'confirmWindow': { 'confirm':_('Confirm'), 'cancel': _('Cancel')},\
	'alertWindow': {'ok': _('OK')},\
}

# login area on the top and right corner of the screen
#---------------------------------------------------------------------------------------
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

#ascii2utf8 = lambda v : v.decode('utf8').encode('utf8')
USERSIDEBARPANELS = \
{
'data': 
	( 
		{ 'id':'00', 'text': _("Portal"), 'onExpand':'portalPanel',\
		  'onCollapse':'sidePanelCollapse', 'contentURL':'portal/portal.ks/page_info' },
		
		{ 'id':'01', 'text': _("Accommodation Service"), 'onExpand':'hotelPanel',\
		  'onCollapse':'sidePanelCollapse' },
		       
		{ 'id':'02', 'text': _("Travel Service"), 'onExpand':'travelPanel',\
		  'onCollapse':'sidePanelCollapse' },
		
		{ 'id':'03', 'text': _("Service"), 'onExpand':'servicePanel',\
		  'onCollapse':'sidePanelCollapse' },
		
		{ 'id':'04', 'text': _("Need Help"), 'onExpand':'issuePanel',\
		  'onCollapse':'sidePanelCollapse', 'contentURL':'issue/userView.ks/page_info' },
		
		{ 'id':'05', 'text': _("Portfolio"), 'onExpand':'portfolioPanel',\
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
		  
		{ 'id':'06', 'text':_("System Config"), 'onExpand':'sysadminPanel',\
		  'onCollapse':'sidePanelCollapse', 'contentURL':'service/service.ks/page_info' },
       
	),
	
'js': 'js/adminSidePanels.js.pih'
}


# the MUI.Panel's ids
PANELSID = {'main':'mainPanel',}

#--------------------------------------------------------------------------------------


##
# Columns in main window setting up
#--------------------------------------------------------------------------------------
COLUMNS = ('leftColumn', 'mainColumn')
#--------------------------------------------------------------------------------------

##
# Portfolio Application module
#--------------------------------------------------------------------------------------
PORTFOLIO = {'panelsId':('editPortfolioPanel','editAccountPanel'),}
#---End--------------------------------------------------------------------------------

##
# Hotel Reservation Application module
#--------------------------------------------------------------------------------------
_hotelUrls = ['/'.join(('service','userHotelsView.ks',url)) for url in ('page_hotelsList','page_hotelInfo','page_roomReservation')]

HOTEL = \
{ 
	'categoryInService': INITCONFIG.getData('service')['hotel']['categoryInService'],	# the value for 'category' property of 'service' Class in schema.py of roundup module

	'mainColumn':{
		'list':{
			'panelId': 'hotelsList', 
			'panelTitle': _('Hotels List'), 'contentUrl': _hotelUrls[0]},

		'info':{
			'panelId': 'hotelsInfo',
			'panelTitle': _('Detail Information of The Hotel'),
			'contentUrl': _hotelUrls[1]}
	},

	'rightColumn':{'panelId':'hotelReservation','panelTitle':_('Your reservations'), 'contentUrl': _hotelUrls[2]}
}

##
# Issue Application Module
##
ISSUE = \
{
}

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


##########################################################################################
#-----New added functins -----------------------------------------------------------------
##########################################################################################

# some global variables stored in Session object of Karrigell
COOKIENAME = "sessionId"
def setCookie(cookie,requestHandler):
	""" Set cookie info in the header of a html page. """	
	sname = COOKIENAME
	# cookie is the Karrigell's global variable "SET_COOKIE",
	# which is a instance of Cookie.SimpleCookie.
	# When a new key is set for a SimpleCookie object, a Morsel instance is created.

	#cookie[sname] = getattr(requestHandler, sname)

	# set cookie path
	#cookie[sname]['path'] = '/'

	return
	
def sexyButton(txt,bnAttrs={},bnType='',size='sexymedium',skin='sexysimple'):
	""" Return a <button> html element which is styled by 'sexybutton' plugin.
	Parameters:
		txt- the text on the button
		bnAttrs- the attributs for <button> element
		bnType- the predefined type in the sexybutton plugin, such as 'ok'
		size- it should be one of 'sexysmall','sexymedium','sexylarge'
		skin- the background color for the button, the sexybutton plugin has designed many, just select one  
	"""
	bnClass = ['sexybutton', size, skin]
	bnClass = ' '.join(bnClass)
	bnAttrs['class'] = bnClass
	return BUTTON(SPAN(txt,**{'class':bnType}),**bnAttrs)

def getConfig(appName):
	# configrable properties
	configField = HOTEL.get('categoryInService')
	props = INITCONFIG.getData(configField)
	props = props and props.get('configProperty') or {}

# recursviely decode all the values in a dictionary object to utf8 format 
def decodeDict2Utf8(d):
	for k,v in d.items():
		if type(v) == type({}):
			d.update({k: decodeDict2Utf8(v)}) 
		else:
			d.update({k: str(v).decode('utf8')})
	return d

