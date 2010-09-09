['page_menuList', 'page_menu', 'index']
""" The portal which is like a desktop user interface. """

from HTMLTags import *

#modules = {'pagefn': 'pagefn.py', 'JSON': 'demjson.py', 'formFn':'form.py'}
#[locals().update({k : Import('/'.join(('',v)))}) for k,v in modules.items() ]


RELPATH = '/'.join(THIS.baseurl.split('/'))
#DATA = Import( '/'.join((RELPATH, 'hotelConfig.py')), rootdir=CONFIG.root_dir)


def _initJs():
	paras = [NAVBAR,]
	paras = tuple(paras)
	js = \
	"""
	var menuId="%s";

	window.addEvent('domready', function(){
		alert($(menuId));
	});
	"""%paras
	return js

def _head():
	PRINT( '<head>')

	metAttrs = [\
		{'http':'Content-Type','content':'text/html; charset=UTF-8'},
		{'http':'X-UA-Compatible','content':'IE=8'},
		{'name': 'description', 'content': _("The portal in a desktop likely style for EasyReception")},
		{'http':'X-UA-Compatible','content':'IE=edge'}
	]
	for tag in [ META(**attr) for attr in metAttrs ]:
		PRINT( tag)

	PRINT( TITLE(_("Desktop portal for EasyReception")))

	# css links
	for name in ("Content.css", "Core.css", "Layout.css", "Dock.css", "Tabs.css", "Window.css" ) :
		PRINT( LINK(**{'rel':'stylesheet', 'type': 'text/css', 'href': '/'.join(('..', 'themes', 'default', 'css', name))}))

	PRINT( \
	"""
	<!--[if IE]>
		<script type="text/javascript" src="scripts/excanvas_r43.js"></script>
	<![endif]-->
	""")

	# javascript files' links
	for name in ('mootools-1.2.4-core.js', 'mootools-1.2.4.2-more.js') :
		PRINT( SCRIPT(**{'type':'text/javascript', 'src': '/'.join(('..', 'lib', 'mootools', name))}))

	for name in ('Core/Core.js', 'Window/Window.js', 'Layout/Layout.js', 'Layout/Dock.js') :
		PRINT( SCRIPT(**{'type':'text/javascript', 'src': '/'.join(('..', 'lib', 'mocha', name))}))


	PRINT( SCRIPT(_initJs(), **{'type':'text/javascript'}))

	PRINT( \
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
	""")

	PRINT( '</head>')
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
		PRINT( li)

	return

def page_menuList(**args):
	menuType = args.get(MENUTYPETAG)
	if MENUTYPE.index(menuType) == 0 :
		data = pagefn.USERMENUS['data']
	else:
		data = pagefn.ADMINMENUS['data']

	_menuHtml(data,menuType)

	return

MENUTYPE = ('userMenu', 'adminMenu')
MENUTYPETAG = 'menuType'
def page_menu(**args):
	""" Return the menus data corresponding to user role. """
	so = Session()
	roles = getattr(so, pagefn.SOINFO['user']).get('roles') or ''

	if pagefn.USEROLE in roles:
		menus = pagefn.USERMENUS
		menuType = MENUTYPE[0]
	else:
		menus = pagefn.ADMINMENUS
		menuType = MENUTYPE[1]

	menus['url'] = '?'.join(( '/'.join((APPATH, 'page_menuList')), '%s=%s'%(MENUTYPETAG, menuType) ))

	# constructs the json objec to be returned
	data = menus.pop('data')

	menus['functions'] = {}
	[ menus['functions'].update({ \
		'-'.join(( menuType, item.get('id'))):\
		{'funcname': item.get('function'), 'popupWindowId': item.get('popupWindowId') or '' }})\
		for item in data \
	]

	PRINT( JSON.encode(menus, encoding='utf8'))
	return

NAVBAR = 'desktopNavbar'
def _header():
	desktopHeader = DIV(**{'id':'desktopHeader'})

	titleWrapper = DIV(**{'id':'desktopTitlebarWrapper'})
	desktopHeader <= titleWrapper

	titleBar = DIV(**{'id':'desktopTitlebar'})
	titleWrapper <= titleBar

	titleBar <= H1('Mocha UI', **{'class':'applicationTitle'})
	leftUpLogo = """A Web Applications <span class="taglineEm">User Interface Library</span>"""
	titleBar <= H2(leftUpLogo, **{'class':'tagline'})

	topNav = DIV(**{'id':'topNav'})
	titleBar <= topNav
	ul = UL(**{'class':'menu-right'})
	li = LI(A("""Welcome <a href="#" onclick="MUI.notification('Do Something');return false;">Demo User</a>."""))
	ul <= li
	li = LI(A("""<a href="#" onclick="MUI.notification('Do Something');return false;">Sign Out</a>"""))
	ul <= li
	topNav <= ul

	navBar = DIV(**{'id':NAVBAR})
	desktopHeader <= navBar

	PRINT( desktopHeader)

	return

def _body():
	PRINT( "<body>")

	PRINT( """<div id="desktop">""")

	_header()

	PRINT( """</div>""")
	PRINT( "</body>")
	return

def index(**args):
	PRINT( '''<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">''')
	PRINT( '<html xmlns="http://www.w3.org/1999/xhtml">')

	_head()

	# body
	_body()

	PRINT( '</html>')
	return


