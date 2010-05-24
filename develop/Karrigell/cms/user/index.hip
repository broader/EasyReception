from HTMLTags import *

modules = {'pagefn' : 'pagefn.py'}
[locals().update({k : Import('/'.join(('..', v)))}) for k,v in modules.items() ]

"""
<link type="text/css" href="css/screen.css" rel="stylesheet" />

<!--[if lte IE 7]>
<style type="text/css" media="all">
@import "css/required-fields-star1-ie.css";
</style>
<![endif]-->

<style type="text/css" media="all" ><![CDATA[
form label.error{
	margin-left: 0em;
}
]]></style>
"""
#jsfiles = ('jquery.form.js', 'jquery.validate.js', 'jquery.jframe.js')
#for name in jsfiles:
#	src = '/'.join(('..', 'js', name))
#	print SCRIPT(**{'type':'text/javascript', 'src': src})
	
#src = '/'.join(('..', 'js', 'jquery.jframe.js' ))
#print SCRIPT(**{'type':'text/javascript', 'src': src})
pagefn.jframe()


title = DIV(Sum((H2(_("Personal Profile"), style="margin-left:1em;"), HR())) )

js_1 = "$('#account_info').hide().show('slow')"
style_1 = "position:relative; border:1px solid #8B8378; margin-left: 2em;"
d1 = {'id':'account_info','class':'info','src':'user/account.ks','onload':js_1,'style':style_1}
leftDiv = DIV(DIV(**d1),**{'class':'c38l'})

js_2 = "$('#base_info').hide().show('slow')"
style_2 = "position:relative; width:40em; border:1px solid #8B8378; margin-left : 1em;"
d2 = {'id':'base_info','class':'info','src':'user/info.ks','onload':js_2,'style':style_2}
rightDiv = DIV(DIV(**d2),**{'class':'c62r'})
 
info = DIV(Sum((leftDiv, rightDiv)), **{'class':'subcolumns'})

print DIV(Sum((title, info)), **{'class':'subcolumns'})
