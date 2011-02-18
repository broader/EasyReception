"""
Pages mainly for administration.
"""
import copy,tools, urllib
from tools import treeHandler

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
INITCONFIG = Import( '/'.join((RELPATH, 'config.py')), rootdir=CONFIG.root_dir)

# The category name for 'hotel' application to 'service' class
SERVICECATEGORY = pagefn.HOTEL.get('categoryInService')

# The id of right panel which shows user's reservations
RESERVESHOWPANEL = pagefn.HOTEL.get('rightColumn')['panelId']

# valid functions for form fields
CHKFNS = ('serviceCategoryChk','serviceNameChk')


# the properties info that will be shown in columns's title in the tree table to show services' list
COLUMNMODEL = [
	{'dataIndex':'name','label':_('Service Name'),'dataType':'string', 'treeColumn':'1', 'properties':{'style':'padding-right:5px;'}},
	{'dataIndex':'description','label':_('Description'),'dataType':'string'},
	{'dataIndex':'price','label':_('Unit Price'),'dataType':'string', 'properties':{'align':'center'}},
	{'dataIndex':'amount','label':_('Total Amount'),'dataType':'number', 'properties':{'align':'center'}},
	{'dataIndex':'detail','label':_('Memo'),'dataType':'string'},
	{'dataIndex':'serial','label':_('Serial'),'dataType':'string','hide':'1'},
	{'dataIndex':'category','label':_('Category'),'dataType':'string','hide':'1'},
	{'dataIndex':'subcategory','label':_('Subcategory'),'dataType':'string','hide':'1'},
	{'dataIndex':'id','label':_('ServiceId'),'dataType':'string','hide':'1'},
	{'dataIndex':'status','label':_('Service Status'),'dataType':'string','hide':'0'}
]

# End*****************************************************************************************


# ********************************************************************************************
# The page functions begining 
# ********************************************************************************************
CONTAINERID = 'userHotelsList'
def page_hotelsList(**args):
	""" The page to show hotels list table."""
	
	print DIV(**{'id':CONTAINERID})
	
	# javascript slice to load data to table
	print pagefn.script( _hotelsListJs(),link=False)	
 	
	return 

