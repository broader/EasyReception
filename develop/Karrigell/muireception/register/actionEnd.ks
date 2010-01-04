"""
The module for registration application. 
"""

from HTMLTags import *

# 'THIS.script_url' is a global variable in Karrigell system
#APPATH = THIS.script_url[1:]
RELPATH = (lambda p : p.split('/')[0])(THIS.baseurl)

#model = Import( '/'.join((RELPATH, 'model.py')))

modules = {'pagefn' : 'pagefn.py',  'JSON' : 'demjson.py', 'form':'form.py'}
[locals().update({k : Import('/'.join(('',v)))}) for k,v in modules.items() ]
 

# ********************************************************************************************
# Page Variables
# ********************************************************************************************

# the session object for this page
SO = Session()

# config data object
CONFIG = Import( '/'.join((RELPATH, 'config.py')), rootdir=CONFIG.root_dir)

# form fields' names in CONFIG file
ACCOUNTFIELDS = 'userAccountInfo'

# base information fields' names in CONFIG file
BASEINFOFIELDS = 'userBaseInfo'

# End*****************************************************************************************

# ********************************************************************************************
# The page functions begining 
# ********************************************************************************************

def index(**args):
	main = []
	text = _("Congradulations! You have registered successfully!<BR>\
		     If you have any question, please contact with us.\
		     You're welcom always!")
		     
	header = H3( text, style='text-align:left;color:saddleBrown;')	
	main.append(DIV(header, **{'class':'subcolumns' }))
	main.append(DIV( HR(), **{'class':'subcolumns' }))	
	
	# the account informations
	table = []
	# append the caption
	table.append( CAPTION(_("Login Information"),\
					  style='text-align: center; font-size: 1.2em;font-weight:bold;'))
					  
	fieldvalues = CONFIG.getData(ACCOUNTFIELDS)
	values = []	
	for field in fieldvalues :
		value = {}
		[ value.update({prop:field.get(prop)}) for prop in ('prompt','type')]		
		value['value'] = getattr(SO, field.get('name'), '')
		values.append(value)
		
	labelStyle = {'label':'font-weight:bold;font-size:1.2em;color:white;', \
					  'td':'text-align:right;background:#9ca2cb'}
					  
	valueStyle = {'label':'color:#ff6600;font-size:1.2em;', 'td':'text-align:left;'}
	
	trs = form.render_table_fields( values, 1, labelStyle, valueStyle)
	table.append(trs)
	table = TABLE(Sum(table), style='width:auto;')
	
	#left = DIV(table, **{'class':'c25l'})
	left = DIV(table, **{'class':'subcolumns'})
	
	# the base informations 
	table = []
	# append the caption
	table.append( CAPTION(_("Base Information"),\
					  style='text-align: center; font-size: 1.1em;font-weight:bold;'))
					  
	fieldvalues = CONFIG.getData(BASEINFOFIELDS)
	soName = pagefn.SOINFO.get('userinfo')
	soValues = getattr(SO, soName, {})
	#print soValues
	values = []	
	for field in fieldvalues :
		value = {}
		[ value.update({prop:field.get(prop)}) for prop in ('prompt','type')]		
		value['value'] = soValues.get(field.get('name')) or '&nbsp;---&nbsp;'
		values.append(value)
	
	trs = form.render_table_fields( values, 4, labelStyle, valueStyle)
	table.append(trs)
	table = TABLE(Sum(table), style='width:auto;')
	
	#right = DIV(table, **{'class':'c75r','style':''})
	right = DIV(table, **{'class':'subcolumns'})
	
	main.append(DIV( Sum((left,HR(),right)), **{'class':'subcolumns','style':'overflow-y:scroll;height:250px;'}))
	main.append(DIV( HR(), **{'class':'subcolumns'}))
	 
	button = BUTTON( _('End Registration'), **{'class':'MooTrans', 'type':'button', 'style':'margin-left:20em;width:auto;'})
	
	main.append(DIV( button, **{'class':'subcolumns'}))
	print DIV(Sum(main), **{'class':'subcolumns', 'style':'background:white;'})
	return
	