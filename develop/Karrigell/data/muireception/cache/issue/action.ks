['page_createIssueForm', 'page_createIssueAction', 'page_editIssueForm', 'page_getNosy4issue', 'page_editIssueAttrForm']
"""
Pages mainly for actions on 'issue'.
"""
import copy

from HTMLTags import *

# 'THIS.script_url' is a global variable in Karrigell system
APPATH = THIS.script_url[1:]
RELPATH = (lambda p : p.split('/')[0])(THIS.baseurl)

model = Import( '/'.join((RELPATH, 'model.py')), REQUEST_HANDLER=REQUEST_HANDLER )

modules = {'pagefn': 'pagefn.py', 'JSON': 'demjson.py', 'formFn':'form.py'}
[locals().update({k : Import('/'.join(('',v)))}) for k,v in modules.items() ]


# ********************************************************************************************
# Page Variables
# ********************************************************************************************

# get the relative url slice as the application name
APP = pagefn.getApp(THIS.baseurl,1)

# the session object for this page
so = Session()
USER = getattr( so, pagefn.SOINFO['user']).get('username')


# *********************************End********************************************************

# ********************************************************************************************
# The page functions begining
# ********************************************************************************************

PROPS =\
[
	{'name': 'keyword','prompt': _('Keyword'),'validate': [],'required': False, 'type':'textMultiCheckbox'},
	{'name': 'title','prompt': _('Title'), 'validate': [],'required': True},
	{'name': 'message','prompt': _('Content'), 'type': 'textarea', 'validate': [],'required': True},
]

def page_createIssueForm(**args):
	creator = args.get('creator') or USER

	form = []

	# hide fileds to submit
	hideInput = [\
		{'name':'creator','value': creator},
	]

	props = PROPS
	for prop in props:
		prop['oldvalue'] = ''
		prop['type'] = prop.get('type') or 'input'
		prop['id'] = prop['name']
		if prop['name'] == 'keyword':
			values = model.get_items_ByString(USER, 'relation', {'klassname':'keyword', 'relateclass':'issue'}, propnames=('klassvalue',))
			if values and type(values) != type(''):
				options = values[0][0].split(',')
			else:
				options = []
			prop['options'] = options

	div = DIV(Sum(formFn.yform(props)))
	form.append(FIELDSET(div))

	# append hidden field that points out the action type
	[item.update({'type':'hidden'}) for item in hideInput]
	[ form.append(INPUT(**item)) for item in hideInput ]

	formId = 'issueCreation'
	form = \
	FORM(
		Sum(form),
		**{'action': '/'.join((APPATH,'page_createIssueAction')), 'id': formId, 'method':'post','class':'yform'}
	)

	PRINT( form)
	# import js slice
	PRINT( pagefn.script(_createIssueJs(formId, creator),link=False))

	return

def _createIssueJs(formId, creator):
	paras = [ APP, formId, 'position:absolute;margin-left:15em;']
	paras.extend( [ pagefn.BUTTONLABELS.get('confirmWindow').get(key) for key in ('confirm','cancel')] )
	paras = tuple(paras)
	js = \
	"""
	var appName='%s', formId='%s', bnStyle='%s',
	confirmBnLabel='%s',cancelBnLabel='%s';

	var issueCreationFormChk;
	// Load the form validation plugin script
	var issueOptions = {
	    onload:function(){
		issueCreationFormChk = new FormCheck(formId,{
		    submitByAjax: true,
		    onAjaxSuccess: function(response){
			// close modal
			MUI.closeModalDialog();
			// show result
			MUI.notification(response);
		    },

 		    display:{
			errorsLocation : 1,
			keepFocusOnError : 0,
			scrollToFirst : false
		    }
		});// the end for 'issueCreationFormChk' definition

	    }// the end for 'onload' definition
	};// the end for 'options' definition

   	MUI.formValidLib(appName,issueOptions);

	// add action buttons
	var bnContainer = new Element('div',{style: bnStyle});
	$(formId).adopt(bnContainer);

	[
	    {'type':'accept','label': confirmBnLabel},
	    {'type':'cancel','label': cancelBnLabel}
	].each(function(attrs,index){
	    options = {
		txt: attrs['label'],
		imgType: attrs['type'],
		bnAttrs: {'style':'margin-right:1em;'}
	    };
	    button = MUI.styledButton(options);
	    button.addEvent('click',actionAdapter);
	    bnContainer.grab(button);
	});

	function actionAdapter(e){
		var button = e.target;
		var label = button.get('text');

		if(label == confirmBnLabel){
			issueCreationFormChk.onSubmit(e);
		}
		else{
			new Event(e).stop();
			MUI.closeModalDialog();
		};
	};
	"""%paras
	return js

