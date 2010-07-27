"""
def _formFieldsConstructor(values):	
	# start to render edit form
	needProps = values.keys()
	props = [item for item in PROPS if item['name'] in needProps]
	for prop in props:
		name = prop['name']
		prop['id'] = name	
		prop['oldvalue'] = ''
				
		if not prop.get('type'):
			prop['type'] = 'text'
			
		if name == 'status':
			# set 'status' field to 'textMultiCheckbox' type
			prop['type'] = 'textMultiCheckbox'
			prop['options'] = [] 
			items = model.get_items_ByString(USER, 'status', {'category':'service'},('name',))
			if items and type(items) == type([]):
				prop['options'] = [i[0] for i in items]
		
		if not prop.has_key('required'):
			prop['required'] = False	 	
	
	return props

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
			values = model.get_items_ByString( USER, 'relation', {'klassname':'keyword', 'relateclass':'issue'}, propnames=('klassvalue',))
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
	var grid = window[issueGrid];
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
		return None 

	# if keyword is a subset of 'klassvalue', the relatevalue will be selected
	assignedRoles = [ row[1] for row in rows if  set(keyword.split(',')).issubset(set(row[0].split(','))) ]
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
"""

