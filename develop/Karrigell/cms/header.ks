from HTMLTags import *

relPath = lambda p : p.split('/')[0]
model = Import('/'.join((relPath(THIS.baseurl), 'model.py')), REQUEST_HANDLER=REQUEST_HANDLER)

modules = {'pagefn' : 'pagefn.py'}
[locals().update({k : Import('/'.join(('',v)))}) for k,v in modules.items() ]


TITLE = \
'''
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<meta http-equiv="Content-type" content="text/html; charset=utf-8" />
<meta name="keywords" content="" />
<meta name="description" content="" />
<!-- add your meta tags here -->
<!--[if lte IE 7]>
<link href="css/patches/patch_3col_standard.css" rel="stylesheet" type="text/css" >
<![endif]-->
<!-- css format for load html slice in main content component -->
<style>
	#main .loading {
		color:#993333; 
		font-size:1.2em; 
		margin: 0 0 0em; 
		text-align: center;
	}			
</style>
<title>%s</title>
'''%title

def index(**args):
	print TITLE
	#print '<title>%s</title>'%args.get(title)
	# yaml css files
	cssfiles = ( 'screen/forms.css', 'add-ons/microformats/microformats.css')
	for f in cssfiles :
		url = '/'.join(('yaml', f))
		print pagefn.css(url)

	# other css files in 'css' directory
	cssfiles=('layout_3col_standard.css', 'impromptu.css')
	for f in cssfiles:
		url = '/'.join(('css', f))
	  	print pagefn.css(url)
     	
   # other css files in 'lib' directory
	cssfiles = ('lib/smartlists/smartlists.css', 'lib/cluetip/jquery.cluetip.css')
	for f in cssfiles:
		print pagefn.css(f)
     	
  	# js files
  	# import files in '/js' directiory
  	jsfiles = ( 'jquery.js', 'jquery.scrollTo-min.js', \
	  			   'jquery.corner.js', 'jquery.impromptu.2.7.js', \
	  			   'jquery.cookie.js', 'jquery.form.js',\
	  			   'jquery.jframe.js', 'jquery.domec-1.0.1.js')
  	
  	for f in jsfiles:
  		url = '/'.join(('js', f))
		print pagefn.script(url, link=True)
     	
	# import files in '/lib' directiory
	jsfiles = ( 'smartlists/jquery.smartlists.js', \
				   'validate/jquery.validate.js', \
				   'validate/validation_messages.js.pih', \
				   'cluetip/jquery.cluetip.js')
			   
	for f in jsfiles:
		url = '/'.join(('lib', f))
		print pagefn.script(url, link=True) 
     	
	print '</head>'