"""
Pages mainly for services view and edit action.
"""
import copy,tools
from tools import treeHandler

from HTMLTags import *

# 'THIS.script_url' is a global variable in Karrigell system
APPATH = THIS.script_url[1:]
RELPATH = (lambda p : p.split('/')[0])(THIS.baseurl)

model = Import( '/'.join((RELPATH, 'model.py')), REQUEST_HANDLER=REQUEST_HANDLER )

modules = {'pagefn': 'pagefn.py', 'JSON': 'demjson.py', 'formFn':'form.py'}
#modules = {'pagefn' : 'pagefn.py',  'JSON' : 'demjson.py', 'formFn':'form.py'}
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
#CONFIG = Import( '/'.join((RELPATH, 'config.py')), rootdir=CONFIG.root_dir)

# valid functions for form fields
CHKFNS = ('serviceCategoryChk','serviceNameChk')

# the properties to be edit in form
PROPS =\ 
[
	{'name':'category','prompt':_('Category'),'validate':[''.join(('~',CHKFNS[0])),],'required':True},
	{'name':'subcategory','prompt':_('Subcategory'),'validate':[],'required':True},
	{'name':'serial','prompt':_('Service Serial'),'validate':[]},
	{'name':'name','prompt':_('Service Name'),'validate':[''.join(('~',CHKFNS[1])),],'required':True},
	{'name':'description','prompt':_('Description'),'validate':[],'type':'textarea'},
	{'name':'price','prompt':_('Unit Price'),'validate':[]},
	{'name':'amount','prompt':_('Amount'),'validate':[]},
	{'name':'detail','prompt':_('Supplement'),'validate':[],'type':'textarea'},
	{'name':'status','prompt':_('Service Status'),'validate':[]}
]

GETPROPSLABEL = lambda name : [item.get('prompt') for item in PROPS if item.get('name')== name ][0]

# the id for category creation form 
SERVICEEDITFORM = 'serviceEditForm'

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
	{'dataIndex':'status','label':_('Service Status'),'dataType':'string','hide':'0'},
	{'dataIndex':'id','label':_('ServiceId'),'dataType':'string','hide':'1'}
]

# End*****************************************************************************************


# ********************************************************************************************
# The page functions begining 
# ********************************************************************************************

def _getCategory( ):
	# get value from 'service' class in database
	values = model.get_items('admin', 'service', ('category',))
	if type(values) == type(''):
		values = []
	else:
		values = [item[0] for item in values ]
		values = [c for c in set(values)]
		values.sort()
	return values
	
def _getTabs(panelId):
	# get service catrgory
	categories = _getCategory()
	
	# constructs the tabs list
	tabs = []
	for category in categories:
		query = '&'.join(['='.join((name,value)) for name,value in {CATEGORYTAG:category,'panel':panelId}.items()])
		d = { \
			'text':category,\
			'id':''.join((category,'Tab')),\
			'url':'/'.join((APPATH, '?'.join(('page_showServiceLayout', query))))}
		
		tabs.append(d)
	
	tabs.append({'id':'addNewService', 'url':'/'.join((APPATH,'page_createCategoryInfo'))})
	return tabs	
	
def index(**args):
	panelId = args.get('panelid')
	
	lis = []
	tabs = _getTabs(panelId)
	for index,tab in enumerate(tabs):
		props = {'id':tab.get('id')}
		if index == 0:
			props['class'] = 'selected'
		
		text = tab.get('text')
		if text: 	
			lis.append(LI(A(tab.get('text')),**props))
		else:
			# append the logo for add new service
			lis.append(LI(A(IMG(src='/'.join((RELPATH,'images/additional','add.png')))),**props))
	
	tabsId = 'panelTabs'
	print DIV(UL(Sum(lis),**{'id': tabsId,'class':'tab-menu'}),**{'class':'toolbarTabs'})
	_indexJs(panelId,tabsId)
	return

