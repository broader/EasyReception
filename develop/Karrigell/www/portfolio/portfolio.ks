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
INITCONFIG = Import( '/'.join((RELPATH, 'config.py')), rootdir=CONFIG.root_dir)

# form fields' names in config.yaml file
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
	pass
	return
	
def page_info(**args):
	print H2('Test Portfolio')
	return
	
def _getCsv(operator, user):
	return model.getUserDossier(operator, user)		
		
def _portfolioTable(user,colsNumber=1,labelStyle='',valueStyle='',tableStyle=''):
	table = []
	values = _getCsv( USER, user)
	fields = INITCONFIG.getData(BASEINFO)
	newFields = formFn.filterProps(fields,values)	
	trs = formFn.render_table_fields( newFields, colsNumber, labelStyle, valueStyle)
	table.append(trs)
	table = TABLE(Sum(table), style=tableStyle)
	return table
	
def page_showPortfolio(**args):
	print H2('Portfolio Information')
	
	main = []
	
	labelStyle = {'label':'font-weight:bold;font-size:1.2em;color:white;', \
					  'td':'text-align:right;background:#9ca2cb'}
					  
	valueStyle = {'label':'color:#ff6600;font-size:1.2em;', 'td':'text-align:center;width:10em;',\
					  'textarea':'width:10em;color:#ff6600;font-size:1.2em;'}
					  
	tableStyle = 'position:relative;left:0.5em;'
	table = _portfolioTable(USER,2,labelStyle,valueStyle,tableStyle)
	
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
	'''
	var portfolioBn='%s', portfolioDlgTitle='%s', portfolioEditUrl='%s';
	function portfolioPageInit(){
	    // add mouseover effect to buttons
	    new MooHover({container:portfolioBn,duration:800});
    
	    // Add click callback functions for buttons
	    $(portfolioBn)
	    .getElements('button')[0]
	    .addEvent('click',function(event){
		new MUI.Modal({
		    width:800, height:380,
		    contentURL: portfolioEditUrl,
		    title: portfolioDlgTitle,
		    modalOverlayClose: false,
		});
	    });
	};
	
	window.addEvent('domready', portfolioPageInit);
	'''%paras
	
	return js

def page_editPortfolio(**args):
	name = args.get('user')
	if not name:
		user = USER
	else:
		user = name
		
	rember = _getCsv(USER,user)
	
	render = INITCONFIG.getData(BASEINFO)
	
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
	left = DIV(Sum(yform(render[:interval])), **{'class':'c33l'})
	next = 2*interval
	center = DIV(Sum(yform(render[interval:next])), **{'class':'c33l', 'style':'border-left:1px solid #DDDDDD;'})
	# for compatiable for ie browser, this div using 'style' property, not 'c33r' css class
	right = DIV(Sum(yform(render[next:])), **{'style':'float:right;width:30%;border-left:1px solid #DDDDDD;'})
	divs = DIV(Sum((left, center, right)), **{'class':'subcolumns'})	

   	# add the <Legend> tag
	legend = LEGEND(Sum([ TEXT(user), TEXT(_('- Base Information ')) ]))    
	form.append(FIELDSET(Sum((legend,divs))))
	
	if user != USER :
		# not self edit action, so save the name of editing user into the form body
		form.append(INPUT(**{'name':'username','value':user,'type':'hidden'}))
		
	# add buttons to this form	
	buttons = \
	[ BUTTON( name, **{'class':'MooTrans', 'type':'button'}) \
	  for name in BNLABELS[1:] ]
	
	div = DIV(Sum(buttons), **{ 'id':PORTFOLIOACTIONBN , 'style':'position:absolute;margin-left:20em;'})    
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
	panelReload = args.get('panelReload') or '1'
	print pagefn.script(_editPortfolioJs(panelReload),link=False)
	return

def _editPortfolioJs(panelReload):
	#paras = [ panelReload,panelId or portfolioPanel, APP, PORTFOLIOACTIONBN, BASEINFO ]
	paras = [ panelReload, portfolioPanel, APP, PORTFOLIOACTIONBN, BASEINFO ]
	paras = tuple(paras)
	js =\
	'''
	var panelReload='%s', currentPanelId='%s', 
	appName='%s', portfolioActionBn='%s', portfolioFormId='%s';

	// Add validation function to the form
	// Set a global variable 'portfolioFormchk', 
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
						
			    // Is it need to update the content of panel?
			    if (panelReload == '1'){
				panel = MUI.Panels.instances.get( currentPanelId );
				props = panel.options;
							
				MUI.updateContent({
				    'element': panel.panelEl,
				    'content': props.content,
				    'method': props.method,
				    'data': props.data,
				    'url': props.contentURL,
				    'onContentLoaded': null
				});
			    };
						
			};               
		    },            

		    display:{
			errorsLocation : 1,
			keepFocusOnError : 0, 
			scrollToFirst : false
		    }
		});// the end for 'portfolioFormchk' define
	    }// the end for 'onload' define
	};// the end for 'options' define
 
	MUI.formValidLib(appName,options);
   
	function editPortfolio(event){
	    portfolioFormchk.onSubmit(event);
	};
	
	function closeDialog(){
	    // close register dialog, this function has been defined in init.js
	    MUI.closeModalDialog();
	    // remove imported Assets
	    MUI.assetsManager.remove(appName,'app');
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
	'''%paras	
	return js	

