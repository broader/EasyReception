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

def _getKeywords():
	values = model.get_items_ByString(USER, 'relation', {'klassname':'keyword', 'relateclass':'issue'}, propnames=('klassvalue',))
	if values and type(values) != type(''):
		options = values[0][0].split(',')
	else:
		options = []
	return options

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
			prop['options'] = _getKeywords()
			 
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
	
	print form
	# import js slice
	print pagefn.script(_createIssueJs(formId, creator),link=False)		
	
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

			if(response==0) return;

			// refresh table grid
			$$('.omnigrid')[0].retrieve('tableInstance').loadData();

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
	print _('New issue node id is %s, the id of the new message of this issue is %s.')%(issueId, msgId)
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
		return [] 

	if keyword:
		# if keyword is a subset of 'klassvalue', the relatevalue will be selected
		assignedRoles = [ row[1] for row in rows if  len(set(keyword.split(',')).intersection(set(row[0].split(',')))) > 0 ]
	else:
		# in this condition, all the administration roles will be returned
		assignedRoles = [ row[1] for row in rows ]
	
	if assignedRoles:
		assignedRoles = ','.join(assignedRoles).split(',')
	else:
		# no assigned roles 
		return [] 

	conditions = [['roles', role, 'OR'] for role in assignedRoles ]
	# the first item need not 'OR' operator symbol
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
	{'name': 'keyword','prompt': _('Keywords'),'validate': [],'required': True},
	{'name': 'nosy','prompt': _('Nosy'),'validate': [],'required': True, 'containerStyle':'border: 0.5px solid #DDDDDD;'}, 
	{'name': 'assignedto','prompt': _('Assinged Person'), 'validate': [],'required': True},
	{'name': 'status','prompt': _('Status'), 'validate': [],'required': True},
]

NOSYOLD = 'oldvalue'
def page_getNosy4issue(**args):
	''' Return the nosy list for each issue. '''
	operator = args.get('user') or USER
	oldValues = args.get(NOSYOLD) or []
	if oldValues :
		oldValues = oldValues.split(',')
	
	keywords = args.get('keyword') or ''
	
	values = _getNosy(keywords)
	
	values.sort()
	values = [\
		{\
		'text':i.decode('utf8'), \
		'selected': i in oldValues and 'true' or 'false'\
		}\ 
		for i in values\
	]
	print JSON.encode(values, encoding='utf8')
	return

def _getIssueStatus():
	''' Return a list containing all the values of the 'status' items whose 'category' property is 'issue'. '''
	props = ('category','name','order')
	status = model.filterByPropValues( USER, 'status', props, {'category':'issue'})	
	if status:
		nameIndex = props.index('name')
		status = [item[nameIndex] for item in status ]
	else:
		status = []
	return status

def _propFormAdapter(**args):
	''' Construct filed's values corresponding to the property name. '''
	oldValue, prop, preferProp, preferValue = \
		[args.get(name) or '' for name in ('oldValue', 'prop', 'preferProp', 'preferValue')]

	# get old values of the properties to be edit
	form = [item for item in ISSUEPROPS if item['name'] == prop ]
	form[0]['oldvalue'] = oldValue
	form[0]['id'] = prop
	if prop == 'keyword':
		form[0]['type'] = 'check'
		form[0]['name'] = prop
		form[0]['options'] = [{'label':keyword, 'value':keyword} for keyword in _getKeywords()]
	elif prop == 'nosy':
		form[0].update({
			'type':'mtMultiSelect', 
			'containerStyle':'border: 0.5px solid #DDDDDD;'
		})

		url = '/'.join((APPATH,'page_getNosy4issue'))
		query = {preferProp: preferValue}
		query = ['='.join((key, value)) for key,value in query.items()]
		query = '&'.join(query)
		url = '?'.join((url, query))
		form[0].update({'dataUrl':url,'fieldName':prop, 'itemsPerPage':5})
		
	elif prop == 'assignedto':
		form[0]['type'] = 'radio'
		form[0]['name'] = prop
		form[0]['options'] = [{'label': person, 'value': person} for person in preferValue.split(',')]
	elif prop == 'status':
		form[0]['type'] = 'radio'
		form[0]['name'] = prop
		form[0]['options'] = [{'label': status, 'value': status} for status in _getIssueStatus()]

	return form

