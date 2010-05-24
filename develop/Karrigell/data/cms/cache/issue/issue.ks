['index', 'page_getData', 'page_newIssue', 'createIssue', 'show', 'page_showIssueInPage', 'get_adminList', 'page_editIssue', 'postEditIssue']
import sys, urllib, copy

# karrigell modules
from HTMLTags import *

# import other moules
model = Import("../model.py", REQUEST_HANDLER=REQUEST_HANDLER)

modules = {'config' : 'backgroundConfig.py', 'JSON' : 'demjson.py', 'formRender' : 'formRender.py', 'pagefn' : 'pagefn.py'}
[locals().update({k : Import('/'.join(('..', v)))}) for k,v in modules.items() ]

so = Session()
if not hasattr(so, 'user'):
	so.user = None


def index(**args):
	PRINT( pagefn.script('lib/dataTable/js/jquery.dataTables.js'))

	# set the language text in web table
	lan = [l for l in ACCEPTED_LANGUAGES if l in ('zh', 'zh-cn', 'cn')]
	if len(lan):
		txt = 'lib/dataTable/i18n/cn_CN.txt'
	else:
		txt = ''

	th_content = config.issuelist_th_content
	# get the index of 'serial' property in titles' columns
	tabletitles = [i[-1] for i in th_content ]
	serialcolumn = str(tabletitles.index("serial"))

	script= '''$(document).ready(function() {
				// call back function for show row info in a editable Div component
				function initialFrame(responseText, textStatus, XMLHttpRequest){
					$(this).activateJFrame();
				};

				// the call back function for each row in table body
				function rowcb(nRow, aData, iDisplayIndex){
					$(nRow).each(function(){
						$(this).click(function(){
							url = "issue/issue.ks/page_showIssueInPage?serial="+aData[%s];
							$("#issue_edit").load(url, "", initialFrame);
						});
					});
					return nRow;
				};

				issueTable = $('#issuesList').dataTable( {
					"bProcessing": true,
					"bServerSide": true,
					"aaSorting": [[ 0, "desc" ]]	,
					"sAjaxSource": "issue/issue.ks/page_getData",
					"sPaginationType": "full_numbers",
					"fnRowCallback": rowcb,
					"oLanguage": {"sUrl": "%s"}
				} );
				$("#issuesList").css("width", "50em");
			} );'''%(serialcolumn, txt)

	PRINT( SCRIPT(script, **{'type': 'text/javascript' , 'charset': 'utf-8'}))
	PRINT( H1(_("Issues' List")))
	PRINT( HR())
	table = []

	# add table head

	th = [TH(item[1], **item[0]) for item in th_content]
	tr = TR(Sum(th))
	table.append(THEAD(tr))

	# add table body
	table.append(TBODY())

	# add table footer
	th =  [TH(item[1]) for item in th_content]
	tr = TR(Sum(th))
	table.append(TFOOT(tr))

	table_props = {'id': 'issuesList', 'class':'display'}
	table = TABLE(Sum(table), **table_props)
	PRINT( DIV(table, **{'id': 'dynamic', 'class': 'example_alt_pagination'}))
	PRINT( DIV(**{'style': 'height: 20px;clear: both;'}))

def page_getData(**args):
	admin = so.user
	# paging arguments
	start = int(args.get('iDisplayStart'))
	step = int(args.get('iDisplayLength'))
	# searching value
	search = args.get('sSearch').strip()
	# order arguments
	# how many columns to be ordered
	columns = args.get('iSortingCols')

	# column's property name
	propnames = [item[-1] for item in config.issuelist_th_content]
	order = []
	if columns:
		for i in range(int(columns)):
			cindex = '_'.join(('iSortCol', str(i)))
			cindex = int(args.get(cindex))
			prop = propnames[cindex]
			corder =  '_'.join(('iSortDir', str(i)))
			if args.get(corder) == 'asc' :
				corder = '+'
			else:
				corder = '-'
			order.append((prop, corder))
	else:
		order.append((propnames[0], '+'))

	total, data = model.get_issues(admin, propnames, search)
	# restruct the properties values
	res = {}
	# the total items number in result
	res['iTotalRecords'] = total
	# the filtered items number to be displayed
	res['iTotalDisplayRecords'] =  len(data)
	res['aaData'] = []
	# set python default encoding to 'utf8'
	reload(sys)
	sys.setdefaultencoding('utf8')

	if data :
		# sort and order
		# set sort keys
		keys = [propnames.index(item[0]) for item in order]
		data.sort(key=lambda row : tuple([row[i] for i in keys] ))
		if order[0][1] == '-':
			data.reverse()

		# get the data of the displayed page
		end = start + step
		# get data slice in the displayed page from the data
		rslice = 	data[start : end]

		# if ascii chars mixins with no ascii chars will result
		# JSON.encode error, so decode all the data items to unicode.
		d = [[i.decode('utf8') for i in row] for row in rslice]
		res['aaData'] = d

	PRINT( JSON.encode(res, encoding='utf8'))

