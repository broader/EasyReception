from HTMLTags import *
#from tools import treeHandler
modules = {'pagefn': 'pagefn.py', 'JSON': 'demjson.py', } #'formFn':'form.py'}
[locals().update({k : Import('/'.join(('',v)))}) for k,v in modules.items() ]

RELPATH = (lambda p : p.split('/')[0])(THIS.baseurl)
APPATH = THIS.script_url[1:]

def page_data(**args):
	res = [{'title': 'Ticket %s'%(i+1), 'content': 'Welcome!'} for i in range(5)]
		
	print JSON.encode(res, encoding='utf-8')
	return

def _js():
	#paras = [ACTIVEAREA, NOTE, '/'.join((APPATH, 'page_data'))]
	paras = [ACTIVEAREA, NOTE, 'page_data']
	paras = tuple(paras)
	js = \
	"""
	var dropArea="%s", note=".%s", dataUrl="%s";

	window.addEvent('domready', function(){
		
		var select = $(dropArea).getNext().getChildren()[0];
		if( ['add', 'closeAll'].contains(select.getProperty('value')))
		    select.setProperty('value', 'cascade');
		
		// the sticky notes widget initial
		var initLayout = select.getProperty('value');
		var options = {
			dropElements: [$(dropArea),],
			container: $(dropArea),
			notesDataUrl: dataUrl,
			layout:  initLayout
		};	
		
		var sn = new StickyNotes(options);
		
		select.addEvent('change',function(e){
			var action = e.target.getProperty('value');
			if (action == 'add') {
				sn.addNotes([{title:'New Ticket', content:'Great China!'},]);
			}
			else if (action == 'closeAll'){
				sn.closeAll();
			}
			else {sn.resetLayout(action);}
		});
		
	});
	"""%paras
	return js

#CONTAINER, ACTIVEAREA, NOTE, NOTEHANDLE, NOTECLOSEBN = 'stickNoteContainer', 'droppable', 'note', 'handle', 'closeNote'
ACTIVEAREA, NOTE, NOTEHANDLE, NOTECLOSEBN = 'droppable', 'note', 'handle', 'closeNote'
def _innerBody():
	#container = DIV(**{'class':CONTAINER,'id':CONTAINER})
	container = DIV()
	
	# the area for dropping notes
	div = DIV(**{'class':ACTIVEAREA,'id':ACTIVEAREA, 'style':'width:80%;background-color:grey;height:800px;float:left;'})
	container <= div
	
	# add a select button to the right margin of the page
	div = DIV(**{'style':'float:right;width:20%;'})
	select = SELECT()
	for name in ('cascade', 'grid', 'circle', 'add', 'closeAll'):
		select <= OPTION(name, value=name)

	div <= select
		
	container <= div

	print container
	
	# js slice
	print pagefn.script(_js(), link=False)

	return
def _body(user=None):
	print "<body>"

	_innerBody()

	print "</body>"
	return

def _head():
	print '<head>'

	metAttrs = [\
		{'http':'Content-Type','content':'text/html; charset=UTF-8'},
		{'http':'X-UA-Compatible','content':'IE=8'},
		{'name': 'description', 'content': _("The portal in a desktop likely style for EasyReception")},
		{'http':'X-UA-Compatible','content':'IE=edge'}
	]
	for tag in [ META(**attr) for attr in metAttrs ]:
		print tag

	print TITLE(_("Sticky Note Test"))

	# css links
	for name in ("stickyNotes.css",) :
		print LINK(**{'rel':'stylesheet', 'type': 'text/css', 'href': '/'.join(('..', name))})

	print \
	"""
	<!--[if IE]>
		<script type="text/javascript" src="scripts/excanvas_r43.js"></script>
	<![endif]-->
	"""

	# javascript files' links
	for name in ('mootools-1.2.4-core.js', 'mootools-1.2.4.2-more.js') :
		print SCRIPT(**{'type':'text/javascript', 'src': '/'.join(('..', '..','..', 'lib', 'mootools', name))})
	
	
	# mootools Assets tools
	#print pagefn.script( '/'.join(('..', 'lib','tools','assetsmanager.js')), link=True)
	print pagefn.script( '/'.join(('..', '..', '..', 'lib','rotate','Fx.Rotate.js')), link=True)
	print pagefn.script( '/'.join(('..', '..', '..', 'lib','stickyNotes','stickyNotes.js')), link=True)
	
	# page initial js
	print '</head>'

	return

def index(**args):
	print '''<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">'''
	print '<html xmlns="http://www.w3.org/1999/xhtml">'
	
	_head()

	# body
	_body()

	print '</html>'	
	return	

