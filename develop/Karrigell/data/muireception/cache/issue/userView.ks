['page_info', 'page_issueDetail', 'page_issueMessages', 'page_issueList', 'page_colsModel', 'page_issuesData']
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

# *********************************End********************************************************

# ********************************************************************************************
# The page functions begining
# ********************************************************************************************

def page_info(**args):
	PRINT( DIV(_('Ask help from the staff of the congress!'), **{'class':'info'}))
	return

ISSUELISTCOLUMNS = \
[\
  {'name':'serial','header':_('Serial'),'dataType':'string'},\
  {'name':'title','header':_('Title'),'dataType':'string'}, \
  {'name':'keyword','header':_('Key Words'),'dataType':'string'},\
  {'name':'messages','header':_('Messages Number'),'dataType':'string'},\
  {'name':'activity','header':_('Activity'),'dataType':'string'}, \
  {'name':'status','header':_('Status'),'dataType':'string'}\
]

SUPPLEMENTLABELS = {'assignedto':_('Assignedto'), 'actor':_('Actor'), 'nosy': _('Nosy')}
SERIALPROP = ISSUELISTCOLUMNS[0].get('name')
def page_issueDetail(**args):
	serial,issueId = [ args.get(name) for name in (SERIALPROP, 'issueId')]
	if serial:
		pass
	elif issueId:
		serial = model.get_item(USER, 'issue', issueId, props=('serial',), keyIsId=True)['serial']
	else:
		PRINT( _('Please select a issue by clicking one row on the left table!'))
		return
	title = _('Serial: ') + str(B(serial))
	title = SPAN(title)

	# issue information, such as title, key words, nosy, edit history
	nodeId = model.serial2id(serial)
	props = ('title', 'keyword', 'nosy', 'creation', 'creator', 'activity', 'actor', 'messages', 'assignedto','status')
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

	PRINT( DIV(title))

	# some detail information fields of this issue
	labels = copy.deepcopy(SUPPLEMENTLABELS)
	[labels.update({item['name']:item['header']}) for item in ISSUELISTCOLUMNS]
	tableFields = []
	showFields = ('title', 'keyword', 'nosy', 'assignedto', 'status', 'activity')
	for field in showFields:
		if field != 'activity':
			value = {'prompt': labels.get(field) or '', 'value':values.get(field) or ''}
		else:
			value = {'prompt': _('Edit History')}
			value['value'] = _('Created by %s at %s, last edit by "%s" at %s.')\
				%tuple([values.get(name) for name in ('creator', 'creation', 'actor', 'activity')])

		tableFields.append(value)

	trs = formFn.render_table_fields(\
		tableFields,\
		cols=1,\
		labelStyle={'label': 'color:#86B50D;font-weight:bold;font-size:12px;'},\
		valueStyle={'label': 'margin-left:10px'}\
	)

	tableId = "issue-%s-info"%(issueId or model.serial2id(serial))
	PRINT( TABLE(TBODY(trs), **{'id':tableId}))

	# list messages of this issue
	messages = values.get('messages')
	number = messages and len(messages) or '0'
	PRINT( _("Messages of this issue"),)

	# add message button
	msgBnId = 'addMessage'
	button = pagefn.sexyButton( \
		_('Add Message'), \
		{'id':msgBnId, 'class': 'sexyblue', 'style':'margin-left:10px;'},\
		'add',\
		'sexysmall'\
	)
	PRINT( button,HR(style="padding:0px;height:0.5px;"))

	msgListContainer = '-'.join(('issue', nodeId, 'msgList'))
	PRINT( DIV(**{'id': msgListContainer}))

	# js slice for show multiful messages in smart list format
	perms = ','.join([str(perms.get(prop)) for prop in showFields[:5]])
	PRINT( pagefn.script(_showMessagesJs(nodeId, msgBnId, tableId, perms, msgListContainer, messages),link=False))
	return

