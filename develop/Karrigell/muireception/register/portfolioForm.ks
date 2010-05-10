"""
The module for registration application. 
"""

import sys,copy
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
so = Session()

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
	rember = dict([ (field.get('name'), getattr(so, field.get('name'), None))  for field in render ])
	
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
	  for name in [_("Back"), _("Next")] ]
	
	div = DIV(Sum(buttons), **{ 'id':FORMBNS, 'style':'position:absolute;margin-left:18em;'})    
	form.append(div)
	
	# form action url
	action = '/'.join((APPATH, '_'.join(('page', 'accountRegister'))))
	 
	form = FORM( Sum(form), 
                 **{
                   'action': action, 
                   'id': BASEINFOFIELDS, 
                   'method':'post',                   
                   'class':'yform'
                 }
               )
	print DIV(form, **{'class':'subcolumns'})
	
	# javascript functions for this page
	paras = [ BASEINFOFIELDS, FORMBNS, _('Account creating failed!') ]
	js = \
	"""
	var formId='%s', buttonsContainer='%s', errInfo='%s';
	
	// Backforward function
	function back(event){ 
		tabSwitch(0);
	};
	 
	// Next step function
	/*********************************************************************
	Set a global variable 'formchk', 
   which will be used as an instance of the validation Class-'FormCheck'.
   **********************************************************************/
   
   var pformchk = new FormCheck( formId,{
		submitByAjax: true,
		
	   onAjaxSuccess: function(response){
	   	if(response != 1){alert(errInfo);}
	      else{ tabSwitch(2);;};               
	   },            
	
	   display:{
	   	errorsLocation : 1,
	      keepFocusOnError : 0, 
	      scrollToFirst : false
	   }
	});// the end for 'formchk' define
	
	
	function next(event){		
		pformchk.onSubmit(event);
	};
		 
	function pageInit(event){
		 
      // add mouseover effect to buttons
      new MooHover({container:buttonsContainer,duration:800});
		 
      // Add click callback functions for buttons
      var bns = $(buttonsContainer).getElements('button');
      bns[0].addEvent('click', back);
      bns[1].addEvent('click', next);
      
   };

   window.addEvent('domready', pageInit);
	"""%tuple(paras)
		
	print pagefn.script(js, link=False)
	return
	
def page_accountRegister(**args):
	""" Register the new user account. """
	#print '1'
	#return 
	
	try:
		account = getattr(so,pagefn.SOINFO['user'])
	except:
		account = {}
		
	try:
		# create the account in database
		form = { 'action': 'register','context': 'user','all_props': {('user', None): copy.deepcopy(account)} }
		client = model.get_client()
		client.form = form
		userId = model.action(client)
	except:
		print sys.exc_info()
		userId = None
	finally:
		pass
	
	if userId:
		isSuccess = '1'
		user = client.user = account.get('username')		
		
		# set the user's base information, 
		# which is stored in a csv format file on server side		
		info = {}		
		fields = [ item.get('name') for item in CONFIG.getData(BASEINFOFIELDS) ]
		
		[ info.update({ name:args.get(name) or '' }) for name in fields ]
		  
		#filename = '_'.join(('user', str(userId), 'info' ))	
		
		# write these informations to database
		res = model.edit_user_info( user, user, 'create', info, None, client)
		if res:
			account.update(info)
			
			# don't save password in session
			account.pop('password')
			
			# get the 'roles' property of this account
			props = ['roles',]
			res = model.get_item(user, 'user', userId, props, keyIsId=True)
			if type(res) == type({}):
				account.update(res)				
			setattr( so, pagefn.SOINFO['user'], account)
	else:
		isSuccess = '0'	
	
	print isSuccess
	
	return
	