from HTMLTags import *
config = Import('../config.py')
model = Import('../model.py', REQUEST_HANDLER=REQUEST_HANDLER)
formRender = Import('../formRender.py')
so =Session()
so.user = getattr(so, 'user', None)

def _getCsv(admin, user):
	# get link id	
	prop = 'info'	
	values = model.get_item(admin, 'user', user, (prop,))
	id = values.get(prop) 
	if not id :
		content = {}
	else:
		# get file content
		content = model.get_file(admin, 'dossier', id)		
	data = model.csv2dict(content)			
	return data	

def _user_baseinfo_transformat(values, toRealValue=1):
	''' Parameters:
		values - a dictionary holds the fields maybe need to be transformatted
	'''
	selects = config.user_form_selects.keys()	
	for k,v in values.items():		
		if k in selects:			
			try:
				v = int(v)
			except:				
				v = 0			
			if toRealValue:
				values[k] = config.user_form_selects[k][v]
			else:
				values[k] = v	
	return 

def index(**args):
	''' Show the base information of a user.
	  When a administrator calls this page, the parameters lists as below:
	  	'username' - the user's name
	  	'columns' - how many columns is shown in one row
	'''
	admin = so.user 			
	user = args.get('username') or admin
	
	# set the link and style properties of <a> tag
	url = 'user/info.ks/page_edit?' +'username=' + user
	cols = args.get('columns')
	if not cols:
		cols = 3
	else:
		cols = int(cols)
	
	url = '&'.join((url, 'columns=%s'%cols))
	d = {'style': 'text-decoration:underline;', 'href': url}
	print DIV(A(_("Edit"), **d) , style="font-weight:bold; font-size:2.5em")		
		
	# get user's base information fields		
	if admin:
		values = _getCsv(admin, user)
	else:
		values = {}
	
	# now replace the multiful selects indexes to the corresponding values
	_user_baseinfo_transformat(values)	
	
	fields = config.base_fields
	names = config.base_fields_names		
	propvalues = [values.get(field) for field in fields]
	table = []
	# append the caption
	caption = '  '.join((user, _("Base Info")))  
	table.append( CAPTION(caption, style='text-align: center; font-size: 1.6em;font-weight:bold;'))
	trs = formRender.render_table_fields(names, propvalues, cols)
	# now constructs the Table
	table.append(trs)
	print TABLE(Sum(table), style="margin-left:3em;")
	
def page_edit(**args):	
	''' Show the form to edit the base information of a user.
	  When a administrator calls this page, the parameters lists as below:
	  	'username' - the user's name
	  	'columns' - how many columns is shown in one row in info.ks.index() page
	'''
	ol_content = config.base_fields_form
	required = ['organization', 'address', 'country', 'city', 'phone']
	form = []
	
	admin = so.user
	user = args.get('username') or admin
	oldvalues = _getCsv(admin, user)
	
	# now replace the multiful selects indexes to the corresponding values
	_user_baseinfo_transformat(oldvalues, toRealValue=0)
		
	ol = formRender.render_ol(ol_content, required, oldvalues)
	# add the <Legend> tag
	legend_tag = '  '.join((user, _("Base Info")))
	ld = LEGEND(SPAN(legend_tag))
	if admin == user :
		formstyle = 'width:auto;margin-left:5em;'
	else:
		formstyle = 'width:auto;'
	form.append(FIELDSET(ld+ol, style=formstyle))
	# add buttons to this form
	bns = config.user_form_buttons
	sbn = INPUT(**{'class':'submit',\
				 'type':'submit', \				 
				 'value':bns[0], \
				 'jframe':'no',\
				 'style': 'width:7.4em;height:2.6em', \
				 'target':'base_info'})

	cbn = INPUT(**{'class':'submit', \
				'type':'button', \
				'name':'cancel',\
				'value':bns[1], \
				'style': 'width:7.4em;height:2.6em'})
				
	buttons = FIELDSET(Sum((sbn, cbn)), **{'class':'submit','style':'padding-left:11em;'})	
	form.append(buttons)	
	# render the html slice which is a form element
	action_url = 'user/info.ks/postedit?' +'username=' + user 
	cols = args.get('columns')
	if cols :		
		action_url = '&'.join((action_url, 'columns=%s'%cols))
	print FORM(Sum(form), **{'id':'baseinfo', 'action': action_url, 'method':'get', 'style':'width:auto;margin-bottom:0em;'})	
	# below is the javascript code for this page
	script = "$(document).ready(function(){$.getScript('user/info.js.pih?formId=baseinfo');});"
	print SCRIPT(script, type="text/javascript")
	
def postedit(**args):
	if args.get('submit') :
		username = args.get('username')		
		# client form edit 'Cancel'  action
		if username :			
			index(**args)				
		else:
			index()	
	else:
		# Proceding form submit aciton, after this process,
		# refresh the Div component by triggering the 'OK' button
		# click event. Notes, triggering is using jFrmaeSubmitInput() function.
				
		# get properties' values 		
		names = config.base_fields		
		values = {}		 
		[values.update({name: args.get(name)}) for name in names]
		# do the real edit action	
		admin = so.user				
		user = args.get('username') or admin
		res = _edit_baseinfo(admin, user, values)
		
		# after form edit, refresh jFrame by jFrameSubmitInput(button)
		# to show form info, here 'button' menas 'OK' button
		print 'bns=$(".submit");'		
		# check the right 'OK' button index in the DOM
		print 'if(bns.length >3){index=4}else{index=1};'
		# refresh the form to information content		
		print 'jFrameSubmitInput(bns.get(index));'
		# The variable name for the dataTable in javascript namespace,
		# which is defined in manage/userlist.ks/index function.
		table = ('usersList', 'uTable')
		#print 'if (typeof(%s) != "undefined"){%s.fnDraw();}'%(table,table)
		print 'if ($("#%s" ).length != 0){%s.fnDraw();}'%table 

def _edit_baseinfo(admin,user,content):
	# Edit the user's base information which has been save in a csv formatted file.
	# Parameters:
	# 	admin -> admin username
	#	user -> 'user' class key property-'username' value
	#	content -> a dictionary hold the values to save to the csv file
	res = model.edit_user_info(admin, user, 'edit', content)
	return res
	
	