ACTIONS = [
	{'type':'house','label':_('Detail Information')},
	{'type':'edit','label':_('Reserve')},
]
VALIDPROPS = ('status', 'id')
def _hotelsListJs():
	paras = [APP, CONTAINERID ]
	paras.extend(VALIDPROPS)
	paras.extend(\
		[ 
			'/'.join((APPATH,name)) 
			for name in ('page_colsModel','page_hotelItems', 'page_capableReserve', 'page_reserveForm')
		]
	)
	paras.extend([ACTIONPROP, ACTIONTYPES[0]])
	
	[ paras.extend( [ action.get(key) for key in ('type','label')]) for action in ACTIONS ] 
	paras.append(_('Please select only one type of room!'))
	paras.append(_('Reservation Edit'))
	paras = tuple(paras)
	js = \
	'''
	var appName='%s', container='%s', 
	validProps = ['%s', '%s'],
	colsModelUrl='%s', rowDataUrl='%s',
	reserveValidUrl='%s', reserveEditUrl='%s',
	action={'%s':'%s'};
	createReserveBnAttributes = [{'type':'%s','label':'%s'},{'type':'%s','label':'%s'}],
	rowSelectErr = '%s', editModalTitle='%s';	
	
	var treeTable;
	var unReserveErr = ''; 
	
	/***********************************************************************
	Add buttons on the bottom of the hotel list table
	************************************************************************/
	function addButton(ti){
	    // Parameter 'ti'- the TreeTable instance
	    bnContainer = new Element('div',{style: 'text-align:left;'});
	    ti.container.grab(bnContainer);
		
	    createReserveBnAttributes.each(function(attrs,index){
			
		options = {
		    txt: attrs['label'],
		    imgType: attrs['type'],
		    bnAttrs: {'style':'margin-right:1em;'}	
		};
			
		button = MUI.styledButton(options);
		button.addEvent('click',actionAdapter.pass(index,this));
			
		bnContainer.grab(button);
			
	    },ti);
		
	};
	
	function actionAdapter(index){
	    trs = this.getSelectedRows();
	    if(trs.length != 1){	// only one row should be selected
		MUI.alert(rowSelectErr);
		return
	    };
		
	    if(index==0){
		hotelDetail(this);
	    }
	    else{
		reservation(this);
	    };
	};
	
	// set a global Request.JSON instance for send validation url for check the capability of selected row
	var couldReserve = null;
	var validRowRequest = new Request.JSON({
	    url: reserveValidUrl,
	    async:false, 
	    onComplete:function(json){
		if(json.ok == '1'){couldReserve=true;}
		else{ unReserveErr = json.info ;};
	    }
	});

	function reservation(ti){
	    tr = ti.getSelectedRows()[0];
		
	    // judge whether selected row is a room and has not been reserved by operator
	    couldReserve = false, options = {};
	    validProps.each(function(prop){
		options[prop] = ti.getCellValueByRowId(tr.get('id'), prop);
	    });
	    validRowRequest.get(options);

	    // popup modal dialog to reserve this type of room
	    if(!couldReserve) {
		MUI.notification(unReserveErr);
		return;
	    };
		
	    // get service id
	    query = ti.getRowDataWithProps(tr);
	    query.combine(action);
	    url = [reserveEditUrl, query.toQueryString()].join('?');	
	    new MUI.Modal({
		width: 450, height: 400, y: 80, title: editModalTitle,
		contentURL: url,
		modalOverlayClose: false,
	    });

	};
	
	function hotelDetail(ti){
	    alert('show hotel detail information action');
	};
	
	/****************************************************************** 
	Initialize tree table 
	******************************************************************/
	// options for TreeTable class initialization
	var options = {
	    onload:function(){
		treeTable = new TreeTable( 
		    container,				
		    {
			colsModelUrl:colsModelUrl,
			treeColumn: 0,					
			dataUrl: rowDataUrl,
			idPrefix: 'hotel-',
			initialExpandedDepth: 1,
			renderOver: addButton
		    }
		);// the end for 'treeTable' definition
			
	    }// the end for 'onload' definition
	};// the end for 'options' definition
	
	// initialize TreeTable class
	MUI.treeTable(appName,options);	
	'''%paras
	return js

def page_colsModel(**args):
	""" 
	Return the columns' model of the trid on the client side, 
	which will be used to show services list.
	Format:
		[{'label':...,'dataIndex':...,'dataType':...},...]
	"""
	colsModel = copy.deepcopy(COLUMNMODEL)
	for item in colsModel:
		for k,v in item.items():
			if type(v) == type(''):
				item.update({k:v.decode('utf8')})
			elif type(v) == type({}):
				item.update({k: pagefn.decodeDict2Utf8(v)})
					
	print JSON.encode(colsModel,encoding='utf8')	
	return

def _getServiceItems(category,props=None):
	# get items from 'service' class in database
	search = {'category' : category}
	items = model.get_items_ByString(USER, 'service', search, props, link2key=True)
	return items

def _data2tree(items,idFn,pidFn):
	""" Constructs a tree.
	Parameters:
	items -  the data to be structured to a tree
	idFn - the function to the node's id 
	pidFn - the function to the id of the parent of a node
	"""
	# tree construntion Class
	return treeHandler.TreeHandler(items, idFn, pidFn)
	
def _node2json(node):
	data = {'data': node.data,'depth':node.depth(),'parent':'', 'id':node.id,'isLeaf':'0'}	
	
	if node.parent:
		data['parent'] = node.parent.id
		
	if node.is_leaf():
		data['isLeaf'] = '1'
	 
	return data

def _treeFlattenData(category,props, idFn, pidFn):
	items = _getServiceItems(category,props)
	treeHandler = _data2tree(items,idFn,pidFn)
	nodes = treeHandler.flatten()
	
	# handle each row of data, transform them to client's required format
	sorted = [ _node2json(node) for node in nodes]
	# sorted[1:] - pop out the first root node which has no data
	return sorted[1:]

