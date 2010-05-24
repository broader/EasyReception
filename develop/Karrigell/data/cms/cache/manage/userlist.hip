[]
from HTMLTags import *

modules = {'pagefn' : 'pagefn.py'}
[locals().update({k : Import(v)}) for k,v in modules.items() ]

PRINT( """
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

<style type="text/css" title="currentStyle">
	<!--@import "lib/dataTable/css/demo_page.css";-->
	@import "lib/dataTable/css/demo_table.css";
</style>
""")

#jsfiles = ('jquery.form.js', 'jquery.validate.js', 'jquery.jframe.js')
#for name in jsfiles:
#	src = '/'.join(('..', 'js', name))
#	print SCRIPT(**{'type':'text/javascript', 'src': src})

#src = '/'.join(('..', 'js', 'jquery.jframe.js' ))
#print SCRIPT(**{'type':'text/javascript', 'src': src})

pagefn.jframe()

# left users list Div component
js_1 = "$('#user_list').hide().show('slow')"
style_1 = "position:relative; border:1px solid #8B8378; margin-left: 2em;"
d1 = {'id':'user_list','class':'info','src':'manage/userlist.ks','onload':js_1,'style':style_1}
leftDiv = DIV(DIV(**d1),**{'class':'c62l'})

# right users base info Div component
js_2 = "$('#base_info').hide().show('slow')"
style_2 = "position:relative; width:auto; border:1px solid #8B8378; margin-left : 1em;margin-right:1em;"
d2 = {'id':'base_info','class':'info','src':'manage/userlist.ks/page_account','onload':js_2,'style':style_2}
rightDiv = DIV(DIV(**d2),**{'class':'c38r'})

info = DIV(Sum((leftDiv, rightDiv)), **{'class':'subcolumns'})

PRINT( DIV(info, **{'class':'subcolumns'}))

PRINT( """
<script type="text/javascript">
	$.fn.waitingJFrame = function () {
          $(this).html('<img src="../images/ajax_loading.gif" alt="Loading......" />');
	};
</script>
""")

