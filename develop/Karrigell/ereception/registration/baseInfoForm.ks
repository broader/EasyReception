"""
The module for registration application. 
"""

import sys
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

# the session object for this page
SO = Session()

# config data object
CONFIG = Import( '/'.join((RELPATH, 'config.py')), rootdir=CONFIG.root_dir)

# account information fields' names in CONFIG file
ACCOUNTFIELDS = 'userAccountInfo'

# base information fields' names in CONFIG file
BASEINFOFIELDS = 'userBaseInfo'

# the id for the SPAN component in the form page which holds buttons 
FORMBNS = 'baseInfoBns'

# End*****************************************************************************************

# ********************************************************************************************
# The page functions begining 
# ********************************************************************************************


def index(**args):	
	render = CONFIG.getData(BASEINFOFIELDS)		
	rember = dict([ (field.get('name'), getattr(SO, field.get('name'), None))  for field in render ])
	
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
	center = DIV(Sum(yform(render[interval:next])), **{'class':'c33r'})
	right = DIV(Sum(yform(render[next:])), **{'class':'c33r'})
	divs = DIV(Sum((left, center, right)), **{'class':'subcolumns'})	
	
   # add the <Legend> tag
	legend = LEGEND(TEXT('Base Information'))    
	form.append(FIELDSET(Sum((legend,divs))))
	
	# add buttons to this form	
	buttons = \
	[ BUTTON( name, **{'class':'MooTrans', 'type':'button'}) \
	  for name in [_("Back"), _("Next"), _("Cancel")] ]
	
	span = DIV(Sum(buttons), **{ 'id':FORMBNS, 'style':'position:absolute;margin-left:18em;'})    
	form.append(span)
	
	# form action url
	action = '/'.join((APPATH, '_'.join(('page', 'accountRegister'))))
	 
	form = FORM( Sum(form), 
                 **{
                   'action': action, 
                   'id': BASEINFOFIELDS, 
                   'method':'get',                   
                   'class':'yform'
                 }
               )
	print DIV(form, **{'class':'subcolumns'})
	
	# javascript functions for this page
	paras = [ pagefn.REGISTERDLG, pagefn.TABSCLASS, BASEINFOFIELDS,\
				 FORMBNS, _('Account creating failed!') ]
	js = \
	"""
	
	var dialogName='%s', tabsClass='%s';
	var formId='%s', buttonsContainer='%s', errInfo='%s';
	
	// get the tabs instance in this page
	var tabs = window[$$('div.'+tabsClass)[0].getAttribute('id')];
	
	// Backforward function
	function back(event){ 
		tabs.toggleTabs(0);
	};
	 
	// Next step function
	/*********************************************************************
	Set a global variable 'formchk', 
   which will be used as an instance of the validation Class-'FormCheck'.
   **********************************************************************/
   
   var formchk = new FormCheck( formId,{
		submitByAjax: true,
		
	   onAjaxSuccess: function(response){
	   	if(response != 1){alert(errInfo);}
	      else{ tabs.toggleTabs(2);};               
	   },            
	
	   display:{
	   	errorsLocation : 1,
	      keepFocusOnError : 0, 
	      scrollToFirst : false
	   }
	});// the end for 'formchk' define
	
	
	function next(event){		
		formchk.onSubmit(event);
	};
	 
	// Cancel function
	function closeDialog(event){
	 	window[dialogName].close();
	 	delete window[dialogName];
	};
		 
	function pageInit(event){
		 
      // add mouseover effect to buttons
      new MooHover({container:buttonsContainer,duration:800});
		 
      // Add click callback functions for buttons
      var bns = $(buttonsContainer).getElements('button');       
       
      $(bns[0]).addEvent('click', back);
      $(bns[1]).addEvent('click', next);

      // Add callback function to 'Cancel' button
      $(bns[2]).addEvent('click', closeDialog);
   };

   window.addEvent('domready', pageInit);
	"""%tuple(paras)
		
	print pagefn.script(js, link=False)
	return
	
def page_accountRegister(**args):
	""" Register the new user account. """
	account = {}	
	names = [item.get('name') for item in CONFIG.getData(ACCOUNTFIELDS) ]
	
	[ account.update({ name:getattr(SO, name, '') }) for name in names ] 
	
	try:
		# create the account in database
		form = {'action': 'register','context': 'user','all_props': {('user', None): account}}
		client = model.get_client()
		client.form = form
		userId = model.action(client)
	except:
		print sys.exc_info()
		userId = None
	finally:
		pass
	
	if userId:
		user = client.user = account.get('username')
		
		isSuccess = '1'
		
		# set the user's base information, 
		# which is stored in a csv format file on server side		
		info = {}		
		fields = [ item.get('name') for item in CONFIG.getData(BASEINFOFIELDS) ]
		
		[ info.update({ name:args.get(name) or '' })\
		  for name in fields ]
		  
		filename = '_'.join(('user', str(userId), 'info' ))	
		
		res = model.edit_user_info( user, user, 'create', info, filename, client)
		if res:
			setattr( SO, pagefn.SOINFO['userinfo'], info)
	else:
		isSuccess = '0'	
	
	print isSuccess
	
	return
	