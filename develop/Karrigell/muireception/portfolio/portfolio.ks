"""
Portfolio module 
"""

from HTMLTags import *

# 'THIS.script_url' is a global variable in Karrigell system
APPATH = THIS.script_url[1:]
RELPATH = (lambda p : p.split('/')[0])(THIS.baseurl)

model = Import( '/'.join((RELPATH, 'model.py')), REQUEST_HANDLER=REQUEST_HANDLER )
modules = {'pagefn' : 'pagefn.py',  'JSON' : 'demjson.py', 'formFn':'form.py'}
[locals().update({k : Import('/'.join(('',v)))}) for k,v in modules.items() ]


# ********************************************************************************************
# Page Variables
# ********************************************************************************************
# form fields' names in CONFIG file
ACCOUNTFIELDS = \
[
	{ 'name':'username', 'prompt':_('Login Name :'), 'type':'text'},\
	{ 'name':'email', 'prompt':_('Email address :'), 'type':'text'},\
	{ 'name':'password', 'prompt':_('Password :'), 'type':'text'},\
	{ 'name':'creation' , 'prompt':_('Created Time :'), 'type':'text'},\
]

# ********************************************************************************************

# get the relative url slice as the application name
APP = pagefn.getApp(THIS.baseurl,1)

# the session object for this page
so = Session()

# config data object
CONFIG = Import( '/'.join((RELPATH, 'config.py')), rootdir=CONFIG.root_dir)

# Account edit button's id
ACCOUNTEDITBN = 'editAccountBn'
# End*****************************************************************************************


# ********************************************************************************************
# The page functions begining 
# ********************************************************************************************

def index(**args):
	print H2('Test Portfolio')
	return
	
def page_portfolio(**args):
	print H2('Portfolio Information')
	return
	
def page_account(**args):
	print H2('Account Information')
	
	user = getattr( so, pagefn.SOINFO['userinfo']).get('username')
	account = {'username':user}

	# get account info
	props = ['email', 'creation']
	res = model.get_item(user, 'user', user, props, keyIsId=False)
	if type(res) == type({}):
		account.update(res)
		account['password'] = _('/')
	#account.update({'username':user})
	
	main = []
	#main.append(DIV( HR(), **{'class':'subcolumns' }))	
	
	# the account informations
	table = []
	# append the caption
	#table.append( CAPTION(_("Login Information"),style='text-align: center; font-size: 1.2em;font-weight:bold;'))
		  
	values = []	
	for field in ACCOUNTFIELDS :
		value = {}
		[ value.update({prop:field.get(prop)}) for prop in ('prompt','type')]		
		value['value'] = account.get(field.get('name'))
		values.append(value)
		
	labelStyle = {'label':'font-weight:bold;font-size:1.2em;color:white;', \
					  'td':'text-align:right;background:#9ca2cb'}
					  
	valueStyle = {'label':'color:#ff6600;font-size:1.2em;', 'td':'text-align:left;'}
	
	trs = formFn.render_table_fields( values, 1, labelStyle, valueStyle)
	table.append(trs)
	table = TABLE(Sum(table), style='position:relative;left:4em;')
	
	accountDiv = DIV(table, **{'class':'subcolumns'})		
	main.append(DIV( accountDiv, **{'class':'subcolumns'}))
	
	button = BUTTON( _('Edit'), **{'class':'MooTrans', 'type':'button', 'style':'font-size:1.6em;width:atuo;'})
	div = DIV( button, **{ 'id':ACCOUNTEDITBN, 'style':'position:absolute;margin-left:10em;'}) 
	
	main.append(div)
	
	print Sum(main)
	
	print pagefn.script(_accountJs(), link=False)
	
	return

def _accountJs(**args):
	paras = [ACCOUNTEDITBN,]
	paras = tuple(paras)
	js = \
	"""
	var buttonsContainer='%s';
	function pageInit(){
		// add mouseover effect to buttons
   	new MooHover({container:buttonsContainer,duration:800});
   	
   	// Add click callback functions for buttons
      $(buttonsContainer)
      .getElements('button')[0]
      .addEvent('click',function(event){
         new MUI.Modal({
         	id:'', contentURL:'', width:400, height:300,
         	title: 'Edit Account',
         	modalOverlayClose: false,
         });
      });
	};
	
	window.addEvent('domready', pageInit);
	"""%paras
	
	return js