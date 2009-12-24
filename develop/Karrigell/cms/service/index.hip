from HTMLTags import *

modules = {'pagefn' : 'pagefn.py'}
[locals().update({k : Import('/'.join(('..' , v)))}) for k,v in modules.items() ]

"""
<link type="text/css" href="yaml/screen/forms.css" rel="stylesheet" />

<style type="text/css" title="currentStyle">
	@import "lib/treeTable/jquery.treeTable.css";
</style>
"""

pagefn.jframe()
	
page = 'service'
pageAction = '.'.join((page, 'ks'))
pageAction = '/'.join((page, pageAction))

# left user's help issue list Div component
#id = 'serviceShow'
js = "$('#%s').hide().show('slow')"%id
style = "position:relative; border:1px solid #8B8378; margin-left: 2em;;"
action = '/'.join((pageAction, 'index'))
d1 = {'class':'info', 'src': action, 'onload':js, 'style':style}
leftDiv = DIV(DIV(**d1),**{'class':'c50l'})

# right Div component includes two components,
# new issue Div and edit issue Div
pages = ( '/'.join((pageAction, 'page_reserveList?init=1')), '/'.join((pageAction, 'page_reserveEdit')) )
style = "position:relative; width:auto; border:1px solid #8B8378; margin-left : 1em;margin-right:1em;"
divs = []
for page in pages:	
	d = { 'class':'dimmed', 'src': page, 'style':style}
	divs.append(DIV(**d))

divs.insert(1, DIV(**{'style': 'height: 0.5em;clear: both;'}))	
rightDiv = DIV(Sum(divs),**{'class':'c50r'})

 
info = DIV(Sum((leftDiv, rightDiv)), **{'class':'subcolumns'})
#print DIV(info, **{'class':'subcolumns'})
print info


"""
<script type="text/javascript">	
	$.fn.waitingJFrame = function () {
          $(this).html('<img src="../images/ajax_loading.gif" alt="Loading......" />');
	};	
</script>
"""