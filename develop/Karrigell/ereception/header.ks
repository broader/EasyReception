from HTMLTags import *

relPath = lambda p : p.split('/')[0]
model = Import('/'.join((relPath(THIS.baseurl), 'model.py')), REQUEST_HANDLER=REQUEST_HANDLER)

modules = {'pagefn' : 'pagefn.py'}
[locals().update({k : Import('/'.join(('',v)))}) for k,v in modules.items()]

TITLE = \
'''
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
   "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
<!-- (en) Add your meta data here -->
<link href="css/my_layout.css" rel="stylesheet" type="text/css"/>
<!--[if lte IE 7]>
<link href="css/patches/patch_my_layout.css" rel="stylesheet" type="text/css" />
<![endif]-->
<title>%s</title>
'''%title


def index(**args):
	print TITLE
	# yaml css files
	cssfiles = ( 'screen/forms.css', 'add-ons/microformats/microformats.css')
	for f in cssfiles :
		print pagefn.css('/'.join(('yaml', f)))
	
	# other css files
   
   # mootools lib
	jsfiles = ( 'mootools-1.2.4-core.js','mootools-1.2.4.2-more.js')
	for name in jsfiles:
		print pagefn.script('/'.join(('js', 'lib', 'mootools', name)), link=True)
   	   	
	# other javascript libraries
   # import files in '/js' directiory
	jsfiles = ( '/'.join(('js','lib','tools','assetsmanager.js')), '/'.join(('js','init.js')))	
	for name in jsfiles:
		print pagefn.script(name, link=True)
   
   # import files in '/lib' directiory
	libnames = ('mavdialog', 'moohover')
	for lib in libnames:
		names = ['/'.join(('js','lib',lib,suffix,'.'.join((lib,suffix))))\
					for suffix in ('css','js')]
		print pagefn.css(names[0])
		print pagefn.script(names[1], link=True)
	
   # this page head tag is completed
	print "</head>"
	return