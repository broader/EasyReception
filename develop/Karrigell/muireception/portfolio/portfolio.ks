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
USER = getattr( so, pagefn.SOINFO['user']).get('username')

# config data object
CONFIG = Import( '/'.join((RELPATH, 'config.py')), rootdir=CONFIG.root_dir)

# form fields' names in CONFIG file
ACCOUNTFIELDS = 'userAccountInfo'
BASEINFO = 'userBaseInfo'

# The ids for the buttons' container to edit information
ACCOUNTEDITBN = 'editAccountBn'
ACCOUNTACTIONBN = 'accountActionBn'

PORTFOLIOEDITBN = 'editPortfolioBn'
PORTFOLIOACTIONBN = 'portfolioActionBn'

BNLABELS = ( _('Edit'), _('OK'), _('Cancel'))

# The ids for MUI.Panels
portfolioPanel,accountPanel = pagefn.PORTFOLIO.get('panelsId') 
# End*****************************************************************************************


# ********************************************************************************************
# The page functions begining 
# ********************************************************************************************

def index(**args):
	print H2('Test Portfolio')
	return
	
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
	user = USER
	values = _getCsv(user,user)
	
	fields = CONFIG.getData(BASEINFO)
	newFields = formFn.filterProps(fields,values)
	
	main,table = ([],[])	
	
	labelStyle = {'label':'font-weight:bold;font-size:1.2em;color:white;', \
					  'td':'text-align:right;background:#9ca2cb'}
					  
	valueStyle = {'label':'color:#ff6600;font-size:1.2em;', 'td':'text-align:center;width:10em;',\
					  'textarea':'width:10em;color:#ff6600;font-size:1.2em;'}
	
	trs = formFn.render_table_fields( newFields, 2, labelStyle, valueStyle)
	table.append(trs)
	table = TABLE(Sum(table), style='position:relative;left:0.5em;')
	
	div = DIV(table, **{'class':'subcolumns'})		
	main.append(DIV( div, **{'class':'subcolumns'}))
	
	button = BUTTON( BNLABELS[0], **{'class':'MooTrans', 'type':'button', 'style':'font-size:1.2em;width:atuo;'})
	div = DIV( button, **{ 'id':PORTFOLIOEDITBN, 'style':'position:absolute;margin-left:20em;'})	
	main.append(div)	
	print Sum(main)
	
	# import js slice  
	print pagefn.script(_portfolioShowJs(),link=False)	
	return

def _portfolioShowJs(**args):
	paras = [PORTFOLIOEDITBN, _('Edit Portfolio'), '/'.join((APPATH,'page_editPortfolio'))]
	paras = tuple(paras)
	js = \
	"""
	var portfolioBn='%s', portfolioDlgTitle='%s', portfolioEditUrl='%s';
	function portfolioPageInit(){
		// add mouseover effect to buttons
   	new MooHover({container:portfolioBn,duration:800});
   	
   	// Add click callback functions for buttons
      $(portfolioBn)
      .getElements('button')[0]
      .addEvent('click',function(event){
         new MUI.Modal({
         	width:600, height:380,
         	contentURL: portfolioEditUrl,
         	title: portfolioDlgTitle,
         	modalOverlayClose: false,
         });
      });
	};
	
	window.addEvent('domready', portfolioPageInit);
	"""%paras
	
	return js

def page_editPortfolio(**args):
	user = USER
	rember = _getCsv(user,user)
	
	render = CONFIG.getData(BASEINFO)
	
	# Add other properties for each field, these properties are 'id','required','oldvalue'
	for element in render :
		name = element.get('name')
		# Add 'id' property for each field		
		element.update({'id':name})
      # Add required property to the needed fields, 
      # here means all the fields will be added the 'required' property.
		element.update({'required':False})
      # add maybe old value
		element.update({'oldvalue':rember.get(name)})	
	
	# render the fields to the form
	form = []
   # get the OL content from formRender.py module	
	yform = formFn.yform
	# calculate the fields' number showing in each column of the form	
	interval = int(len(render)/3)	
	style = 'border-left:1px solid #DDDDDD;'		
	left = DIV(Sum(yform(render[:interval])), **{'class':'c33l', 'style':style})
	next = 2*interval
	center = DIV(Sum(yform(render[interval:next])), **{'class':'c33r', 'style':style})
	right = DIV(Sum(yform(render[next:])), **{'class':'c33r', 'style':style})
	divs = DIV(Sum((left, center, right)), **{'class':'subcolumns'})	
	
   # add the <Legend> tag
	legend = LEGEND(TEXT(_('Base Information')))    
	form.append(FIELDSET(Sum((legend,divs))))
	
	# add buttons to this form	
	buttons = \
	[ BUTTON( name, **{'class':'MooTrans', 'type':'button'}) \
	  for name in BNLABELS[1:] ]
	
	div = DIV(Sum(buttons), **{ 'id':PORTFOLIOACTIONBN , 'style':'position:absolute;margin-left:12em;'})    
	form.append(div)
	
	# form action url
	action = '/'.join((APPATH, '_'.join(('page', 'editPortfolioAction'))))
	 
	form = FORM( Sum(form), 
                 **{
                   'action': action, 
                   'id': BASEINFO, 
                   'method':'post',                   
                   'class':'yform'
                 }
               )
	print DIV(form, **{'class':'subcolumns'})
	
	# import js slice  
	print pagefn.script(_editPortfolioJs(),link=False)	
	return