def _showMessagesJs(nodeId, msgBnId, tableId, perms, msgListContainer, msgIds):
	''' Add callback functions for buttons, and show the messages in a smarlt lists format of each issue. '''
	paras = [ APP, nodeId, msgBnId]

	# add edit buttons to each row of the table which shows the properties' values of the issue
	issueEdit = [tableId, perms, _('Edit')]
	paras.extend(issueEdit)
	paras.append( _('Edit Issue'))

	actions = [ \
		'/'.join(('/'.join(THIS.script_url.split('/')[:-1]), 'action.ks', name)) \
		for name in ('page_editIssuePropForm', 'page_addMessageForm')\
	]

	paras.extend(actions)
	paras.append(_('Add New Message'))

	paras.extend([_('Edit Title'), _('Edit Keywords'), _('Edit Nosy'), _('Edit Assignedto'), _('Edit Status')])
	paras.extend(['title', 'keyword', 'nosy', 'assignedto', 'status'])

	# the url to load the messages of this issue
	page = '/'.join((APPATH, 'page_issueMessages'))
	page = '?'.join((page, '='.join(('ids', ','.join(msgIds)))))
	paras.extend([msgListContainer, page ])

	msgCounts = _('Total {total} items.')
	msgPageInfo = _("Page <span class='{pageInfoClass}' >{currentPage}</span> of {pageNumber}")
	filterBnLabel = _('Filter')
	paras.extend([ msgCounts, msgPageInfo, filterBnLabel, ','.join(MSGPROPS) ])
	paras = tuple(paras)
	js = \
	"""
	var appName="%s", issueId="%s", addMsgBn="%s",
	    tableId="%s",

	    // edit issue's properties config
	    perms="%s",	editIssueBnTxt="%s", editDlgTitle="%s",
	    editIssuePropUrl="%s",

	    // the config for adding new message
	    addMessageUrl="%s", addMessageTitle="%s",

	    // the properties' information of the issue
	    propTitles = ["%s", "%s", "%s", "%s", "%s" ],
	    props = ["%s", "%s", "%s", "%s", "%s" ],

	    listContainer="%s", msgUrl="%s",
	    countInfo="%s", pageInfo="%s", filterBnLabel="%s", fields="%s";

	// a handy function to get value from the td component in a tr
	function _getTdValue(table, index,tag){
		tr = $(table).getElements('tr')[index];
		return tr.getElements(tag)[0].get('text').trim();
	};

	// add edit button to the table component which holds the fields of issue
	function editIssueProp(event){
		new Event(event).stop();
		bn = event.target;
		data = bn.retrieve('formData');

		query = $H();
		query.combine({ 'issueId': issueId, 'prop':props[data.propIndex] });
		// get old value of this property
		query['oldValue'] = _getTdValue(tableId,data.propIndex, 'label');
		// get the value of the preferable property
		preferIndex = data.propIndex-1;
		if( preferIndex > 0 && preferIndex < 3){
			query.combine({
				'preferValue': _getTdValue(tableId, preferIndex, 'label'),
				'preferProp': props[preferIndex]
			});
		};

		var url = [editIssuePropUrl, query.toQueryString()].join('?');
		new MUI.Modal({
			width: 400, height: 360, y: 80,
			title: propTitles[data.propIndex],
			contentURL: url,
			modalOverlayClose: false
		});
	};

	function editButton(index){
		options = {
			txt: editIssueBnTxt,
			imgType: 'edit',
			bnAttrs: {'style':'margin-right:1em;'},
			bnSize: 'sexysmall',
			bnSkin: 'sexygreen'
		};
		button = MUI.styledButton(options);
		button.store('formData', {'propIndex':index});
		button.addEvent('click', editIssueProp);
		return button
	};

	// permission to edit this property
	perms = perms.split(',');
	$(tableId).getElements('tr').each(function(tr,index){
		$(tr).setStyle('height', '35px');
		if(index==5 || perms[index] == '0') return;
		td = new Element('td');
		td.grab(editButton(index));
		tr.grab(td);
	});

	var msgFields = fields.split(',');
	function msgRender(liData){
		var container = new Element('div', {style:'border-bottom: 1px solid grey;'});

		data = $H(liData);
		msgFields.each(function(field){
			rowData = data.get(field);
			if(field!='content'){
				label = new Element('span', {style:'font-weight:bold;', html:rowData.label});
				seperator = new Element('span', {html: ' : '});
				value = new Element('span', {html: rowData.value});
				row = new Element('div');
				row.adopt(label, seperator, value);
			}
			else{
				value = new Element('span', {html: rowData.value});
				row = new Element('div', {'class':'note'});
				row.adopt(value);

			};
			container.grab(row);

		});
		return container
	};

	function messagesList(){
		var smartList = new SmartList(listContainer, {
			dataUrl: msgUrl,
			liRender: msgRender,
			filterBnLabel: filterBnLabel,
			pageInfoTmpls: {
				'total': countInfo,
				'page': pageInfo
			},
			contentClass: ''
		});
		$(listContainer).store('smartListInstance',smartList);
	};

	MUI.smartList(appName, {'onload': messagesList});

	// callback function for add message button
	$(addMsgBn).store('issueId', issueId);
	$(addMsgBn).addEvent('click', function (event){
		new Event(event).stop();

		query = $H();
		query.combine({ 'issueId': event.target.retrieve('issueId')});

		url = [addMessageUrl, query.toQueryString()].join('?');
		new MUI.Modal({
			width: 400, height: 250, y: 80,
			title: addMessageTitle,
			contentURL: url,
			modalOverlayClose: false
		});
	});

	"""%paras
	return js

