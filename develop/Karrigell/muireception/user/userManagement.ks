"""
User Management module 
"""
import sys

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
CONFIG = Import( '/'.join((RELPATH, 'config.py')), rootdir=CONFIG.root_dir)

# variables for data grid
GRIDID, FILTERINPUTID,FILTERBN,FILTERCLEARBN = ('usersGrid', 'filterInput','filterbn','filtereset')
USERCOLUMNS = \
[
	{'name':'username'},\
	{'name':'firstname'},\
	{'name':'lastname'},\
	{'name':'gender'},\
	{'name':'country'},\
	{'name':'organization'},\
	{'name':'email'}\
]

ACCOUNTFIELDS = 'userAccountInfo'
PORTFOLIOFIELDS = 'userBaseInfo'
GRIDSORTONTAG, GRIDSORTBYTAG = ('sorton', 'sortby')

# End*****************************************************************************************


# ********************************************************************************************
# The page functions begining 
# ********************************************************************************************

def index(**args):
	print DIV(_("Monitor user's registration and edit their information"),**{'class':'info'})
	return

def usersTrid(**args):
	title = _("Registered Users' List")
	#li = []
	input = INPUT(**{'style':'margin:15px 5px 15px 0;','id':FILTERINPUTID,'value':''})
	bn = A(_('Filter'),**{'id':FILTERBN, 'href':'javascript:;'})
	rbn = A(_('Clear Filter'),**{'id':FILTERCLEARBN, 'href':'javascript:;'})
	
	print H2(title),HR(style='padding:0 0 0.1em'),SPAN(Sum((input,bn,TEXT('|'),rbn))),DIV(**{'id':GRIDID})
	print pagefn.script(_usersTridJs(), link=False)
	return

def _usersTridJs(**args):
	paras = [ APP,GRIDID,]
	
	# append the ids of the elements for filter function 
	paras.extend([FILTERINPUTID,FILTERBN,FILTERCLEARBN])
	
	paras.extend(pagefn.GRIDFILES)
	[ paras.append('/'.join((APPATH,name)))\ 
	  for name in ('page_usersData','page_colsModel')]
	paras = tuple(paras)
	js = \
	"""
	var appName='%s', gridId='%s',
	filterInput='%s',filterBn='%s',filterClearBn='%s',
	gridCss='%s',gridSupplement='%s',gridJs='%s',
	dataUrl='%s',colsModelUrl='%s';
	
	var colsModel=null, datagrid=null; 
	var jsonRequest = new Request.JSON({
		async: false,
		url: colsModelUrl, 
		onSuccess: function(json){
    		colsModel = json['data'];
    	}
	}).get();
	
	// get the global Assets manager
   var am = MUI.assetsManager;
   // clear existed imported Assets 
   am.remove(appName,'app');
   
   
   $(filterBn).addEvent('click',function (e){
   	datagrid.loadData(dataUrl, {'filter':$(filterInput).value || ''});
   });
   
   $(filterClearBn).addEvent('click', function(e){
   	$(filterInput).setProperty('value','');
   	datagrid.loadData(dataUrl);
   });
   
   
   function gridRowSelect(evt){
   	// evt.target:the grid object
   	// evt.indices:the multi selected rows' indexes
   	// evt.row:a json object which hold name and value pair of each column field
   	row = evt.target.getDataByRow(evt.row);
   };
   
   var datagrid = null;
   
	function renderGrid(){	
			
		datagrid = new omniGrid( gridId, {
			columnModel: colsModel,
			/*
			buttons : [
				{name: 'Add', bclass: 'add', onclick : gridButtonClick},
				{name: 'Delete', bclass: 'delete', onclick : gridButtonClick},
				{separator: true},
				{name: 'Duplicate', bclass: 'duplicate', onclick : gridButtonClick}
				],
			*/
			//buttons: null,
			url: dataUrl,
			accordion: false,
			accordionRenderer: null,
			autoSectionToggle: false,
			perPageOptions: [20,40,50,100,200],
			perPage:10,
			page:1,
			pagination:true,
			serverSort:true,
			showHeader: true,
			sortHeader: true,
			alternaterows: true,
			resizeColumns: true,
			multipleSelection:true,
			width:810,
			height: 420
		});
		
		datagrid.addEvent('click', gridRowSelect);
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
	""" 
	Return the columns' model of the trid on the client side, which is used to show registered users.
	Format:
		[{'header':...,'dataIndex':...,'dataType':...},...]
	"""
	colsModel = []
	fields = CONFIG.getData(ACCOUNTFIELDS)
	fields.extend(CONFIG.getData(PORTFOLIOFIELDS))
	showProps = [item.get('name') for item in USERCOLUMNS]		
	for field in fields :
		name = field['name']				
		if not name in showProps :
			continue		
		options = {'header':field['prompt'],'dataIndex':name,'dataType':'string'}		
		width = USERCOLUMNS[showProps.index(name)].get('width')
		if width:
			options['width'] = width	
		
		colsModel.append(options)
	
	colsModel.sort(key=lambda item: showProps.index(item.get('dataIndex')))
		
	print JSON.encode({'data':colsModel})
	return

def _getData(search=None):
	
	pass
		
def page_usersData(**args):
	# paging arguments
	showPage, pageNumber = [ int(args.get(name)) for name in ('page', 'perpage') ]
	search = args.get('filter')
	
	# arguments for sort action
	sortby,sorton = [ args.get(name) or '' for name in (GRIDSORTONTAG,GRIDSORTBYTAG)]
	
	
	# returned data object
	d = {'page':showPage,'data':[],'search':search}
	
	# column's property name
	showProps = [item.get('name') for item in USERCOLUMNS]
	total, data = model.get_userlist(USER, showProps, search)
	
	d['total'] = total
	
	if data:
		# set python default encoding to 'utf8'
		reload(sys)
		sys.setdefaultencoding('utf8')
			
		# sort data
		if sortby :			
			data.sort(key=lambda row:row[propnames.index(sortby)])	
		
		if sorton == 'DESC':
			data.reverse()
			
		# get the data of the displayed page
		start = (showPage-1)*pageNumber
		end = start + pageNumber - 1
		if end >= total:
			end = total
		# get data slice in the displayed page from the data 	
		rslice = data[start : end]
		
		# if ascii chars mixins with no ascii chars will result
		# JSON.encode error, so decode all the data items to unicode.		 
		encoded = [[i.decode('utf8') for i in row] for row in rslice]
		
		# constructs each row to be a dict object that key is a property.
		encoded = [dict([(prop,value) for prop,value in zip(showProps,row)]) for row in rslice]
		
		# some properties need to be transformated
		transProps = [{'name':'gender','function':(lambda i: pagefn.GENDER[int(i)] )},]
		names = [prop.get('name') for prop in transProps]
		for row in encoded :
			for prop in transProps:
				old = row[prop.get('name')]
				new = prop.get('function')(old)
				row[prop.get('name')] = new
				
		d['data'] = encoded
	
	print JSON.encode(d, encoding='utf8')
	
	return