def _editPortfolioJs(**args):
	paras = [ portfolioPanel, APP, PORTFOLIOACTIONBN, BASEINFO ]
	
	# add some files' path for validation function
	paras.extend(pagefn.FCLIBFILES)
	
	paras = tuple(paras)
	js =\
	"""
	var portfolioPanelId='%s',appName='%s', 
	portfolioActionBn='%s', portfolioFormId='%s',
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
	var portfolioFormchk;
    
	// Load the form validation plugin script
	var options = {
		onload:function(){    		
			portfolioFormchk = new FormCheck( portfolioFormId,{
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
						var panel = MUI.Panels.instances.get( portfolioPanelId ),
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
   
   function editPortfolio(event){
		portfolioFormchk.onSubmit(event);
	};
	
	function closeDialog(){
		// close register dialog, this function has been defined in init.js
   	MUI.closeModalDialog();
   	
   	// remove imported Assets
   	am.remove(appName,'app');
	};
	
	function exitEditPortfolio(event){
		new Event(event).stop();
		closeDialog();
	};
	
	function editPortfolioPageInit(){
		// add mouseover effect to buttons
   	new MooHover({container: portfolioActionBn,duration:800});
   	
   	var fns = [ exitEditPortfolio, editPortfolio ]
   	$( portfolioActionBn )
	   .getElements('button')
	   .each(function(button){
		   button.addEvent('click', fns.pop());
	   });
	};
	
	window.addEvent('domready', editPortfolioPageInit );
	"""%paras	
	return js	

def page_editPortfolioAction(**args):
	info = {}		
	fields = [ item.get('name') for item in CONFIG.getData(BASEINFO) ]
	[ info.update({ name:args.get(name) or '' }) for name in fields ]	
	user = USER
	# write these informations to database
	res = model.edit_user_info( user, user, 'create', info)
	if res :
		print '1'
	else:
		print '0'
	return
			
def page_showAccount(**args):
	print H2('Account Information')
	
	user = USER
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
		  	
	fields = CONFIG.getData(ACCOUNTFIELDS)
	fields.append({ 'name':'creation' , 'prompt':_('Created Time :'), 'type':'text'})
	values = formFn.filterProps(fields, account)
	"""
	values = []	
	for field in fields :
		value = {}
		[ value.update({prop:field.get(prop)}) for prop in ('prompt','type')]		
		value['value'] = account.get(field.get('name'))
		values.append(value)
	"""
		
	labelStyle = {'label':'font-weight:bold;font-size:1.2em;color:white;', \
					  'td':'text-align:right;background:#9ca2cb'}
					  
	valueStyle = {'label':'color:#ff6600;font-size:1.2em;', 'td':'text-align:center;',\
					  'textarea':'width:10em;color:#ff6600;font-size:1.2em;'}
	
	trs = formFn.render_table_fields( values, 1, labelStyle, valueStyle)
	table.append(trs)
	table = TABLE(Sum(table), style='position:relative;left:4em;')
	
	accountDiv = DIV(table, **{'class':'subcolumns'})		
	main.append(DIV( accountDiv, **{'class':'subcolumns'}))
	
	button = BUTTON( BNLABELS[0], **{'class':'MooTrans', 'type':'button', 'style':'font-size:1.6em;width:atuo;'})
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
	var accountBn='%s', accountDlgTitle='%s', accountEditUrl='%s';
	function pageInit(){
		// add mouseover effect to buttons
   	new MooHover({container: accountBn,duration:800});
   	
   	// Add click callback functions for buttons
      $(accountBn)
      .getElements('button')[0]
      .addEvent('click',function(event){
         new MUI.Modal({
         	contentURL:'', width:400, height:350,
         	contentURL: accountEditUrl,
         	title: accountDlgTitle,
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
	user = USER
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
	bns = BNLABELS[1:]
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
	
	
	