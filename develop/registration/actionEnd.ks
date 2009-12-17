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
		     
	header = H3( text, style='text-align:left;background:white;')
	header = Sum((BR(), BR(), header))
	
	#print header, HR(style='color:white;border-color:white;margin:0px;padding:0px;')
	
	# the account informations
	table = []
	# append the caption
	table.append( CAPTION(_("Login Information"),\
					  style='text-align: center; font-size: 1.2em;font-weight:bold;'))
					  
	fieldvalues = CONFIG.getData(ACCOUNTFIELDS)
	fieldtitles = [ item.get('prompt') for item in fieldvalues ]
	fieldnames = [ item.get('name') for item in fieldvalues ]
	values = [ getattr(SO, name, '') for name in fieldnames ]
	
	labelStyle = {'label':'font-weight:bold;font-size:1.3em;color:white;', \
					  'td':'text-align:right;background:#9ca2cb'}
					  
	valueStyle = {'label':'color:#ff6600;font-size:1.6em;', 'td':'text-align:left;'}
	trs = form.render_table_fields(fieldtitles, values, 1, labelStyle, valueStyle)
	table.append(trs)
	table = TABLE(Sum(table), style='width:100%;')
	
	left = DIV(table, **{'class':'c50r'})
	
	main.append(DIV( Sum((DIV(header, **{'class':'c50l'}),left)), \
					**{'class':'subcolumns', 'style':'background:white;'})
				  )
	main.append(HR(style='color:white;border-color:white;margin:0px;padding:0px;'))
	# the base informations 
	table = []
	# append the caption
	table.append( CAPTION(_("Base Information"),\
					  style='text-align: center; font-size: 1.1em;font-weight:bold;'))
					  
	fieldvalues = CONFIG.getData(BASEINFOFIELDS)
	fieldtitles = [ item.get('prompt') for item in fieldvalues ]
	fieldnames = [ item.get('name') for item in fieldvalues ]
	soName = pagefn.SOINFO.get('userinfo')
	soValues = getattr(SO, soName, {})
	values = [ soValues.get(name) or '' for name in fieldnames ]
	trs = form.render_table_fields(fieldtitles, values, 4, labelStyle, valueStyle)
	table.append(trs)
	table = TABLE(Sum(table), style='width:100%;')
	
	#right = DIV(table, **{'class':'c62r'})
	#print DIV( Sum((left,right)), **{'class':'subcolumns', 'style':'background:white;'})
	main.append(DIV( table, **{'class':'subcolumns', 'style':'background:white;'}))
	
	button = BUTTON( _('End Registration'), **{'class':'MooTrans', 'type':'button', 'style':'margin-left:20em;'})
	main.append(DIV( button, **{'class':'subcolumns', 'style':'background:white;'}))
	print DIV(Sum(main), style='', **{'class':'subcolumns'})
	return
	