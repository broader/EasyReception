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

# get the relative url slice as the application name
APP = pagefn.getApp(THIS.baseurl,1)

# the session object for this page
so = Session()
user = getattr( so, pagefn.SOINFO['userinfo']).get('username')

# config data object
CONFIG = Import( '/'.join((RELPATH, 'config.py')), rootdir=CONFIG.root_dir)

# form fields' names in CONFIG file
ACCOUNTFIELDS = 'userAccountInfo'

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
	
	account = {'username':user}

	# get account info
	props = ['email', 'creation']
	res = model.get_item(user, 'user', user, props, keyIsId=False)
	if type(res) == type({}):
		account.update(res)
		account['password'] = '/'
	
	main = []
	
	# the account informations
	table = []
	# append the caption
	#table.append( CAPTION(_("Login Information"),style='text-align: center; font-size: 1.2em;font-weight:bold;'))
		  
	values = []	
	fields = CONFIG.getData(ACCOUNTFIELDS)
	fields.append({ 'name':'creation' , 'prompt':_('Created Time :'), 'type':'text'})
	for field in fields :
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
	
	# import js slice  
	print pagefn.script(_accountShowJs(), link=False)
	
	return

def _accountShowJs(**args):
	paras = [ACCOUNTEDITBN, _('Edit Account'), '/'.join((APPATH,'page_editAccount'))]
	paras = tuple(paras)
	js = \
	"""
	var buttonsContainer='%s', dlgTitle='%s',url='%s';
	function pageInit(){
		// add mouseover effect to buttons
   	new MooHover({container:buttonsContainer,duration:800});
   	
   	// Add click callback functions for buttons
      $(buttonsContainer)
      .getElements('button')[0]
      .addEvent('click',function(event){
         new MUI.Modal({
         	id:'', contentURL:'', width:400, height:350,
         	contentURL: url,
         	title: dlgTitle,
         	modalOverlayClose: false,
         });
      });
	};
	
	window.addEvent('domready', pageInit);
	"""%paras
	
	return js
	
def page_editAccount(**args):
	
	fields = CONFIG.getData(ACCOUNTFIELDS)
	
	# remove 'username' field
	fields.pop(0)
	[ fields[index].update({'validate':value}) \
	  for index,value in zip((0,1),(['email',], ['length[6,-1]',]))]
	fields.insert(1, \
		{'prompt':_("Confirm Email :"), \
		 'name':'cemail', 'type':'text',\
		 'validate':['email','confirm[%s]'%fields[0].get('name')]}\
	)
	
	fields.append(\
		{'prompt':_("Confirm Password :"),\
		 'name':'cpwd', \
		 'type':'password',\
		 'validate':['confirm[%s]'%fields[-1].get('name'),]}\
	)
	
	
	# get account info
	props = ['email',]
	values = model.get_item(user, 'user', user, props, keyIsId=False)
	if type(values) != type({}):
		values = {}
	
	# Add other properties for each field, these properties are 'id','required','oldvalue'
	for field in fields :
		# Add 'id' property for each field
	 	name = field.get('name')
	 	field.update({'id':name})
	 	# Add required property to the needed fields, 
	 	# here means all the fields will be added the 'required' property.
	 	field.update({'required':True})
	 	# add maybe old value
	 	field.update({'oldvalue':values.get(name)})
   
	
   
	# render the fields to the form
	form = []
	# get the OL content from formRender.py module	
	yform = formFn.yform(fields)
	
	div = DIV( Sum(yform), **{'class':'subcolumns'})
            
	# add the <Legend> tag
	info = '--->'.join((_('Login Name'), user))
	
	legend = LEGEND(TEXT(info))    
	form.append(FIELDSET(Sum((legend,div))))
    
	# add buttons to this form   
	bns =[_("OK"), _("Cancel")] 
	btypes = ('submit','button') 
	bns = [BUTTON(text, **{'class':'MooTrans', 'type': btype}) for text, btype in zip( bns, btypes)]
	span = DIV(Sum(bns), **{ 'id':ACCOUNTEDITBN, 'style':'position:absolute;margin-left:5em;'})    
	form.append(span)
    
	# form action url
	action = '/'.join((APPATH, '_'.join(('page', 'valid'))))              
              
	form = FORM( \
				Sum(form),\ 
				**{'action': action, 'id': ACCOUNTFIELDS, 'method':'get','class':'yform'}\
				)
				
	print DIV(form, **{'class':'subcolumns'})
	
	return
	
	