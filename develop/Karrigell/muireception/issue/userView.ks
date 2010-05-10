"""
Pages mainly for administration.
"""
#import copy,tools
#from tools import treeHandler

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

# config data object
#INITCONFIG = Import( '/'.join((RELPATH, 'config.py')), rootdir=CONFIG.root_dir)

# *********************************End********************************************************

# ********************************************************************************************
# The page functions begining 
# ********************************************************************************************

def page_issueList(**args):
	userViewIssueList = 'userViewIssueList'
	print DIV(**{'id': userViewIssueList})
	print pagefn.script( _issueListJs( userViewIssueList), link=False)
	return
ACTIONTAG, ACTIONS, ACTIONLABELS = 'action', ['create','edit','delete'],[_('Create'), _('Edit'), _('Delete')]
def _issueListJs(container):
	paras = [ APP, container, _('Your Issues List'),ACTIONTAG]
	# filter labels
	paras.extend([pagefn.JSLIB['dataGrid']['filter']['labels'][name] for name in ('action', 'clear')])
	# edit action buttons' labels
	[ paras.extend(item) for item in (ACTIONS, ACTIONLABELS) ]

	paras.extend([ '/'.join((APPATH,name)) for name in ( 'page_colsModel',)])
	paras = tuple(paras)
	js = \
	"""
	var appName='%s', container=$('%s'), appTitle='%s', actionTag='%s',
	// labels for filter buttons
	filterBnLabels=['%s', '%s'],	
	// actions and labels for actions
	actions=['%s', '%s', '%s'], bnsLabels=['%s', '%s', '%s'],
	// column model for issue grid
	colsModelUrl='%s';
	
	// title for this app
	container.adopt( new Element('h2',{html:appTitle}), new Element('hr',{style:'padding-bottom:0.1em;'}));	

	// Action area
	var actionArea = new Element('div');	
	// filter operation area
	var filterContainer= [], filterInput= new Element('input', {style:'margin-right:0.5em'});
	filterContainer.push(filterInput);
	filterBnLabels.each(function(label,index){
		var filterBn = new Element('a', {html:label, href:'javascript:;'});
		filterBn.addEvent('click', function(event){
			alert('china');
		});

		filterContainer.push(filterBn);
	});
	filterContainer.splice(filterContainer.length-1, 0, new Element('span',{html:' | '}));
	
	/**********************************************************************************
	Return a button container which contains three buttons - 'create','edit','delete'
	***********************************************************************************/
	function issueEditButtons(serial){
		bnAttributes = [
			{'type':'edit','label': '', 'bnSize':'sexysmall', 'bnSkin': 'sexyblue', 'action':''},
			{'type':'delete','label': '', 'bnSize':'sexysmall', 'bnSkin': 'sexyred', 'action':''}
		];	

		bnContainer = new Element('div',{style: 'text-align:right;'});
		
		bnAttributes.each(function(attrs,index){
			
			options = {
				txt: attrs['label'],
			   	imgType: attrs['type'],
				bnAttrs: {'style':'margin-right:1em;'},	
				bnSize: attrs['bnSize'],
				bnSkin: attrs['bnSkin']
			};
			
			button = MUI.styledButton(options);
			// save the serial and action value to button
			button.store('formData', {'serial':serial, 'action':attrs['action']});

			button.addEvent('click',reserveActionAdapter);
			
			bnContainer.grab(button);
			
		});
		
		return bnContainer		
	};
	
	function issueActionAdapter(event){
		new Event(event).stop();
		button = event.target;
		data = button.retrieve('formData');
		query = $H();
		query[actionTag] = data.action;
		query['serial'] = data.serial;
		if(actions.indexOf(data.action)==0){	// 'edit' action
			url = [editUrl, query.toQueryString()].join('?');	
			new MUI.Modal({
         			width: 450, height: 400, y: 80, title: '',
         			contentURL: url,
         			modalOverlayClose: false
         		});
		}
		else{	// 'delete' action
			info = 'Delete Rservation:<br>' + query.serial;
			MUI.confirm(info, delReservation.pass(query), {});
		};
		
	};

	// 'create','edit','delete' action buttons
	var bnsContainer = new Element('span');

	actionArea.adopt([filterContainer, bnsContainer]);
	container.adopt(actionArea);
	
	// datagrid body
	var issueListGrid = new Element('div');
	container.adopt(issueListGrid);
	
	function renderIssueGrid(){	
		var colsModel=null;
	
		// load column model for the grid from server side 
		var jsonRequest = new Request.JSON({
			async: false, url: colsModelUrl, 
			onSuccess: function(json){
    				colsModel = json['data'];
    			}
		}).get();

		datagrid = new omniGrid( issueListGrid, {
			columnModel: colsModel,	url: '', accordion: true,
			accordionRenderer: issueGridAccordion,
			autoSectionToggle: true,
			perPageOptions: [15,25,50,100],
			perPage:10, page:1, pagination:true, serverSort:true,
			showHeader: true, sortHeader: true, alternaterows: true,
			resizeColumns: true, multipleSelection:true,
			width:720, height: 280
		});
		
		datagrid.addEvent('dblclick', issueGridRowAction);
	};
	
	function issueGridAccordion(obj){
		/* Parameters
   		obj :
   		{ 
   			parent: Li element which holds the content for accordion, 
   			row: the index for the row in the grid, 
   			grid: table grid instance
   		}
   		*/
		/*
   		row = obj.grid.getDataByRow(obj.row);
   		name = row['username'];
   		url = userInfoUrl+'?username='+name;
   		obj.parent.load(url);
		*/
	};

	function issueGridRowAction(event){
		/* Parameters
   		evt.target:the grid object
   		evt.indices:the multi selected rows' indexes
   		evt.row: the index of the row in the grid
   		*/
	};
	
	MUI.dataGrid(appName, {'onload':renderIssueGrid});

	"""%paras
	return js

ISSUELISTCOLUMNS = \
[\ 
  {'name':'serial','header':_('Serial'),'dataType':'string'},\ 
  {'name':'title','header':_('Title'),'dataType':'string'}, \
  {'name':'keyword','header':_('Key Words'),'dataType':'string'},\ 
  {'name':'messages','header':_('Messages Number'),'dataType':'string'},\ 
  {'name':'creation','header':_('Creation'),'dataType':'string'}, \
  {'name':'activity','header':_('Activity'),'dataType':'string'}, \
  {'name':'status','header':_('Status'),'dataType':'string'}\
]
def page_colsModel(**args):
	""" 
	Return the columns' model of the grid on the client side, which is used to show users' issues.
	Format:
		[{'header':...,'dataIndex':...,'dataType':...},...]
	"""
	[ item.update({'dataIndex': item.pop('name')}) for item in ISSUELISTCOLUMNS ]
	colsModel = [ pagefn.decodeDict2Utf8(item) for item in ISSUELISTCOLUMNS]
	print JSON.encode({'data':colsModel}, encoding='utf8')
	return

def page_issuesData(**args):
	# paging arguments
	showPage, pageNumber = [ int(args.get(name)) for name in ('page', 'perpage') ]
	search = args.get('filter')
	
	# arguments for sort action
	sortby,sorton = [ pagefn.JSLIB['dataGrid']['sorTag'][name] for name in ('sortOn', 'sortBy')] 
	
	# returned data object
	d = {'page':showPage,'data':[],'search':search}
	
	# column's property name
	showProps = [item.get('name') for item in ISSUELISTCOLUMNS]
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
				row[i] = s.decode('utf8')		
		
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

def page_info(**args):
	print DIV(_('Ask help from the staff of the congress!'), **{'class':'info'})
	return
