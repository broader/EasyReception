[]
from HTMLTags import *

modules = {'pagefn' : 'pagefn.py'}
[locals().update({k : Import('/'.join(('..', v)))}) for k,v in modules.items() ]

PRINT( """
<!--
<link type="text/css" href="yaml/screen/forms.css" rel="stylesheet" />
-->

<style type="text/css" title="currentStyle">
	@import "lib/dataTable/css/demo_table.css";
	@import "lib/multiselect/style.css";
	@import "lib/asmselect/jquery.asmselect.css";
</style>
""")

jsfiles = ('jquery.form.js', )
jsfiles = ['/'.join(('..', 'js', name)) for name in jsfiles]
for src in jsfiles:
	PRINT( SCRIPT(**{'type':'text/javascript', 'src': src}))

# initial jframe
pagefn.jframe()

# left user's help issue list Div component
js_1 = "$('#issue_list').hide().show('slow')"
style_1 = "position:relative; border:1px solid #8B8378; margin-left: 2em;;"
d1 = {'id':'issue_list','class':'info','src':'issue/issue.ks/index','onload':js_1,'style':style_1}
leftDiv = DIV(DIV(**d1),**{'class':'c62l'})

# right Div component includes two components,
# new issue Div and edit issue Div
ids = (('issue_new', 'issue/issue.ks/show'), ('issue_edit','issue/issue.ks/page_editIssue'))
style = "position:relative; width:auto; border:1px solid #8B8378; margin-left : 1em;margin-right:1em;"
divs = []
for id in ids:
	js = "$('#%s').hide().show('slow')"%id	[0]
	d = {'id': id[0], 'class':'dimmed', 'src': id[1], 'onload':js, 'style':style}
	divs.append(DIV(**d))

divs.insert(1, DIV(**{'style': 'height: 0.5em;clear: both;'}))
rightDiv = DIV(Sum(divs),**{'class':'c38r'})

info = DIV(Sum((leftDiv, rightDiv)), **{'class':'subcolumns'})

PRINT( DIV(info, **{'class':'subcolumns'}))

PRINT( """
<script type="text/javascript">
	$.fn.waitingJFrame = function () {
          $(this).html('<img src="../images/ajax_loading.gif" alt="Loading......" />');
	};
</script>
""")

