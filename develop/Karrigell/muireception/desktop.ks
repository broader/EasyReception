""" The portal which is like a desktop user interface. """

from HTMLTags import *
from tools import treeHandler
modules = {'pagefn': 'pagefn.py',  'JSON': 'demjson.py', } #'formFn':'form.py'}
[locals().update({k : Import('/'.join(('',v)))}) for k,v in modules.items() ]

#APPATH = THIS.script_url[1:]
#RELPATH = '/'.join(THIS.baseurl.split('/'))
#DATA = Import( '/'.join((RELPATH, 'hotelConfig.py')), rootdir=CONFIG.root_dir)
 

def _initJs():
	paras = [NAVBAR,'page_menuData']
	paras = tuple(paras)
	js = \
	"""
	var menuContainer="%s", menuUrl="%s";
	
	// get the global Assets manager
	var am = MUI.assetsManager;

	/*
	**	Initialize menu by json data from server side
	*/
	function menuInit(){
		var data = new Request.JSON({
			async: false,
			url: menuUrl, 
			onSuccess:function(json,html){	
				var assetOptions = {
					'url':json['js'],	// load the menus' corresponding clickable functions
					'app':'',
					'type':'js'
				};
		
				var onloadOptions = {
					onload: function(){
						// load html slice to the navigation bar		
						var ul = new Element('ul');
						ul.set('load', {url:json.url, async:false});
						ul.load();
						$(menuContainer).grab(ul,'top');

						// add event to each menu item
						$H(json.functions).each(function(func, nid){
							$(nid).setProperties({
								'class':'returnFalse',
								'style':'text-decoration:none;',
								'href': 'javascript:;'
							});
							$(nid).store('popupWindowId',func.popupWindowId);

							if($type(window[func.funcname])) $(nid).addEvent('click', window[func.funcname]);
						});
					}
				};
			
				// load js slice
				am.import( assetOptions, onloadOptions );
			}
		}).get();
	
	};

	window.addEvent('domready', function(){
		menuInit();
	});
	"""%paras	
	return js 

def _head():
	print '<head>'

	metAttrs = [\
		{'http':'Content-Type','content':'text/html; charset=UTF-8'},
		{'http':'X-UA-Compatible','content':'IE=8'},
		{'name': 'description', 'content': _("The portal in a desktop likely style for EasyReception")},
		{'http':'X-UA-Compatible','content':'IE=edge'}
	]
	for tag in [ META(**attr) for attr in metAttrs ]:
		print tag

	print TITLE(_("Desktop portal for EasyReception"))

	# css links
	for name in ("Content.css", "Core.css", "Layout.css", "Dock.css", "Tabs.css", "Window.css" ) :
		print LINK(**{'rel':'stylesheet', 'type': 'text/css', 'href': '/'.join(('..', 'themes', 'default', 'css', name))})

	print \
	"""
	<!--[if IE]>
		<script type="text/javascript" src="scripts/excanvas_r43.js"></script>
	<![endif]-->
	"""

	# javascript files' links
	for name in ('mootools-1.2.4-core.js', 'mootools-1.2.4.2-more.js') :
		print SCRIPT(**{'type':'text/javascript', 'src': '/'.join(('..', 'lib', 'mootools', name))})
	
	for name in ('Core/Core.js', 'Window/Window.js', 'Layout/Layout.js', 'Layout/Dock.js') :
		print SCRIPT(**{'type':'text/javascript', 'src': '/'.join(('..', 'lib', 'mocha', name))})

	print SCRIPT(**{'type':'text/javascript', 'src': "../js/init-desktop4user.js"})
	
	# mootools Assets tools
	print pagefn.script( '/'.join(('..', 'lib','tools','assetsmanager.js')), link=True)
	
	# page initial js
	#jsfiles = ('init.js.pih', 'layoutInit.js.pih')
	jsfiles = ('initMUI.js.pih', )
	for name in jsfiles:
		print pagefn.script( '/'.join(('..', 'js', name)), link=True)

	print SCRIPT(_initJs(), **{'type':'text/javascript'})

	print \
	"""
	<style type="text/css" >	

	/* This CSS should be placed in a style sheet. It is only here in order to not conflict with the other demos. */

	#pageWrapper {
		background: #777;
	}

	.desktopIcon {
		margin: 15px 0 0 15px;
		cursor: pointer;	
	}	

	</style>
	"""

	print '</head>'
	return

def _renderMenuNode(nodes, node, prefix):
	li = LI()
	aLink = A( node.data.get('text'), **{'id': '-'.join(( prefix, node.id))})
	li <= aLink
	if node.children:	# has submenus
		ul = UL() 
		for child in node.children:
			ul <= _renderMenuNode(nodes,child, prefix)
			nodes.remove(child)

		li <= ul

	return li

