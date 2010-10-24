['index']
""" The portal for user's login """

from HTMLTags import *
modules = {'pagefn': 'pagefn.py', }
[locals().update({k : Import('/'.join(('',v)))}) for k,v in modules.items() ]

# the content in <head> tag of this html page
def _head():
	PRINT( '<head>')

	metAttrs = [\
		{'http':'Content-Type','content':'text/html; charset=UTF-8'},
		{'http':'X-UA-Compatible','content':'IE=8'},
		{'name': 'description', 'content': _("The portal for Congress Management")},
		{'http':'X-UA-Compatible','content':'IE=edge'}
	]
	for tag in [ META(**attr) for attr in metAttrs ]:
		PRINT( tag)

	PRINT( TITLE(_("Portal for Congress Management")))

	# css links of mochaUI liberary
	for name in ("Content.css", "Core.css", "Layout.css", "Dock.css", "Tabs.css", "Window.css" ) :
		PRINT( LINK(**{'rel':'stylesheet', 'type': 'text/css', 'href': '/'.join(('..', 'themes', 'default', 'css', name))}))

	PRINT( \
	"""
	<!--[if IE]>
		<script type="text/javascript" src="scripts/excanvas_r43.js"></script>
	<![endif]-->
	""")

	# javascript files' links
	for name in ('mootools-1.2.4-core.js', 'mootools-1.2.4.2-more.js', 'Date.Chinese.CN.js' ) :
		PRINT( SCRIPT(**{'type':'text/javascript', 'src': '/'.join(('..', 'lib', 'mootools', name))}))

	for name in ('Core/Core.js', 'Window/Window.js', 'Window/Modal.js', 'Layout/Layout.js', 'Layout/Dock.js') :
		PRINT( SCRIPT(**{'type':'text/javascript', 'src': '/'.join(('..', 'lib', 'mocha', name))}))

	# mootools Assets tools
	PRINT( pagefn.script( '/'.join(('..', 'lib','tools','assetsmanager.js')), link=True))

	# page initial js
	jsfiles = ('initMUI.js.pih', 'portalInit.js.pih', 'layoutInit.js.pih')
	for name in jsfiles:
		PRINT( pagefn.script( '/'.join(('..', 'js', name)), link=True))

	PRINT( '</head>')
	return

# the nab bar and login area
def _header():
	desktopHeader = DIV(**{'id':'desktopHeader'})

	titleWrapper = DIV(**{'id':'desktopTitlebarWrapper'})
	desktopHeader <= titleWrapper

	titleBar = DIV(**{'id':'desktopTitlebar'})
	titleWrapper <= titleBar

	titleBar <= H1('Mocha UI', **{'class':'applicationTitle'})
	leftUpLogo = """%s <span class="taglineEm">%s</span>"""%(_("Simple, Effective"), _("Portal for congress service"))
	titleBar <= H2(leftUpLogo, **{'class':'tagline'})

	topNav = DIV(**{'id':'topNav'})
	titleBar <= topNav
	ul = UL(**{'class':'menu-right'})
	li = LI(TEXT("""<a href="#" >%s </a>"""%_("Sign In")))
	ul <= li
	li = LI(TEXT("""<a href="#" >%s</a>"""%_("Register")))
	ul <= li
	topNav <= ul

	desktopHeader <= DIV(**{'id':'desktopNavbar'})

	PRINT( desktopHeader)

	return

# dock bar which holds the hanlers of the minisized windows
def _dock():
	dockwrapper = DIV(**{'id':'dockWrapper'})

	dock = DIV(**{'id':'dock'})
	dockwrapper <= dock

	for tag in ('dockPlacement', 'dockAutoHide'):
		dock <= DIV(**{'id':tag})

	dock <= DIV(DIV(**{'id':'dockClear', 'class':'clear'}), **{'id':'dockSort'})

	PRINT( dockwrapper)
	return

# the footer information of this page
def _footer():
	footWrapper = DIV(**{'id':'desktopFooterWrapper'})
	info = \
	"""
	<span style="float:right;">
		&copy; 2007-2010
		<a target="_blank" href="http://www.acroes.com/" style="color:#CCF564;">
			%s
		</a> - MIT License
	</span>
	"""%_('北京昊鹏星辰科技有限责任公司')

	footer = DIV(info, **{'id':'desktopFooter'})
	footWrapper <= footer
	PRINT( footWrapper)

	return

def _innerBody():
	# dock bar which holds the hanlers of the minisized windows
	_dock()

	# the main operation area
	PRINT( DIV(DIV(**{'id':'page'}), **{'id':'pageWrapper'}))

	# the footer information of this page
	_footer()

	return

def _body():
	PRINT( "<body>")

	PRINT( """<div id="desktop">""")

	# the nab bar and login area
	_header()

	_innerBody()

	PRINT( """</div>""")
	PRINT( "</body>")
	return

# the main frame for this html page
def index(**args):
	PRINT( '''<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">''')
	PRINT( '<html xmlns="http://www.w3.org/1999/xhtml">')

	# <head> tag
	_head()

	# <body> tag
	_body()

	PRINT( '</html>')
	return


