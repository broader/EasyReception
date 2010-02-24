"""
Service module 
"""

from HTMLTags import *

# 'THIS.script_url' is a global variable in Karrigell system
APPATH = THIS.script_url[1:]
RELPATH = (lambda p : p.split('/')[0])(THIS.baseurl)

model = Import( '/'.join((RELPATH, 'model.py')), REQUEST_HANDLER=REQUEST_HANDLER )
modules = {'pagefn' : 'pagefn.py',  'JSON' : 'demjson.py', 'formFn':'form.py'}
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

# creation form id
CATEGORYCREATIONFORM = 'categoryCreationForm'

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
	
	tabs.append({'id':'addNewService', 'url':'/'.join((APPATH,'page_createCategory'))})
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

def _getServiceItems(category, props=None):
	# get items from 'service' class in database
	search = {'category' : category}
	values = model.get_items_ByString(USER, 'service', search, props)
	return values
	
PROPS4TABLE =  ['serial', 'name','subcategory','description', 'detail', 'price', 'amount']
TABLECONTAINER = 'servcieTableDiv'

def page_showService(**args):
	category = args.get('category')
	# render the style of service table
	containerId = '-'.join((category,TABLECONTAINER))
	print DIV(**{'id':containerId})
	
	# javascript slice to load data to table
	print pagefn.script(_showServiceJs(containerId),link=False)
	
 
	#print args.get('category') or ''	
	#
	items = _getServiceItems(args.get('category'),PROPS4TABLE)	
	return

def _showServiceJs(tableContainerId):
	paras = [APP, tableContainerId,]
	paras = tuple(paras)
	js = \
	"""
	var appName='%s', container='%s';
	
	var treeTable;
	
	var options = {
		onload:function(){    		
			treeTable = new TreeTable( 
				container,
				{header:['h1','h2','h3']}
			);// the end for 'treeTable' definition
			
		}// the end for 'onload' definition
	};// the end for 'options' definition
	
	MUI.treeTable(appName,options);
	"""%paras
	return js
	
def page_createCategory(**args):
	names = ('category','description')
	
	# start to render edit form
	props = [item for item in PROPS if item['name'] in names]
	for prop in PROPS:
		prop['id'] = prop['name']		
		if not prop.get('type'):
			prop['type'] = 'text'
			
		if not prop.has_key('required'):
			prop['required'] = False	 	
		
		prop['oldvalue'] = ''
	
	# render the fields to the form	
	form = []
	# get the OL content from formRender.py module	
	div = DIV(Sum(formFn.yform(props)))
	
	# add the <Legend> tag	
	legend = LEGEND(TEXT(_('Create New Category For Service')))    
	form.append(FIELDSET(Sum((legend,div))))
	# append hidden field that points out the action type
	form.append(INPUT(**{'name':'action','value':'create','type':'hidden'}))
	
	# add buttons to this form	
	button = BUTTON( _('Create'), **{'class':pagefn.BUTTONSTYLE, 'type':'button'})
	
	div = DIV(button, **{'style':'position:absolute;margin-left:15em;'})    
	form.append(div)
	
	form = \
	FORM( 
		Sum(form), 
		**{'action': '/'.join((APPATH,'page_serviceEditAction')), 'id': CATEGORYCREATIONFORM, 'method':'post','class':'yform'}
	)
				
	print DIV(form,style='width:50%;margin-left:5em;')
	print pagefn.script(_createCategoryJs(),link=False)
	
	return

def _createCategoryJs():
	paras = [CATEGORYCREATIONFORM,CHKFNS[0],'/'.join((APPATH,'page_categoryValid')),_('The category input name has been used already!')]
	paras = tuple(paras)
	js = \
	"""
	var formId='%s',
	categroyValidFn='%s',categoryValidAction='%s',categoryErr='%s';
	
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
          categroyValidTag=false;   // reset global variable 'accountValidTag' to be 'false'
          return true
       }             
       return false;
    }
    
   
   function createService(event){
		serviceCategoryFormchk.onSubmit(event);
	};	
	
	$(formId).getElements('button')[0].addEvent('click',createService);
	
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
	
	