def _indexJs(panelId,tabsId):
	content = \
	"""
	var panelId='%s',tabsId='%s';
	MochaUI.initializeTabs(tabsId);
	"""%(panelId,tabsId)	
	
	js = [content,]
	tabs = _getTabs(panelId)
	for tab in tabs :
		slice = \
		"""
		$('%s').addEvent('click', function(e){
			MochaUI.updateContent({
				'element':  $(panelId),
				'url':       '%s'
			});
		});
		"""%tuple([tab.get(name) for name in ('id','url')])
		js.append(slice)
	
	content = \
	"""
	$(tabsId).getElements('li')[0].fireEvent('click');
	"""
	js.append(content)
	js = '\n'.join(js)
	print pagefn.script(js,link=False)
	return 

def page_info(**args):
	print P('For editing servcie, please select a category of service by clicking the tabs on right operation panel first !')
	return
	
# set suplement administration info
SERVICEADMIN = {getattr(pagefn,'HOTEL')['categoryInService']:{'url':'service/adminHotels.ks',}}
SERVICEADMINSUFFIX = 'admin'

def page_showServiceLayout(**args):
	ctag = CATEGORYTAG
	category,panel = [ args.get(attr) for attr in (ctag, 'panel')]
	
	# temporary function to add 'category' query to url
	urlGenerator = lambda url : '?'.join((url, '='.join((ctag,category))))

	# try to get the url for MUI.Panel, 
	# which maybe supplied supplement administration functions
	adminUrl = '' 
	for key,value in SERVICEADMIN.items():
		if key.upper() == category.upper():
			adminUrl = value.get('url') 
			break
	
	adminUrl = adminUrl and urlGenerator(adminUrl)

	#container = '-'.join((category, SERVICEADMINSUFFIX))
	container = panel

	print DIV(**{'id':container})

	# add javascript slice
	# set service list url for MUI.Panel
	url = '/'.join((APPATH,'page_showService'))
	url =  urlGenerator(url)

	paras = [container, url, adminUrl]
	paras = tuple(paras)
	js = \
	"""
	var containerId='%s', listUrl='%s',adminUrl='%s';

	var mainColumn = [containerId, 'column'].join('-'),
	listPanel = [containerId, 'panel'].join('-');
	if(adminUrl==''){
		new MUI.Column({ 
			id: mainColumn,	container:containerId, placement:'main',
			sortable: false
		});
		
		new MUI.Panel({
			id: listPanel, header:false, column: mainColumn,
			contentURL: listUrl
		});
	}
	else{
		// create MUI.Columns
		var rightColumn = [containerId, 'right', 'column'].join('-');	
		var columnIds = [mainColumn,rightColumn];
		var columnAttrs = [
			{'id':columnIds[0],'placement':'main','resizeLimit':[100,200],'width':null},
			{'id':columnIds[1],'placement':'right','resizeLimit':[400,500],'width':500}
		];
	
		columnAttrs.each(function(attr){
			new MUI.Column({
				container: containerId, id: attr.id, placement: attr.placement, 
				sortable: false, width: attr.width, resizeLimit: attr.resizeLimit 
			});
		});

		
		var adminPanel = [containerId, 'admin','panel'].join('-');
		// create MUI.Panels
		[
			{'column':columnIds[0],'id': listPanel,'url': listUrl},
			{'column':columnIds[1],'id': adminPanel,'url': adminUrl}		
		].each(function(attrs){
			new MUI.Panel({
				id: attrs.id,
				column: attrs.column, 
				header: false,
				contentURL: attrs.url,
				//onExpand: MUI.accordionPanels.pass(attrs.id)
			});
		
		});

		/*
		new MUI.Panel({
			id: listPanel, header:false, column: mainColumn,
			contentURL: listUrl
		});
		
		var adminPanel = [containerId, 'admin','panel'].join('-');
		new MUI.Panel({
			id: adminPanel, header:false, column: rightColumn,
			contentURL: adminUrl
		});
		*/

	};
	"""%paras
	print pagefn.script(js, link=False)
	return

PROPS4TABLE =  ['serial', 'name','subcategory','description', 'detail', 'price', 'amount']
TABLECONTAINER = 'servcieTableDiv'
CONTAINERID = lambda category : '-'.join((category,TABLECONTAINER))

