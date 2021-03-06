from HTMLTags import *

relPath = lambda p : p.split('/')[0]
model = Import('/'.join((relPath(THIS.baseurl), 'model.py')), REQUEST_HANDLER=REQUEST_HANDLER)

modules = {'pagefn' : 'pagefn.py', 'JSON' : 'demjson.py', 'config': 'config.py'}
[locals().update({k : Import('/'.join(('',v)))}) for k,v in modules.items() ]

so = Session()
if not hasattr(so, 'user'):
	so.user = None 
	
def index():	
	# import css files
	cssfiles = ( 'lib/ui/css/flick/jquery-ui-1.7.2.custom.css',)
	for css in cssfiles:
		# in ks functions, it's need to add '..' path prefix
		src = '/'.join(('..','..',css))		
		print pagefn.css(src)
	
	css = \
	'''	
	<!--[if lte IE 7]>
	<style type="text/css" media="all">
	@import "css/required-fields-star1-ie.css";
	</style>
	<![endif]-->
	'''
	#print css

	# import js files
	jsfiles = ('js/jquery.form.js', 'lib/ui/js/jquery-ui-1.7.2.custom.min.js', 'lib/validate/jquery.validate.js' )
	for src in jsfiles :		
		# in ks functions, it's need to add '..' path prefix		
		src = '/'.join(('..','..',src))
		print pagefn.script(src, link=True)
	
	# initialize the tab widget
	script = \
	'''
	$(document).ready(function(){
		$("#tabs").tabs().data('disabled.tabs', [1, 2]);
	});
	'''
	print pagefn.script(script, link=False)
	
	# page content
	print H2(_("The Register Process"),style='margin-left:1em;')
	li = []
	tabs = config.tabs
	for tabTitle,tabAction,tabIndex in tabs :
		action = '/'.join(('register', tabAction))
		attrs = {'href': action, 'title': 'tabDiv'}
		li.append( LI(A(tabTitle, **attrs), **{'style':'list-style-type:none;'}) )
	ul = UL(Sum(li))
	tabs = DIV(ul, **{'id':'tabs'})
	tabContent = DIV(**{'id':'tabDiv'})
	print DIV(Sum((tabs, tabContent)),style='margin-left:2em;') 			
