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
<div id="header" role="banner">
	<div id="topnav" role="contentinfo">
		<span><a href="#">Login</a> | <a href="#">Contact</a> | <a href="#">Imprint</a></span> 
	</div>
	<h1>YAML | &laquo;Simple Project&raquo; Template</h1>
	<span>A YAML based Layout in a <em>ready to use</em> project structure</span>
</div>

<!-- begin: main navigation #nav -->
<div id="nav"  role="navigation">
	<div class="hlist">
		<ul>
			<li class="active"><strong>Button 1</strong></li>
			<li><a href="#">Button 2</a></li>
			<li><a href="#">Button 3</a></li>
			<li><a href="#">Button 4</a></li>
			<li><a href="#">Button 5</a></li>
		</ul>
	</div>
</div>
<!-- end: main navigation -->
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

# Page Variables
HEADERDIV = 'header'
NAVDIV = 'nav'
LOGINFORM = 'loginForm'
LOGINSPAN = 'login'
MENU = 'menu'
DEMOSELECT = 'demoSelect'
DEFAULTPAGE = 'home.pih'
MAINDIV = 'main' 
# End

# Page Functions
def index():
     divs = [DIV( _header(), **{'id' : HEADERDIV}), DIV(_nav(), **{'id' : NAVDIV})]
     print Sum(divs)
     script = \
     '''
     window.addEvent('domready',function(){
     $("%s").load("%s");
     });
     '''%(MAINDIV, DEFAULTPAGE)
     print pagefn.script(script, link=False)
     return
    
def _loginScript( ):
     paras = [ LOGINSPAN, MAINDIV ]
     # MOODIABOX js and css files' path
     libName = 'erdialog'
     paras.extend(\
        [ '/'.join(('js',\
                    'lib',
                    libName,
                    p,\
                    '.'.join((libName,p))))\
          for p in ('css', 'js')]\
     )
     # add the popup dialog name which is a global name in javascript namespace
     paras.append(pagefn.DIALOG)
     
     # add the registration action page
     paras.append('registration/registration.ks/index')
     paras = tuple(paras)
     script = '''
     window.addEvent('domready',function(){
        var links=$("%s").getElements("a");
        var mainDiv="%s";	
        var diaboxCss="%s", diaboxJs="%s", diabox="%s";
        var regLink="%s";
        
        // pop up dialog for login  action
        $(links[0]).addEvent('click',function(){
        });
     		
        // Pop up dialog for registration
        $(links[1]).addEvent('click', function(){                   
           var dialogCss = new Asset.css(diaboxCss, {id: 'diaboxCss'});
           new Asset.javascript(diaboxJs,
                 {
                    id:'diaboxJs',
                    onload:function(){ window[diabox]=new ERDialog({'url':regLink});}
                 }
           );
        });
     });
     '''%paras
     return script
		
def _header(**args):
	  ''' Return the content in <div id="header"></div>.
	  '''
	  contents = [  DIV( SPAN( page_loginSpan(), **{'id' : LOGINSPAN } ), **{'id' : 'topnav'}), \
		             H1(  _('EasyReception Congress Management Portal')), \
		             SPAN( _("Simple, Professional and Methodical"), style='margin-left:0.5em;')]

	  return Sum(contents)
	
def page_loginSpan(**args):
	  backPage = args.get('page')
	  attr = { 'style' : 'font-weight:bold; font-size:1.2em;'}
	  if not so.user:
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

def _nav( ):
     ''' Return the content in <div id="nav"></div>.
     '''
     contents = [ A(**{ 'id' : 'navigation', 'name' : 'navigation' }),\
                  DIV( UL( page_menuList(), **{ 'id' : MENU }), **{'class' : 'hlist'})\
                 ]
     return Sum(contents)

def page_menuList(**args):
	  backPage = args.get('page') 
	  ul = []	
	  if backPage == '0':
		  print Sum(ul)
	  else:
		  return Sum(ul)
	
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

