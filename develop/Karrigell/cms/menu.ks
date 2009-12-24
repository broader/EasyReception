from HTMLTags import *

relPath = lambda p : p.split('/')[0]
model = Import('/'.join((relPath(THIS.baseurl), 'model.py')), REQUEST_HANDLER=REQUEST_HANDLER)
VERSION = Import('/'.join((relPath(THIS.baseurl), 'version.py')))

modules = {'pagefn' : 'pagefn.py', 'JSON' : 'demjson.py' }
[locals().update({k : Import('/'.join(('',v)))}) for k,v in modules.items() ]

so = Session()
if not hasattr(so, 'user'):
	so.user = None 
	
	
'''
<div id="header">
---><div id="topnav">
------><span id="login"></span>
---></div>
---><h1>The name of this system</h1>
---><span>Some description for this system!</span>
</div>

<div id="nav">
---><a id="navigation"  name ="navigation"></a>
---><div class="hlist">
------><ul id="menu"></ul>
---></div>
</div>
'''

HEADERDIV = 'header'
NAVDIV = 'nav'
def index( ) :
	divs = [DIV( _header(), **{'id' : HEADERDIV}), DIV(_nav(), **{'id' : NAVDIV})]
	print Sum(divs)
	script = \
	'''
	$(document).ready(function(){
		$("#%s").load("%s");
	})'''%(MAINDIV, ENTRANCE)	
	print pagefn.script(script, link=False)


APPATH = 'menu.ks'
LOGINFORM = 'loginForm'
def _loginScript( ):
	paras = [ LOGINSPAN, LOGINFORM, '/'.join((APPATH, 'page_validForm')), \
			'/'.join((APPATH, 'page_postValid')), pagefn.AJAXLOADING]
	
	paras.extend( FORMFIELDS )
	paras.extend( [ 'menu.ks/page_validName', _("There is no such a user name! Please input right name.")] )
	paras.extend( [ 'menu.ks/page_validPwd', _("Invalid Password!")] )
	paras.append( 'menu.ks/page_postValid')
	paras.extend( pagefn.FORM_BNS ) 
	#paras.extend( [ MAINDIV, 'register' ] )
	paras.extend( [ MAINDIV, 'register/register.ks/index' ] )
	paras = tuple(paras)
	script = \
	'''
	$(document).ready(function(){	
		var links = $("#%s a");	
		
		// pop up dialog for login  action
		$( links[0] ).click(function(){
			var formId="%s", formSelector="#"+formId; 
			var formUrl="%s", actionUrl="%s";			
			var ajaxLoading="%s";
			var user="%s", pwd="%s";
			var existName="%s", nameErr="%s";
			var validPwd="%s", pwdErr="%s";
			var postAction="%s";
			
			// add validation function to form		 
			function formValid(v,m){
				// "Cancel" button, do nothing
				if(!v){ return true };		
								
				$(formSelector).valid();						
				var inputs = $(formSelector + " input");
				var data = {user: $(inputs[0]).val(), pwd: $(inputs[1]).val()}		
				$.getJSON(validPwd, data, function(json){
					if(eval(json.valid)){
						// user and password is right						
						$(formSelector).html('<img src="url">'.replace(/url/i, ajaxLoading))
						$.getScript('menu.ks/page_postValid');
					}
					else{
						// password is invalid
						var validator = $(formSelector).validate();
						validator.showErrors({pwd : pwdErr});
					};
				});
				return false								
			}
			
			// set form content
			function setForm(){				
				$(formSelector).load( formUrl);
				$(formSelector).validate({
					rules : { 
						user : { remote: existName},						
					},
					messages : {
						user: {remote : nameErr}						
					},
					onkeyup : false,							
					errorClass: "highlight",
					errorElement: "div"
				 });
			}			
			
			// a html slice which just renders a form whose id is 'formId'		
			var html = '<form id="x" class="yform"><img src="url"></form>'.replace(/x/i, formId).replace(/url/i, ajaxLoading);
			var option = 	{ prefix: "cleanblue",			  		   	
				  		   buttons: { %s : true, %s : false},
				  		   top: 30,		  		   			  		   
		       		   submit: formValid,
		       		   loaded: setForm,
		       		   zIndex: 0,		       		   
				  		   opacity : 0.9};			
			
			var prompt = $.prompt(html, option);			
		});
		
		// toggle to register page
		$( links[1] ).click(function(){			
			$("#%s").load("%s");
		});
	});
	'''%paras
	return script

