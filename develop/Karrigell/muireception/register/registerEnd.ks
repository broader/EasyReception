"""
The module for registration application. 
"""

from HTMLTags import *

# 'THIS.script_url' is a global variable in Karrigell system
#APPATH = THIS.script_url[1:]
RELPATH = (lambda p : p.split('/')[0])(THIS.baseurl)

#model = Import( '/'.join((RELPATH, 'model.py')))

modules = {'pagefn' : 'pagefn.py', 'formFn':'form.py'}
[locals().update({k : Import('/'.join(('',v)))}) for k,v in modules.items() ]
 

# ********************************************************************************************
# Page Variables
# ********************************************************************************************

# the session object for this page
so = Session()

# config data object
CONFIG = Import( '/'.join((RELPATH, 'config.py')), rootdir=CONFIG.root_dir)

# get the relative url slice as the application name
APP = pagefn.getApp(THIS.baseurl,1)

# form fields' names in CONFIG file
ACCOUNTFIELDS = 'userAccountInfo'

# base information fields' names in CONFIG file
#BASEINFOFIELDS = 'userBaseInfo'

# End*****************************************************************************************

# ********************************************************************************************
# The page functions begining 
# ********************************************************************************************

def index(**args):
	main = []
	text = _("Congradulations! You have registered successfully!<BR>\
		     	 Below is your account information.<BR>")
		     
	header = H2( text, style='text-align:left;color:saddleBrown;')	
	main.append(DIV(header, **{'class':'subcolumns' }))
	main.append(DIV( HR(), **{'class':'subcolumns' }))	
	
	# the account informations
	table = []
	# append the caption
	table.append( CAPTION(_("Login Information"),\
					  style='text-align: center; font-size: 1.2em;font-weight:bold;'))
	
	try:
		account = getattr(so,pagefn.SOINFO['userinfo'])
	except:
		account = {}
		  
	fieldvalues = CONFIG.getData(ACCOUNTFIELDS)
	values = []	
	for field in fieldvalues :
		value = {}
		[ value.update({prop:field.get(prop)}) for prop in ('prompt','type')]		
		value['value'] = account.get(field.get('name'))
		values.append(value)
		
	labelStyle = {'label':'font-weight:bold;font-size:1.2em;color:white;', \
					  'td':'text-align:right;background:#9ca2cb'}
					  
	valueStyle = {'label':'color:#ff6600;font-size:1.2em;', 'td':'text-align:left;'}
	
	trs = formFn.render_table_fields( values, 1, labelStyle, valueStyle)
	table.append(trs)
	table = TABLE(Sum(table), style='position:relative;left:15em;')
	
	accountDiv = DIV(table, **{'class':'subcolumns'})		
	main.append(DIV( accountDiv, **{'class':'subcolumns'}))
	
	main.append(DIV( HR(), **{'class':'subcolumns'}))
	
	text = _("You could edit your account and other portfolio information in this system later.<BR>\
				If you have any question, please contact with us.<BR>You're welcom always !")
	prompt = DIV( H2(text), **{'class':'warning', 'style':'text-align:left;color:saddleBrown;'})	
	main.append(DIV( prompt, **{'class':'subcolumns' }))
	
	bnId = 'endRegister'
	button = BUTTON( _('End Registration'), **{'class':'MooTrans', 'type':'button', 'style':'font-size:0.9em;width:atuo;'})
	span = DIV( button, **{ 'id':bnId, 'style':'position:absolute;margin-left:20em;'}) 
	
	main.append(DIV( span, **{'class':'subcolumns'}))
	print DIV(Sum(main), **{'class':'subcolumns', 'style':'background:white;'})
	
	paras = [bnId, APP, pagefn.LOGINPANEL]
	paras = tuple(paras)
	js = \
	"""
	var bnContainer='%s', appName='%s', loginPanel='%s';
	
	// get the global Assets manager
	var am = MUI.assetsManager;
    
	// add mouseover effect to buttons
   new MooHover({container:bnContainer,duration:800});
   
   $(bnContainer)
   .getElements('button')[0]
   .addEvent('click',function(){
   	// call login function which is a inner function of MUI object
   	MUI.login();
   	
   	// close register dialog, this function has been defined in init.js
   	MUI.closeModalDialog();
   	
   	am.remove(appName,'app');
	});
	"""%paras
	print pagefn.script(js, link=False)
	return
	