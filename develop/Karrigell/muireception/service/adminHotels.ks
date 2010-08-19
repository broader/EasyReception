"""
Pages mainly for administration functions for 'Hotel' service.
"""
import copy
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
INITCONFIG = Import( '/'.join((RELPATH, 'config.py')), rootdir=CONFIG.root_dir)

#************************************************End******************************************


# ********************************************************************************************
# The page functions begining 
# ********************************************************************************************
INLINEDITCLASS = 'editable'
def index(**args):
	"""
	Show configurable properties for 'Hotel' service.
	"""
	# title
	txt = 'Configurable Properties'
	block = [DIV(A(txt),style="font-weight:bold; font-size:1.2em; padding-bottom:5px;color:#096DD1;")]
	
	# configrable properties
	configField = getattr(pagefn, 'HOTEL').get('categoryInService')
	props = INITCONFIG.getData('service')
	props = props and props.get('hotel')['configProperty'] or {}
	
	# constructs table header
	headers = ('name', 'prompt', 'property', 'value')
	tds = [TH(header) for header in headers]
	
	table = [TR(Sum(tds)),]
	
	# constructs table body
	
	style = 'font-weight:bold;font-size:1.3em;color:#86B50D'
	trs = []
	for value in props:
		tds = []
		for index, attr in enumerate(headers) :				
			d = {}
			if index == 0 :
				d['style'] = style
			elif index == len(headers)-1:
				d['class'] =  ' '.join((INLINEDITCLASS,'@input'))
				d['rel'] = value.get('name')
			else:
				d = {}

			td = TD(value.get(attr) or '', **d)				 
			tds.append(td)
		
		trs.append(TR(Sum(tds)))
	
	table.append(TBODY(Sum(trs)))
	tableId = 'hotelConfigPropsTable'
	block.append(TABLE(Sum(table), **{'id':tableId}))
	
	print Sum(block)

	print pagefn.script(_indexJs(tableId),link=False)
	return

def _indexJs(tableId):
	paras = [ APP, tableId, INLINEDITCLASS, '/'.join((APPATH,'page_editProp'))]
	paras = tuple(paras)
	js = \
	"""
	var appName='%s', container='%s', editableClass='%s', editUrl='%s';
	
	var selector = 'td.'+editableClass;
	var els = $(container).getElements(selector);
	var elsArray = [];
	
	els.each(function(el){
		// get input type
		inpuType = el.get('class').split(' ').erase('editable');
		inpuType = inpuType.length==1 ? inpuType[0] : 'input';
		// get rid of the '@' tag before input type
		inpuType = inpuType.substr(1);
		
		var options = {
			'editUrl': editUrl,
			'errorHandler': info,
			'editFieldName': el.get('rel'),
			'errorHandler': info,
			'inpuType': inpuType
		};
		elsArray.push({'element': el, 'options': options});	
	});
	
	MUI.inlineEdit(appName, elsArray);
	
	function info(){ MUI.notification('Edit action failed!');};
	
	"""%paras
	return js

def page_setProp(**args):
	res = {'ok':'1'}
	print JSON.encode(res)
	return


