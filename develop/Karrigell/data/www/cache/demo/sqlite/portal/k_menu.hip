[]
# Vertical menu
# Parameters :
# - labels : a list with menu items labels
# - urls : the list of matching urls to display when a menu item is selected
# - targetUrl : the url to call to reload the page
# - _selected : the selected item, if specified

try:
	selected=int(_selected)
except:
	selected=0

PRINT( '<table cellpadding="3" cellspacing="0" width="100%">\n')
PRINT( '<tr>')
PRINT( '<td valign="top"><table cellpadding="3" cellspacing="0">')
for i in range(len(labels)):
	label=labels[i]
	if i==selected:
		PRINT( '\t<tr><td bgcolor="#D0D0D0">')
		PRINT( '\n\t\t<a class="tab" href="%s?selected=%s">%s</a>' %(targetUrl,i,label))
		PRINT( '\n\t</td></tr>')
	else:
		PRINT( '\t<tr><td bgcolor="#808080">')
		PRINT( '\n\t\t<a class="tab" href="%s?selected=%s">%s</a>' %(targetUrl,i,label))
		PRINT( '\n\t</td></tr>')
PRINT( "\n</table></td>")
PRINT( '<td valign="top">')
Include('poems/'+urls[selected])
PRINT( "</td></tr></table>")