ADDSERVICEBUTTON = 'addService'
ADDSERVICEBUTTONID = lambda category : '-'.join((category,ADDSERVICEBUTTON))

def page_showService(**args):
	"""
	Render the services' list.
	"""
	category = args.get('category')
	
	print DIV(**{'id':CONTAINERID(category)})
	
	# javascript slice to load data to table
	print pagefn.script( _showServiceJs(category),link=False)	
 	
	return 

CATEGORYTAG = 'category'
ACTIONS = [
	{'type':'add','label':_('Add')},
	{'type':'edit','label':_('Edit')},
	{'type':'delete','label':_('Delete')}
]

ACTIONTYPES = [item.get('type') for item in ACTIONS]
ACTIONLABELS = [item.get('label') for item in ACTIONS]
ACTIONPROP,PARENTNAMEPROP = ('action','parentName')
def _showServiceJs(category):
	paras = [APP, CATEGORYTAG, category, CONTAINERID(category)]
	paras.extend(\
		['/'.join((APPATH,name)) for name in \
		('page_colsModel','page_serviceItems', 'page_editService', 'page_serviceEditAction')\
		]\
	)
	
	paras.append(_('Create New Subategory'))
	paras.extend([_('Create a new subcategory for service'), _('Edit Service Information')])	
	
	[ paras.extend(l) for l in (ACTIONTYPES,ACTIONLABELS)]
	paras.extend([ACTIONPROP, PARENTNAMEPROP])
	
	# 'edit' and 'delete' should select a row first
	paras.append(_('For this type of action, please select a row first !'))
	
	# could not select more than one row
	paras.append(_('Please select no more than one row !'))
	
	paras = tuple(paras)
	js = \
	"""
	var appName='%s', categoryInfo=['%s','%s'],
	container='%s', colsModel='%s',
	rowsUrl='%s', actionUrl='%s', deleteUrl='%s',
	addCategoryBnLabel='%s',
	modalTitles = {'category':'%s', 'service':'%s'},
	actionTypes = ['%s', '%s', '%s'],
	actionLabels = ['%s', '%s', '%s'],
	actionProp = '%s', parentName='%s',
	noneRowErr = '%s', moreRowErr='%s';
	
	var treeTable;
	
	var modalOptions = {
		width:600, height:480, modalOverlayClose: false,
   		onClose: function(e){
   		// refresh table's body
   		treeTable.refreshTbody();
   	}
	};
	
	// The function to add action buttons to each row in the table.
	function addButton(ti){		
		// Parameter 'ti'- the TreeTable instance
		bnContainer = new Element('div',{style: 'text-align:left;'});
		ti.container.grab(bnContainer);
		
		// add 'add','edit','delete' buttons
		actionTypes.each(function(actionType,index){
			options = {
				txt: actionLabels[index],
			   imgType: actionType,
				bnAttrs: {'style':'margin-right:1em;'}	
			};
			
			button = MUI.styledButton(options);
			button.addEvent('click',action2service.pass(index,this));
			
			bnContainer.grab(button);
			
		},ti);
	};
	
	/*
	The action to service item.
	*/
	function action2service(index){
		trs = this.getSelectedRows();
		if(trs.length == 0 && [1,2].contains(index)){	// 'edit' or 'delete' action
			MUI.alert(noneRowErr);
			return
		}
		else if(trs.length > 1 && [0,1,2].contains(index)){
			MUI.alert(moreRowErr);
			return
		};
		
		query = '';
		
		if(trs.length == 0){	// create a new subcategory
			query = categoryInfo.join('='); 
		}
		else if(trs.length > 0 ){
			tr = trs[0];
			// get data of this row
			query = this.getRowDataWithProps(tr);
			
			// if node has parent, add its parent name to query object
			parentId = null, parentInnerId = tr.retrieve('parent');
			if (parentInnerId){
				parentId = this.genRowId(parentInnerId);
			};
			
			parentNameValue = '';
			if(parentId){
				parentNameValue = this.getCellValueByRowId(parentId,'name');
			};
				
			query[parentName] = parentNameValue;
			query[actionProp] = actionTypes[index];
			
			// transform the query json object to a url query string
			query = query.toQueryString();
		}
		
		if([0,1].contains(index)){
			// set the really action url
			url = [actionUrl, query].join('?');
			
			// the modal to edit a service item  
			modalOptions.contentURL = url;
			
			modalOptions.title = (trs.length!=0)? modalTitles.service : modalTitles.category ;
			new MUI.Modal(modalOptions);
		}
		else {	// 'delete' action
			MUI.confirm('Delete service items:', delServiceItems.bind(this), {});
		};
	};
	
	/******************************************************************
	Service item delelting action
	******************************************************************/
	function delServiceItems(isConfirm){
		if(isConfirm.toInt()==1){return};
		
		jsonRequest = new Request.JSON({async:false});    
	        
  		// set some options for Request.JSON instance
                jsonRequest.setOptions({
        	url: deleteUrl,
  	        onSuccess: function(res){
         		MUI.notification(res);
         		this.refreshTbody();
         		}.bind(this)
      		});
	   
		tr = this.getSelectedRows()[0];
	   
	   	data = {'id':this.getInnerId(tr.id),'category':this.getCellValueByRowId(tr.id,'category')};
	   	data[actionProp] = actionTypes[2];
	   	jsonRequest.get(data);
		
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
					colsModelUrl:colsModel,
					treeColumn: 0,					
					dataUrl: [rowsUrl, categoryInfo.join('=')].join('?'),
					idPrefix: 'service-',
					initialExpandedDepth: 2,
					renderOver: addButton
				}
			);// the end for 'treeTable' definition
			
		}// the end for 'onload' definition
	};// the end for 'options' definition
	
	// initialize TreeTable class
	MUI.treeTable(appName,options);

	"""%paras
	return js

