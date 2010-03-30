"""
Pages mainly for services view and edit action.
"""
import sys, copy,tools
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

# End*****************************************************************************************

# ********************************************************************************************
# The page functions begining 
# ********************************************************************************************

def _formEditProps4classStatus():
	# get all classes' names in roundup.db
	
	# get all user defined names in roundup.status items
	
	# constructs property for the field in html form element
	
 
	return
	
# the classes that could be edited by web page
FORMPROPS4CLASS = [\
	{'name': 'role', 'propsFn': _formEditProps4classStatus},
	{'name': 'keyword',},
	{'name': 'priority',},
	{'name': 'status',},
	{'name': 'user',},
	{'name': 'webaction',},
	{'name': 'service',},
	{'name': 'reserve',} 
]

#WEB_EDIT_CLASS = ['role', 'keyword','priority', 'status', 'user', 'webaction', 'service', 'reserve' ]
WEB_EDIT_CLASS = [item.get('name') for item in FORMPROPS4CLASS]

def _getTabs(panelId):
	# get service catrgory
	klasses = WEB_EDIT_CLASS	
	
	# constructs the tabs list
	tabs = []
	for klass in klasses:		
		query = '&'.join(['%s=%s'%(k,v) for k,v in {'panel':panelId,'klass':klass}.items()])
		d = { 'text':klass,\
				'id':''.join((klass,'Tab')),\
				'url':'/'.join((APPATH, '?'.join(('page_showClass', query))))}
		tabs.append(d)
	
	return tabs	
	
def index(**args):
	panelId = args.get('panelid')
	
	lis = []
	tabs = _getTabs(panelId)
	for i ,tab in enumerate(tabs):
		props = {'id':tab.get('id')}
		if i == 0:
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

CONTAINER_PREFIX = 'klass'
def page_showClass(**args):
	klass,panel = [args.get(name) for name in (CLASSPROP,'panel')]
	#print H3(klass)
	container = '-'.join((CONTAINER_PREFIX,klass))
	print DIV(**{'id': container})
	print pagefn.script(_showClassJs(klass,panel),link=False)
	return

CLASSPROP = 'klass'
def _showClassJs(klass,panel):
	paras = [USER,klass,panel,CLASSPROP]
	paras.extend(['/'.join((APPATH,page)) for page in ('page_classInfo','page_classList')])
	paras = tuple(paras)
	js = \
	"""
	var user='%s',klass='%s', containerId='%s', klassProp='%s'
	infoUrl='%s', editUrl='%s';
	
	// create MUI.Columns
	var columnIds = ['klassEditColumn','klassInfoColumn'];
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
	
	// get content urls
	query = $H();
	query[klassProp] = klass;
	query = query.toQueryString();
	
	// create MUI.Panels
	[
		{'column':columnIds[0],'id':'klassEditPanel','url':editUrl},
		{'column':columnIds[1],'id':'klassInfoPanel','url':infoUrl}
		
	].each(function(attrs){
		pid = attrs.id,
		url = [attrs.url,query].join('?');
		new MUI.Panel({
			id: attrs.id,
			column: attrs.column, 
			header: false,
			contentURL: url,
			onExpand: MUI.accordionPanels.pass(attrs.id)
		});
		
	});
	
	
	"""%paras 
	return js

CLASSNAMESTYLE = "font-weight:bold; font-size:2.5em; padding-bottom:5px;color:#096DD1;"
def page_classInfo(**args):
	klass = args.get(CLASSPROP)

	# Class name
	block = [DIV(A(klass) , style=CLASSNAMESTYLE),]			
	
	# Properties for this Class
	props = model.get_class_props(USER, klass, protected=1)
	propnames = props.keys()
	propnames.sort()
	
	d = {'style':'font-weight:bold;font-size:1.3em;color:#86B50D'}
	table = []
	for propname in propnames:			
		prop = TD(propname,**d)			
		des = TD(repr(props[propname]).strip('<>'))
		tr = TR(Sum((prop, des)))
		table.append(tr)			
	
	block.append(TABLE(TBODY(Sum(table))))
	print Sum(block)
	return

CONTAINER = 'classListGridContainer'
def page_classList(**args):
	klass = args.get(CLASSPROP)
	print DIV(**{'id':CONTAINER})
	print pagefn.script(_classEditJs(klass), link=False)	
	return
	
