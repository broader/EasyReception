"""
Service module 
"""
import copy
from HTMLTags import *

# 'THIS.script_url' is a global variable in Karrigell system
APPATH = THIS.script_url[1:]
RELPATH = (lambda p : p.split('/')[0])(THIS.baseurl)

model = Import( '/'.join((RELPATH, 'model.py')), REQUEST_HANDLER=REQUEST_HANDLER )

modules = {'pagefn': 'pagefn.py', 'JSON': 'demjson.py', 'formFn':'form.py', 'tree':'lib/tree/logilab/tree.py'}
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

PROPS =\ 
[
	{'name':'category','prompt':_('Category'),'validate':[''.join(('~',CHKFNS[0])),],'required':True},
	{'name':'subcategory','prompt':_('Subcategory'),'validate':[],'required':True},
	{'name':'name','prompt':_('Service Name'),'validate':[''.join(('~',CHKFNS[1])),],'required':True},
	{'name':'description','prompt':_('Description'),'validate':[],'type':'textarea'},
	{'name':'price','prompt':_('Unit Price'),'validate':[]},
	{'name':'amount','prompt':_('Amount'),'validate':[]},
	{'name':'detail','prompt':_('Supplement'),'validate':[],'type':'textarea'},
]

# the id for category creation form 
CATEGORYCREATIONFORM = 'categoryCreationForm'

# the properties info that will be shown in columns's title in the services' list
COLUMNMODEL = [
	{'dataIndex':'name','label':_('Service Name'),'dataType':'string'},
	{'dataIndex':'description','label':_('Description'),'dataType':'string'},
	{'dataIndex':'price','label':_('Unit Price'),'dataType':'string'},
	{'dataIndex':'amount','label':_('Total Amount'),'dataType':'number'},
	{'dataIndex':'','label':_('Actions'),'dataType':'button'},
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
			lis.append(LI(A(IMG(src='/'.join((RELPATH,'images/icons/16x16','add_16.png')))),**props))
	
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
	print pagefn.script(_showServiceJs(category),link=False)	
 	
	return

CATEGORYTAG = 'category'
def _showServiceJs(category):
	paras = [APP, CATEGORYTAG, category, CONTAINERID(category)]
	paras.extend(['/'.join((APPATH,name)) for name in ('page_colsModel','page_serviceItems')])
	paras.extend([_('Add'),_('Create New Subategory')])
	paras.extend([_('Create a new subcategory for service'), '/'.join((APPATH,'page_createCategory'))])
	paras = tuple(paras)
	js = \
	"""
	var appName='%s', categoryInfo=['%s','%s'],
	container='%s', colsModel='%s',rowsUrl='%s',
	addBnLabel='%s',addCategoryBnLabel='%s'
	categoryModal={'title':'%s','url':'%s'};
	
	var treeTable;
	
	// The function to insert action buttons to each row in the table,
	// and insert a subcategory creation button out of the table.
	function addButton(ti){
		// Parameter 'ti'- the TreeTable instance
		
		// add the action button out of the table
		
		//if(rows.length == 0 ){
		
		ti.container.grab(Element('button',{
			'html':addCategoryBnLabel,
			'events':{
				'click': function(){
					// the dialog to create a new subcategory of service
					url = [categoryModal.url, categoryInfo.join('=')].join('?');
			   	new MUI.Modal({
			      	width:600, height:380, contentURL: url,
			      	title: categoryModal.title,
			      	modalOverlayClose: false,
			      	onClose: function(e){
			      		MUI.refreshMainPanel();
			      	}
			      });
				}
			}
		}));
		//};
		
		// add action buttons to each row 
		ti.getTrs()
		.each(function(row){
			td = row.getLast();
			[{'label':addBnLabel,'imgUrl':'images/icons/16x16/add_16.png'},]
			.each(function(data){
				img = new Element('img',{
					'src': data['imgUrl'],
				   'html': data['label'],
				});
				
				td.grab(img);
			});
		});
	};
	
	// options for TreeTable class initialization
	var options = {
		onload:function(){    		
			treeTable = new TreeTable( 
				container,				
				{
					colsModelUrl:colsModel,
					dataUrl: [rowsUrl, categoryInfo.join('=')].join('?'),
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

def _getServiceItems(category, props=None):
	# get items from 'service' class in database
	search = {'category' : category}
	return model.get_items_ByString(USER, 'service', search, props)
	
def page_serviceItems(**args):
	"""
	"""
	category = args.get(CATEGORYTAG)
	props = [item.get('dataIndex') for item in COLUMNMODEL[:-1]]
	props.extend(['serial', 'category', 'subcategory','nodetype'])
		
	# filter the root category items	
	nameIndex = props.index('name')	
	rows = filter( lambda item: item[nameIndex], _getServiceItems(category, props) )
	
	for row in rows:		
		for index,value in enumerate(row):
			if value:
				row[index] = value.decode('utf8')
			else:
				row[index] = ''.decode('utf8')
		
	print JSON.encode(rows,encoding='utf8')
	return

def page_createCategoryInfo(**args):
	"""
	"""
	info = _("Here you can create a new category of service.It's need to define the name and decritpiton of the new category.")
	containerId = 'createNewCategory'
	print DIV(**{'class':'note','style':'width:40%;','id':containerId})
	
	paras = [info, containerId,_('Create A New Category For Service')]
	paras.extend([_('Create a new category for service'),'/'.join((APPATH,'page_createCategory'))])	
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
		
def page_createCategory(**args):
	ctag = CATEGORYTAG
	category = args.get(ctag)	
	names = ['category','description']
	if category:
		names.insert(1,'name')
	
	# start to render edit form
	props = [item for item in PROPS if item['name'] in names]
	for prop in PROPS:
		prop['id'] = prop['name']		
		if not prop.get('type'):
			prop['type'] = 'text'
			
		if not prop.has_key('required'):
			prop['required'] = False	 	
		
		if prop['name'] == ctag and category:
			prop['oldvalue'] = category
			prop['readonly'] = ''
			prop['validate'] = []
			prop['required'] = False
		else:
			prop['oldvalue'] = ''
	
	# render the fields to the form	
	form = []
	# get the OL content from formRender.py module	
	div = DIV(Sum(formFn.yform(props)))
	form.append(FIELDSET(div))
	
	# append hidden field that points out the action type
	form.append(INPUT(**{'name':'action','value':'create','type':'hidden'}))
	
	# add buttons to this form	
	buttons = [ \
		BUTTON( _('Create'), **{'class':pagefn.BUTTONSTYLE, 'type':'button'}),\
		BUTTON( _('Cancel'), **{'class':pagefn.BUTTONSTYLE, 'type':'button'})\
	]
	
	div = DIV(Sum(buttons), **{'style':'position:absolute;margin-left:15em;'})    
	form.append(div)
	
	form = \
	FORM( 
		Sum(form), 
		**{'action': '/'.join((APPATH,'page_serviceEditAction')), 'id': CATEGORYCREATIONFORM, 'method':'post','class':'yform'}
	)
				
	print DIV(form,style='')
	print pagefn.script(_createCategoryJs(),link=False)
	
	return

def _createCategoryJs():
	paras = [CATEGORYCREATIONFORM,]
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
	if action == 'create':
		sid = model.create_item(USER, 'service', args)
		if sid:
			successTag = 1
	else:
		pass
		
	print successTag
	return
	
def page_categoryValid(**args):
	name =args.get('name')
	res ={'valid':1}
	categories = _getCategory()
	res['category'] = categories 
	if name in categories:
		res['valid'] = 0
	print JSON.encode(res)	
	return

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
	
	