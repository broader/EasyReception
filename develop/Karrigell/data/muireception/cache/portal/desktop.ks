['index']
""" The portal which is like a desktop user interface. """

from HTMLTags import *

#modules = {'pagefn': 'pagefn.py', 'JSON': 'demjson.py', 'formFn':'form.py'}
#[locals().update({k : Import('/'.join(('',v)))}) for k,v in modules.items() ]


RELPATH = '/'.join(THIS.baseurl.split('/'))
#DATA = Import( '/'.join((RELPATH, 'hotelConfig.py')), rootdir=CONFIG.root_dir)


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
		PRINT( LINK(**{'rel':'styleshee', 'type': 'text/css', 'href': '/'.join(('..', '..', '..', '..', 'themes', 'default', 'css', name))}))

	PRINT( \
	"""
	<!--[if IE]>
		<script type="text/javascript" src="scripts/excanvas_r43.js"></script>
	<![endif]-->
	""")

	# javascript files' links
	for name in ('mootools-1.2.4-core.js', 'mootools-1.2.4.2-more.js') :
		PRINT( SCRIPT(**{'type':'text/javascript', 'src': '/'.join(('..', '..', 'lib', 'mootools', name))}))

	for name in ('Core/Core.js', 'Window/Window.js', 'Layout/Layout.js', 'Layout/Dock.js') :
		PRINT( SCRIPT(**{'type':'text/javascript', 'src': '/'.join(('..', '..', 'lib', 'mocha', name))}))


	PRINT( SCRIPT(**{'type':'text/javascript', 'src': '../../scripts/demo-virtual-desktop-init.js'}))

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