def _classEditJs(klass):
	paras = [CLASSPROP, klass, APP, CONTAINER]
	paras.append(' '.join((klass,_('Items'))))
	paras.append(CLASSNAMESTYLE)
	paras.extend([_('Filter'),_('Clear Filter')])	
	# url links
	[ paras.append('/'.join((APPATH,name)))\ 
	  for name in ('page_colsModel', 'page_classItems', 'page_classEdit')]
	
	paras = tuple(paras)
	js = \
	"""
	var klassProp='%s', klass='%s', appName='%s', 
	container='%s',
	title='%s', titleStyle='%s',
	filterLabel="%s", clearFilterLabel="%s",
	
	colsModelUrl='%s', dataUrl='%s', editUrl='%s';
	
	var colsModel=null, datagrid=null;
	
	// load column model for the grid from server side 
	var reqData = {};
	reqData[klassProp] = klass;
	var jsonRequest = new Request.JSON({
		async: false,
		url: colsModelUrl, 
		onSuccess: function(json){
    		colsModel = json['data'];
    	}
	}).get(reqData);
   
	// add title and a underline
	span = new Element('span',{html:title,style:titleStyle});	
	hr = new Element('hr',{style:'padding:0 0 0.1em;'});
	$(container).adopt(span,hr);
	
	 
   // add filter input Element   
   var filterInput = new Element('input',{style:'margin:15px 5px 15px 0;'});
   
   var filterButton = new Element('a',{html:filterLabel,href:'javascript:;'});
   
   filterButton.addEvent('click',function (e){
   	datagrid.loadData(dataUrl, {'filter': filterInput.value || ''});
   });
   
   
   var filterClearButton = new Element('a',{html: clearFilterLabel,href:'javascript:;'});
   filterClearButton.addEvent('click', function(e){
   	filterInput.setProperty('value','');
   	datagrid.loadData();
   }); 
   
   span = new Element('span');
   $(container).grab(span);
   interval = new Element('span',{html:' | '});
   span.adopt(filterInput, filterButton, interval, filterClearButton);   
   
   // edit the data of selected row
   function gridRowEdit(evt){
   	/* Parameters
   	evt.target:the grid object
   	evt.indices:the multi selected rows' indexes
   	evt.row: the index of the row in the grid
   	*/
   	
   	// get the data of the selected row
   	row = evt.target.getDataByRow(evt.row);
   	
   	var urls = [];
   	$H({'user':row['username'],'panelReload':'0'})
   	.each(function(value,key){
   		urls.push([key,value].join('='));
   	});
   	url = [editUrl,urls.join('&')].join('?');
   	//url = editUrl + '?'+'user='+row['username'];
   	
   	// the dialog to edit portfolio
   	new MUI.Modal({
      	width:600, height:380, contentURL: url,
      	title: 'Edit Class Item',
      	modalOverlayClose: false,
      	onClose: function(e){ datagrid.loadData();}
      });
   	
   };   
   
   div = new Element('div');
   $(container).grab(div);
   
	function renderGrid(){
		datagrid = new omniGrid( div, {
			columnModel: colsModel, url: dataUrl, urlData: reqData,
			autoSectionToggle: true,
			perPageOptions: [10,20,30],
			perPage:10,	page:1, pagination:true, serverSort:true,
			showHeader: true,	sortHeader: true,	alternaterows: true,
			resizeColumns: true,	multipleSelection:true,
			width:700, height: 320
		});

	};
	
	MUI.dataGrid(appName, {'onload':renderGrid});
	
	// add action buttons	
	var bnContainer = new Element('div',{style: 'text-align:left;padding-top:5px;'});
	$(container).adopt(bnContainer);
	
	[
		{'type':'add','label':'Add'},
		{'type':'edit','label':'Edit'},
		{'type':'delete','label':'Delete'}
	].each(function(attrs,index){
		options = {
			txt: attrs['label'],
		   imgType: attrs['type'],
			bnAttrs: {'style':'margin-right:1em;'}	
		};
		button = MUI.styledButton(options);		
		button.addEvent('click',actionAdapter.pass(index));
		bnContainer.grab(button);
	},datagrid);
	
	function actionAdapter(index){
		var trs = datagrid.selected;
		if( index != 0 && trs.length != 1 ){	// only one row should be selected
			MUI.alert('Please select one row!');
			return
		};
		
		var modalOptions = {
			width:600, height:380, modalOverlayClose: false,
	   	onClose: function(e){
	   		// refresh table's body
	   		datagrid.loadData();
	   	}
		};
		
		var query = $H();
		query[klassProp]= klass;
		switch(index){
			case 0:	// add action
				url = [editUrl, query.toQueryString()].join('?');
				// the modal to edit a service item  
				modalOptions.contentURL = url;
				
				modalOptions.title = 'Add Class Item' ;
				new MUI.Modal(modalOptions);
				break;
			case 1:	// edit action	
				// set the really action url
				query.extend(datagrid.getDataByRow(trs[0]));
				url = [editUrl, query.toQueryString()].join('?');
				
				// the modal to edit a service item  
				modalOptions.contentURL = url;
				
				modalOptions.title = 'test' ;
				new MUI.Modal(modalOptions);
				break;
			case 2:	// delete action
				alert('delete action');
		};
	};
	
	"""%paras
	return js

def _getClassProps(klass, needId=True):
	operator = USER
	props = model.get_class_props( operator, klass).keys()
	
	if klass == 'user':
		props.remove('password')
		
	props.sort()
	if needId:
		props.insert(0, 'id')
		
	return props
	
