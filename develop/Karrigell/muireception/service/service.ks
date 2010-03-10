"""
Service module 
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
]

GETPROPSLABEL = lambda name : [item.get('prompt') for item in PROPS if item.get('name')== name ][0]

# the id for category creation form 
SERVICEEDITFORM = 'serviceEditForm'

# the properties info that will be shown in columns's title in the tree table to show services' list
COLUMNMODEL = [
	{'dataIndex':'name','label':_('Service Name'),'dataType':'string', 'treeColumn':'1'},
	{'dataIndex':'description','label':_('Description'),'dataType':'string'},
	{'dataIndex':'price','label':_('Unit Price'),'dataType':'string'},
	{'dataIndex':'amount','label':_('Total Amount'),'dataType':'number'},
	{'dataIndex':'detail','label':_('Memo'),'dataType':'string'},
	{'dataIndex':'serial','label':_('Serial'),'dataType':'string','hide':'1'},
	{'dataIndex':'category','label':_('Category'),'dataType':'string','hide':'1'},
	{'dataIndex':'subcategory','label':_('Subcategory'),'dataType':'string','hide':'1'},
	{'dataIndex':'id','label':_('ServiceId'),'dataType':'string','hide':'1'},
	{'dataIndex':'addAction','label':_('Add'),'dataType':'button','imgUrl':'images/additional/add.png'},
	{'dataIndex':'editAction','label':_('Edit'),'dataType':'button','imgUrl':'images/additional/edit.png'},
	{'dataIndex':'delAction','label':_('Delete'),'dataType':'button','imgUrl':'images/additional/delete.png'},
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
	
def _getTabs(**args):
	# get service catrgory
	categories = _getCategory()
	
	# constructs the tabs list
	tabs = []
	for category in categories:
		d = { 'text':category,\
				'id':''.join((category,'Tab')),\
				'url':'/'.join((APPATH, '?'.join(('page_showService', 'category=%s'%category))))}
		tabs.append(d)
	
	tabs.append({'id':'addNewService', 'url':'/'.join((APPATH,'page_createCategoryInfo'))})
	return tabs	
	
def index(**args):
	panelId = args.get('panelid')
	
	lis = []
	tabs = _getTabs()
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
	tabs = _getTabs()
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
#ACTIONAMES = ['add','edit','delete']
ACTIONAMES = [ item.get('dataIndex') for item in COLUMNMODEL[-3:] ]
ACTIONPROP,PARENTNAMEPROP = ('action','parentName')
def _showServiceJs(category):
	paras = [APP, CATEGORYTAG, category, CONTAINERID(category)]
	paras.extend(['/'.join((APPATH,name)) for name in ('page_colsModel','page_serviceItems', 'page_editService')])
	paras.append(_('Create New Subategory'))
	paras.extend([_('Create a new subcategory for service'), _('Edit Service Information')])
	
	paras.extend( [ item.get('dataIndex') for item in COLUMNMODEL[-3:] ] )
	paras.extend([ACTIONPROP, PARENTNAMEPROP])
	
	paras = tuple(paras)
	js = \
	"""
	var appName='%s', categoryInfo=['%s','%s'],
	container='%s', colsModel='%s',rowsUrl='%s', actionUrl='%s',
	addCategoryBnLabel='%s',
	modalTitles = {'category':'%s', 'service':'%s'},
	bnFnNames = ['%s','%s','%s'],
	actionProp = '%s', parentName='%s';
	
	var treeTable;
	
	var modalOptions = {
		width:600, height:380, modalOverlayClose: false,
   	onClose: function(e){
   		// refresh table's body
   		treeTable.refreshTbody();
   	}
	};
	
	// The function to insert action buttons to each row in the table,
	// and insert a subcategory creation button out of the table.
	function addButton(ti){
		// Parameter 'ti'- the TreeTable instance
		
		// add the action button out of the table
		ti.container.grab(Element('button',{
			'html':addCategoryBnLabel,
			'events':{
				'click': function(e){
					// the dialog to create a new subcategory of service 
					modalOptions.contentURL = [actionUrl, categoryInfo.join('=')].join('?');
					modalOptions.title = modalTitles.category;
					new MUI.Modal(modalOptions);
			      
				}
			}
		}));
		
	};
	
	// the callback function for action button in each row
	function editService(e){
		tr = e.target.getParents('tr')[0];
		
		// get data of this row
		query = this.getRowDataWithProps(tr);
		
		// add parent name to query object
		parentId = tr.retrieve('parent');
		
		parentNameValue = '';
		if(parentId)
			parentNameValue = this.getCellValueByRowId(parentId,'name');
			
		query[parentName] = parentNameValue;
		
		// get action type
		td = e.target.getParents('td')[0];
		colIndex = tr.getChildren('td').indexOf(td);	
		query[actionProp] = this.getHeaderProps()[colIndex];
		
		// set the really action url
		url = [actionUrl, query.toQueryString()].join('?');
		
		// the modal to edit a service item  
		modalOptions.contentURL = url;
		modalOptions.title = modalTitles.service;
		new MUI.Modal(modalOptions);
		
	};
	
	var bnFns = $H([editService, editService, editService].associate(bnFnNames));
	
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
					bnFunctions: bnFns,
					renderOver: addButton
				}
			);// the end for 'treeTable' definition
			
		}// the end for 'onload' definition
	};// the end for 'options' definition
	
	// initialize TreeTable class
	MUI.treeTable(appName,options);

	"""%paras
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
		[item.update({k:v.decode('utf8')}) for k,v in item.items()]		
	print JSON.encode(colsModel,encoding='utf8')	
	return

def _transform(node,parentIndex):	
	data = {'data': node.data[:len(COLUMNMODEL[:-1])],'depth':node.depth(),'parent':'', 'id':node.id}
	
	parent = node.parent
	if parent and parent.data:
		 data['parent'] = parent.data[parentIndex]
	 
	return data
	
def _getServiceItems(category, props=None, sort4tree=False):
	# get items from 'service' class in database
	search = {'category' : category}
	items = model.get_items_ByString(USER, 'service', search, props)
	if not sort4tree:
		return items
		
	# constructs a tree 
	# the function to the node's id 
	idFn = lambda i: i[props.index('id')]
	# the function to the id of the parent of a node
	pidFn = lambda i: i[props.index('subcategory')]
	# tree construntion Class
	tree = treeHandler.TreeHandler(items, idFn, pidFn)
	
	# handle each row of data, transform them to client's required format
	# sorted[1:] - pop out the first root node which has no data
	parentIndex = props.index('serial')	
	sorted = [ _transform(node, parentIndex) for node in tree.flatten()]
	return sorted[1:]
	
def page_serviceItems(**args):
	"""
	"""
	category = args.get(CATEGORYTAG)
	
	# filter the last three column that are  action clolumns 
	props = [item.get('dataIndex') for item in COLUMNMODEL[:-3]]
	#props.extend(['category', 'subcategory','id'])
		
	# filter the root category items	
	nameIndex = props.index('name')	
	rows = filter( lambda item: item['data'][nameIndex], _getServiceItems(category, props, True))
	
	#rows = _getServiceItems(category, props)
	#print rows
	
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
			
		if not prop.has_key('required'):
			prop['required'] = False	 	
	
	return props
	
def page_editService(**args):
	props = copy.deepcopy(args)	
	actionType = None
	action,category = [ args.get(name) for name in (ACTIONPROP,'category') ]
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
		if category:
			props.pop('category')
			[props.update({name:None,}) for name in ('name','description')]			
			info = [ {'label':GETPROPSLABEL(prop), 'value':args.get(prop)} for prop in ('category',)]
			hideInput = info			
			props = _formFieldsConstructor(props)
		else:
			[ props.update({name:None,}) for name in ('category','description')]
			props = _formFieldsConstructor(props,False) 
		
		hideInput.append({'label':ACTIONPROP,'value':ACTIONAMES[0]})
	else:
		hideInput.append({'label':ACTIONPROP,'value':action})
		names = [item.get('name') for item in PROPS if item.get('name') not in ('category','subcategory','serial')]
		index = ACTIONAMES.index(action) 
		if index == 0:	# add action			 
			[props.pop(name) for name in props.keys() if name not in names ]			
			props = _formFieldsConstructor(props)
			d = {'label':GETPROPSLABEL('category'),'value':args.get('category')}
			[ item.append(d) for item in (info,hideInput)]
			info.append({'label':GETPROPSLABEL('subcategory'),'value':args.get('name')})
			hideInput.append({'label':'subcategory', 'value':args.get('id')})			
		elif index == 1 :	# edit action
			[props.pop(name) for name in props.keys() if name not in names ]			
			props = _formFieldsConstructor(props)
			d = {'label':GETPROPSLABEL('category'),'value':args.get('category')}			
			[ item.append(d) for item in (info,hideInput)]
			info.append({'label':GETPROPSLABEL('subcategory'),'value':args.get(PARENTNAMEPROP)})
			info.append({'label':GETPROPSLABEL('serial'),'value':args.get('serial')})
			hideInput.append({'label':'id', 'value':args.get('id')})
		elif index == 2 :	# delete action
			pass
	
	
	#props = _formFieldsConstructor(**args)
	
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
		#left = DIV(Sum(formFn.yform(props[:interval])), **{'class':'c50l', 'style':style})
		left = DIV(Sum(formFn.yform(props[:interval])), **{'class':'c50l'})
		right = DIV(Sum(formFn.yform(props[interval:])), **{'class':'c50r'})
		divs = DIV(Sum((left, right)), **{'class':'subcolumns'})
		form.append(divs)	
		bnStyle = 'position:absolute;margin-left:12em;'
		
	# append hidden field that points out the action type
	form.append(INPUT(**{'name':'action','value':args.get('action') or '','type':'hidden'}))
	
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
						alert(response);
						MUI.refreshMainPanel();
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
      el.errors.push(categoryErr)
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
      }             
      return false;
   };    
	
	/******************************************************************************
	Check whether the service name has been used
	******************************************************************************/
	var serviceNameRequest = new Request.JSON({async:false});
	var nameValidTag = false;
	
	window[serviceNameValidFn] = function(el){
		el.errors.push(serviceNameErr)
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
      		value = element.getParent('div').getParent('div')
      		.getElement('input[id=category]')
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
	
	
	var buttons = $(formId).getElements('button')
	buttons[0].addEvent('click', function(e){
		serviceCategoryFormchk.onSubmit(e);
	});
	
	buttons[1].addEvent('click', function(e){
		new Event(e).stop();
		MUI.closeModalDialog();
	});
	
	"""%paras
	
	return js

def page_serviceEditAction(**args):
	action = args.pop('action')
	successTag = 0
	actions = ACTIONAMES
	if not action:
		actionType = 0
	else:
		actionType = actions.index(action)
		 
	if actionType == 0:	# 'add' action
		sid = model.create_item(USER, 'service', args)
		if sid:
			successTag = 1
	elif actionType == 1:	# 'edit' action
		pass	
	elif actionType == 2:	# 'delete' action
		pass	
		
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
	names = _getServiceItems(category, props=('name',))
	if names :
		names = [ item[0] for item in names ]
	else:
		names = []
		 
	if inputName in names:
		res['valid'] = 0
	res = {'valid':1}
	print JSON.encode(res)	
	return
	
	