def _decodeDict2Utf8(d):
	[d.update({k:v.decode('utf8')}) for k,v in d.items()]
	return d
	
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
				item.update({k:_decodeDict2Utf8(v)})
				
		#[item.update({k:v.decode('utf8')}) for k,v in item.items()]		
	print JSON.encode(colsModel,encoding='utf8')	
	return

def _getServiceItems(category,props=None):
	# get items from 'service' class in database
	search = {'category' : category}
	items = model.get_items_ByString(USER, 'service', search, props, needId=False,link2key=True)
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
	#return tree.flatten()
	
def _node2json(node):
	data = {'data': node.data,'depth':node.depth(),'parent':'', 'id':node.id,'isLeaf':'0'}	
	
	if node.parent:
		data['parent'] = node.parent.id
		
	if node.is_leaf():
		data['isLeaf'] = '1'
	 
	return data

def _treeFlattenData(category,props, idFn, pidFn):
	items = _getServiceItems(category,props)
	#idFn = lambda i: i[props.index('id')]
	#pidFn = lambda i: i[props.index('subcategory')]
	treeHandler = _data2tree(items,idFn,pidFn)
	nodes = treeHandler.flatten()
	# handle each row of data, transform them to client's required format
	# sorted[1:] - pop out the first root node which has no data
	sorted = [ _node2json(node) for node in nodes]
	return sorted[1:]

def page_serviceItems(**args):
	"""
	"""
	category = args.get(CATEGORYTAG)
	
	# filter the last three column that are  action clolumns 
	#props = [item.get('dataIndex') for item in COLUMNMODEL[:-3]]
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

