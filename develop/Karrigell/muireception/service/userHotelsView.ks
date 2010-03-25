"""
Pages mainly for administration.
"""
import copy,tools
from tools import treeHandler

from HTMLTags import *

# 'THIS.script_url' is a global variable in Karrigell system
APPATH = THIS.script_url[1:]
RELPATH = (lambda p : p.split('/')[0])(THIS.baseurl)

model = Import( '/'.join((RELPATH, 'model.py')), REQUEST_HANDLER=REQUEST_HANDLER )

modules = {'pagefn': 'pagefn.py', 'JSON': 'demjson.py', 'formFn':'form.py'}
[locals().update({k : Import('/'.join(('',v)))}) for k,v in modules.items() ]


# ********************************************************************************************
# Page Variables
# ********************************************************************************************

# get the relative url slice as the application name
APP = pagefn.getApp(THIS.baseurl,1)

# the session object for this page
so = Session()
USER = getattr( so, pagefn.SOINFO['user']).get('username')

# The category name for 'hotel' application to 'service' class
SERVICECATEGORY = pagefn.HOTEL.get('categoryInService')

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

#GETPROPSLABEL = lambda name : [item.get('prompt') for item in PROPS if item.get('name')== name ][0]

# the id for category creation form 
#SERVICEEDITFORM = 'serviceEditForm'

# the properties info that will be shown in columns's title in the tree table to show services' list
COLUMNMODEL = [
	{'dataIndex':'name','label':_('Service Name'),'dataType':'string', 'treeColumn':'1', 'properties':{'style':'padding-right:5px;'}},
	{'dataIndex':'description','label':_('Description'),'dataType':'string'},
	{'dataIndex':'price','label':_('Unit Price'),'dataType':'string', 'properties':{'align':'center'}},
	{'dataIndex':'amount','label':_('Total Amount'),'dataType':'number', 'properties':{'align':'center'}},
	{'dataIndex':'detail','label':_('Memo'),'dataType':'string'},
	{'dataIndex':'serial','label':_('Serial'),'dataType':'string','hide':'1'},
	{'dataIndex':'category','label':_('Category'),'dataType':'string','hide':'1'},
	{'dataIndex':'subcategory','label':_('Subcategory'),'dataType':'string','hide':'1'},
	{'dataIndex':'id','label':_('ServiceId'),'dataType':'string','hide':'1'}
]

# End*****************************************************************************************


# ********************************************************************************************
# The page functions begining 
# ********************************************************************************************
CONTAINERID = 'userHotelsList'
def page_hotelsList(**args):
	""" The page to show hotels list table."""
	
	print DIV(**{'id':CONTAINERID})
	
	# javascript slice to load data to table
	print pagefn.script( _hotelsListJs(),link=False)	
 	
	return 

ACTIONS = [
	{'type':'house','label':_('Detail Information')},
	{'type':'edit','label':_('Reserve')},
]

