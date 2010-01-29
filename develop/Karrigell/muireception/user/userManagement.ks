"""
User Management module 
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
CONFIG = Import( '/'.join((RELPATH, 'config.py')), rootdir=CONFIG.root_dir)

# variables for data grid
USERCOLUMNS = ['username','firstname','lastname','gender','country','organization','email']
ACCOUNTFIELDS = 'userAccountInfo'
PORTFOLIOFIELDS = 'userBaseInfo'

# End*****************************************************************************************


# ********************************************************************************************
# The page functions begining 
# ********************************************************************************************

def index(**args):
	print DIV(_("Monitor user's registration and edit their information"),**{'class':'info'})
	return

GRIDID = 'usersGrid'
def usersTrid(**args):
	title = _('Registered Users List')
	print H2(title)
	print DIV(**{'id':GRIDID})
	print pagefn.script(_usersTridJs(), link=False)
	return

def _usersTridJs(**args):
	paras = [ APP,GRIDID,]
	paras.extend(pagefn.GRIDFILES)
	[ paras.append('/'.join((APPATH,name)))\ 
	  for name in ('page_usersData','page_colsModel')]
	paras = tuple(paras)
	js = \
	"""
	var appName='%s', gridId='%s',
	gridCss='%s',gridSupplement='%s',gridJs='%s',
	dataUrl='%s',colsModelUrl='%s';
	
	var colsModel = null; 
	var jsonRequest = new Request.JSON({
		async: false,
		url: colsModelUrl, 
		onSuccess: function(json){
    		colsModel = json['data'];
    	}
	}).get();
	
	// get the global Assets manager
   var am = MUI.assetsManager;
   am.remove(appName,'app');
   
   function gridButtonClick(event){
   	new Event(event).stop();
   	alert('button clicked!');
   };
   
	function renderGrid(){	
			
		var datagrid = new omniGrid( gridId, {
			columnModel: colsModel,
			buttons : [
				{name: 'Add', bclass: 'add', onclick : gridButtonClick},
				{name: 'Delete', bclass: 'delete', onclick : gridButtonClick},
				{separator: true},
				{name: 'Duplicate', bclass: 'duplicate', onclick : gridButtonClick}
				],
			url: dataUrl,
			accordion: false,
			accordionRenderer: null,
			autoSectionToggle: false,
			perPageOptions: [10,20,50,100,200],
			perPage:10,
			page:1,
			pagination:true,
			serverSort:false,
			showHeader: true,
			sortHeader: true,
			alternaterows: true,
			resizeColumns: true,
			multipleSelection:true,
			width:710,
			height: 320
		});
	};
	
	var toImport =
	[	{'type':'css','src':gridCss,'options':null},
		{'type':'css','src':gridSupplement,'options':null},
		{'type':'js','src':gridJs,'options': {'onload':renderGrid}}
	] 
	
   toImport.each(function(props){
   	src = props['src'], type=props['type'], options=props['options'];
		if(!$defined(am.imported[src])){			
			if (options != null){
				am.import({'url':src,'app':appName,'type':type},options);
			}
			else{
		 		am.import({'url':src,'app':appName,'type': type});
		 	}
		};	
   });
	"""%paras
	
	return js

def page_colsModel(**args):
	colsModel = []
	fields = CONFIG.getData(ACCOUNTFIELDS)
	fields.extend(CONFIG.getData(PORTFOLIOFIELDS))
	
	for field in fields :
		name = field['name']		
		if not name in USERCOLUMNS :
			continue		
		colsModel.append({'header':field['prompt'],'dataIndex':name,'dataType':'string'})
	
	print JSON.encode({'data':colsModel})
	return
	
def page_usersData(**args):
	d = {'page':1,'total':'16','data':[]}
	
	for i in range(10):
		row = dict([(name,i) for name in USERCOLUMNS ])
		d['data'].append(row)
	
	print JSON.encode(d)
	return