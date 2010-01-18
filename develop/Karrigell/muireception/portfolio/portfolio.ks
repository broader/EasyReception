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

#user = getattr( so, pagefn.SOINFO['userinfo']).get('username')

# config data object
CONFIG = Import( '/'.join((RELPATH, 'config.py')), rootdir=CONFIG.root_dir)

# form fields' names in CONFIG file
ACCOUNTFIELDS = 'userAccountInfo'

# The ids for the buttons' container to edit account information
ACCOUNTEDITBN = 'editAccountBn'
ACCOUNTACTIONBN = 'AccountActionBn'

# The ids for MUI.Panels
portfolioPanel,accountPanel = pagefn.PORTFOLIO.get('panelsId') 
# End*****************************************************************************************


# ********************************************************************************************
# The page functions begining 
# ********************************************************************************************

def index(**args):
	print H2('Test Portfolio')
	return

def _getUser():
	so = Session()
	user = getattr( so, pagefn.SOINFO['userinfo']).get('username')
	return user
	
def _getCsv(operator, user):
	# get link id	
	prop = 'info'	
	values = model.get_item( operator, 'user', user, (prop,))
	nodeId = values.get(prop) 
	if not nodeId :
		content = {}
	else:
		# get file content
		content = model.get_file( operator, 'dossier', nodeId)		
	data = model.csv2dict(content)			
	return data	
	
def page_showPortfolio(**args):
	print H2('Portfolio Information')
	user = _getUser()
	values = _getCsv(user,user)
	print values
	return
	
def page_showAccount(**args):
	print H2('Account Information')
	
	user = _getUser()
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
	info = ': '.join((_('Login Name'), user))
	
	legend = LEGEND(TEXT(info))    
	form.append(FIELDSET(Sum((legend,div))))
    
	# add buttons to this form   
	bns =[_("OK"), _("Cancel")] 
	btypes = ('submit','button') 
	bns = [BUTTON(text, **{'class':'MooTrans', 'type': btype}) for text, btype in zip( bns, btypes)]
	span = DIV(Sum(bns), **{ 'id':ACCOUNTACTIONBN, 'style':'position:absolute;margin-left:5em;'})    
	form.append(span)
    
	# form action url
	action = '/'.join((APPATH, '_'.join(('page', 'editAccountAction'))))              
              
	form = FORM( \
				Sum(form),\ 
				**{'action': action, 'id': ACCOUNTFIELDS, 'method':'get','class':'yform'}\
				)
				
	print DIV(form, **{'class':'subcolumns'})
	
	print pagefn.script(_editAccountJs(), link=False)
	
	return

def _editAccountJs(**args):
	paras = [ accountPanel, APP, ACCOUNTACTIONBN, ACCOUNTFIELDS ]
	
	# add some files' path for validation function
	paras.extend(pagefn.FCLIBFILES)
	
	paras = tuple(paras)
	
	js =\
	"""
	var panelId='%s',appName='%s', 
	buttonsContainer='%s', formId='%s',
	hackCss='%s', fcI18nJs='%s', fcJs='%s', fcCss='%s';
	
	
	// get the global Assets manager
   var am = MUI.assetsManager;
    
   // Add validation function to the form
   // import css file for validation
   [ hackCss, fcCss].each(function(src){
   	if(!$defined(am.imported[src])){
    		am.import({'url':src,'app':appName,'type':'css'});
    	}	
	});
	
	// Set a global variable 'formchk', 
	// which will be used as an instance of the validation Class-'FormCheck'.
	var formchk;
    
	// Load the form validation plugin script
	var options = {
		onload:function(){    		
			formchk = new FormCheck( formId,{
				submitByAjax: true,
				onAjaxSuccess: function(response){
					if(response != 1){
						MUI.notification('Account creating failed!');
					}
					else{	
						MUI.notification('Edit Successfully');	// Successfully action
						// close edit dialog
						closeDialog();
						
						// refresh account show page
						var panel = MUI.Panels.instances.get(panelId),
						options = panel.options;
						MUI.updateContent({
							'element': panel.panelEl,
							'content': options.content,
							'method': options.method,
							'data': options.data,
							'url': options.contentURL,
							'onContentLoaded': null
						});
					};               
				},            

				display:{
					errorsLocation : 1,
					keepFocusOnError : 0, 
					scrollToFirst : false
				}
			});// the end for 'formchk' define
		}// the end for 'onload' define
	};
    
   am.import({'url':fcJs,'app':appName,'type':'js'},options);
   
   function edit(event){
		formchk.onSubmit(event);
	};
	
	function closeDialog(){
		// close register dialog, this function has been defined in init.js
   	MUI.closeModalDialog();
   	
   	am.remove(appName,'app');
	};
	
	function exit(event){
		new Event(event).stop();
		closeDialog();
	};
	
	function pageInit(){
		// add mouseover effect to buttons
   	new MooHover({container:buttonsContainer,duration:800});
   	
   	var fns = [exit, edit]
   	$(buttonsContainer)
	   .getElements('button')
	   .each(function(button){
		   button.addEvent('click', fns.pop());
	   });
	};
	
	window.addEvent('domready', pageInit);
	"""%paras
	
	return js

def page_editAccountAction(**args):
	""" Edit the user's account information. """
	fields = CONFIG.getData(ACCOUNTFIELDS)	
	# remove 'username' field
	fields.pop(0)
	
	names = [field.get('name') for field in fields ]
	
	props = {}
	[props.update({key: args.get(key)}) for key in names ]	
	
	# excute user's edit action
	model.edit_item(user, 'user', user, props, actionType='edit', keyIsId=False)
	
	print '1'
	return
	
	
	