def page_editIssuePropForm(**args):
	''' print the html form for editing the value of a specified attribute of a issue item. '''
	issueId, prop =	[args.get(name) for name in ('issueId', 'prop')]
	
	editor = USER
	# get old values of the properties to be edit
	form = _propFormAdapter(**args)
	
	div = DIV(Sum(formFn.yform(form)))
	forms = [FIELDSET(div),]
	
	# append hidden field that points out the action type
	hideInput = [{'value':editor, 'name':'editor'}, {'value':issueId, 'name':'issueId'},]
	[item.update({'type':'hidden'}) for item in hideInput]
	[ forms.append(INPUT(**item)) for item in hideInput ]

	formId = 'editIssueProp-%s'%prop
	form = FORM( \
		Sum(forms),\ 
		**{'action': '/'.join((APPATH,'page_editIssuePropAction')), 'id': formId, 'method':'post','class':'yform'}\
	)
	
	print form
	# import js slice
	print pagefn.script(_editIssuePropJs(formId, issueId),link=False)

	return

def _editIssuePropJs(formId, issueId):
	paras = [ APP, pagefn.ISSUE['userView']['rightColumn']['panelId'], issueId, formId, 'position:absolute;margin-left:15em;']
	paras.extend( [ pagefn.BUTTONLABELS.get('confirmWindow').get(key) for key in ('confirm','cancel')] )
	paras.append('/'.join(('/'.join(THIS.script_url.split('/')[:-1]), 'userView.ks', 'page_issueDetail')))
	
	# the tables' id which shows detail information of the issue in the page
	paras.append('-'.join(('issue',issueId,'info')))

	# the properties of the issue that could be edit
	paras.extend(['title', 'keyword', 'nosy', 'assignedto', 'status'])

	paras = tuple(paras)
	js = \
	"""
	var appName="%s", infoPanel="%s", issueId="%s", formId="%s", 
	    bnStyle="%s", confirmBnLabel="%s",cancelBnLabel="%s",
	    infoUrl="%s", infoTableId = "%s",
	    editProps = ["%s", "%s", "%s", "%s", "%s" ];

	var propEditFormChk;
	// Load the form validation plugin script
	var propEditOptions = {
	    onload:function(){ 
		propEditFormChk = new FormCheck(formId,{
		    submitByAjax: true,
		    onAjaxSuccess: function(response){
			// close modal
			MUI.closeModalDialog(); 
			
			if(response==0) return;

			// refresh table grid
			$$('.omnigrid')[0].retrieve('tableInstance').loadData();

			// refresh the showing value of the property in the cell of the table component 
			res = response.split(':');
			var propIndex = editProps.indexOf(res[0]);
			$(infoTableId).getElements('tr')[propIndex]
			.getElements('label')[0]
			.set('text', res[1]);
		    },            
		    
 		    display:{
			errorsLocation : 1,
			keepFocusOnError : 0, 
			scrollToFirst : false
		    }
		});// the end for 'propEditFormChk' definition
			
	    }// the end for 'onload' definition
	};// the end for 'options' definition
 
   	MUI.formValidLib(appName,propEditOptions);
	
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
			propEditFormChk.onSubmit(e);
		}
		else{
			new Event(e).stop();
			MUI.closeModalDialog();
		}; 
	};
	"""%paras
	return js

def page_editIssuePropAction(**args):
	''' Edit the value of the property of issue and save the result to database. '''
	editor, issueId = [args.pop(name) for name in ('editor','issueId')]
	iprops = copy.deepcopy(args) 
	
	# judge whether the argument includes multiful values of checkboxes
	if len(iprops.keys()) == 1:
		key = iprops.keys()[0]
		# filter the checkbox value and restore the property name
		if '-' in key :
			key,value = iprops.popitem()
			iprops[key.split('-')[0]] = value

	elif len(iprops.keys()) > 1:
		key, value = iprops.popitem()
		key = key.split('-')[0]
		values = iprops.values()
		values.append(value)
		iprops = {key: ','.join(values)}

	# this action doesn't edit message of this issue	
	mprops = {}

	# save the prop and new value to be saved to database
	prop, newValue = iprops.items()[0]	
	# edit the value of the property of this issue  
	issueId, msgId = model.edit_issue(editor, iprops, mprops, issueId, True)
	print ':'.join((prop,newValue))
	return