def page_loginSpan(**args):
	backPage = args.get('page')
	attr = { 'style' : 'font-weight:bold; font-size:1.2em;'}
	if not so.user :	
		login = [ A(info, href='#', **attr) for info in ( _('Login'), _('Register'))]
		login.insert( 1, TEXT('&nbsp;|&nbsp;&nbsp;'))
		login.append( pagefn.script(_loginScript(), link=False ) )		
		login = Sum( login )
	else:
		attr['style'] += ';color:gainsboro;'
		txt = ''.join((_('Welcome,'), so.user, '!'))
		login = STRONG(txt, **attr) 
	
	if backPage == '0':
		print login		
	else:
		return login
	
LOGINSPAN = 'login'	
def _header(**args):
	''' Return the content in <div id="header"></div>.
	'''
	contents = [ DIV( SPAN( page_loginSpan(), **{'id' : LOGINSPAN } ), **{'id' : 'topnav'}), \
			     H1(  _('EasyReception Congress Management Portal')), \
			     SPAN( _("Simple, Professional and Methodical"), style='margin-left:0.5em;')]

	return Sum(contents)


def page_menuList(**args):
	backPage = args.get('page') 
	ul = []
	if so.user:
		# set menu 
		if so.useroles and 'Admin' in so.useroles:
			config = Import('admin_config.py')			
		else:
			config = Import('config.py')
		
		for link, label in config.menus:
			ul.append(LI(A(label, href=link)))			
				
		ul.append(LI(A(_("Logout"), id='logout', href='#')))
		# add click response to each menu item
		script = \
		'''
		$(document).ready(function(){
			// the function to switch the content of 'main' Div component in main page 
			function showMain(){							
				var url = this.hash.slice(1);		
				$('#main')
				.html( '<div id="loader" style="margin-left: 30em;"><img src="images/ajax_loading.gif" alt="loading..." /></div>' )
				.load( url, function(){
					this.scrollLeft = 0;//scroll back to the left
				});				
				this.blur(); // Remove the awful outline
				return false;
			}
			
			$('.hlist a').click(showMain);
			
			$("#menu a:last")
			.unbind()
			.bind('click', function(){
				$.getScript('menu.ks/page_toggleMenu?showMenu=0');
			});
		
		});
		'''
		ul.append(pagefn.script(script, link=False))
	
	if backPage == '0':
		print Sum(ul)
	else:
		return Sum(ul)
	
MENU = 'menu'
def _nav( ):
	''' Return the content in <div id="nav"></div>.
	'''
		
	contents = [ A(**{ 'id' : 'navigation', 'name' : 'navigation' }), \
			     	 DIV( UL( page_menuList(), **{ 'id' : MENU }), **{'class' : 'hlist'})\
			     ]
	return Sum(contents)

def page_toggleMenu(**args):
	showMenu = args.get('showMenu')	
	if int(showMenu) == 1:
		pass
	else:
		# It's a logout action, clear user's information in session
		so.user, so.useroles = 2*[None]
		
	# change the content of login span and menu list 
	paras = [ LOGINSPAN, 'menu.ks/page_loginSpan?page=0', \
			MENU, 'menu.ks/page_menuList?page=0',\
			MAINDIV, ENTRANCE ]
	paras = tuple(paras)
	script = \
	'''	
	var loginSpan="#%s", spanUrl="%s";
	var menuList="#%s", menuUrl="%s";
	$(loginSpan).load(spanUrl);
	$(menuList).load(menuUrl);
	var main="#%s", defaultPage="%s";
	$(main).load(defaultPage);
	'''%paras
	print script

