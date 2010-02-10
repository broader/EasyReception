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

SERVICECHECKFUNCTION = 'serviceCheck'

PROPS =\ 
[
	{'name':'category','prompt':_('Category'),'validate':[]},
	#{'name':'subcategory','prompt':_('Subcategory'),'validate':[''.join(('~',SERVICECHECKFUNCTION))],'required':False},
	{'name':'name','prompt':_('Service Name'),'validate':[]},
	{'name':'description','prompt':_('Description'),'validate':[],'type':'textarea'},
	{'name':'price','prompt':_('Unit Price'),'validate':[]},
	{'name':'amount','prompt':_('Amount'),'validate':[]},
	#{'name':'detail','prompt':_('Supplement'),'validate':[],'required':False,'type':'textarea'},
]

# creation form id
CREATIONFORMID = 'createForm'

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
				'url':'?'.join(('page_showService','category=%s'%category))}
		tabs.append(d)
	
	tabs.append({'id':'addNewService', 'url':'/'.join((APPATH,'page_createService'))})
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

def page_showService(**args):
	print args.get('category') or ''	
	return
	
def page_createService(**args):
	#print H2('Create new category of service.')
	
	# start to render edit form
	props = PROPS
	for prop in PROPS:
		prop['id'] = prop['name']		
		if not prop.get('type'):
			prop['type'] = 'text'
			
		if not prop.has_key('required'):
			prop['required'] = True		 	
		
		prop['oldvalue'] = ''
	
	# render the fields to the form	
	form = []
	# get the OL content from formRender.py module	
	yform = formFn.yform
	
	interval = int(len(prop)/2)
	left = DIV(Sum(yform(props[ :interval ])), **{'class':'c50l' })	
	right = DIV(Sum(yform(props[ interval: ])), **{'class':'c50r'})
	div = DIV(Sum((left,right)))	
	
	# add the <Legend> tag	
	legend = LEGEND(TEXT(_('Create New Service')))    
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
		**{'action': '', 'id': CREATIONFORMID, 'method':'post','class':'yform'}
	)
				
	print DIV(form,style='width:50%;margin-left:5em;')
	print pagefn.script(_createJs(),link=False)
	
	return

def _createJs():
	paras = [CREATIONFORMID,]
	paras = tuple(paras)
	js = \
	"""
	var formId='%s';
	
	// add mouseover effect to buttons
	new MooHover({container: formId,duration:800});
	
	function createService(event){
		//portfolioFormchk.onSubmit(event);
		alert('create action');
	};
	
	$(formId).getElements('button')[0].addEvent('click',createService);
	
	"""%paras
	
	return js


	