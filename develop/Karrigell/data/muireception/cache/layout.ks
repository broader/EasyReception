['index', 'page_loginForm', 'page_accountValid', 'page_welcomeInfo', 'page_menuList', 'page_menu', 'page_sideBarPanels', 'page_closeSession']
"""
The pages and functions for menu setup
"""

import sys

# added module in Karrigell "/karrigell/packages" directory
import tools
from tools import treeHandler

from HTMLTags import *

# 'THIS.script_url' is a global variable in Karrigell system
APPATH = THIS.script_url[1:]
RELPATH = (lambda p : p.split('/')[0])(THIS.baseurl)
model = Import( '/'.join((RELPATH, 'model.py')), REQUEST_HANDLER=REQUEST_HANDLER )
modules = {'pagefn' : 'pagefn.py',  'JSON' : 'demjson.py'}
[locals().update({k : Import('/'.join(('',v)))}) for k,v in modules.items() ]

VERSION = Import('/'.join((RELPATH, 'version.py')))

# ********************************************************************************************
# Page Variables
# ********************************************************************************************

# get the relative url slice as the application name
APP = 'loginDialog'

# the session object for this page
#so = Session()

# config data object
CONFIG = Import( '/'.join((RELPATH, 'config.py')), rootdir=CONFIG.root_dir)

LOGINFORM = 'loginForm'

FORMFIELDS = \
[\
	{'name':'username','label':_('Login Name'),'class':"validate['required','~accountCheck']"},\
	{'name':'password','label':_('Password'),'class':"validate['required','~pwdCheck']"}\
]

DEMOSELECT = 'demoSelect'

FORMBUTTONS = 'loginFormbns'

# End*****************************************************************************************


# ********************************************************************************************
# The page functions begining
# ********************************************************************************************

def index(**args):
	pass
	return


def page_loginForm(**args):
	# render fields
	table = [ CAPTION(SPAN(_('User Info'), **{'style' : 'font-weight:bold;font-size: 1.5em;'})), ]
	tbody = []
	# append demostartion selection
	if VERSION.version == 'demo' :
		tbody.append(TR(TD(_autoDemo(), colspan='2',style='border-bottom:black 1px;')))

	# append account inputs
	for field in FORMFIELDS :
		name = field.get('name')
		label = TD(LABEL(field.get('label'),style='width:100%;'))
		attr = {'name':name}
		attr['class'] = ' '.join((field.get('class'), 'type-text'))

		if name != 'password':
			attr['type'] = 'text'
		else:
			attr['type'] = 'password'
		input = SPAN(INPUT(**attr))
		input = TD(input)
		tbody.append(TR(Sum((label, input))))

	table.append(Sum(tbody))
	table = TABLE(Sum(table))
	# append submit buttons
	bns =[ BUTTON( _("OK"), **{'class':'MooTrans', 'type':'submit'}),\
			 BUTTON( _("Cancel"), **{'class':'MooTrans', 'type':'button'})]

	bns = [ SPAN(bn) for bn in bns ]
	bns = DIV(Sum(bns),**{'id':FORMBUTTONS,'style':'position:relative;float:right;'})
	form = Sum([table, bns])
	# render form
	PRINT( FORM(form,**{'id':LOGINFORM, 'class':'yform' }))
	PRINT( pagefn.script(_loginFormJs(),link=False))
	return

def _autoDemo( ):
	""" Render a html slice to select a type of user to demostrate the function of this system.
	"""
	options = [ OPTION(_('Select a type of user'), disabled='', selected=''), ]
	for user, des in VERSION.demoUsersDes.items() :
		name, pwd = [ VERSION.demoUsers[user].get(field) for field in ('name', 'pwd') ]
		options.append(OPTION(des, **{'value' : name, 'ref' : pwd}))

	select = SELECT(Sum(options), **{'id' : DEMOSELECT})
	prompt = SPAN(VERSION.demoPrompt,style='font-size:15px;',**{'class':'highlight'})
	return Sum(( prompt, BR(), select, HR(style='padding:0 0 0.2em;')))