def page_colsModel(**args):
	""" 
	Return the columns' model of the trid on the client side, which is used to show registered users.
	Format:
		[{'header':...,'dataIndex':...,'dataType':...},...]
	"""
	klass = args.get(CLASSPROP)
	colsModel = [{'header': prop, 'dataIndex':prop,'dataType':'string'} for prop in _getClassProps(klass)] 
		
	print JSON.encode({'data':colsModel})
	return
	
GRIDSORTONTAG, GRIDSORTBYTAG = ('sorton', 'sortby')	
def page_classItems(**args):
	klass = args.get(CLASSPROP)
	
	# paging arguments
	showPage, pageNumber = [ int(args.get(name)) for name in ('page', 'perpage') ]
	search = args.get('filter')
	
	# arguments for sort action
	sortby,sorton = [ args.get(name) or '' for name in (GRIDSORTONTAG,GRIDSORTBYTAG)]
	
	
	# returned data object
	d = {'page':showPage,'data':[],'search':search, 'total':0}
	
	# column's property name
	showProps = _getClassProps(klass)
	if search:
		data = model.fuzzyQuery( USER, klass, search, showProps, require=None)
	else:
		data = model.get_items( USER, klass, _getClassProps(klass))
	
	if not data or (type(data) != type([])):
		print JSON.encode(d, encoding='utf8')	
		return
	
	d['total'] = total = len(data)	
					
	# a temporary handle function for list key
	def _cmpKey(row):
		if sortby:
			i = row[showProps.index(sortby)]
		else:
			i = row[0]
			
		try:
			i = int(i)
		except:
			pass
		return i
	
	# sort data
	data.sort(key=_cmpKey)	
	
	if sorton == 'DESC':
		data.reverse()
		
	# get the data of the displayed page
	start = (showPage-1)*pageNumber
	end = start + pageNumber
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
			row[i] = str((s or '')).decode('utf8')			
		
	# constructs each row to be a dict object that key is a property.
	encoded = [dict([(prop,value) for prop,value in zip(showProps,row)]) for row in rslice]
	
	# some properties need to be transformated		
	d['data'] = encoded
	
	print JSON.encode(d, encoding='utf8')	
	return

def _formFieldsConstructor(klass, values, setOldValue=False):	
	"""
	Constructs the form fields.
	Each form field should has the below propertites.
	'id' - the id for this form fieldElement;
	'name' - field name;
	'prompt' -  the text to decribe the filed which usually is at the left of the form field;
	'oldvalue' - for edit action, old value is needed;
	'type' - the form field type, that usually are 'input','text'
	'required' - is this filed could not be empty?
	'validate' - form field validate function names, should be a list 
	"""
	if type(values) == type([]):
		keys = values
	else:
		keys = values.keys()
		keys.sort()
		
	newprops = []
	for key in keys:	
		prop = {}
		prop['id'] = prop['name'] = prop['prompt'] = key	
		prop['oldvalue'] = ''
		if setOldValue:
			prop['oldvalue'] = values.get(key) or ''			
				
		prop['type'] = 'text'
		prop['required'] = False
		prop['validate'] = []
		newprops.append(prop)	 	
	
	return newprops

def _category4status():
	pass
	return
		
ACTIONPROP,ACTIONTYPES = 'action',('create','edit')
def page_classEdit(**args):
	print H2('Edit Class %s Item'%args.get(CLASSPROP))
	klass = args.pop(CLASSPROP)
	# store the files to be shown and hidden
	info,hideInput = [],[]
	
	props = copy.deepcopy(args)
	if props.has_key('id'):
		# edit action
		actionType = ACTIONTYPES[1]
		nid = props.pop('id')
		info.append( {'prompt':_('Item ID:'), 'value':nid})
		
		[hideInput.append({'name':name,'value':value}) \
		for name,value in ((CLASSPROP,klass),('id',nid),(ACTIONPROP,ACTIONTYPES[1]))]
		
		props = _formFieldsConstructor(klass,props,True)
	else:
		# create action
		hideInput.append({'name':ACTIONPROP,'value':ACTIONTYPES[0]})
		props = _getClassProps(klass, needId=False)
		props = _formFieldsConstructor(klass,props)
	
	# show the fields in 'info' list before html Form Element
	if info:
		[ item.update({'prompt':''.join((item.get('prompt') or '',':'))}) for item in info ]
		labelStyle = {'label':'font-weight:bold;font-size:1.2em;color:dackblue;', \
						  'td':'text-align:right;'}
						  
		valueStyle = {'label':'color:#ff6600;font-size:1.2em;', 'td':'text-align:left;width:6em;'}
						  
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
		**{'action': '/'.join((APPATH,'page_serviceEditAction')), 'id': 'classItemEditForm', 'method':'post','class':'yform'}
	)
				
	print DIV(form,style='')
	
	return

	