def page_createIssueAction(**args):
	creator, message, title, keyword = [args.get(name) for name in ('creator','message', 'title', 'keyword')]
	iprops = {}
	iprops['title'] = title
	iprops['nosy'] = USER

	# set 'keyword' and 'assignedto' properties
	if keyword and type(keyword) == type(''):
		iprops['keyword'] = keyword.split(',')
		# get nosy list
		users = _getNosy(keyword)
		if users:
			iprops['nosy'] = ','.join(users )

		# get 'assigned' user for this issue
		user = _getAssigned(keyword)
		if user:
			iprops['assignedto'] = user

	mprops = {'content':message}

	# create this issue and corresponding msg
	issueId, msgId = model.edit_issue(creator, iprops, mprops)
	PRINT( _('New issue node id is %s, the id of the new message of this issue is %s.')%(issueId, msgId))
	return

def _getAssigned(keyword):
	user = None
	rows = _getRelationValue('keyword', 'user')
	if rows:
		rows = filter(\
			lambda row: set(row[0].split(',')) == set(keyword.split(',')),\
			rows)
		if rows:
			user = rows[0][1]
	return user

def _getNosy(keyword):
	rows = _getRelationValue('keyword', 'role')
	if not rows:
		return None

	if keyword:
		# if keyword is a subset of 'klassvalue', the relatevalue will be selected
		assignedRoles = [ row[1] for row in rows if  set(keyword.split(',')).issubset(set(row[0].split(','))) ]
	else:
		# in this condition, all the administration roles will be returned
		assignedRoles = [ row[1] for row in rows ]

	if assignedRoles:
		assignedRoles = ','.join(assignedRoles).split(',')
	else:
		# no assigned roles
		return None

	conditions = [['roles', role, 'OR'] for role in assignedRoles ]
	conditions[0].pop(-1)
	nosy = model.get_adminlist(USER, ('username',), conditions)
	if nosy:
		nosy = [ i[0] for i in nosy ]

	return nosy

def _getRelationValue(klass, relateclass):
	rows = model.get_items_ByString( \
		USER,\
		'relation',\
		{'klassname': klass, 'relateclass': relateclass}, \
		propnames=('klassvalue','relatevalue')\
	)
	return rows

ISSUEPROPS =\
[
	{'name': 'title','prompt': _('Title'),'validate': [],'required': True, 'type':'input'},
	{'name': 'keyword','prompt': _('Keywords'),'validate': [],'required': True, 'type':'textMultiCheckbox'},
	{'name': 'nosy','prompt': _('Nosy'),'validate': [],'required': True, 'type':'mtMultiSelect', 'containerStyle':'border: 0.5px solid #DDDDDD;'},
	{'name': 'assignedto','prompt': _('Assinged Person'), 'validate': [],'required': True, 'type':'select'},
]
def page_editIssueForm(**args):
	''' The form page to edit the properties of a roundup.issue class item. '''

	editor = args.get('user') or USER

	# get old values of the properties to be edit
	issueId = args.get('id')
	props = [ attr.get('name') for attr in ISSUEPROPS ]

	oldValues = model.get_item(editor, 'issue', issueId, props, keyIsId=True)
	form = []
	for prop in ISSUEPROPS:
		prop['oldvalue'] = oldValues.get(prop['name']) or ''
		prop['id'] = prop['name']
		if prop['name'] == 'keyword':
			values = model.get_items_ByString(USER, 'relation', {'klassname':'keyword', 'relateclass':'issue'}, propnames=('klassvalue',))
			if values and type(values) != type(''):
				options = values[0][0].split(',')
			else:
				options = []
			prop['options'] = options
		elif prop['name'] == 'nosy':
			url = '/'.join((APPATH,'page_getNosy4issue'))
			query = {NOSYOLD: prop['oldvalue'],}
			query = ['='.join((key, value)) for key,value in query.items()]
			query = '&'.join(query)
			url = '?'.join((url, query))
			prop.update({'dataUrl':url,'fieldName':prop['name'], 'itemsPerPage':3})
		elif prop['name'] == 'assignedto':
			prop['options'] = [{'label': str(item), 'value': str(item)} for item in _getNosy('') ]


	div = DIV(Sum(formFn.yform(ISSUEPROPS)))
	form.append(FIELDSET(div))

	# append hidden field that points out the action type
	#[item.update({'type':'hidden'}) for item in hideInput]
	#[ form.append(INPUT(**item)) for item in hideInput ]

	formId = 'issueEdit'
	form = FORM( \
		Sum(form),\
		**{'action': '/'.join((APPATH,'page_editIssueAction')), 'id': formId, 'method':'post','class':'yform'}\
	)

	PRINT( form)
	# import js slice
	PRINT( pagefn.script(_editIssueJs(formId, editor),link=False))

	return

NOSYOLD = 'oldvalue'
def page_getNosy4issue(**args):
	''' Return the nosy list for each issue. '''
	operator = args.get('user') or USER
	oldValues = args.get(NOSYOLD) or []
	if oldValues :
		oldValues = oldValues.split(',')

	values = _getNosy('')
	values.sort()
	values = [\
		{\
		'text':i.decode('utf8'), \
		'selected': i in oldValues and 'true' or 'false'\
		}\
		for i in values\
	]
	PRINT( JSON.encode(values, encoding='utf8'))
	return

