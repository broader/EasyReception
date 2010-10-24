"""
Login & Registration functions for this web site.
"""

from HTMLTags import *

APPATH = THIS.script_url[1:]
# get the relative url slice as the application name
APP = 'loginDialog'

modules = {'JSON' : 'demjson.py'}
[locals().update({k : Import('/'.join(('',v)))}) for k,v in modules.items() ]

def page_loginForm(**args):	 
	# render fields
	#table = [ CAPTION(SPAN(_('User Info'), **{'style' : 'font-weight:bold;font-size: 1.5em;'})), ]
	table = []
	tbody = []		

	# append demostartion selection
	#if VERSION.version == 'demo' :		
	tbody.append(TR(TD(_autoDemo(), colspan='2',style='border-bottom:black 1px;')))
	
	# append account inputs	
	for field in FORMFIELDS :
		name = field.get('name')
		label = TD(LABEL(field.get('label'),style=''))
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
	bns =[]

	bnAttrs = [{'label':_("OK"), 'css':'ok'},{'label':_("Cancel"), 'css':'cancel'}]
	for attr in bnAttrs :
		label,klass = [ attr.get(name) for name in ('label', 'css') ]
		bns.append(BUTTON(SPAN(SPAN(SPAN(label, **{'class': klass}))), **{'class':'sexybutton'}))			 

	#bns = [ SPAN(bn) for bn in bns ] 
	bns = DIV(Sum(bns),**{'id':FORMBUTTONS,'style':'position:relative;float:right;padding-top:5px;'})
	form = Sum([table, HR(), bns])
	# render form		
	print FORM(form,**{'id':LOGINFORM})
	print SCRIPT(_loginFormJs())
	return

demoUsers = \
{  'demo' : {'name' : 'demo', 'pwd' : '990508'},\
   'admin' : {'name' : 'admin', 'pwd' : '990508'}\
}

demoUsersDes = {'demo' : _('Normal User'), 'admin' : _('Administrator')}
demoPrompt = _('For demostration, please select a existed user account!')

def _autoDemo( ):
	""" Render a html slice to select a type of user to demostrate the function of this system.
	"""
	options = [ OPTION(_('Select a type of user'), disabled='', selected=''), ]
	for user, des in demoUsersDes.items() :
		name, pwd = [ demoUsers[user].get(field) for field in ('name', 'pwd') ] 
		options.append(OPTION(des, **{'value' : name, 'ref' : pwd}))
	
	select = SELECT(Sum(options), **{'id' : DEMOSELECT})
	prompt = SPAN(demoPrompt,style='font-size:15px;',**{'class':'highlight'})
	return Sum(( prompt, BR(), select, HR(style='padding:0 0 0.2em;')))
	

LOGINFORM = 'loginForm'

FORMFIELDS = \
[\
	{'name':'username','label':_('Login Name'),'class':"validate['required','~accountCheck']"},\
	{'name':'password','label':_('Password'),'class':"validate['required','~pwdCheck']"}\
]  

DEMOSELECT = 'demoSelect'

FORMBUTTONS = 'loginFormbns'

def _loginFormJs():

	# callback function for slect action
	paras = [ LOGINFORM, DEMOSELECT, FORMBUTTONS]
	
	# append the error prompts for fields' validation 
	paras.extend([ _('The input account is not existed !'), _('The input password is wrong, please input the valid password!')])
	
	# append the action urls for fields' validation 
	paras.append( '/'.join((APPATH, 'page_accountValid')))

	paras.extend([ url for url in ( 'js/formcheck/theme/red/formcheck.css', 'js/formcheck/formcheck.js', 'js/formcheck/lang.js.pih')])
	
	paras = tuple(paras)
	script = \
	"""
	var loginForm='%s', select='%s', bnsContainer='%s',	
	    accountErr='%s', pwdErr='%s', 
	    checkUrl='%s',
	    formcheckUrls=["%s", "%s", "%s"] ;


	function closeLoginPanel(){
		// hide login panel
		var data = $('loginPanel').retrieve('slide');
		data.element.empty();
		data.instance.hide();
			
		// clear capable formcheck invalid prompt info
		$$('.fc-tbx').each(function(el,index){el.destroy();});
	};	
    
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
					closeLoginPanel();

					window.open(
						"http://muireception:8080/portal/mocha_desktop.pih",
						"Online Registration System"
					)
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

	// load formcheck lib files
	var formcheckCss = new Asset.css(formcheckUrls[0]);	
	var foemcheckJs = new Asset.javascript(formcheckUrls[1], options);
	var foemcheckI18n = new Asset.javascript(formcheckUrls[2]);
		
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
		
		// add callback functions to submit buttons
		var buttons = $(loginForm).getElements('button');
		
		// submit button
		buttons[0].addEvent('click',function(e){
			loginFormchk.onSubmit(e);			
		});
		
		// cancel button
		buttons[1].addEvent('click',function(e){
			new Event(e).stop();
			closeLoginPanel();
		});
		
	});
	"""%paras
	return script

DEMOUSERS = ('admin', 'demo')
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
	fields = DEMOUSERS

	keys = args.keys()
	if len(keys) == 2:
		# check whether the password is valid	
		if args.get('username') in fields:
			res['valid'] = 1
			
	else:
		# check whether the account is existed 
		if args.get('name') in fields:
			res['valid'] = 1		

	try:	
		sys.setdefaultencoding('utf8')
	except:
		pass
	
	print JSON.encode(res)

	return

