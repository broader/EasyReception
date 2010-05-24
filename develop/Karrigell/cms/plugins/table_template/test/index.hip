"""
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<meta http-equiv="Content-type" content="text/html; charset=utf-8" />
<meta name="keywords" content="" />
<meta name="description" content="" />
<!-- add your meta tags here -->
<!-- <link type='text/css' href='mediagroove.css' rel='StyleSheet'/> -->
<link type='text/css' href='prettyinpink.css' rel='StyleSheet'/>
</head>

<body>
"""
from HTMLTags import *
# construts a demo content to list in the page
content = []
for i in range(22):
	a = [i, '.'.join((str(i), 'html'))]
	content.append(a)

GROUPNUMBER=2
# get the number of the 'TR' elements
groups = divmod(len(content), GROUPNUMBER)
if groups[1]:
	groups = groups[0] +1
else:
	groups = groups[0]

table = []
# append the caption
table.append( CAPTION('Test Table Style'))
tr = []
for i in range(GROUPNUMBER):
	tr.append(TH('field name'))
	tr.append(TH('field value'))
table.append(THEAD(TR(Sum(tr))))

trs = []	
for g in range(groups) :
	tr = []
	# every 5 'TD' element consists 1 'TR' 
	for i in range(GROUPNUMBER):
		try:
			id, link = content.pop(0)
			#td = TD(DIV(id, href=link,style='text-align:right;'))+TD(INPUT(**{'type':'text','value':'test'})) 
			td = TD(DIV(id, href=link, style='text-align:right;'))+TD(LABEL('test',style='align:right'))
		except:
			break 		 			
		tr.append(td)
	trs.append(TR(Sum(tr)))

# now constructs the Table
table.append( Sum(trs))
print TABLE(Sum(table))

"""
</body>
</html>
"""
