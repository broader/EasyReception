"""
The pages and functions for menu setup
"""

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
#APP = pagefn.getApp(THIS.baseurl,1)

# the session object for this page
SO = Session()

# config data object
CONFIG = Import( '/'.join((RELPATH, 'config.py')), rootdir=CONFIG.root_dir)

LOGINFORM = 'loginForm'

FORMFIELDS = \
[\
	{'name':'user','label':_('Login Name'),'class':'validate[required, ~accountCheck]'},\
	{'name':'pwd','label':_('Password'),'class':'validate[required, ~pwdCheck]'}\
]  

DEMOSELECT = 'demoSelect'

FORMBUTTONS = 'loginFormbns'

# form fields' names in CONFIG file
#ACCOUNTFIELDS = 'userAccountInfo'

# The id for the 'Account' form
#ACCOUNTFORM = 'AccountForm'

# the id for the SPAN component in the account form page which holds buttons 
#ACCOUNTFORMBNS = 'accountBns'

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
		
		if name != 'pwd':		
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
	print FORM(form,**{'id':LOGINFORM, 'class':'yform'})
	print pagefn.script(_formJs(),link=False)
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
	
def _formJs():
	# callback function for slect action
	paras = [ LOGINFORM, DEMOSELECT, FORMBUTTONS]
	
	# add some files' path for validation function
	names = ('css/hack.css', 'theme/red/formcheck.css', 'lang.js.pih', 'formcheck.js')
	paras.extend([ '/'.join(( 'lib', 'formcheck', name )) for name in names])
	paras.append('loginDialog')
	
	# append the error prompts for fields' validation 
	paras.extend([pagefn.ACCOUNTERR, pagefn.PWDERR])
	
	# append the action urls for fields' validation 
	paras.append( '/'.join((APPATH, 'page_accountValid')))
	paras = tuple(paras)
	script = \
	"""
	window.addEvent('domready', function() {
		var loginForm='%s', select='%s',	bnsContainer='%s';
		
		// variables for formcheck js lib 
		var hackCss='%s', fcCss='%s',fcLangJs='%s', fcJs='%s';
		var appName='%s', accountErr='%s', pwdErr='%s', 
		checkUrl='%s';
		
		// get the global Assets manager
		var am = MUI.assetsManager;
	    
		// Add validation function to the form
		// import css file for validation
		[ hackCss, fcCss].each(function(src){
			if(!$defined(am.imported[src])){
				am.import({'url':src,'app':appName,'type':'css'});
			}	
		});
		
		// import js file for validation
		am.import({'url':fcI18nJs,'app':appName,'type':'js'});
		
		// Set a global variable 'formchk', 
    	// which will be used as an instance of the validation Class-'FormCheck'.
    	var formchk;
    
		// Load the form validation plugin script
		var options = {
			onload:function(){    		
				formchk = new FormCheck( loginForm,{
					
					onValidateSuccess: function(){
						MUI.notification('Success');
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
		
		
		/*** Check whether the input account is existed.************************************/    
    	// A Request.JSON class for send validation request to server side
    	var accountRequest = new Request.JSON({async:false});
    
    	var accountValidTag = false;
    	function accountCheck(el){
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
       	}             
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
       	// set some options for Request.JSON instance
       	pwdRequest.setOptions({
         	url: checkUrl,
         	data: [input.getProperty('name'), input.getProperty('value')].join('='),
          	onSuccess: function(res){
            	if(res.valid == 1){ pwdValidTag=true };
          	}
       	});
       
       	pwdRequest.get({'name':el.getProperty('value')});
       	if(pwdValidTag){
         	pwdValidTag=false;   // reset global variable 'pwdValidTag' to be 'false'
          	return true
       	}             
       	return false;
    	};
    	/***********************************************************************************/
    	
    	
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
			new Event(e).stop();
			MUI.notification('ok');
		});
		
		// cancel button
		buttons[1].addEvent('click',function(e){
			new Event(e).stop();
			MUI.closeModalDialog();
		});
		
		// add validations to form fields
	});
	"""%paras
	return script

def page_accountValid(**args):
	res = {'valid':0}
	# check validation type
	fields = [field.get('name') for field in FORMFIELDS ]
	keys = args.keys()
	if set(fields) == set(keys):
		# check whether the password is valid		
		pass	
	else:
		# check whether the account is existed 
		username = args.get(fields[0])
		if model.userCheck(username) :
			res['valid'] = 1

	print JSON.encode(res)
	return
	
	