def page_createCategoryInfo(**args):
	"""
	"""
	info = _("Here you can create a new category of service.It's need to define the name and decritpiton of the new category.")
	containerId = 'createNewCategory'
	print DIV(**{'class':'note','style':'width:40%;','id':containerId})
	
	paras = [info, containerId,_('Create A New Category For Service')]
	paras.extend([_('Create a new category for service'),'/'.join((APPATH,'page_editService'))])	
	script = \
	"""
	var info="%s", containerId='%s', bnLabel='%s', 
	modalInfo={'title':'%s', 'url':'%s'};
	
	$(containerId).grab(new Element(
		'h6',
		{'html':info}
	));
	
	$(containerId).grab(new Element('br'));
	
	$(containerId).grab(new Element(
	    'button',
	    {
	        'html': bnLabel,
		'events':{
		    'click': function(e){
			new Event(e).stop();
					
			// the dialog to create a new subcategory of service
			new MUI.Modal({
			    width:600, height:380, contentURL: modalInfo.url,
			    title: modalInfo.title,
			    modalOverlayClose: false,
			    onClose: function(e){
			    	MUI.refreshMainPanel();
			    }
			});
		    }
		}
	    }
	));
	
	"""%tuple(paras)
	print pagefn.script(script,link=False)	
	return

def _formFieldsConstructor(values,setOldValue=False):	
	# start to render edit form
	needProps = values.keys()
	props = [item for item in PROPS if item['name'] in needProps]
	for prop in props:
		name = prop['name']
		prop['id'] = name	
		prop['oldvalue'] = ''
		if setOldValue:
			prop['oldvalue'] = values.get(name) or ''			
				
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
	
def page_editService(**args):
	props = copy.deepcopy(args)	
	actionType = None
	action,category = [ args.get(name) for name in (ACTIONPROP,'category') ]
	
	# store the files to be shown and hidden
	info,hideInput = [],[]
	
	# judge the action type
	# has action value?
	# -> has action
	# ---> action value shows its type
	#
	# -> no action
	# ---> has category?
	# ------> no category, it's category creating action
	# ------> has category, it's subcategory creating action
	
	if not action :
		if category:	# category 'create' action
			props.pop('category')
			[props.update({name:None,}) for name in ('name','description')]			
			info.append( {'prompt':GETPROPSLABEL('category'), 'value':args.get('category')} )
			hideInput.append( {'name':'category', 'value':args.get('category')} )			
			props = _formFieldsConstructor(props)
		else:	# subcategory 'create' action
			[ props.update({name:None,}) for name in ('category','description')]
			props = _formFieldsConstructor(props,False) 
		
		hideInput.append({'name':ACTIONPROP,'value':ACTIONTYPES[0]})
	else:
		hideInput.append({'name':ACTIONPROP,'value':action})
		names = [item.get('name') for item in PROPS if item.get('name') not in ('category','subcategory','serial')]
		index = ACTIONTYPES.index(action) 
		if index == 0:	# add action			 
			[props.pop(name) for name in props.keys() if name not in names ]			
			props = _formFieldsConstructor(props)
			
			info.append( {'prompt':GETPROPSLABEL('category'),'value':args.get('category')} )
			hideInput.append( {'name':'category','value':args.get('category')})
			info.append({'prompt':GETPROPSLABEL('subcategory'),'value':args.get('name')})
			hideInput.append({'name':'subcategory', 'value':args.get('id')})			
		elif index == 1 :	# edit action
			[props.pop(name) for name in props.keys() if name not in names ]			
			props = _formFieldsConstructor(props,True)
			# for 'edit' action, it's no need to check service 'name' property
			filter(lambda i: i['name']=='name', props)[0]['validate'] = []
			
			info.append( {'prompt':GETPROPSLABEL('category'),'value':args.get('category')} )
			info.append({'prompt':GETPROPSLABEL('subcategory'),'value':args.get(PARENTNAMEPROP)})
			info.append({'prompt':GETPROPSLABEL('serial'),'value':args.get('serial')})
			
			hideInput.append({'name':'id', 'value':args.get('id')})
	
	# show the fields in 'info' list before html Form Element
	if info:
		[ item.update({'prompt':''.join((item.get('prompt') or '',':'))}) for item in info ]
		labelStyle = {'label':'font-weight:bold;font-size:1.2em;color:dackblue;', \
						  'td':'text-align:right;'}
						  
		valueStyle = {'label':'color:#ff6600;font-size:1.2em;', 'td':'text-align:left;width:auto;'}
						  
		print TABLE(formFn.render_table_fields(info, 2, labelStyle, valueStyle), style='border:none;')
	
	# render the fields to the form	
	form = []
	# get the OL content from formRender.py module
	if len(props) < 4:	
		div = DIV(Sum(formFn.yform(props)))
		form.append(FIELDSET(div))
		bnStyle = 'position:absolute;margin-left:15em;'
	else:
		interval = int(len(props)/2)+1	
		style = 'border-right:1px solid #DDDDDD;'	
		left = DIV(Sum(formFn.yform(props[:interval])), **{'class':'c50l'})
		right = DIV(Sum(formFn.yform(props[interval:])), **{'class':'c50r'})
		divs = DIV(Sum((left, right)), **{'class':'subcolumns'})
		form.append(divs)	
		bnStyle = 'position:absolute;margin-left:12em;'
		
	# append hidden field that points out the action type
	[item.update({'type':'hidden'}) for item in hideInput]
	[ form.append(INPUT(**item)) for item in hideInput ]
	
	# add buttons to this form	
	buttons = [ \
		BUTTON( _('Confirm'), **{'class':pagefn.BUTTONSTYLE, 'type':'button'}),\
		BUTTON( _('Cancel'), **{'class':pagefn.BUTTONSTYLE, 'type':'button'})\
	]
	
	div = DIV(Sum(buttons), **{'style':bnStyle})    
	form.append(div)
	
	form = \
	FORM( 
		Sum(form), 
		**{'action': '/'.join((APPATH,'page_serviceEditAction')), 'id': SERVICEEDITFORM, 'method':'post','class':'yform'}
	)
				
	print DIV(form,style='')
	print pagefn.script(_editServiceJs(),link=False)
	
	return

