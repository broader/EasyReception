[]
PRINT( '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">')
PRINT( '<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="cn" lang="cn">')
PRINT( '<head>')
PRINT( '<meta http-equiv="Content-type" content="text/html; charset=utf-8" />')
PRINT( '<meta name="keywords" content="" />')
PRINT( '<meta name="description" content="" />')
PRINT( '<!-- add your meta tags here -->')

PRINT( '<!--[if lte IE 7]>')
PRINT( '<link href="css/patches/patch_my_layout_test.css" rel="stylesheet" type="text/css" >')
PRINT( '<![endif]-->')

PRINT( '<title>%s</title>'%title)

PRINT( '<!-- Set the js and css files to be included -->')
cssfiles=('my_layout.css', 'lavalamp.css', 'jquery.lightbox-0.5.css' )
jsfiles=('jquery.js', 'jquery.lavalamp.js', 'jquery.easing.js', 'jquery.scrollTo-min.js', 'jquery.scrollTo.init.js' )
for f in cssfiles:
	url = '/'.join(('css', f))
     	PRINT( '<link rel="stylesheet" type="text/css" href="%s"  media="screen"  />\n' %url)
for f in jsfiles:
    	url = '/'.join(('js', f))
     	PRINT( '<script type="text/javascript" src="%s"></script>\n' %url)

PRINT( '<script type="text/javascript"> $(function() { $(".lavaLampWithImage").lavaLamp({ fx: "backout", speed: 700 })}); </script>')

PRINT( '</head>')

