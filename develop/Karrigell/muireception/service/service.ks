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

# config data object
#CONFIG = Import( '/'.join((RELPATH, 'config.py')), rootdir=CONFIG.root_dir)

TABS = [\
{'text':'Overview','id':'panelTabsLink','url':'pages/overview.html'},
{'text':'Download','id':'panelTabs2link', 'url':'pages/download.html'}]
# End*****************************************************************************************


# ********************************************************************************************
# The page functions begining 
# ********************************************************************************************
def index(**args):
	panelId = args.get('panelid')
	
	lis = []
	for index,tab in enumerate(TABS):
		props = {'id':tab.get('id')}
		if index == 0:
			props['class'] = 'selected'
			
		lis.append(LI(A(tab.get('text')),**props))
	
		
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
	for tab in TABS:
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
	
	js = '\n'.join(js)
	print pagefn.script(js,link=False)
	return 

def page_info(**args):
	print P('For editing servcie, please select a category of service by clicking the tabs on right operation panel first !')
	return
	
