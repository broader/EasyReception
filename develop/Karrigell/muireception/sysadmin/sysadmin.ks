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
	klass,panel = [args.get(name) for name in (CLASSPROP,'panel')]
	#print H3(klass)
	container = '-'.join((CONTAINER_PREFIX,klass))
	print DIV(**{'id': container})
	print pagefn.script(_showClassJs(klass,panel),link=False)
	return

CLASSPROP = 'klass'
def _showClassJs(klass,panel):
	paras = [USER,klass,panel,CLASSPROP]
	paras.extend(['/'.join((APPATH,page)) for page in ('page_classInfo','page_classEdit')])
	paras = tuple(paras)
	js = \
	"""
	var user='%s',klass='%s', containerId='%s', klassprop='%s'
	infoUrl='%s', editUrl='%s';
	
	// create MUI.Columns
	var columnIds = ['klassEditColumn','klassInfoColumn'];
	var columnAttrs = [
		{'id':columnIds[0],'placement':'main','resizeLimit':[100,200],'width':null},
		{'id':columnIds[1],'placement':'right','resizeLimit':[400,500],'width':500}
	];
	
	columnAttrs.each(function(attr){
		new MUI.Column({
			container: containerId, id: attr.id, placement: attr.placement, 
			sortable: false, width: attr.width, resizeLimit: attr.resizeLimit 
		});
	});
	
	// get content urls
	query = $H();
	query[klassprop] = klass;
	query = query.toQueryString();
	
	// create MUI.Panels
	[
		{'column':columnIds[0],'id':'klassEditPanel','url':editUrl},
		{'column':columnIds[1],'id':'klassInfoPanel','url':infoUrl}
		
	].each(function(attrs){
		pid = attrs.id,
		url = [attrs.url,query].join('?');
		new MUI.Panel({
			id: attrs.id,
			column: attrs.column, 
			header: false,
			contentURL: url,
			onExpand: MUI.accordionPanels.pass(attrs.id)
		});
		
	});
	
	
	"""%paras 
	return js

CLASSNAMESTYLE = "font-weight:bold; font-size:2.5em; padding-bottom:5px;color:#096DD1;"
def page_classInfo(**args):
	klass = args.get(CLASSPROP)

	# Class name
	block = [DIV(A(klass) , style=CLASSNAMESTYLE),]
			
	
	# Properties for this Class
	props = model.get_class_props(USER, klass, protected=1)
	propnames = props.keys()
	propnames.sort()
	
	d = {'style':'font-weight:bold;font-size:1.3em;color:#86B50D'}
	table = []
	for propname in propnames:			
		prop = TD(propname,**d)			
		des = TD(repr(props[propname]).strip('<>'))
		tr = TR(Sum((prop, des)))
		table.append(tr)			
	
	block.append(TABLE(TBODY(Sum(table))))
	print Sum(block)
	return

GRIDID, FILTERINPUTID,FILTERBN,FILTERCLEARBN = ('classGrid', 'filterInput','filterbn','filtereset')
def page_classEdit(**args):
	klass = args.get(CLASSPROP)
	title = ' '.join((klass,_('Items')))
	
	input = INPUT(**{'style':'margin:15px 5px 15px 0;','id':FILTERINPUTID,'value':''})
	bn = A(_('Filter'),**{'id':FILTERBN, 'href':'javascript:;'})
	rbn = A(_('Clear Filter'),**{'id':FILTERCLEARBN, 'href':'javascript:;'})
	
	print SPAN(title,style=CLASSNAMESTYLE),HR(style='padding:0 0 0.1em'),SPAN(Sum((input,bn,TEXT(' | '),rbn))),DIV(**{'id':GRIDID})
	#print pagefn.script(_usersTridJs(), link=False)
	
	return
	
def _classEditJs():
	paras = []
	paras = tuple(paras)
	js = \
	"""
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
	
	