def _getKeywords(**args):
	search = {'category': 'UserSubmit'}
	ids = model.stringFind('keyword', search)
	if not args.get('props'):
		props = ['id', 'name']
	else:
		props = args.get('props')
	return model.get_items('admin', 'keyword', props, True, ids)

def page_newIssue(**args):
	PRINT( H1('New Message To LOC'))
	PRINT( HR())
	# construct the issue submit form
	# get keywords
	keywords = _getKeywords()

	# constructs the template
	template = []
	# the keywords selects' options
	options = []
	for i,k in enumerate(keywords):
		d = {'value': k[0]}
		if i == 0:
			d .update({'selected':'selected'})
		options.append((d, _(k[1]) ) )

	template.append([_("Keyword:"),{'id':'nkeyword', 'name':'keyword'}, options, 'select'])
	template.append([_("Title:"),{'id':'ntitle', 'name':'title', 'type':'text'}, 'text'])
	template.append([_("Content:"), {'id':'ncontent','name':'content', 'rows':'3', 'cols':'17'}, 'textarea'])

	required = ('title', 'content')
	form = formRender.render_rows(template, {}, required)

	values = config.form_buttons
	sbn = INPUT(**{'id': 'submit',\
				 'type':'submit', \
				 'value': values[0], \
				  'jframe':'no',\
				  'target':'issue_new',\
				 'style': 'width:7em;height:2.6em;font-weight:bold;font-size:1.1em;' })

	cbn = INPUT(**{'type':'button', \
				'name':'cancel',\
				'value': values[1], \
				'style': 'width:7em;height:2.6em;font-weight:bold;font-size:1.1em;'})

	buttons = DIV(Sum((sbn, cbn)), **{'class':'type-button'})
	form.append(buttons)
	action_url = 'issue/issue.ks/createIssue'
	formId = 'issue_new_form'
	PRINT( FORM(Sum(form), **{'id': formId, 'class': 'yform', 'action': action_url}))
	# below is the javascript code for this page
	script = "$(document).ready(function(){$.getScript('issue/jframe.js.pih?formId=%s');});"%formId
	PRINT( SCRIPT(script, type="text/javascript"))

def createIssue(**args):
	# get submit button
	sbn = args.get('submit')
	buttons = config.form_buttons

	if sbn==None:
		# create new message of a issue
		fields = ('title', 'keyword')
		iprops = {}
		[iprops.update({name:  args.get(name)}) for name in fields]
		iprops['nosy'] = so.user
		keyword =iprops.get('keyword')
		if keyword:
			keywords = _getKeywords(props=('id', 'assignedto'))
			for i, a in keywords:
				if int(i) == int(keyword) :
					# add 'assignedto' value
					iprops['assignedto'] = a
					# add 'nosy' value
					iprops['nosy'] = ','.join((so.user, a))

		# For 'keyword' property, it's need to add '+' to the submit value,
		# that means it's a addedd action to 'keyword' property.
		iprops['keyword'] = ''.join(('+', iprops['keyword']))
		mprops = {'content':args.get('content')}
		issueId, msgId = model.edit_issue(so.user, iprops, mprops)

		PRINT( 'alert("New issue id is %s, new message id is %s");'%(issueId, msgId))
		# refresh the show Div component
		PRINT( 'button=document.getElementById("submit");')
		PRINT( 'jFrameSubmitInput(button);')
		# The variable name for the dataTable in javascript namespace,
		# which is defined in manage/userlist.ks/index function.
		table = ('issuesList', 'issueTable')
		PRINT( 'if ($("#%s" ).length != 0){%s.fnDraw();}'%table)
	else:
		show()

def show(**args):
	url = 'issue/issue.ks/page_newIssue'
	d = {'style': 'text-decoration:underline;', 'href': url}
	PRINT( DIV(A(_("New Message To LOC"), **d) , style="font-weight:bold; font-size:2.5em;"))
	PRINT( HR())
	return