def _editServiceJs():	
	paras = [SERVICEEDITFORM,]
	paras.extend(CHKFNS)
	paras.extend(['/'.join((APPATH, name)) for name in ('page_categoryValid','page_serviceNameValid')])
	paras.extend([_('The input name for category has been used already!'),_('The input service name has been used already!')])
	paras = tuple(paras)
	js = \
	"""
	var formId='%s',
	categroyValidFn='%s', serviceNameValidFn='%s',
	categoryValidAction='%s', serviceNameValidAction='%s',
	categoryErr='%s', serviceNameErr='%s';
	
	// add mouseover effect to buttons
	new MooHover({container: formId,duration:800});
	
	// Add validation function to the form
	// Set a global variable 'serviceCategoryFormchk', 
	// which will be used as an instance of the validation Class-'FormCheck'.
	var serviceCategoryFormchk;
    
	// Load the form validation plugin script
	var options = {
	    onload:function(){    		
		serviceCategoryFormchk = new FormCheck( formId,{
		    submitByAjax: true,
		    onAjaxSuccess: function(response){
			if(response == 1){
		            MUI.closeModalDialog();
			};               
		    },            
		    
  		    display:{
			errorsLocation : 1,
			keepFocusOnError : 0, 
			scrollToFirst : false
		    }
		});// the end for 'serviceCategoryFormchk' definition
	    }// the end for 'onload' definition
	};// the end for 'options' definition
 
      	MUI.formValidLib(appName,options);
   
   	/*****************************************************************************
   	Check whether the category name has been used    
   	*****************************************************************************/    
   	// A Request.JSON class for send validation request to server side
   	var categoryRequest = new Request.JSON({async:false});
    
   	var categroyValidTag = false;
   	window[categroyValidFn] = function(el){
      		el.errors.push(categoryErr);
	
	      	// set some options for Request.JSON instance
      		categoryRequest.setOptions({
         		url: categoryValidAction,
         		onSuccess: function(res){
           			if(res.valid == 1){categroyValidTag=true};
         		}
      		});
       
      		categoryRequest.get({'name':el.getProperty('value')});
      		if(categroyValidTag){
         		categroyValidTag=false;   // reset global variable 'categroyValidTag' to be 'false'
         		return true
      		};             
      		return false;
   	};    
	
	/******************************************************************************
	Check whether the service name has been used
	******************************************************************************/
	var serviceNameRequest = new Request.JSON({async:false});
	var nameValidTag = false;
	
	window[serviceNameValidFn] = function(el){
		el.errors.push(serviceNameErr);
	
	      	// set some options for Request.JSON instance
      		serviceNameRequest.setOptions({
         		url: serviceNameValidAction,
         		onSuccess: function(res){
           			if(res.valid == 1){nameValidTag=true};
         		}
      		});
      
	      	serviceNameRequest.get({
      			'name':el.getProperty('value'),
      			'category': function(element){
      				var value = element.getParents('form')[0].getElement('input[name=category]')
      				.getProperty('value');
      				return value
      			}(el)
      		});
      
		if(nameValidTag){
        		nameValidTag=false;   // reset global variable 'nameValidTag' to be 'false'
         		return true
      		}             
      		
		return false;
	};
	
	
	var buttons = $(formId).getElements('button');

	buttons[0].addEvent('click', function(e){
		serviceCategoryFormchk.onSubmit(e);
	});
	
	buttons[1].addEvent('click', function(e){
		new Event(e).stop();
		MUI.closeModalDialog();
	});
	
	"""%paras
	
	return js

