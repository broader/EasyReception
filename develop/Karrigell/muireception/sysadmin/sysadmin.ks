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

# the classes that could be edited by web page
WEB_EDIT_CLASS = ['role', 'keyword','priority', 'status', 'user', 'webaction', 'service', 'reserve' ]


# End*****************************************************************************************

# ********************************************************************************************
# The page functions begining 
# ********************************************************************************************

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
	klass,panel = [args.get(name) for name in ('klass','panel')]
	#print H3(klass)
	container = '-'.join((CONTAINER_PREFIX,klass))
	print DIV(**{'id': container})
	print pagefn.script(_showClassJs(panel),link=False)
	return
	
def _showClassJs(panel):
	paras = [panel,]
	paras = tuple(paras)
	js = \
	"""
	//var containerId='systemAdminPanel';
	var containerId='%s';
	
	new MUI.Column({
		container: containerId, id: 'klassEditColumn', placement: 'main', 
		sortable: false, width: null, resizeLimit: [100,200] 
	});
	
	new MUI.Column({
		container: containerId, id: 'klassInfoColumn', placement: 'right',  
		sortable: false, width: 500, resizeLimit: [400,500] 
	});
	
	// the panel to show hotel list
	pid = "infoPanel";
	new MUI.Panel({
		id: pid,
		column: 'klassInfoColumn', 
		header: false,
		contentURL: "sysadmin/sysadmin.ks/test",
		onExpand: MUI.accordionPanels.pass(pid)
	});
	
	// the panel to show hotel list
	pid = "editPanel";
	new MUI.Panel({
		id: pid,
		column: 'klassEditColumn', 
		header: false,
		contentURL: "",
		onExpand: MUI.accordionPanels.pass(pid)
	});
	
	"""%paras 
	return js
	
def test():
	print H2('test')
	return
	
	
	
	