MSGNUMBERPERPAGE = 3
MSGPROPS = ['serial', 'date', 'author', 'content']
def page_issueMessages(**args):
	''' Return a JSON object which holds the contents of messages of specified issue.'''
	perPage, page = [\
		int(args.get(name) or number) \
		for name, number in zip(('itemsPerPage','currentPage'),(MSGNUMBERPERPAGE,1))]

	# get messages
	msgIds = args.get('ids')
	if not msgIds or not msgIds.split(','):
		PRINT( JSON.encode([], encoding='utf8'))
		return

	msgIds = msgIds.split(',')
	mprops = MSGPROPS
	labels = (_('Serial'), _('Date'), _('Author'), _('Content'))
	messages = model.get_items(args.get('user'), 'msg', mprops, link2key=True, ids=msgIds)

	items = []
	if messages:
		for msg in messages :
			items.append([str(x) for x in msg])

	search = args.get('search')
	if search:
		items = filter(lambda i: search in ','.join([str(v) for v in i]), items)

	data = {'total': len(items)}
	data['pageNumber'] = (lambda x,y: x/y + (x%y != 0 and 1 or 0) )(data['total'], perPage)
	begin = perPage*(page-1)
	end = begin + perPage
	items = items[begin:end]

	msgData = []
	for item in items:
		msgData.append(\
			dict(\
				[ (prop,{'value':str(value).decode('utf8'),'label':label}) \
				  for prop,value,label in zip(mprops, item,labels)\
				]\
			)\
		)

	data.update( {'currentPage': page, 'data': msgData })
	PRINT( JSON.encode(data, encoding='utf8'))
	return

def page_issueList(**args):
	userViewIssueList = 'userViewIssueList'
	PRINT( DIV(**{'id': userViewIssueList}))
	PRINT( pagefn.script( _issueListJs( userViewIssueList), link=False))
	return

