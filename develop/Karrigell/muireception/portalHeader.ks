from HTMLTags import *

modules = {'pagefn' : 'pagefn.py'}
[locals().update({k : Import('/'.join(('',v)))}) for k,v in modules.items()]	
	
TITLE = \
'''
<head>
	<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
	<meta http-equiv="X-UA-Compatible" content="IE=8" />
	<title>%s</title>
	<meta name="description" content="A Web Applications For Congress Reception Work!" />	
'''%_("Portal For Congress Service") 


def index(**args):
	print TITLE
	
	# yaml css framework 
	for name in ( 'my_layout.css', 'forms.css'):
		print pagefn.css('/'.join(('css', 'yaml', name)))
	
	# yaml hack file
	csslice = \
	"""
	<!--[if lte IE 7]>
	<link href="%s" rel="stylesheet" type="text/css" />
	<![endif]-->
	"""%'/'.join(('css','yaml','patches','patch_my_layout.css'))
	print csslice
	
	# mootools spinner css fiel
	print pagefn.css('/'.join(('css', 'spinner', 'spinner.css')))
	
	# the css files for the theme of web user interface 
	cssfiles = ( 'Content.css', 'Core.css', 'Layout.css','Dock.css','Window.css','Tabs.css')
	for f in cssfiles :
		print pagefn.css('/'.join(('themes', 'default', 'css', f)))
	
	# other css files
	# moohover css, to be deleted
	print pagefn.css('/'.join(('lib', 'moohover','css','moohover.css')))	
	# sexyButton css
	print pagefn.css('/'.join(('images', 'SexyButtons', 'sexybuttons.css')))
	
	# IE hack for canvas tag
	jSlice = \
	"""
	<!--[if IE]>
		<script type="text/javascript" src="%s"></script>
	<![endif]-->
	"""%'/'.join(('lib', 'canvas', 'excanvas_r43.js'))
	print jSlice
   
	# mootools lib
	jsfiles = ( 'mootools-1.2.4-core.js','mootools-1.2.4.2-more.js', 'Date.Chinese.CN.js')
	for name in jsfiles:
		print pagefn.script('/'.join(('lib', 'mootools', name)), link=True)
	
	# moohover lib, to be deleted
	print pagefn.script('/'.join(('lib', 'moohover','js','moohover.js')), link=True)
	
	# rotate plugin for Elements
	print pagefn.script('/'.join(('lib', 'rotate', 'Fx.Rotate.js')), link=True)
		
	# MochaUI lib
	jsfiles = [ 'Core/Core.js', 'Layout/Layout.js', 'Layout/Dock.js','Window/Window.js',\
			'Window/Modal.js','Components/Tabs.js' ]
					
	for name in jsfiles:
		print pagefn.script( '/'.join(('lib', 'mocha',name)), link=True)
	
	# mootools Assets tools
	print pagefn.script( '/'.join(('lib','tools','assetsmanager.js')), link=True)
	
	# page initial js
	jsfiles = ('initMUI.js.pih', 'portalInit.js.pih', 'portaLayoutInit.js.pih')
	for name in jsfiles:
		print pagefn.script( '/'.join(('js', name)), link=True)
	   
	# this page head tag is completed
	print "</head>"
	return