def _editIssueJs(formId, editor):
	paras = [ APP, formId, 'position:absolute;margin-left:15em;']
	paras.extend( [ pagefn.BUTTONLABELS.get('confirmWindow').get(key) for key in ('confirm','cancel')] )
	paras = tuple(paras)
	js = \
	"""
	var appName='%s', formId='%s', bnStyle='%s',
	confirmBnLabel='%s',cancelBnLabel='%s';

	var issueEditFormChk;
	// Load the form validation plugin script
	var issueOptions = {
	    onload:function(){
		issuEditFormChk = new FormCheck(formId,{
		    submitByAjax: true,
		    onAjaxSuccess: function(response){
			// close modal
			MUI.closeModalDialog();
			// show result
			MUI.notification(response);
		    },

 		    display:{
			errorsLocation : 1,
			keepFocusOnError : 0,
			scrollToFirst : false
		    }
		});// the end for 'issueCreationFormChk' definition

	    }// the end for 'onload' definition
	};// the end for 'options' definition

   	MUI.formValidLib(appName,issueOptions);

	// add action buttons
	var bnContainer = new Element('div',{style: bnStyle});
	$(formId).adopt(bnContainer);

	[
	    {'type':'accept','label': confirmBnLabel},
	    {'type':'cancel','label': cancelBnLabel}
	].each(function(attrs,index){
	    options = {
		txt: attrs['label'],
		imgType: attrs['type'],
		bnAttrs: {'style':'margin-right:1em;'}
	    };
	    button = MUI.styledButton(options);
	    button.addEvent('click',actionAdapter);
	    bnContainer.grab(button);
	});

	function actionAdapter(e){
		var button = e.target;
		var label = button.get('text');

		if(label == confirmBnLabel){
			issuEditFormChk.onSubmit(e);
		}
		else{
			new Event(e).stop();
			MUI.closeModalDialog();
		};
	};
	"""%paras
	return js

def _editIssueTitle(issueId, oldValue):
	editor = USER

	# get old values of the properties to be edit
	form = copy.deepcopy(ISSUEPROPS)[:1]
	form[0]['oldvalue'] = oldValue
	form[0]['id'] = form[0]['name']
	div = DIV(Sum(formFn.yform(form)))
	forms = [FIELDSET(div),]

	# append hidden field that points out the action type
	#[item.update({'type':'hidden'}) for item in hideInput]
	#[ form.append(INPUT(**item)) for item in hideInput ]

	formId = 'editIssueTitle'
	form = FORM( \
		Sum(forms),\
		**{'action': '/'.join((APPATH,'page_editTitleAction')), 'id': formId, 'method':'post','class':'yform'}\
	)

	PRINT( form)
	# import js slice
	PRINT( pagefn.script(_editTitleJs(formId, editor),link=False))
	return

def _editTitleJs(formId, editor):
	paras = [ APP, formId, 'position:absolute;margin-left:15em;']
	paras.extend( [ pagefn.BUTTONLABELS.get('confirmWindow').get(key) for key in ('confirm','cancel')] )
	paras = tuple(paras)
	js = \
	"""
	var appName='%s', formId='%s', bnStyle='%s',
	confirmBnLabel='%s',cancelBnLabel='%s';

	var titleEditFormChk;
	// Load the form validation plugin script
	var titleEditOptions = {
	    onload:function(){
		titleEditFormChk = new FormCheck(formId,{
		    submitByAjax: true,
		    onAjaxSuccess: function(response){
			// close modal
			MUI.closeModalDialog();
			// show result
			MUI.notification(response);
		    },

 		    display:{
			errorsLocation : 1,
			keepFocusOnError : 0,
			scrollToFirst : false
		    }
		});// the end for 'issueCreationFormChk' definition

	    }// the end for 'onload' definition
	};// the end for 'options' definition

   	MUI.formValidLib(appName,titleEditOptions);

	// add action buttons
	var bnContainer = new Element('div',{style: bnStyle});
	$(formId).adopt(bnContainer);

	[
	    {'type':'accept','label': confirmBnLabel},
	    {'type':'cancel','label': cancelBnLabel}
	].each(function(attrs,index){
	    options = {
		txt: attrs['label'],
		imgType: attrs['type'],
		bnAttrs: {'style':'margin-right:1em;'}
	    };
	    button = MUI.styledButton(options);
	    button.addEvent('click',actionAdapter);
	    bnContainer.grab(button);
	});

	function actionAdapter(e){
		var button = e.target;
		var label = button.get('text');

		if(label == confirmBnLabel){
			issuEditFormChk.onSubmit(e);
		}
		else{
			new Event(e).stop();
			MUI.closeModalDialog();
		};
	};
	"""%paras
	return js

def page_editIssueAttrForm(**args):
	''' Edit the value of a specified attribute of a issue item. '''
	issueId, oldValue, prop, preferProp, preferValue = \
		[args.get(name) for name in ('issueId', 'oldValue', 'prop', 'preferProp', 'preferValue')]

	if prop == 'title':
		 _editIssueTitle(issueId, oldValue)

	return

