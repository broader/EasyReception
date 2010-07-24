['page_issueDetail', 'page_issueList', 'page_colsModel', 'page_issuesData', 'page_info', 'page_createIssueForm', 'page_createIssueAction']
"""
Pages mainly for administration.
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

# config data object
#INITCONFIG = Import( '/'.join((RELPATH, 'config.py')), rootdir=CONFIG.root_dir)

# *********************************End********************************************************

# ********************************************************************************************
# The page functions begining
# ********************************************************************************************
ISSUELISTCOLUMNS = \
[\
  {'name':'serial','header':_('Serial'),'dataType':'string'},\
  {'name':'title','header':_('Title'),'dataType':'string'}, \
  {'name':'keyword','header':_('Key Words'),'dataType':'string'},\
  {'name':'messages','header':_('Messages Number'),'dataType':'string'},\
  #{'name':'creation','header':_('Creation'),'dataType':'string'}, \
  {'name':'activity','header':_('Activity'),'dataType':'string'}, \
  {'name':'status','header':_('Status'),'dataType':'string'}\
]

SERIALPROP = ISSUELISTCOLUMNS[0].get('name')
def page_issueDetail(**args):
	serial = args.get(SERIALPROP)
	if not serial:
		PRINT( _('Please select a issue by clicking one row on the left table!'))
		return
	title = _('Serial: ') + str(B(serial))
	title = SPAN(title)
	buttons = [\
		pagefn.sexyButton(txt,{'class': 'sexyblue', 'style':'margin-left:10px;'},bnType, 'sexysmall')\
		for txt,bnType in zip(\
			(_('Edit'), _('Delete')),
			('edit', 'delete')
		)
	]
	buttons = SPAN(Sum(buttons),style='margin-left:2em;')

	# issue information, such as title, key words, nosy, edit history
	nodeId = model.serial2id(serial)
	props = ('title', 'keyword', 'nosy', 'creation', 'creator', 'activity', 'actor', 'messages', 'assignedto')
	values = model.get_item(USER, 'issue', nodeId, props, keyIsId=True)
	# set the properties to be checked whether the viewer has a valid permission
	toCheck = copy.deepcopy(values)
	if not values:
		return
	elif values.get('nosy'):
		toCheck['nosy'] = values['nosy'].split(',')

	# add 'serial' which is a key of 'args' to 'toCheck'
	toCheck.update(args)
	# Permission check
	# First, check whether arguments has 'pageaction' field,
	# if there is no 'pageaction' in arguments,
	# then using this page url and remove the first '/' symbol
	perms = _permissionCheck(**toCheck)
	pageAction = args.get('pageaction') or THIS.url.split('?')[0][1:]
	userRoles = getattr( so, pagefn.SOINFO['user']).get('roles').split(',')
	if not model.permissionCheck(USER, userRoles, pageAction) or not perms.get('pageaction'):
		PRINT( _('You have no permission for this action!'))
		return

	PRINT( DIV(Sum((title, buttons,HR(style="padding:0px;height:0.5px;")))))

	# js slice
	PRINT( pagefn.script(_issueDetailJs(),link=False))
	return

def _issueDetailJs():
	paras = [ APP, ]
	paras = tuple(paras)
	js = \
	"""
	var appName="%s";
	function issueDetail(){
		alert('show issue detail');
	};

	MUI.smartList(appName, {'onload': issueDetail});
	"""%paras
	return js

def page_issueList(**args):
	userViewIssueList = 'userViewIssueList'
	PRINT( DIV(**{'id': userViewIssueList}))
	PRINT( pagefn.script( _issueListJs( userViewIssueList), link=False))
	return

ACTIONTAG, ACTIONS, ACTIONLABELS = 'action', ['create','edit'],[_('Create'), _('Edit')]
def _issueListJs(container):
	paras = [ APP, container, ACTIONTAG]
	# filter labels
	paras.extend([pagefn.JSLIB['dataGrid']['filter']['labels'][name] for name in ('action', 'clear')])
	# edit action buttons' labels
	[ paras.extend(item) for item in (ACTIONS, ACTIONLABELS) ]

	paras.extend([ \
		'/'.join((APPATH,name)) \
		for name in ( 'page_colsModel', 'page_issuesData', 'page_createIssueForm', 'page_issueDetail')\
	])

	paras.append(_('Create a new issue'))
	paras.append(pagefn.ISSUE['userView']['rightColumn']['panelId'])
	paras.append(SERIALPROP)
	paras = tuple(paras)
	js = \
	"""
	var appName='%s', container=$('%s'), actionTag='%s',

	// labels for filter buttons
	filterBnLabels=['%s', '%s'],

	// actions and labels for actions
	actions=['%s', '%s'], bnLabels=['%s', '%s'],

	// column model for issue grid
	colsModelUrl='%s',

	// grid data source url
	issueGriDataUrl='%s',

	// create action url
	createUrl='%s', editUrl='%s',

	createTitle='%s', detailPanel='%s', serialProp='%s';

	// global name for datagrid
	var issueGrid = null;

	// Action area
	var actionArea = new Element('div', {style:'padding-bottom:0.3em;'});

	// filter operation area
	var filterContainer= [], filterInput= new Element('input', {style:'margin-right:0.5em'});
	filterContainer.push(filterInput);
	filterBnLabels.each(function(label,index){
		var filterBn = new Element('a', {html:label, href:'javascript:;'});
		filterBn.addEvent('click', function(event){
			alert('china');
		});

		filterContainer.push(filterBn);
	});
	filterContainer.splice(filterContainer.length-1, 0, new Element('span',{html:' | '}));

	/**********************************************************************************
	Return a button container which contains three buttons - 'create','edit','delete'
	***********************************************************************************/
	function issueEditButtons(){
		bnAttributes = [
			{'type':'add','label': bnLabels[0], 'bnSize':'sexysmall', 'bnSkin': 'sexyblue', 'action':actions[0]},
			{'type':'edit','label': bnLabels[1], 'bnSize':'sexysmall', 'bnSkin': 'sexyblue', 'action':actions[1]}
		];

		bnContainer = new Element('span',{style: 'margin-left:10em;'});
		bnAttributes.each(function(attrs,index){
			options = {
				txt: attrs['label'],
			   	imgType: attrs['type'],
				bnAttrs: {'style':'margin-right:1em;'},
				bnSize: attrs['bnSize'],
				bnSkin: attrs['bnSkin']
			};
			button = MUI.styledButton(options);
			button.store('formData', {'action':attrs['action']});
			button.addEvent('click', issueActionAdapter);
			bnContainer.grab(button);
		});
		return bnContainer
	};

	function issueActionAdapter(event){
		new Event(event).stop();
		button = event.target;
		data = button.retrieve('formData');
		actionType = actions.indexOf(data.action);
		switch (actionType){
			case 0 :	// 'create' action
				createIssue(issueGrid, data.action);
				break;
			case 1 :// 'edit' action
				alert('edit action');
				alert(issueGrid.getSelectedIndices().length);
				break;
			case 2:
				alert('delete action');
				break;
		};
	};

	function createIssue(ti, action){
		query = $H();
		query.combine({actionTag:action});
		new MUI.Modal({
         		width: 450, height: 320, y: 80, title: createTitle,
         		contentURL: createUrl,
         		modalOverlayClose: false,
			onClose: function(e){
      				ti.loadData();
      			}
         	});
	};

	actionArea.adopt([filterContainer, issueEditButtons()]);
	container.adopt(actionArea);

	// datagrid body
	var issueGridContainer = new Element('div');
	container.adopt(issueGridContainer);

	function renderIssueGrid(){
		var colsModel=null;

		// load column model for the grid from server side
		var jsonRequest = new Request.JSON({
			async: false, url: colsModelUrl,
			onSuccess: function(json){
    				colsModel = json['data'];
    			}
		}).get();

		issueGrid = new omniGrid( issueGridContainer, {
			columnModel: colsModel,	url: issueGriDataUrl,
			perPageOptions: [15,25,40,60],
			perPage:15, page:1, pagination:true, serverSort:true,
			showHeader: true, sortHeader: true, alternaterows: true,
			resizeColumns: true, multipleSelection:true,
			width:650, height: 400
		});

		issueGrid.addEvent('dblclick', issueGridRowAction);
		issueGrid.addEvent('click', issueGridShow);
	};

	function issueGridShow(event){
		/* Parameters
   		evt.target:the grid object
   		evt.indices:the multi selected rows' indexes
   		evt.row: the index of the row in the grid
		*/
		var data = event.target.getDataByRow(event.row);
		var q = $H();
		q[serialProp] = data[serialProp];
		var url = [ editUrl, q.toQueryString()].join('?');
		var panel = MUI.getPanel(detailPanel);
		panel.options.contentURL = url;
		panel.newPanel();
	};

	function issueGridRowAction(event){
		/* Parameters
   		evt.target:the grid object
   		evt.indices:the multi selected rows' indexes
   		evt.row: the index of the row in the grid
   		*/
	};

	MUI.dataGrid(appName, {'onload':renderIssueGrid});

	"""%paras
	return js



def page_colsModel(**args):
	"""
	Return the columns' model of the grid on the client side, which is used to show users' issues.
	Format:
		[{'header':...,'dataIndex':...,'dataType':...},...]
	"""
	[ item.update({'dataIndex': item.pop('name')}) for item in ISSUELISTCOLUMNS ]
	colsModel = [ pagefn.decodeDict2Utf8(item) for item in ISSUELISTCOLUMNS]
	PRINT( JSON.encode({'data':colsModel}, encoding='utf8'))
	return

DEFAULTSORTON, DEFAULTSORTBY = 'activity', 'DESC'
def page_issuesData(**args):
	# paging arguments
	showPage, pageNumber = [ int(args.get(name)) for name in ('page', 'perpage') ]
	search = args.get('filter') or ''

	# returned data object
	d = {'page':showPage,'data':[],'search':search}

	# column's property name
	showProps = [item.get('name') for item in ISSUELISTCOLUMNS]
	total, data = model.get_issues(USER, showProps, search)
	d['total'] = total

	if data:
		# sort data
		# arguments for sort action
		tags = [ pagefn.JSLIB['dataGrid']['sorTag'][name] for name in ('sortOn', 'sortBy')]
		sorton,sortby = [ args.get(name) or defaultValue for name,defaultValue in zip(
			tags,
			[ DEFAULTSORTON, DEFAULTSORTBY])
		]

		if sorton in ('creation', 'activity'):
			import datetime
			# a temporary function to construct a datetime.datetime object from 'activity' data
			def _cmpActivity(d):
				src = [l.split(sep) for l,sep in zip(d.split('.'), ('-',':'))]
				res = []
				[ [ res.append(int(i)) for i in l] for l in src]
				return datetime.datetime(*res)

			data.sort(key=lambda row: _cmpActivity(row[showProps.index(sorton)]))
			data.reverse()
		else:
			data.sort(key=lambda row: row[showProps.index(sorton)])

		if sortby == 'DESC':
			data.reverse()

		# get the data of the displayed page
		start = (showPage-1)*pageNumber
		end = start + pageNumber - 1
		if end >= total:
			end = total
		# get data slice in the displayed page from the data
		rslice = data[start : end]

		# if ascii chars mixins with non-ascii chars will result
		# JSON.encode error, so decode all the data items to utf8.
		# set python default encoding to 'utf8'
		reload(sys)
		sys.setdefaultencoding('utf8')

		for row in rslice:
			for i,s in enumerate(row) :
				# get 'messages' index
				mindex = [ item.get('name') for item in ISSUELISTCOLUMNS].index('messages')
				if i == mindex:
					s = str(len(s.split(',')))

				row[i] = s.decode('utf8')

		# constructs each row to be a dict object that key is a property.
		encoded = [dict([(prop,value) for prop,value in zip(showProps,row)]) for row in rslice]

		d['data'] = encoded

	PRINT( JSON.encode(d, encoding='utf8'))
	return

def page_info(**args):
	PRINT( DIV(_('Ask help from the staff of the congress!'), **{'class':'info'}))
	return

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

def _permissionCheck(**args):
	'''
	Check detailed access permission to 'issue' class.
	The relation between user role and actions:
	--------------------------------------------------------------
	role/action	view	edit	detailEditFields
	admin		OK	OK
	creator		OK	OK	'title','keyword'
	assignedto	OK	OK	'nosy', 'assignedto'
	nosy		OK	X
	--------------------------------------------------------------
	'''

	perms = {}
	user = args.get('user') or USER
	# super user 'admin' has all of the permissions
	if user == 'admin':
		[perms.update({key: True}) for key in args.keys()]
		perms['pageaction'] = True
		return perms

	if args.get('nosy') and user in args['nosy']:
		perms['pageaction'] = True
	else:
		perms['pageaction'] = False
		return perms

	if user in [args.get(name) for name in ('assignedto', 'creator')]:
		hasperm = True
	else:
		hasperm = False
	[ perms.update({key:hasperm}) for key in ('title', 'keyword')]

	# only the assignedto person could edit 'nosy' and 'assignedto' fields
	if user == args.get('assignedto'):
		hasperm = True
	else:
		hasperm = False

	[perms.update({key:hasperm}) for key in ('nosy', 'assignedto')]
	return perms