def _loginFormJs():
	# callback function for slect action
	paras = [ LOGINFORM, DEMOSELECT, FORMBUTTONS]
	paras.append(APP)

	# append the error prompts for fields' validation
	paras.extend([ _('The input account is not existed !'), _('The input password is wrong, please input the valid password!')])

	# append the action urls for fields' validation
	paras.append( '/'.join((APPATH, 'page_accountValid')))

	paras = tuple(paras)
	script = \
	"""
	var loginForm='%s', select='%s',	bnsContainer='%s';
	var appName='%s', accountErr='%s', pwdErr='%s',
	checkUrl='%s';

	// get the global Assets manager
	var am = MUI.assetsManager;

	// Add validation function to the form
	// Set a global variable 'loginFormchk',
 	// which will be used as an instance of the validation Class-'FormCheck'.
 	var loginFormchk;

	// Load the form validation plugin script
	var options = {
		onload:function(){

			loginFormchk = new FormCheck( loginForm,{
				submit: false,

				onValidateSuccess: function(){
					// load the script which will set the user's menus
					MUI.login();

					// remove all the imported Assets of login module
					am.remove(appName,'app');

					// everything is done, close the dialog
					MUI.closeModalDialog();
					return false
				},

				display:{
					errorsLocation : 1,
					keepFocusOnError : 0,
					scrollToFirst : false
				}
			});// the end for 'loginFormchk' define
		}// the end for 'onload' define
	};
	MUI.formValidLib(appName,options);


	/*** Check whether the input account is existed.************************************/
 	// A Request.JSON class for send validation request to server side
 	var accountRequest = new Request.JSON({async:false});

 	var accountValidTag = false;
 	var accountCheck = function(el){
		el.errors.push(accountErr)
		// set some options for Request.JSON instance
		accountRequest.setOptions({
			url: checkUrl,
			onSuccess: function(res){
				if(res.valid == 1){accountValidTag=true};
			}
		});

		accountRequest.get({'name':el.getProperty('value')});
		if(accountValidTag){
			accountValidTag=false;   // reset global variable 'accountValid' to be 'false'
			return true
		};

		return false;
 	};
 	/***********************************************************************************/


 	/*** Check whether the input password is valid************************************/
 	// A Request.JSON class for send validation request to server side
 	var pwdRequest = new Request.JSON({async:false});

 	var pwdValidTag = false;
 	function pwdCheck(el){
		el.errors.push(pwdErr)
		// get account input information
		var input = $(loginForm).getElements('input')[0];
		var actionUrl = checkUrl + '?'+[input.getProperty('name'), input.getProperty('value')].join('=');
		// set some options for Request.JSON instance
		pwdRequest.setOptions({
			url: actionUrl,
			onSuccess: function(res){
				if(res.valid == 1){ pwdValidTag=true };
			}
		});

		pwdRequest.get({'name':el.getProperty('value')});
		if(pwdValidTag){
			pwdValidTag=false;   // reset global variable 'pwdValidTag' to be 'false'
			return true
		};

		return false;
 	};
 	/***********************************************************************************/


	window.addEvent('domready', function() {

		// add callback function to select changing
		$(select).addEvent('change',function(e){
			var selected = e.target;
			var selector = 'option[value=x]'.replace(/x/i, selected.getProperty('value'));
			option = selected.getElement(selector);
			new Event(e).stop();
			var a = [ option.getProperty('value'),option.getProperty('ref')]
			$(loginForm).getElements('input').each(function(input){
				input.setProperty('value', a.shift());
			});
		});

		// add mouseover effect to buttons
		new MooHover({container:bnsContainer,duration:800});

		// add callback functions to submit buttons
		var buttons = $(loginForm).getElements('button');

		// submit button
		buttons[0].addEvent('click',function(e){
			loginFormchk.onSubmit(e);
		});

		// cancel button
		buttons[1].addEvent('click',function(e){
			new Event(e).stop();
			MUI.closeModalDialog();
		});

	});
	"""%paras
	return script