def page_hotelItems(**args):
	category = SERVICECATEGORY
	
	# filter the last three column that are  action clolumns 
	props = [item.get('dataIndex') for item in COLUMNMODEL ]
		
	# filter the root category items	
	nameIndex = props.index('name')	
	idFn = lambda i: i[props.index('id')]
	pidFn = lambda i: i[props.index('subcategory')]
	rows = filter( lambda item: item['data'][nameIndex], _treeFlattenData(category,props,idFn,pidFn))	
	
	for index,item in enumerate(rows):
		data = item['data']
		for i,value in enumerate(data):
			if value:
				data[i] = value.decode('utf8')
			else:
				data[i] = ''.decode('utf8') 
		
		item['data'] = data
		
	print JSON.encode(rows,encoding='utf8')
	return

def page_hotelInfo(**args):
	print H2('The detail information for one hotel')
	return

def page_roomReservation(**args):
	containerId = '-'.join((USER, 'hotelReservation'))
	print DIV(**{'id': containerId})
	print pagefn.script(_roomReservationJs(containerId, args.get('panelId')),link=False)

	return

def _roomReservationJs(container, panelId):
	if not panelId:
	    panelId = RESERVESHOWPANEL
	paras = [container, panelId]
	paras.extend([ '/'.join((APPATH, name)) for name in ('page_reservationData','page_reserveForm','page_reserveEditAction')])
	paras.extend([_('Total reservations'), _('Total Cost'), _('Subtotal'), ACTIONPROP])
	paras.extend(ACTIONTYPES[1:])
	# add buttons' labels
	paras.extend((_('Edit'), _('Delete')))
	
	paras = tuple(paras)
	js = \
	'''
	var container=$('%s'), panelId='%s', 
	dataUrl='%s', editUrl='%s', deleteUrl='%s',
	totalNumber='%s', totalCost='%s', subLabel='%s',
	actionTag='%s', actions=['%s','%s'],
	bnLabels=['%s', '%s'];

	// the 'colon' symbol
	var colon = new Element('span',{html:'&nbsp;:&nbsp;'});

	// common seperator element
	var sep = new Element('span',{html:'&nbsp;,&nbsp;'});
	
	// subtotal cost information
	var subCostInfo = new Element('div');
	subCostInfo.inject(container, 'bottom');
	container.grab( new Element('hr', {style:'padding:0.1em;'}));
	
	// append labels for subtotal information
	// total reservations amount
	var totalReserves = new Element('span',{html:totalNumber});
	var totalReservesValue = new Element('span', {style:'color:red;font-weight:bold;font-size:1.2em;'});
	subCostInfo.adopt(totalReserves,colon.clone(),totalReservesValue, sep.clone());

	// total cost
	var subCostInfoLabel = new Element('span',{html:totalCost});
	var subCostValue = new Element('span', {style:'color:red;font-weight:bold;font-size:1.2em;'});
	subCostInfo.adopt(subCostInfoLabel,colon.clone(),subCostValue);
	
	// detail information for reserved rooms 
	var ul = new Element('ul',{style:'list-style-type:none;overflow-y:scroll;height:400px;'});
	ul.inject(container, 'bottom');
	
	var request4roomReserve = new Request.JSON({url:dataUrl, onComplete: renderUl}).get();
	
	function renderUl(data){
	    data.each(renderLi);
	    subCostValue.set('text', '￥'+subCostValue.retrieve('value').toString());
	    totalReservesValue.set('text', ul.getElements('li').length);
	};
	
	function rendeRow4Li(elements){
	    div = new Element('div');
	    elements.each(function(el){div.adopt(el);});
	    return div 
	};
	
	var cssTempl = $H({'price':'uprice','amount':'amount'});
	function _renderField(data, name){
	    label = new Element('span',{html:data.prompt});
	    if(cssTempl.has(name)){
		label.addClass(cssTempl[name]);
	    };
		
	    if(name == 'amount'){
		value = new Element('span',{html:data.value.toInt()});
	    }
	    else if(name == 'price'){
		value = new Element('span',{html: '￥'+data.value.toInt().toString()});
	    }
	    else{
		value = new Element('span',{html:data.value});
	    };
	    return [label, colon.clone(), value]
	};
	
	
	function renderFields(fields, data){
	    var elements = [];
	    fields.each(function(name){
		elements.push(_renderField(data[name],name));
		elements.push(sep.clone());			
	    });
	    elements.pop();
	    return elements
	};

	var liTemplate = new Element('li',{style:'border-bottom:gainsboro 2px solid;padding: 3px 0;'});
	function renderLi(data){
	    li = liTemplate.clone();	
	    li.addClass('hotel');
	    ul.adopt(li);
		
	    // reservation serial and creation time
	    li.adopt(rendeRow4Li(renderFields(['serial','creation'],data)));

	    // hotel and room information
	    hotel = new Element('span',{html:data.hotel.value, 'class':'hotelname'});
	    room = new Element('span',{html:data.name.value});
	    li.adopt(rendeRow4Li([hotel, sep.clone(), room]));

	    // room description
	    desPrompt = new Element('span',{html:data.description.prompt});
	    des = new Element('span',{html:data.description.value});
	    li.adopt(rendeRow4Li(renderFields(['description'],data)));
		
	    // cost information
	    fields = renderFields(['price','amount'],data);

	    label = new Element('span',{html: subLabel, 'class':'sub'});
	    value = data.price.value.toFloat()*data.amount.value.toInt();
	    sub = new Element('span',{html: '￥'+value.toInt().toString() });
	    subCostValue.store('value', (subCostValue.retrieve('value') || 0).toFloat() + value);
	    fields.extend([sep.clone(),label, colon.clone(),sub]);
	    li.adopt(rendeRow4Li(fields));

	    // user's addenum requestion
	    fields = renderFields(['memo'],data);
	    li.adopt(rendeRow4Li(fields));
		
	    // add action buttons
	    li.adopt(reserveEditButtons(data.serial.value));

	};

	/***********************************************************************
	Return a button container which contains two buttons
	************************************************************************/
	function reserveEditButtons(serial){
	    var bnAttributes = [
		{'type':'edit','label': bnLabels[0], 'bnSize':'sexysmall', 'bnSkin': 'sexyblue', 'action':actions[0]},
		{'type':'delete','label': bnLabels[1], 'bnSize':'sexysmall', 'bnSkin': 'sexyred', 'action':actions[1]}
	    ];	

	    bnContainer = new Element('div',{style: 'text-align:right;'});
		
	    bnAttributes.each(function(attrs,index){
		var options = {
		    txt: attrs['label'],
		    imgType: attrs['type'],
		    bnAttrs: {'style':'margin-right:1em;'},	
		    bnSize: attrs['bnSize'],
		    bnSkin: attrs['bnSkin']
		};
			
		button = MUI.styledButton(options);
		// save the serial and action value to button
		button.store('formData', {'serial':serial, 'action':attrs['action']});
		button.addEvent('click',reserveActionAdapter);
		bnContainer.grab(button);
	    });
		
	    return bnContainer		
	};

	function reserveActionAdapter(event){
	    new Event(event).stop();
	    button = event.target;
	    data = button.retrieve('formData');
	    query = $H({'panelId':panelId});
	    query[actionTag] = data.action;
	    query['serial'] = data.serial;
	    if(actions.indexOf(data.action)==0){	// 'edit' action
		url = [editUrl, query.toQueryString()].join('?');	
		new MUI.Modal({
		    width: 450, height: 400, y: 80, title: '',
		    contentURL: url,
		    modalOverlayClose: false
		});
	    }
	    else{	// 'delete' action
		info = 'Delete Rservation:<br>' + query.serial;
		MUI.confirm(info, delReservation.pass(query), {});
	    };
		
	};

	function delReservation(querystr){
	    url = [deleteUrl, querystr.toQueryString()].join('?');	
	    // set some options for Request.HTML instance
	    deletRequest = new Request({async:false});
	    deletRequest.setOptions({
		url: url,
		onSuccess: function(text, xml){
		    MUI.notification(text);
		    MUI.refreshPanel(panelId);
		}
	    });
	   
	    deletRequest.get();
	};
	
	'''%paras
	return js