def _permissionCheck(**args):
	''' Check the more detailed permissions of the action to 'issue' class.
	   The valid permissions:
	   	super user 'admin' has all the permissions;
	   	users in the 'nosy' list of this issue could view this issue and submit message;
	   	'assignedto' could edit all the permissions;
	   	'creator' could only edit 'title'/'keyword' properties.
	'''
	perms = {}
	# super user 'admin' has all of the permissions
	if so.user == 'admin':
		[perms.update({key : True}) for key in args.keys()]
		perms['pageaction'] = True
		return perms

	if args.get('nosy') and so.user in args['nosy'] :
		perms['pageaction'] = True
	else:
		perms['pageaction'] = False
		return perms

	if so.user in [args.get(name) for name in ('assignedto', 'creator')] :
		hasperm = True
	else:
		hasperm = False
	[ perms.update({key : hasperm}) for key in ('title', 'keyword')]

	# only the assigned person could edit 'nosy' and 'assignedto' properties' values
	if so.user == args.get('assignedto'):
		hasperm = True
	else:
		hasperm = False
	[ perms.update({key : hasperm}) for key in ('nosy', 'assignedto')]

	return perms

def page_showIssueInPage(**args):
	''' Show issues divided into multipage.
	'''
	page = []
	serial = args.get('serial') or ''

	# get issue's property's values
	if not serial :
		return

	id = model.serial2id(serial)
	props = ('title', 'keyword', 'nosy', 'creation', 'creator', 'activity', 'actor', 'messages', 'assignedto')
	values = model.get_item(so.user, 'issue', id, props, keyIsId=True)
	# set the properties to be checked if it has valid permission
	toCheck = copy.deepcopy(values)
	if not values:
		return
	elif values.get('nosy'):
		toCheck['nosy'] = values['nosy'].split(',')

	# add 'serial' which is a key of 'args' to 'toCheck'
	toCheck.update(args)
	# First check if arguments has 'pageaction',
	# if there is no 'pageaction' in arguments
	# then get this page url and remove the first '/' character.
	perms = _permissionCheck(**toCheck)
	pageAction = args.get('pageaction') or THIS.url.split('?')[0][1:]

	if not model.permissionCheck(so.user, so.useroles, pageAction) or not perms.get('pageaction'):
		PRINT( pagefn.prompt(_('You have no permission for this action'), needJs=False))
		page_editIssue()
		return

	for k,v in values.items() :
		if not v:
			values[k] = ''
			continue

		if k == 'keyword':
			values[k] = _(v)
		if k in ('creation', 'activity'):
			if v:
				values[k] = model.time2local( ACCEPTED_LANGUAGES, v)

	# constructs the table component to show issue's information
	tablevalues = [['title', _('Title')],\
				 ['keyword', _('Keywords')],\
				 ['nosy', _('Related Persons')],\
				 ['creator', _('Edit History')] ]
	d = {'style':'font-weight:bold;font-size:0.9em;color:#86B50D'}
	font = {'style':'font-size:1.1em;', 'colspan':2}
	table = []
	for prop, label in tablevalues :
		des = TD(label,**d)
		if prop != 'creator' :
			text = TD(values.get(prop), **font)
		else:
			text = 'Created by %s at %s. Last edited at %s.'\
				   %tuple([values.get(name) for name in ('creator', 'creation', 'activity') ])
			text = TD(_(text), **font)

		tr = TR(Sum((des, text)))
		table.append(tr)

	page.append(TABLE(TBODY(Sum(table)) ))
	# render messages of this issue
	msgids = values.get('messages')

	if not msgids:
		msgs = H4(_('No Messages'))
	else:
		msgnumber = len(msgids)
		mtitle = _("Messages List ---Total %s messages"%msgnumber)
		mstyle = {'style':'font-weight:bold;font-size:1.2em;', 'align':'left'}
		msgs = [ BR(), DIV(mtitle, **mstyle)]
		# append category and pagination table row
		#listId = id
		listId = 'sl'
		tds = [ TD(DIV('', **{'id' : '-'.join((listId, tag))})) for tag in ('flag-dropdown', 'pagination') ]
		mtable = [TR(Sum(tds)) ]

		mprops = ('serial', 'author', 'date', 'content')
		titles = (_('Serial'), _('Author'), _('Date'))
		messages = model.get_items(so.user, 'msg', mprops, link2key=True, ids=msgids)
		# render the html to show these messages
		divs = []
		for message in messages :
			# messages list title
			row = [ DIV(Sum((B(titles[index] + ' : '), TEXT(str(message[index] ))))) \
				    for  index in (0,2) ]
			author = Sum((B(titles[1] + ' : '), SPAN(str(message[1] ), **{'class' : 'flags'})))
			row.append(DIV(author))
			row.append(TEXTAREA(message[-1], **{'class' : 'note', 'style' : 'width : 90%;', 'readonly' : 'readonly'}))
			row.append(HR())
			divs.append(DIV(Sum(row), **{'class' : 'item'}))

		td = TD(DIV(Sum(divs), **{'id' : listId}), colspan=2 )
		mtable.append(TR(td))
		mtable = TABLE(TBODY(Sum(mtable)), **{'style' : 'width:100%;'})
		msgs.append(mtable)
		msgs = Sum(msgs)

	# append messages
	page.append(msgs)

	# set the submit parameters for the url
	paras = {}
	paras['serial'] = serial
	paras['creator'] = values.get('creator')

	[paras.update({name: urllib.quote(values.get(name)) or ''}) \
	for name in ('title', 'keyword', 'nosy', 'assignedto') ]

	actionpath = 	'issue/issue.ks/page_editIssue'
	# check the permission to this action path
	if model.permissionCheck(so.user, so.useroles, actionpath):
		urlparas = ['%s=%s'%(k,v) for k,v in paras.items()]
		url = '?'.join((actionpath, '&'.join(urlparas)))
		d = {	'href': url,\
			'style': 'text-decoration:underline;font-weight:bold; font-size:2.5em;',
			'id' : 'issue_edit_link'}
		head = [TEXT(_("Issue No. %s")%serial), TEXT(14*'-'), A(_('Edit'), **d)]
	else:
		head = [TEXT(_("Issue No. %s")%serial)]

	div = DIV( Sum(head), style="font-weight:bold;")
	[page.insert(0, item) for item in (div, BR()) ]
	PRINT( Sum(page))

	# the javascript for show multi messages in smart list
	if msgids :
		txt = urllib.quote(_("All Message's Writers"))
		js = 'lib/smartlists/smartlists.js.pih?listId=%s&prompt=%s&pageItems=%s'%(listId, txt, 3)
		script = '''$(document).ready(function(){
					$.getScript('%s');
				});'''%js
		PRINT( pagefn.script(script,link=False))