def _menuHtml(data, prefix):
	''' Constructs the menus list recursively. '''
	idFn = lambda i : i.get('id')
	pidFn = lambda i : i.get('parent')
	handler = treeHandler.TreeHandler(data, idFn, pidFn)
	nodes = handler.flatten()[1:]	# delete the first 'root' node

	# now recursively render the menu tree into html
	while nodes :
		node = nodes.pop(0)
		li = _renderMenuNode(nodes, node, prefix)
		print li
	
	return 

def page_menuList(**args):
	menuType = args.get(MENUTYPETAG)
	if menuType == None or MENUTYPE.index(menuType) == 0 :
		data = pagefn.USERMENUS['data']
	else:
		data = pagefn.ADMINMENUS['data']

	_menuHtml(data,menuType)

	return

MENUTYPE = ('userMenu', 'adminMenu')
MENUTYPETAG = 'menuType' 
def page_menuData(**args):
	""" Return the menus data corresponding to user role. """
	so = Session()
	roles = getattr(so, pagefn.SOINFO['user']).get('roles') or ''
		
	if pagefn.USEROLE in roles:
		menus = pagefn.USERMENUS
		menuType = MENUTYPE[0]
	else:
		menus = pagefn.ADMINMENUS
		menuType = MENUTYPE[1]

	menus['js'] = '/'.join(('..', menus['js']))	
	menus['url'] = '?'.join(( 'page_menuList', '%s=%s'%(MENUTYPETAG, menuType) ))
	
	# constructs the json objec to be returned
	data = menus.pop('data')
	
	menus['functions'] = {}
	[ menus['functions'].update({ \
		'-'.join(( menuType, item.get('id'))):\
		{'funcname': item.get('function'), 'popupWindowId': item.get('popupWindowId') or '' }})\ 
		for item in data \
	]

	print JSON.encode(menus, encoding='utf8')
	return

NAVBAR = 'desktopNavbar'
def _header(user=None):
	
	desktopHeader = DIV(**{'id':'desktopHeader'})

	titleWrapper = DIV(**{'id':'desktopTitlebarWrapper'})
	desktopHeader <= titleWrapper

	titleBar = DIV(**{'id':'desktopTitlebar'})
	titleWrapper <= titleBar

	titleBar <= H1('Mocha UI', **{'class':'applicationTitle'})
	leftUpLogo = """%s <span class="taglineEm">%s</span>"""%(_("Simple, Effective"), _("Portal for congress administration"))
	titleBar <= H2(leftUpLogo, **{'class':'tagline'})

	topNav = DIV(**{'id':'topNav'})
	titleBar <= topNav
	ul = UL(**{'class':'menu-right'})
	li = LI(TEXT("""%s <a href="#" onclick="MUI.notification('Do Something');return false;">%s</a>."""%(_("Welcome"), user or '')))
	ul <= li
	li = LI(TEXT("""<a href="#" onclick="MUI.notification('Do Something');return false;">%s</a>"""%_("Sign Out")))
	ul <= li	
	topNav <= ul
	
	navBar = DIV(**{'id':NAVBAR})
	desktopHeader <= navBar

	print desktopHeader
	
	return

def _dock():
	# dock bar
	dockwrapper = DIV(**{'id':'dockWrapper'})

	dock = DIV(**{'id':'dock'})
	dockwrapper <= dock

	for tag in ('dockPlacement', 'dockAutoHide'):
		dock <= DIV(**{'id':tag})	

	dock <= DIV(DIV(**{'id':'dockClear', 'class':'clear'}), **{'id':'dockSort'})

	print dockwrapper
	return

def _page():
	# main desktop page
	pageWrapper = DIV(**{'id':'pageWrapper'})
	page = DIV(**{'id':'page'})
	pageWrapper <= page

	for name in ('globe.png', 'speaker.png', 'view.png', 'headset.png', 'camera.png') :
		page <= IMG(**{\
			'class':'desktopIcon', \
			'src':'../images/icons/48x48/%s'%name, \
			'alt':'Camera', 'width':'48', 'height':'48', 'onload':'fixPNG(this)'\
		})
		page <= BR()


	print pageWrapper
	
	return

def _footer():
	# footer
	footWrapper = DIV(**{'id':'desktopFooterWrapper'})
	info = \
	"""
	&copy; 2007-2010 <a target="_blank" href="http://www.acroes.com/">北京昊鹏星辰科技有限责任公司</a> - MIT License
	"""

	footer = DIV(info, **{'id':'desktopFooter'})
	footWrapper <= footer
	print footWrapper
	
	return

def _innerBody():

	_dock()
	
	_page()
	
	_footer()
	
	return

def _body(user=None):
	print "<body>"

	print """<div id="desktop">"""
	
	_header(user)

	_innerBody()

	print """</div>"""
	print "</body>"
	return

def index(**args):
	print '''<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">'''
	print '<html xmlns="http://www.w3.org/1999/xhtml">'
	
	_head()

	user = args.get('user') or None	
	# set user information to session object
	data = {'user': user,'roles': "User"}			
	so = Session()
	setattr( so, pagefn.SOINFO['user'], data)

	# body
	_body(user)

	print '</html>'	
	return	

