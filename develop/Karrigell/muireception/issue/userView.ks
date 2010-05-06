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

def _issueListJs(container):
	paras = [ container, _('Your Issues List'),]
	paras.extend([pagefn.JSLIB['dataGrid']['filter']['labels'][name] for name in ('action', 'clear')])
	paras = tuple(paras)
	js = \
	"""
	var container=$('%s'), appTitle='%s',
	filterBnLabels=['%s', '%s'];
	
	// title for this app
	container.adopt( new Element('h2',{html:appTitle}), new Element('hr',{style:'padding-bottom:0.1em;'}));	
	
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
	filterContainer.each(function(el){ container.adopt(el);});	

	// datagrid body
	var issueListGrid = new Element('div', {html: 'datagrid'});
	container.adopt(issueListGrid);
	
	"""%paras
	return js

def page_info(**args):
	print DIV(_('Ask help from the staff of the congress!'), **{'class':'info'})
	return