def _hotelsListJs():
	paras = [APP, CONTAINERID,]
	paras.extend(['/'.join((APPATH,name)) for name in ('page_colsModel','page_hotelItems')])
	[ paras.extend( [ action.get(key) for key in ('type','label')]) for action in ACTIONS ] 
	paras.append(_('Please select only one type of room!'))
	paras = tuple(paras)
	js = \
	"""
	var appName='%s', container='%s', colsModelUrl='%s', rowDataUrl='%s',
	bnAttributes = [{'type':'%s','label':'%s'},{'type':'%s','label':'%s'}],
	errInfo = '%s';	
	
	var treeTable;
	
	/***********************************************************************
	Add buttons on the bottom of the hotel list table
	************************************************************************/
	function addButton(ti){
		// Parameter 'ti'- the TreeTable instance
		bnContainer = new Element('div',{style: 'text-align:left;'});
		ti.container.grab(bnContainer);
		
		bnAttributes.each(function(attrs,index){
			
			options = {
				txt: attrs['label'],
			   imgType: attrs['type'],
				bnAttrs: {'style':'margin-right:1em;'}	
			};
			
			button = MUI.styledButton(options);
			button.addEvent('click',actionAdapter.pass(index,this));
			
			bnContainer.grab(button);
			
		},ti);
		
	};
	
	function actionAdapter(index){
		trs = this.getSelectedRows();
		if(trs.length != 1){	// only one row should be selected
			MUI.alert(errInfo);
			return
		};
		
		if(index==0){
			hotelDetail(this);
		}
		else{
			reservation(this);
		};
	};
	
	function reservation(ti){
		alert('reserve action');
	};
	
	function hotelDetail(ti){
		alert('show hotel detail information action');
	};
	
	/****************************************************************** 
	Initialize tree table 
	******************************************************************/
	// options for TreeTable class initialization
	var options = {
		onload:function(){
			treeTable = new TreeTable( 
				container,				
				{
					colsModelUrl:colsModelUrl,
					treeColumn: 0,					
					dataUrl: rowDataUrl,
					idPrefix: 'hotel-',
					initialExpandedDepth: 1,
					renderOver: addButton
				}
			);// the end for 'treeTable' definition
			
		}// the end for 'onload' definition
	};// the end for 'options' definition
	
	// initialize TreeTable class
	MUI.treeTable(appName,options);	
	"""%paras
	return js

# decode all the values in a dictionary object to utf8 format 
def _decodeDict2Utf8(d):
	[d.update({k:v.decode('utf8')}) for k,v in d.items()]
	return d
	
def page_colsModel(**args):
	""" 
	Return the columns' model of the trid on the client side, 
	which will be used to show services list.
	Format:
		[{'label':...,'dataIndex':...,'dataType':...},...]
	"""
	colsModel = copy.deepcopy(COLUMNMODEL)
	for item in colsModel:
		for k,v in item.items():
			if type(v) == type(''):
				item.update({k:v.decode('utf8')})
			elif type(v) == type({}):
				item.update({k:_decodeDict2Utf8(v)})
					
	print JSON.encode(colsModel,encoding='utf8')	
	return

def _getServiceItems(category,props=None):
	# get items from 'service' class in database
	search = {'category' : category}
	items = model.get_items_ByString(USER, 'service', search, props)
	return items

def _data2tree(items,idFn,pidFn):
	""" Constructs a tree.
	Parameters:
	items -  the data to be structured to a tree
	idFn - the function to the node's id 
	pidFn - the function to the id of the parent of a node
	"""
	# tree construntion Class
	return treeHandler.TreeHandler(items, idFn, pidFn)
	
def _node2json(node):
	data = {'data': node.data,'depth':node.depth(),'parent':'', 'id':node.id,'isLeaf':'0'}	
	
	if node.parent:
		data['parent'] = node.parent.id
		
	if node.is_leaf():
		data['isLeaf'] = '1'
	 
	return data

def _treeFlattenData(category,props, idFn, pidFn):
	items = _getServiceItems(category,props)
	treeHandler = _data2tree(items,idFn,pidFn)
	nodes = treeHandler.flatten()
	
	# handle each row of data, transform them to client's required format
	# sorted[1:] - pop out the first root node which has no data
	sorted = [ _node2json(node) for node in nodes]
	return sorted[1:]

def page_hotelItems(**args):
	"""
	"""
	category = SERVICECATEGORY
	
	# filter the last three column that are  action clolumns 
	#props = [item.get('dataIndex') for item in COLUMNMODEL[:-3]]
	props = [item.get('dataIndex') for item in COLUMNMODEL ]
		
	# filter the root category items	
	nameIndex = props.index('name')	
	#rows = filter( lambda item: item['data'][nameIndex], _getServiceItems(category, props, True))
	idFn = lambda i: i[props.index('id')]
	pidFn = lambda i: i[props.index('subcategory')]
	rows = filter( lambda item: item['data'][nameIndex], _treeFlattenData(category,props,idFn,pidFn))	
	
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

	