def get_adminList(**args):
	search = args.get('tag')
	filter, search = [args.get(name).strip() for name in ('filter', 'tag')]

	if filter:
		others = [ k for k in args.keys() if k not in ('filter', 'tag') ]
		others = [ i.split(':')[1]  for i in others]
		others.append(filter.split(':')[1])
		filter = others
	else:
		filter = []
		new = []

	conditions = [('roles', 'Admin')]
	if search:
		conditions.append(( 'username' ,search, 'AND'))

	adminlist = model.get_adminlist('admin', ('username', 'roles'), conditions)

	l = []
	if adminlist :
		l = [i[0] for i in adminlist if i[0] not in filter]
		l = [{'caption': v, 'value': v} for v in l]

	#l.extend([{'filter':filter, 'first': new}])
	l = JSON.encode(l)
	PRINT( l)


def page_editIssue(**args):
	PRINT( H1(_('Edit Issue')))
	PRINT( HR())
	if not args:
		return
	elif args.get('keyword'):
		args['keyword'] = ','.join([_(v) for v in args.get('keyword').split(',') ])

	## construct the issue submit form
	toCheck = copy.deepcopy(args)
	perms = _permissionCheck(**toCheck)

	# constructs the template
	template = []
	# The classify fieldset of this issue
	# set the 'serial' of this issue to the form
	template.append([ None,{'id':'serial', 'name':'serial', 'type':'hidden', 'value': args.get('serial')}, 'input'])

	style = {'id':'title', 'name':'title', 'type':'text'}
	if not perms.get('title'):
		style['readonly'] = 'readonly'
	template.append([_("Title:"),style, 'text'])

	# the keywords selects' options
	template.append([_("Keyword:"),{'id':'keyword', 'name':'keyword', 'readonly': 'readonly'}, 'multiselect'])

	# the related persons for this issue
	template.append([_("Related Persons:"),{'id':'nosy', 'name':'nosy', 'readonly': 'readonly'}, 'multiselect'])

	# the assigned person select
	# get nosy
	nosy, assignedto = [args.get(name) for name in ('nosy', 'assignedto') ]
	nosy = nosy.split(',')
	if nosy[0] != '':
		nosy.insert(0, '')
	options = []
	for p in nosy:
		d = {'value': p}
		if p == assignedto:
			d .update({'selected':'selected'})
		options.append((d, p ) )

	attr = {'id':'assignedto', 'name':'assignedto'}
	if not perms.get('assignedto') :
		attr['disabled'] = 'disabled'
	template.append([_("assignedto:"), attr, options, 'select'])
	fieldset = formRender.render_rows(template, args)
	fieldset.insert(0, LEGEND(_('Classify')))

	form = []
	form.append(FIELDSET(Sum(fieldset)))

	# The fieldset for new message added to this issue
	template = []
	template.append([_("Content:"), {'id':'content','name':'content', 'rows':'3', 'cols':'17'}, 'textarea'])
	fieldset = formRender.render_rows(template, args)
	fieldset.insert(0, LEGEND(_('New message for this issue')))
	form.append(FIELDSET(Sum(fieldset)))

	values = config.form_buttons
	bn_style = 'width:7em;height:2.6em;font-weight:bold;font-size:1.1em;'
	sbn = INPUT(**{'id': 'edit',\
				 'type':'submit', \
				 'value': values[0], \
				  'jframe':'no',\
				  'target':'issue_edit',\
				 'style': bn_style})

	cbn = INPUT(**{'type':'button', \
				'name':'cancel',\
				'value': values[1], \
				'style': bn_style})

	buttons = DIV(Sum((sbn, cbn)), **{'class':'type-button'})
	form.append(buttons)
	#action_url = 'issue/issue.ks/postEditIssue?serial=%s'%args.get('serial')
	action_url = 'issue/issue.ks/postEditIssue'
	formId = 'issue_edit_form'
	PRINT( FORM( Sum(form), \
			     **{ 'id': formId,\
			           'class': 'yform',\
			           'action': action_url}))

	# below is the javascript code for this page

	# parameters to script
	keywords = _getKeywords()
	if keywords:
		keywords = ','.join([_(i[1] )  for i in keywords])
	else:
		keywords = ''

	paras = {	'kbutton': _('Change Keywords'),\
			'klabel' : _('Select Keywords'),\
			'kbn_enable': str(int(perms.get('keyword'))),\
			'pbutton' :  _('Change Persons'),\
			'pbn_enable': str(int(perms.get('assignedto'))),\
			'plabel' : _('Select Persons'),\
			'keywords' : keywords,\
			'ok' :  _('OK'),\
			'cancel' : _('Cancel')\
		  }
	url = '&'.join(['='.join((k,v)) for k,v in paras.items()])
	# the script to initialize multiselect buttons
	selectInit = '?'.join(('issue/multiSelect.js.pih', url))
	# the script to initialize the jframe
	frameInit = 'issue/jframe.js.pih?formId=%s'%formId
	script = '''$(document).ready(function(){
				$.getScript('%s');
				$.getScript('%s');
			});'''%(selectInit, frameInit)
	PRINT( SCRIPT(script, type="text/javascript"))