ACTIONTAG, ACTIONS, ACTIONLABELS = 'action', ['create','delete'],[_('Create'), _('Delete')]
def _issueListJs(container):
	paras = [ APP, container, ACTIONTAG]
	# filter labels
	paras.extend([pagefn.JSLIB['dataGrid']['filter']['labels'][name] for name in ('action', 'clear')])
	# edit action buttons' labels
	[ paras.extend(item) for item in (ACTIONS, ACTIONLABELS) ]

	paras.extend([ \
		'/'.join((APPATH,name)) \
		for name in ( 'page_colsModel', 'page_issuesData', 'page_issueDetail')\
	])

	paras.extend(\
		[ '/'.join(('/'.join(THIS.script_url.split('/')[:-1]), 'action.ks', name))
		  for name in ('page_createIssueForm', 'page_deleteIssueAction')]\
	)

	paras.extend(\
		[
		_('Create a new issue'),
		pagefn.JSLIB['dataGrid']['prompt']['noRow'],
		pagefn.JSLIB['dataGrid']['prompt']['deleteSuccess'],
		pagefn.JSLIB['dataGrid']['prompt']['deleteFailed']
		]\
	)

	# set the right panel id
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

	// edit action url
	editUrl='%s',
	// create action url
	createUrl='%s',
	// delete action url
	delIssueUrl="%s",
	createTitle='%s',
	// delete issues
	propmt4selectRow="%s", prompt4delSuccess="%s", prompt4delFailed="%s",

	detailPanel='%s', serialProp='%s';

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
			var search = '';
			if(index == 0){
				search = filterInput.get('value');
			}
			else filterInput.set('value','');
			// refresh table grid
			var grid = $$('.omnigrid')[0].retrieve('tableInstance');
			grid.options.urlData = {'filter':search};
			grid.loadData();
		});

		filterContainer.push(filterBn);
	});
	// insert a seperator symbol to the container array
	filterContainer.splice(filterContainer.length-1, 0, new Element('span',{html:' | '}));

	/**********************************************************************************
	Return a button container which contains three buttons - 'create','edit','delete'
	***********************************************************************************/
	function issueEditButtons(){
		bnAttributes = [
			{'type':'add','label': bnLabels[0], 'bnSize':'sexysmall', 'bnSkin': 'sexyblue', 'action':actions[0]},
			{'type':'delete','label': bnLabels[1], 'bnSize':'sexysmall', 'bnSkin': 'sexyblue', 'action':actions[1]}
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
			case 1 :
				deleteIssue(issueGrid);
				break;
		};
	};

	function createIssue(ti, action){
		query = $H();
		query.combine({actionTag:action});
		new MUI.Modal({
         		width: 450, height: 320, y: 80, title: createTitle,
         		contentURL: createUrl,
         		modalOverlayClose: false
         	});
	};

	// delete a issue shown in the table
	function deleteIssue(ti){
		if( ti.selected.length == 0){
			MUI.notification(propmt4selectRow);
			return
		};

		var serials = ti.selected.map(function(rowIndex,index){
			return ti.getDataByRow(rowIndex)[serialProp];
		});

		var req = new Request.JSON( {
			url: delIssueUrl,
			onComplete: function(result){
				var info = result.success==1 ? prompt4delSuccess.substitute({'info':result.deleted}): prompt4delFailed ;
				MUI.crawler(info, {width:300, height: 100, closeAfter:5000});
				ti.loadData();
			}
		});
		var q = $H();
		q[serialProp] = serials.join(',');
		req.get(q);
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

		// create a 'omniGrid' instance and assign it to the global variable 'issueGrid'
		issueGrid = new omniGrid( issueGridContainer, {
			columnModel: colsModel,	url: issueGriDataUrl,
			perPageOptions: [15,25,40,60],
			perPage:15, page:1, pagination:true, serverSort:true,
			showHeader: true, sortHeader: true, alternaterows: true,
			resizeColumns: true, multipleSelection:true,
			width:700, height: 400
		});
		issueGrid.addEvent('click', issueGridShow);
		// save the omniGrid instance
		$$('.omnigrid')[0].store('tableInstance',issueGrid);
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
	user = args.get('user') or USER

	# paging arguments
	showPage, pageNumber = [ int(args.get(name)) for name in ('page', 'perpage') ]
	search = args.get('filter') or ''

	# returned data object
	d = {'page':showPage,'data':[],'search':search}

	# a temporary inner function to filter issues
	#def _issueFilter(_nosy, _creator):
	def _issueFilter(*_props):
		_viewPermission = False
		_values = ','.join([ str(i) for i in _props])
		if user in _values and search in _values:
			_viewPermission = True

		return _viewPermission

	# column's property name
	showProps = [item.get('name') for item in ISSUELISTCOLUMNS]

	# constructs the arguments for filtering function
	fargs = copy.deepcopy(showProps)
	if not set(['nosy','creator']).issubset(set(fargs)) :
		fargs.extend(['nosy','creator'])

	total, data = model.get_issues(user, showProps, search, filterFn=_issueFilter, filterArgs=fargs)

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
				src = [ l.split(sep) for l,sep in zip(str(d).split('.'), ('-',':')) ]
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
					s = str(len(s))
					#s = ','.join(s)

				row[i] = str(s).decode('utf8')

		# constructs each row to be a dict object that key is a property.
		encoded = [dict([(prop,value) for prop,value in zip(showProps,row)]) for row in rslice]

		d['data'] = encoded

	PRINT( JSON.encode(d, encoding='utf8'))
	return

def _permissionCheck(**args):
	'''
	Check detailed access permission to 'issue' class.
	The relation between user role and actions:
	--------------------------------------------------------------
	role/action	view	edit	detailEditFields
	admin		OK	OK
	creator		OK	OK	'title','keyword'
	assignedto	OK	OK	'nosy', 'assignedto','status'
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
		perms['pageaction'] = 1
	elif args.get('creator') and user == args['creator']:
		perms['pageaction'] = 1
	else:
		perms['pageaction'] = 0
		return perms

	if user in [args.get(name) for name in ('assignedto', 'creator')]:
		hasperm = 1
	else:
		hasperm = 0
	[ perms.update({key:hasperm}) for key in ('title', 'keyword')]

	# only the assignedto person could edit 'nosy' and 'assignedto' fields
	if user == args.get('assignedto'):
		hasperm = 1
	else:
		hasperm = 0

	#[perms.update({key:hasperm}) for key in ('nosy', 'assignedto', 'status')]
	[perms.update({key:1}) for key in ('nosy', 'assignedto', 'status')]
	return perms


