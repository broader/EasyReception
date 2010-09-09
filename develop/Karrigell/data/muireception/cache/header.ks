['index']
from HTMLTags import *

modules = {'pagefn' : 'pagefn.py'}
[locals().update({k : Import('/'.join(('',v)))}) for k,v in modules.items()]

TITLE = \
'''
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
	<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
	<meta http-equiv="X-UA-Compatible" content="IE=8" />
	<title>%s</title>
	<meta name="description" content="A Web Applications For Congress Reception Work!" />
'''%_("EasyReception Congress Management Portal")


def index(**args):
	PRINT( TITLE)

	# yaml css framework
	for name in ( 'my_layout.css', 'forms.css'):
		PRINT( pagefn.css('/'.join(('css', 'yaml', name))))

	# yaml hack file
	csslice = \
	"""
	<!--[if lte IE 7]>
	<link href="%s" rel="stylesheet" type="text/css" />
	<![endif]-->
	"""%'/'.join(('css','yaml','patches','patch_my_layout.css'))
	PRINT( csslice)

	# mootools spinner css fiel
	PRINT( pagefn.css('/'.join(('css', 'spinner', 'spinner.css'))))

	# the css files for the theme of web user interface
	cssfiles = ( 'Content.css', 'Core.css', 'Layout.css','Dock.css','Window.css','Tabs.css')
	for f in cssfiles :
		PRINT( pagefn.css('/'.join(('themes', 'default', 'css', f))))

	# other css files
	# supplement css
	PRINT( pagefn.css('/'.join(('css', 'supplement.css'))))
	# moohover css
	PRINT( pagefn.css('/'.join(('lib', 'moohover','css','moohover.css'))))
	# sexyButton css
	PRINT( pagefn.css('/'.join(('images', 'SexyButtons', 'sexybuttons.css'))))

	# IE hack for canvas tag
	jSlice = \
	"""
	<!--[if IE]>
		<script type="text/javascript" src="%s"></script>
	<![endif]-->
	"""%'/'.join(('lib', 'canvas', 'excanvas_r43.js'))
	PRINT( jSlice)

   # mootools lib
	jsfiles = ( 'mootools-1.2.4-core.js','mootools-1.2.4.2-more.js')
	for name in jsfiles:
		PRINT( pagefn.script('/'.join(('lib', 'mootools', name)), link=True))

	# moohover lib
	PRINT( pagefn.script('/'.join(('lib', 'moohover','js','moohover.js')), link=True))

	# MochaUI lib
	jsfiles = [ 'Core/Core.js', 'Layout/Layout.js', 'Layout/Dock.js','Window/Window.js',\
					'Window/Modal.js','Components/Tabs.js' ]

	for name in jsfiles:
		PRINT( pagefn.script( '/'.join(('lib', 'mocha',name)), link=True))

	# mootools Assets tools
	PRINT( pagefn.script( '/'.join(('lib','tools','assetsmanager.js')), link=True))

	# page initial js
	#jsfiles = ('init.js.pih', 'layoutInit.js.pih')
	jsfiles = ('initMUI.js.pih', 'init.js.pih', 'layoutInit.js.pih')
	for name in jsfiles:
		PRINT( pagefn.script( '/'.join(('js', name)), link=True))

   # this page head tag is completed
	PRINT( "</head>")
	return

