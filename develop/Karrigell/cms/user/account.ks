from HTMLTags import *

model = Import("../model.py", REQUEST_HANDLER=REQUEST_HANDLER)
config = Import("../config.py")
so = Session()
USER_PROPS = ['username', 'email']

def _get_oldvalue(user, props=None):		
	props = model.get_item(user, 'user', user, USER_PROPS)
	if not props:
		props = {}
	
	return props	

def index(**args):	
	# set the link and style properties of <a> tag
	d = {'style': 'text-decoration:underline;', 'href': 'user/account.ks/page_edit'}
	print DIV(A(_("Edit"), **d), style="margin-left:7.6em;font-weight:bold;font-size:2.5em")
	# all the login and base information fields have been stored in session object
	names = USER_PROPS
	props = _get_oldvalue(so.user, names)	
	
	##------------------Render account info table ---------------------------------- 
	table = []
	# append the caption
	table.append( CAPTION(_("Login Info"), style='text-align: center; font-size: 1.6em;font-weight:bold;'))
	values = [props.get(name, None) for name in names]

	formRender = Import('../formRender.py')

	cols = 1
	trs = formRender.render_table_fields(names, values, cols)
	# now constructs the Table
	table.append(trs)
	print TABLE(Sum(table), style="margin-left:4em;")
	#-------------------Login info table end -------------------------------------

def page_edit(**args):
	# The meaning of each item lists as below:
	# first item is the value for 'Fieldset' tag;
	# second item shows those 'Li' tags which needs add 'Required' mark.
	# third item is a list consisted by :
	# 1) first item is the same value for  'for' attribute of 'Label' as for  'id', 'name' attributes of 'Input';
	# 2) second  item is the value of 'Label';
	# 3) third item is the value of 'class' and 'type' attributes of 'Input'.
	legend_tag = _("Login Info")
	ol_content=[ [ _("Login Name :"), {'id':'username', 'name':'username','type':'text', 'disabled':''},'input'],\
			       [_("Old Password :"), {'id':'oldpwd', 'name':'oldpwd', 'type':'password'},'input'],\  
		       	       [_("New Password :"), {'id':'pwd', 'name':'password', 'type':'password', 'minlength': 6},'input'],\
		       	       [_("Confirm New Password :"), {'id':'cpwd', 'name':'cpwd', 'type':'password'},'input'],\		       	       
		       	       [_("Email address :"), {'id':'email', 'name':'email', 'class':'email', 'type':'text'},'input'],\		               
		             ]
	required = ['oldpwd', 'password']

	form = []
	# get the OL content from formRender.py module
	formRender = Import('../formRender.py')
	oldvalues = _get_oldvalue(so.user)	
	#[setattr(so, name, value) for name,value in oldvalues.items() ]
	#ol = formRender.render_ol(ol_content, required, so)
	ol = formRender.render_ol(ol_content, required, oldvalues)

	# add the <Legend> tag
	ld = LEGEND(SPAN(legend_tag))
	form.append(FIELDSET(ld+ol, style='width:auto;'))

	# add buttons to this form
	#bns =[_("OK"), _("Cancel")]
	bns = config.user_form_buttons
	sbn = INPUT(**{'class':'submit',\
				 'type':'submit', \				 
				 'value':bns[0], \
				 'jframe':'no',\
				 'style': 'width:7.4em;height:2.6em', \
				 'target':'account_info'})

	cbn = INPUT(**{'class':'submit', \
				'type':'button', \
				'name':'cancel',\
				'value':bns[1], \
				'style': 'width:7.4em;height:2.6em'})
				
	buttons = FIELDSET(Sum((sbn, cbn)), **{'class':'submit','style':'padding-left:6em;'})	
	form.append(buttons)	
	# render the html slice which is a form element
	print FORM(Sum(form), **{'id':'account', 'action': 'user/account.ks/postedit', 'method':'get', 'style':'width:auto;margin-bottom:0em;'})	
	# below is the javascript code for this page
	script = "$(document).ready(function(){$.getScript('user/account.js.pih?formId=account');});"
	print SCRIPT(script, type="text/javascript")

def postedit(**args):		
	if args.get('submit') :
		# client form edit 'cancel' or 'ok' action				
		index()	
	else:
		# do client form edit aciton
		names = ('email', 'password')
		props = {}
		[props.update({name: args.get(name)}) for name in names]
		# if 'password' not changed, don't submit it
		if not props.get('password'):
			props.pop('password')
			
		user = so.user
		# form values edit action
		model.edit_item(user, 'user', user, props)		
		# after form edit, refresh jFrame to show form info
		print 'jFrameSubmitInput($(".submit").get(1));'
		
		