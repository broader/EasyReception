['page_info', 'index', 'page_colsModel', 'page_usersData', 'page_userInfo']
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
GRIDSORTONTAG, GRIDSORTBYTAG = [ pagefn.JSLIB['dataGrid']['sorTag'][name] for name in ('sortOn', 'sortBy')]
BASEINFO = 'userBaseInfo'
# End*****************************************************************************************


# ********************************************************************************************
# The page functions begining
# ********************************************************************************************

def page_info(**args):
	PRINT( DIV(_("Monitor user's registration and edit their information"),**{'class':'info'}))
	return

def index(**args):
	title = _("Registered Users' List")

	input = INPUT(**{'style':'margin:15px 5px 15px 0;','id':FILTERINPUTID,'value':''})
	bn = A( pagefn.JSLIB['dataGrid']['filter']['labels']['action'] ,**{'id':FILTERBN, 'href':'javascript:;'})
	rbn = A( pagefn.JSLIB['dataGrid']['filter']['labels']['clear'],**{'id':FILTERCLEARBN, 'href':'javascript:;'})

	PRINT( H2(title),HR(style='padding:0 0 0.1em'),SPAN(Sum((input,bn,TEXT(' | '),rbn))),DIV(**{'id':GRIDID}))
	PRINT( pagefn.script(_usersGridJs(), link=False))
	return

def _usersGridJs(**args):
	paras = [APP, GRIDID]

	# append the ids of the elements for filter function
	paras.extend([FILTERINPUTID,FILTERBN,FILTERCLEARBN])

	# url links
	[ paras.append('/'.join((APPATH,name)))\
	  for name in ('page_usersData','page_colsModel', 'page_userInfo')]


	# the url to edit portfolio
	paras.append('portfolio/portfolio.ks/page_editPortfolio')

	paras.append(_('Portfolio Edit'))

	paras = tuple(paras)
	js = \
	'''
	var appName='%s', gridId='%s',
	filterInput='%s',filterBn='%s',filterClearBn='%s',
	dataUrl='%s',colsModelUrl='%s', userInfoUrl='%s',
	editUrl='%s',
	dialogTitle='%s';

	var colsModel=null, datagrid=null;

	// load column model for the grid from server side
	var jsonRequest = new Request.JSON({
	    async: false, url: colsModelUrl,
	    onSuccess: function(json){
		colsModel = json['data'];
	    }
	}).get();

	// search action for grid
   	$(filterBn).addEvent('click',function (e){
	    datagrid.loadData(dataUrl, {'filter':$(filterInput).value || ''});
   	});

  	// refresh grid
   	$(filterClearBn).addEvent('click', function(e){
	    $(filterInput).setProperty('value','');
	    datagrid.loadData();
   	});

   	// edit the data of selected row
   	function gridRowEdit(evt){
	    /* Parameters
	    evt.target:the grid object
	    evt.indices:the multi selected rows' indexes
	    evt.row: the index of the row in the grid
	    */

	    // get the data of the selected row
	    row = evt.target.getDataByRow(evt.row);

	    var urls = [];
	    $H({'user':row['username'],'panelReload':'0'})
	    .each(function(value,key){
		urls.push([key,value].join('='));
	    });
	    url = [editUrl,urls.join('&')].join('?');

	    // the dialog to edit portfolio
	    new MUI.Modal({
		width:850, height:400, contentURL: url,
		resizable: true,
		title: dialogTitle,
		modalOverlayClose: false,
		onClose: function(e){
		    datagrid.loadData();
		}
	    });

   	};

   	// accordion function which show more data for each row
   	function gridRowAccordion(obj){
	    /* Parameters
	    obj :
	    {
		parent: Li element which holds the content for accordion,
		row: the index for the row in the grid,
		grid: table grid instance
	    }
	    */
	    if(obj.parent.get('html') != '')
		return;

	    obj.grid.container.set('spinner').spin();

	    row = obj.grid.getDataByRow(obj.row);
	    name = row['username'];
	    url = userInfoUrl+'?username='+name;
	    obj.parent.set('load',{
		onComplete: function(){
		    obj.grid.container.unspin();
	    }});
	    obj.parent.load(url);
   	};


	function renderGrid(){

	    datagrid = new omniGrid( gridId, {
		columnModel: colsModel,	url: dataUrl, accordion: true,
		accordionRenderer: gridRowAccordion,
		autoSectionToggle: true,
		perPageOptions: [15,30,50,100,200],
		perPage:10, page:1, pagination:true, serverSort:true,
		showHeader: true, sortHeader: true, alternaterows: true,
		resizeColumns: true, multipleSelection:true,
		width:810, height: 350
	    });

	    datagrid.addEvent('dblclick', gridRowEdit);
	};

	MUI.dataGrid(appName, {'onload':renderGrid});

	'''%paras

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

	PRINT( JSON.encode({'data':colsModel}))
	return

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
		# sort data
		if sortby :
			data.sort(key=lambda row:row[showProps.index(sortby)])

		if sorton == 'DESC':
			data.reverse()

		# get the data of the displayed page
		start = (showPage-1)*pageNumber
		end = start + pageNumber - 1
		if end >= total:
			end = total
		# get data slice in the displayed page from the data
		rslice = data[start : end]

		# if ascii chars mixins with non-ascii chars will result
		# JSON.encode error, so decode all the data items to utf8.
		# set python default encoding to 'utf8'
		reload(sys)
		sys.setdefaultencoding('utf8')

		for row in rslice:
			for i,s in enumerate(row) :
				row[i] = (s or '').decode('utf8')

		# constructs each row to be a dict object that key is a property.
		encoded = [dict([(prop,value) for prop,value in zip(showProps,row)]) for row in rslice]

		# some properties need to be transformated
		transProps = [{'name':'gender','function':(lambda v: pagefn.GENDER[int(v or 0)] )},]
		names = [prop.get('name') for prop in transProps]

		for row in encoded :
			for prop in transProps:
				name = prop.get('name')
				new = prop.get('function')(row[name])
				# set the key for a new value
				row[name] = new

		d['data'] = encoded

	PRINT( JSON.encode(d, encoding='utf8'))
	return

def page_userInfo(**args):
	user = args.get('username')
	values = model.getUserDossier(USER, user)
	fields = CONFIG.getData(BASEINFO)
	showProps = [item.get('name') for item in USERCOLUMNS]
	fields = [item for item in fields if item.get('name') not in showProps]
	newFields = formFn.filterProps(fields,values)

	labelStyle = {'label':'font-weight:bold;font-size:1.0em;color:white;', \
					  'td':'text-align:right;background:#9ca2cb'}

	valueStyle = {'label':'color:#ff6600;font-size:1.0em;', 'td':'text-align:center;width:5em;',\
					  'textarea':'width:10em;color:#ff6600;font-size:1.1em;'}

	trs = formFn.render_table_fields( newFields, 4, labelStyle, valueStyle)
	table = []
	table.append(trs)
	tableStyle = 'position:relative;'
	table = TABLE(Sum(table), style=tableStyle)
	PRINT( DIV(table))
	return