def page_addMessageForm(**args):
	''' Return a form to add new message to a issue item. '''
	issueId = args.get('issueId') 
	
	editor = USER
	# get old values of the properties to be edit
	form = [{\
		'name': 'messages','id': 'messages', 'prompt': _('New Message'),
		'validate': [],'required': True, 'type':'textarea', 'oldvalue':'',
		'style': 'width:90.5%; height:9em;'
	},]

	div = DIV(Sum(formFn.yform(form)))
	forms = [FIELDSET(div),]
	
	# append hidden field that points out the action type
	hideInput = [{'value':editor, 'name':'editor'}, {'value':issueId, 'name':'issueId'},]
	[item.update({'type':'hidden'}) for item in hideInput]
	[ forms.append(INPUT(**item)) for item in hideInput ]

	formId = 'addMessage-issue-%s'%issueId
	form = FORM( \
		Sum(forms),\ 
		**{'action': '/'.join((APPATH,'page_addMessageAction')), 'id': formId, 'method':'post','class':'yform'}\
	)
	
	print form
	# import js slice
	print pagefn.script(_addMessageJs(formId, issueId),link=False)

	return

def _addMessageJs(formId, issueId):
	paras = [ APP, pagefn.ISSUE['userView']['rightColumn']['panelId'], issueId, formId, 'position:absolute;margin-left:15em;']
	paras.extend( [ pagefn.BUTTONLABELS.get('confirmWindow').get(key) for key in ('confirm','cancel')] )
	paras.append('/'.join(('/'.join(THIS.script_url.split('/')[:-1]), 'userView.ks', 'page_issueDetail')))
	paras = tuple(paras)
	js = \
	"""
	var appName="%s", infoPanel="%s", issueId="%s", formId="%s", 
	    bnStyle="%s", confirmBnLabel="%s",cancelBnLabel="%s",
	    infoUrl="%s";	

	var addMsgFormChk;
	// Load the form validation plugin script
	var addMsgOptions = {
	    onload:function(){ 
		addMsgFormChk = new FormCheck(formId,{
		    submitByAjax: true,
		    onAjaxSuccess: function(response){
			// close modal
			MUI.closeModalDialog(); 
			
			if(response==0) return;

			// refresh table grid
			$$('.omnigrid')[0].retrieve('tableInstance').loadData();

			// refresh the detail information of this issue
			var msgList = $(['issue',issueId, 'msgList'].join('-')).retrieve('smartListInstance');
			var url = msgList.options.dataUrl;
			var urlArgs = url.split('?');
			var ids = urlArgs[1].parseQueryString()['ids'];				
			ids = [ids,response.toInt().toString()].join(',');
			msgList.options.dataUrl = [urlArgs[0], $H({'ids':ids}).toQueryString()].join('?');
			msgList.reset();
		    },            
		    
 		    display:{
			errorsLocation : 1,
			keepFocusOnError : 0, 
			scrollToFirst : false
		    }
		});// the end for 'issueCreationFormChk' definition
			
	    }// the end for 'onload' definition
	};// the end for 'options' definition
 
   	MUI.formValidLib(appName,addMsgOptions);
	
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
			addMsgFormChk.onSubmit(e);
		}
		else{
			new Event(e).stop();
			MUI.closeModalDialog();
		}; 
	};
	"""%paras
	return js

def page_addMessageAction(**args):
	''' Add a new message to the specified issue and save the result to database. '''
	editor, issueId, message = [args.pop(name) for name in ('editor','issueId', 'messages')]
	iprops = {}
	mprops = {'content':message}
	
	# edit the value of the property of this issue  
	issueId, msgId = model.edit_issue(editor, iprops, mprops, issueId, True)
	print msgId
	return
