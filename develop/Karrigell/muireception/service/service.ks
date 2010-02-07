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

PROPS =\ 
[
	{'name':'category','prompt':_('Category'),'validate':[]},
	{'name':'name','prompt':_('Name'),'validate':[]},
	{'name':'description','prompt':_('Description'),'validate':[]},
	{'name':'price','prompt':_('Unit Price'),'validate':[]},
	{'name':'amount','prompt':_('Amount'),'validate':[]}
]

SERVICECHECKFUNCTION = 'serviceCheck'

DETAILPROPS = \
[
	{'name':'alias','prompt':_('Service name'),'validate':[]},
	{'name':'parent','prompt':_('The serial number of the parent service'),'validate':[''.join(('~',SERVICECHECKFUNCTION))]}
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
	print H2('Create new category of service.')
	
	# start to render edit form
	props = PROPS
	props.extend(DETAILPROPS)
	for prop in PROPS:
		name = prop['name']
		prop['id'] = name
		prop['type'] = 'text'
		if name != 'parent':
			prop['required'] = True
		else:
			prop['required'] = False			 	
		
		prop['oldvalue'] = ''
		
	props.append({'name':'action','oldvalue':'create','type':'hidden','validate':[]})
	
	# render the fields to the form	
	form = []
	# get the OL content from formRender.py module	
	yform = formFn.yform(props)	
	div = DIV( Sum(yform), **{'class':'subcolumns'})
	
	# add the <Legend> tag
	info = ': '.join((_('Create New Service'), USER))
	
	legend = LEGEND(TEXT(info))    
	form.append(FIELDSET(Sum((legend,div))))
	
	form = FORM( \
				Sum(form),\ 
				**{'action': '', 'id': '', 'method':'post','class':'yform'}\
				)
				
	print DIV(form, **{'class':'subcolumns'})
	return




	