DEMOSELECT = 'demoSelect'
def _autoDemo( ):
	''' Render a html slice to select a type of user to demostrate the function of this system.
	'''
	label = LABEL(VERSION.demoPrompt)
	options = [ OPTION(_('Select a type of user'), disabled='', selected=''), ]
	for user, des in VERSION.demoUsersDes.items() :
		name, pwd = [ VERSION.demoUsers[user].get(field) for field in ('name', 'pwd') ] 
		options.append(OPTION(des, **{'value' : name, 'ref' : pwd}))
	select = SELECT(Sum(options), **{'id' : DEMOSELECT})
	
	# callback function for slect action
	paras = [ LOGINFORM, DEMOSELECT ]
	paras = tuple(paras)
	script = \
	'''
	$(document).ready(function(){
		var loginForm="#%s", select="#%s" ;
		$(select).change(function(){			
			var selected = $(select).children("option:selected");			
			var a = [ selected.attr("value"), selected.attr("ref") ]			
			$(loginForm + " input").each(function(){
				$(this).attr("value", a.shift());
			});
		});
	});
	'''%paras
	return Sum((label, BR(), select, pagefn.script(script, link=False))) 
	
	
FORMFIELDS = ( 'user', 'pwd')
FIELD2INFO = {'user': _('Login Name'), 'pwd' : _('Password') }  
def page_validForm(**args):
	fields = required = FORMFIELDS
	field2info = FIELD2INFO	 
	# render fields
	table = [ CAPTION(SPAN(_('User Info'), **{'style' : 'font-weight:bold;font-size: 1.5em;'})), ]
	tbody = []		
	# append demostartion
	if VERSION.version == 'demo' :
		tbody.append(TR(TD(_autoDemo(), colspan='2')))		
		
	for field in fields :
		label = TD(LABEL(field2info.get(field)))
		attr = {'name' : field, 'class':'required'}
		if field != 'pwd':		
			attr['type'] = 'text'
		else:
			attr['type'] = 'password'
		input = SPAN(INPUT(**attr))
		input = TD(input)			
		tbody.append(TR(Sum((label, input))))
		
	table.append(Sum(tbody))
	# render form	

	print TABLE(Sum(table))

def _valid(usr='', pwd=None):
	''' There are three validation results,
	  (0, "Invalid password")
	  (1, "Valid user name and password")
	  (2, "Invalid user name")
	'''
	data = model.login(usr, pwd)

	return data
	

def page_validName(**args):
	name, pwd = [args.get(v) for v in FORMFIELDS]	
	data = _valid(name, pwd)
	if int(data[0]) == 2 :
		print 'false'
	else:					
		print 'true'

def _setSession(user):
	''' When user has login on, save user's roles and name into session.
	'''
	data = model.get_item(user, 'user', user, props=('roles',), keyIsId=False)
	if data:
		roles = data.get('roles').split(',')
	else:
		roles = None
	# saves user's name and roles to session object			
	[setattr(so, attr, value) for attr, value in zip(('user', 'useroles'), (user, roles))]

	return
	

def page_validPwd(**args):
	name, pwd = [args.get(v) for v in FORMFIELDS]
	data = _valid(name, pwd)
	res = {'valid' : 'false'}
	if int(data[0]) == 1 :
		# get user's roles
		_setSession(name)
		res['valid'] = 'true'
	
	print JSON.encode(res, encoding='utf8')

ENTRANCE = 'home.pih'
MAINDIV = 'main' 

def page_postValid(**args):		
	user = args.get('user')
	if user :
		_setSession(user)
		
	# successful login prompt
	txt = ','.join(( so.user or '', _('Login Successfully! ')))		
	print '$.prompt.close();$.prompt("%s", {prefix: "cleanblue", buttons: {%s : true}});' \
			%(txt, _("OK"))
				
	# display user name in the topright of the page					
	print '$.getScript("menu.ks/page_toggleMenu?showMenu=1");'
	# display the main page
	print '$("#%s").load("%s");' %(MAINDIV, ENTRANCE)
	