RESERVESHOWPROPS = ('target', 'amount', 'memo','creation', 'serial')
RESERVEFIELDSPROMPT = {'amount':_('Amount'), 'memo':_('Addendum'), 'creation':_('Action Day'), 'serial': _('Reservation Serial')}
def page_reservationData(**args):
	# get reservations for this user
	booker = args.get('booker') or USER
	reservations = model.get_reservations( USER, booker, props=RESERVESHOWPROPS) or []
	values = []
	for reserve in reservations:
		serviceId = reserve[0]
		roomInfo = _roomInfo(serviceId)	
		# format Date object 
		reserve[3] = str(reserve[3])[:10]
		miscValues = dict([(name,value) for name,value in zip(RESERVESHOWPROPS[1:],reserve[1:])])	
		miscValues = _addPrompt(miscValues,RESERVEFIELDSPROMPT)
		roomInfo.update(miscValues)
                roomInfo = pagefn.decodeDict2Utf8(roomInfo)
		values.append(roomInfo)
		# get hotel and room information
	print JSON.encode(values,encoding='utf8')	
	return

def _addPrompt(dictValues, dictPrompts):
	[ dictValues.update({key: {'value':dictValues.pop(key),'prompt':label}}) for key,label in dictPrompts.items() ]
	return dictValues