def _deletable(nodeId,category):
	""" Judge wheher this node could be deleted by its node id. """
	
	res = {'permission':True, 'info': _('Service item has been deleted!')}
	
	props = ('id','subcategory')
	items = _getServiceItems(category, props)
	idFn = lambda i: i[props.index('id')]
	pidFn = lambda i: i[props.index('subcategory')]
	treeHandler = _data2tree(items,idFn,pidFn)
	
	
	# get all the ids of nodes in this branch
	nodes = treeHandler.rootNode.get_node_by_id(nodeId).flatten()
	nodeIds = [n.id for n in nodes]
	res['toDelete'] = nodeIds
	
	# get all the related services' ids that has been reserved
	reservedIds = model.get_items( USER, 'reserve', props=('target',), link2key=False,ids=None)
	
	#if type(reservedIds) == type('') :
	#	reservedIds = [str(i) for i in range(10)]
		#res['reserved'] = reservedIds
	
	reservations = list(set(nodeIds).intersection(set(reservedIds))) 
	if reservations:
		res['permission'] = False
		
		res['info'] = ' '.join(
			[	_('There is reservations related with this service item, so it could not be deleted!'),
				_('The ids of related reservations are '),
				','.join(reservations)\
			]
		)
	
	return res
	
def page_serviceEditAction(**args):
	action = args.pop('action')
	successTag = 0
	actions = ACTIONTYPES
	if not action:
		actionType = 0
	else:
		actionType = actions.index(action)
		 
	if actionType == 0:	# 'add' action
		sid = model.create_item(USER, 'service', args)
		if sid:
			successTag = 1
	elif actionType == 1:	# 'edit' action
		sid = args.pop('id')
		model.edit_item(USER, 'service', sid, args, 'edit', True)	
		successTag = 1
	elif actionType == 2:	# 'delete' action
		sid,category = [ args.get(prop) for prop in ('id','category')]
		
		judge = _deletable(sid,category)
		if judge.get('permission'):
			[ model.delete_item( USER, 'service', nid, isId=True) for nid in judge.get('toDelete')]
		
		successTag = JSON.encode( judge.get('info'), encoding='utf8')		
	
	print successTag
	return

# valid whether the input categroy name has been used 
def page_categoryValid(**args):
	name =args.get('name')
	res ={'valid':1}
	categories = _getCategory()
	res['category'] = categories 
	if name in categories:
		res['valid'] = 0
	print JSON.encode(res)	
	return

# valid whether the input service name has been used
def page_serviceNameValid(**args):
	inputName,category = [ args.get(prop) for prop in ('name','category')]
	
	res = {}
	names = _getServiceItems(category,props=('name',))
	if names :
		names = [ item[0] for item in names ]
	else:
		names = []
		 
	if inputName in names:
		res['valid'] = 0
	
	res = {'valid':1}
	print JSON.encode(res)	
	return
	
	