def page_accountValid(**args):
	"""
	This action has two functions,
	one is to check whether the input user name is existed;
	second is to check whether the password is valid.
	Because this action url could be called by two javascript function,
	so according to the arguments to determine which function is callback.
	"""
	res = {'valid':0}
	# check validation type
	fields = [field.get('name') for field in FORMFIELDS ]
	keys = args.keys()
	if len(keys) == 2:
		# check whether the password is valid
		account = [args.get(name) for name in ( fields[0], 'name')]
		data = model.login(*account)

		# There are three validation results,
		# (0, "Invalid password")
		# (1, "Valid user name and password", roles)
		# (2, "Invalid user name")
		if data[0] == 1:
			res['valid'] = 1
			# valid user name and password, save them to session object
			data = {fields[0]:account[0],'roles':data[-1]}

			so = Session()
			setattr( so, pagefn.SOINFO['user'], data)
			res['user'] = data
			pagefn.setCookie(SET_COOKIE,REQUEST_HANDLER)

	else:
		# check whether the account is existed
		if model.userCheck( args.get('name') ) :
			res['valid'] = 1

	try:
		sys.setdefaultencoding('utf8')
	except:
		pass

	for k,v in res.items():
		res[k]= str(v).decode('utf8')

	PRINT( JSON.encode(res,encoding='utf8'))
	return

def page_welcomeInfo(**args):
	"""
	Return the welcome information,
	which will be shown on the top right of the screen.
	"""
	so = Session()
	try:
		username = getattr(so, pagefn.SOINFO['user']).get('username') or ''
	except:
		username = ''


	# set the welcome information which will be shown on the top right of the screen
	welcomeInfo = ''.join((_('Welcome, '), username, ' !'))
	welcomeInfo = H2(welcomeInfo, style='font-size:20px;color:white;')

	PRINT( str(welcomeInfo))
	return

def _renderMenuNode(nodes, node, prefix):
	li = LI()
	aLink = A( node.data.get('text'), **{'id': '-'.join(( prefix, node.id))})
	li <= aLink
	if node.children:	# has submenus
		ul = UL()
		for child in node.children:
			ul <= _renderMenuNode(nodes,child, prefix)
			nodes.remove(child)

		li <= ul

	return li

def _menuHtml(data, prefix):
	''' Constructs the menus list recursively. '''
	idFn = lambda i : i.get('id')
	pidFn = lambda i : i.get('parent')
	handler = treeHandler.TreeHandler(data, idFn, pidFn)
	nodes = handler.flatten()[1:]	# delete the first 'root' node

	# now recursively render the menu tree into html
	while nodes :
		node = nodes.pop(0)
		li = _renderMenuNode(nodes, node, prefix)
		PRINT( li)

	return

def page_menuList(**args):
	menuType = args.get(MENUTYPETAG)
	if MENUTYPE.index(menuType) == 0 :
		data = pagefn.USERMENUS['data']
	else:
		data = pagefn.ADMINMENUS['data']

	_menuHtml(data,menuType)

	return

MENUTYPE = ('userMenu', 'adminMenu')
MENUTYPETAG = 'menuType'
def page_menu(**args):
	""" Return the menus data corresponding to user role. """
	so = Session()
	roles = getattr(so, pagefn.SOINFO['user']).get('roles') or ''

	if pagefn.USEROLE in roles:
		menus = pagefn.USERMENUS
		menuType = MENUTYPE[0]
	else:
		menus = pagefn.ADMINMENUS
		menuType = MENUTYPE[1]

	menus['url'] = '?'.join(( '/'.join((APPATH, 'page_menuList')), '%s=%s'%(MENUTYPETAG, menuType) ))

	# constructs the json objec to be returned
	data = menus.pop('data')

	menus['functions'] = {}
	[ menus['functions'].update({ \
		'-'.join(( menuType, item.get('id'))):\
		{'funcname': item.get('function'), 'popupWindowId': item.get('popupWindowId') or '' }})\
		for item in data \
	]

	PRINT( JSON.encode(menus, encoding='utf8'))
	return

def page_sideBarPanels(**args):
	""" Return the panels info in the left side bar. """
	so = Session()
	roles = getattr(so, pagefn.SOINFO['user']).get('roles') or ''

	if pagefn.USEROLE in roles:
		panels = pagefn.USERSIDEBARPANELS
	else:
		panels = pagefn.ADMINSIDEBARPANELS

	for panelData in panels['data']:
		panelData['text'] = panelData['text'].decode('utf8')

	PRINT( JSON.encode(panels, encoding='utf8'))
	return

def page_closeSession(**args):
	""" Logout action, remove current session. """
	#so = Session()
	#so.close()
	return