def _roomInfo(serviceId) :
	"""
	Return the information for a type of room.
	The format of returned information is:
	{
	'name':{'value': valueOfName, 'prompt': promptOfName},
	'description':...,
	'price':...,
	'subcategory':...,
	'hotel':...}
	"""
	# get hotel name
	roomProps = ['name', 'description', 'price', 'subcategory']
	roomValues = model.get_item(USER, 'service', serviceId, roomProps, keyIsId=True)
	# hotel info
	hotelId = roomValues.pop('subcategory')
	hotel = model.get_item(USER, 'service', hotelId, ('name',), keyIsId=True).get('name')
	roomValues['hotel'] = hotel
	# add prompt to each item
	labels = {'name':_('Room Type'), 'description': _('Description'), 'price': _('Unit Price'), 'hotel': _('Hotel')}
	roomValues = _addPrompt(roomValues, labels)	
	return roomValues	

def _chkReserved(serviceId, booker):
	# get reservations for thi booker	
	reservations = model.get_reservations( USER, booker, props=('target',)) or []
	reservations = [item[0] for item in reservations ]
	valid = (serviceId not in reservations) and 1 or 0
	return valid

def page_capableReserve(**args):
	status2chk, serviceId = [ args.get(prop) for prop in VALIDPROPS ]
	
	# response information
	info = []

	# get the status that could be reserved
	status = INITCONFIG.getData('service')['hotel']['configProperty'][0]['value'] 
	validStatus = (not status2chk in (None,'')) and (status2chk in status) and 1 or 0
	
	if not validStatus:
		info.append(_('Selected hotel could not be reserved!'))
	
	# confirm that user had not reserved this room
	hasReserved = _chkReserved(serviceId, USER)
	if not hasReserved:
		info.append(_('Selected room has been reserved by you!'))
	
	print JSON.encode({'ok': validStatus and hasReserved, 'info': ' '.join(info)})
	return