def page_editPortfolioAction(**args):
	info = {}		
	fields = [ item.get('name') for item in INITCONFIG.getData(BASEINFO) ]
	[ info.update( {name: args.get(name) or ''} ) for name in fields ]
	
	operator = USER
	user = args.get('username') 
	if user :
		action = 'edit'
	else:
		action = 'create'
		user = USER	
	# write these informations to database
	res = model.edit_user_info( operator, user, action, info)
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
	props = ['email', 'creation', 'activity']
	res = model.get_item(user, 'user', user, props, keyIsId=False)
	if type(res) == type({}):
		account.update(res)
		account['password'] = '/'
	
	main = []
	
	# the account informations
	table = []
	
	# append the caption
	#table.append( CAPTION(_("Login Information"),style='text-align: center; font-size: 1.2em;font-weight:bold;'))
		  	
	fields = INITCONFIG.getData(ACCOUNTFIELDS)
	fields.append({ 'name':'creation' , 'prompt':_('Created Time :'), 'type':'text'})
	fields.append({ 'name':'activity' , 'prompt':_('Activity :'), 'type':'text'})
	values = formFn.filterProps(fields, account)
	#values = []	
	#for field in fields :
	#	value = {}
	#	[ value.update({prop:field.get(prop)}) for prop in ('prompt','type')]		
	#	value['value'] = account.get(field.get('name'))
	#	values.append(value)
		
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
	'''
	var accountBn='%s', accountDlgTitle='%s', accountEditUrl='%s';

	function pageInit(){
	    // add mouseover effect to buttons
	    new MooHover({container: accountBn,duration:800});
   	
	    // Add click callback functions for buttons
	    $(accountBn)
	    .getElements('button')[0]
	    .addEvent('click',function(e){
		new Event(e).stop();
		new MUI.Modal({
		    width:500, height:380, scrollbars:false,
		    contentURL: accountEditUrl,
		    title: accountDlgTitle,
		    modalOverlayClose: false
		});
	    });
	};
	
	window.addEvent('domready', pageInit);
	'''%paras
	
	return js
	
def page_editAccount(**args):
	
	fields = INITCONFIG.getData(ACCOUNTFIELDS)
	
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
	paras = [ accountPanel, APP, ACCOUNTACTIONBN, ACCOUNTFIELDS, pagefn.ADMINMENUS['data'][1]['popupWindowId'] ]	
	paras = tuple(paras)
	
	js =\
	'''
	var panelId='%s',appName='%s', 
	    buttonsContainer='%s', formId='%s',
	    // the dom id for popup window which is been showing the portfolio of this user
	    popupWindowId="%s";	

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
			    // close edit dialog
			    closeDialog();

			    if($(popupWindowId)){
				/* 
				when $(popupWindowId) is a element, 
				that means this edit action is called by a MUI.Window( used in the navigation bar of admin user's view), 
				it's need to refresh the content in the MUI.Window instance.						
				*/
				var wInstance = MUI.Windows.instances.get("adminProfileWindow");
				var options = wInstance.options;
							
				MUI.updateContent({
				    'element': wInstance.windowEl,
				    'content': options.content,
				    'method': options.method,
				    'url': options.contentURL,
				    'data': options.data,
				    'onContentLoaded': null 
				});
				return
			    };
	
			    MUI.notification('Edit Successfully');	// Successfully action
			    // refresh account show page
			    var panel = MUI.Panels.instances.get(panelId),
				props = panel.options;
			    MUI.updateContent({
				'element': panel.panelEl,
				'content': props.content,
				'method': props.method,
				'data': props.data,
				'url': props.contentURL,
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
    
	MUI.formValidLib(appName,options);
   
	function edit(event){
	    formchk.onSubmit(event);
	};
	
	function closeDialog(){
	    // close register dialog, this function has been defined in init.js
	    MUI.closeModalDialog();
   	
	    MUI.assetsManager.remove(appName,'app');
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
	'''%paras
	
	return js

def page_editAccountAction(**args):
	""" Edit the user's account information. """
	fields = INITCONFIG.getData(ACCOUNTFIELDS)	
	# remove 'username' field
	fields.pop(0)
	
	names = [field.get('name') for field in fields ]
	
	props = {}
	[props.update({key: args.get(key)}) for key in names ]	
	
	# excute user's edit action
	user = USER
	model.edit_item(user, 'user', user, props, actionType='edit', keyIsId=False)
	
	print '1'
	return
	
	
	
