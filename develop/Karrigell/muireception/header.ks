from HTMLTags import *

#relPath = lambda p : p.split('/')[0]
#model = Import('/'.join((relPath(THIS.baseurl), 'model.py')), REQUEST_HANDLER=REQUEST_HANDLER)

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
	print TITLE
	
	# the css files for the theme of web user interface 
	cssfiles = ( 'Content.css', 'Core.css', 'Layout.css','Dock.css','Window.css','Tabs.css')
	for f in cssfiles :
		print pagefn.css('/'.join(('themes', 'default', 'css', f)))
	
	# other css files
	
	# IE hack for canvas tag
	jSlice = \
	"""
	<!--[if IE]>
		<script type="text/javascript" src="%s"></script>
	<![endif]-->
	"""%'/'.join(('lib', 'canvas', 'excanvas_r43.js'))
	print jSlice
   
   # mootools lib
	jsfiles = ( 'mootools-1.2.4-core.js','mootools-1.2.4.2-more.js')
	for name in jsfiles:
		print pagefn.script('/'.join(('lib', 'mootools', name)), link=True)
		
	# MochaUI lib
	jsfiles = [ 'Core/Core.js', 'Layout/Layout.js', 'Layout/Dock.js','Window/Window.js',\
					'Window/Modal.js','Components/Tabs.js' ]
					
	for name in jsfiles:
		print pagefn.script( '/'.join(('lib', 'mocha',name)), link=True)
	
	
	# page initial js
	print pagefn.script( '/'.join(('js','init.js')), link=True)
	   
   # this page head tag is completed
	print "</head>"
	return