ACTIONPROP,ACTIONTYPES = 'actionType',['create','edit', 'delete']
def page_reserveForm(**args):
	action, panelId = args.get(ACTIONPROP), args.get('panelId')
	table = []
	# room fields
	fields, fieldsProp = [], ['name', 'description', 'price']
	
	actionIndex = ACTIONTYPES.index(action)
	oldvalues = {}
	
	def _getFields(props, values):
		_fields = []
		for prop in props :
			# label for each field
			data = filter(lambda i : i.get('dataIndex')== prop ,COLUMNMODEL)[0]
			if prop != 'name':
				info = {'prompt':data.get('label'),'value':values.get(prop)}
			else:
				info = {'prompt': _('Room Type'),'value':values.get(prop)}
			_fields.append(info)
		return _fields

	if actionIndex == 0 :	# 'create' action
		serviceId = args.get('id') 
		# hotel info
		# get hotel name
		hotelId = args.get('subcategory')
		if hotelId:
			hotel = model.get_item(USER, 'service', hotelId, ('name',), keyIsId=True).get('name')
		else:
			hotel = ''
		
		# get room info	
		fields = _getFields(fieldsProp, args)
		formargs = [action, serviceId]

	elif actionIndex == 1:	# 'edit' action
		# get the serial of this reservation	
		reserveSerial = args.get('serial')
		reserveProps = [ item['name'] for item in RESERVEFORMPROP]
		reserveProps.extend(('target','id'))
		oldvalues = model.get_items_ByString(USER, 'reserve', {'serial':reserveSerial},reserveProps)[0]
		# get room info
		reserveId,serviceId = [oldvalues.pop(-1) for i in range(2)]
		oldvalues = dict([(k,v) for k,v in zip(reserveProps[:2],oldvalues)])
		roomInfo = _roomInfo(serviceId)
		# hotel name
		hotel = roomInfo.pop('hotel').get('value')
		[roomInfo.update({name: value.get('value')}) for name,value in roomInfo.items()]
		#print roomInfo
		fields = _getFields(fieldsProp, roomInfo)
		formargs = [action, reserveId, oldvalues, panelId]
	
	attrs = {'style' : 'text-align: center; font-size: 1.6em;font-weight:bold;'}
	table.append( CAPTION(hotel, **attrs))
	trs = formFn.render_table_fields(fields,cols=1,labelStyle={},valueStyle={'td':'padding-left:2em;'})
	table.append(trs)	
	
	# information for hotel and room
	print DIV(TABLE(Sum(table)), style='margin-left:1em;')
	
	# reserve form
	_reserveForm(*formargs)
	
	return

RESERVEFORMPROP =\ 
[
	{'name': 'amount','prompt': _('Amount'),'validate': ['number'],'required': True},
	{'name': 'memo','prompt': _('Addendum'), 'type': 'textarea', 'validate': [],'required': False},
]
def _reserveForm(action, target, oldvalues={}, panelId=None):
	form = []

	# hide fileds to submit
	if ACTIONTYPES.index(action) in (0,1):
		hideInput = [\
			{'name':'booker','value':USER}, 
			{'name': ACTIONPROP,'value':action},
			{'name': 'target', 'value':target}
		]

	props = RESERVEFORMPROP
	for prop in props:
		prop['oldvalue'] = oldvalues.get(prop['name']) or ''
		prop['type'] = prop.get('type') or 'input'

	div = DIV(Sum(formFn.yform(props)))
	form.append(FIELDSET(div))
	
	# append hidden field that points out the action type
	[item.update({'type':'hidden'}) for item in hideInput]
	[ form.append(INPUT(**item)) for item in hideInput ]
	

	bnStyle = 'position:absolute;margin-left:15em;' 
	formId = 'reserveEditForm'
	form = \
	FORM( 
		Sum(form), 
		**{'action': '/'.join((APPATH,'page_reserveEditAction')), 'id': formId, 'method':'post','class':'yform'}
	)
				
	print DIV(form,style='')
	
	# import js slice
	print pagefn.script(_reserveFormJs(formId, bnStyle, panelId), link=False)
	return