def postEditIssue(**args):
	# get submit button
	sbn = args.get('submit')
	buttons = config.form_buttons

	if sbn == None :
		# edit this issue and its message
		fields = ('title', 'keyword', 'nosy', 'assignedto')
		iprops = {}
		[iprops.update({name:  args.get(name) or ''}) for name in fields]
		keywords = iprops.get('keyword')
		oldkeys = _getKeywords()
		if keywords :
			new = []
			for k in keywords.split(','):
				[new.append(id) for id, value in oldkeys if k == _(value) ]
			iprops['keyword'] = ','.join(new)

		serial = args.get('serial')
		if serial:
			id = model.serial2id(serial)
			content = args.get('content')
			if content :
				mprops = {'content': content}
			else:
				mprops = None
			res = model.edit_issue(so.user, iprops, mprops, serial)
			res = ','.join(res)
		else:
			res = 'Invalid serial for this issue, edit action failed!'

		# refresh the show Div component
		PRINT( ''' button=document.getElementById("edit");\
			      jFrameSubmitInput(button);''')

		# The variable name for the dataTable in javascript namespace,
		# which is defined in manage/userlist.ks/index function.
		table = ('issuesList', 'issueTable')
		PRINT( 'if ($("#%s" ).length != 0){%s.fnDraw();}'%table)
	else:
		pageaction = THIS.url.split('/')
		pageaction[-1] = 'page_showIssueInPage'
		pageaction.pop(0)
		pageaction = '/'.join(pageaction)
		page_showIssueInPage(serial=args.get('serial'), pageaction=pageaction)