def _reserveFormJs(formId, bnStyle, panelId):
	paras = [ APP, panelId or RESERVESHOWPANEL, formId, bnStyle]
	paras.extend( [ pagefn.BUTTONLABELS.get('confirmWindow').get(key) for key in ('confirm','cancel')] )
	paras = tuple(paras)
	js = \
	'''
	var appName='%s', panelId='%s',
	formId='%s', bnStyle='%s',
	confirmBnLabel='%s',cancelBnLabel='%s';
	
	var reserveEditFormChk;
	// Load the form validation plugin script
	var options = {
	    onload:function(){ 
		reserveEditFormChk = new FormCheck( formId,{
		    submitByAjax: true,
		    onAjaxSuccess: function(response){
			if(response == 1){ 
			    MUI.closeModalDialog(); 
			    // rfresh the corresponding MUI.Panel
			    MUI.refreshPanel(panelId);	
			}
			else{ MUI.notification('Action Failed');};               
		    },            
		    
 		    display:{
			errorsLocation : 1,
			keepFocusOnError : 0, 
			scrollToFirst : false
		    }
		});// the end for 'reserveEditFormChk' definition
			
	    }// the end for 'onload' definition
	};// the end for 'options' definition
 
   	MUI.formValidLib(appName,options);
	
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
		reserveEditFormChk.onSubmit(e);
	    }
	    else{
		new Event(e).stop();
		MUI.closeModalDialog();
	    }; 
	};
	'''%paras
	return js

def page_reserveEditAction(**args):
	# get action type
	action = args.pop(ACTIONPROP)
	
	# response tag 
	ok = 0
	actionIndex = ACTIONTYPES.index(action)
	if actionIndex == 0 :	# 'create' action
		rid = model.create_item( USER, 'reserve', args)
		if rid:
			ok = 1
	elif actionIndex == 1 :	# 'edit' action
		reserveId = args.pop('target') 
		actionRes = model.edit_item( USER, 'reserve', reserveId, args, 'edit', keyIsId=True)
		if actionRes:
			ok = 1
	elif actionIndex == 2 : # 'delete' action
		reserveSerial = args.get('serial')
		rid = model.get_items_ByString(USER, 'reserve', {'serial':reserveSerial}, ('id',))[0][0]
		model.delete_item( USER, 'reserve', rid, isId=True)
		ok = ' '.join((rid, _('has been deleted!')))
		
	print ok
	return

def page_hotelNames(**args):
    """ Return a json object which holds the information of each hotel."""
    props = ['name','description','detail', 'serial', 'subcategory']
    items = _getServiceItems(SERVICECATEGORY,props)
    # fileter the room items
    items = filter(lambda item: item[0] and not item[4], items)
    #items = filter(lambda item: not item[3], items)
    for index,row in enumerate(items):
	items[index] = [(i or '').decode('utf8') for i in row[:4] ]

    print JSON.encode(items,encoding='utf8')	
    return

def page_hotelNameList(**args):
    """ The page just show a table which holds the name list for the hotel."""
    TableId = 'hotelNameList'
    print TABLE(**{'id':TableId})
    
    paras = [TableId,]
    headers = [_('Name'), _('Description'), _('Memo'), _('Serial')]
    paras.extend(headers)
    paras.append('/'.join((APPATH, 'page_hotelNames')))
    paras = tuple(paras)
    js = \
    '''
    var table="%s", headers=["%s","%s","%s","%s"],
	hotelInfoUrl="%s";

    var hotelTable = new HtmlTable($(table));

    function setVisibility(row){
	[0,1,2,3].each(function(index){
	    var toSet = {content:row[index] || "/"};
	    if([0,1,2].contains(index)){
		// just align the content to the left margin
		toSet.properties = {style:'text-align:left;'};
	    }
	    else{
		// 'serial' property need's not shown
		toSet.properties = {style:'display:none;'};
	    };
	    row[index] = toSet;
	});
	
	return row
    };

    // set headers
    hotelTable.set('headers', setVisibility(headers));

    // get hotels' information
    var request = new Request.JSON({
	url: hotelInfoUrl,
	async:false, 
	onComplete:function(json){
	    json.each(function(row){
		hotelTable.push(setVisibility(row));
	    }); 
	}
    });
    request.get();

    '''%paras
    print pagefn.script(js, link=False)
    return

