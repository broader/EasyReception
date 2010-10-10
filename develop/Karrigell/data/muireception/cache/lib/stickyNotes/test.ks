['index']
from HTMLTags import *
#from tools import treeHandler
modules = {'pagefn': 'pagefn.py', } # 'JSON': 'demjson.py', } #'formFn':'form.py'}
[locals().update({k : Import('/'.join(('',v)))}) for k,v in modules.items() ]


def _js():
	paras = [ACTIVEAREA, NOTE]
	paras = tuple(paras)
	js = \
	"""
	var dropArea="%s", note=".%s";

	window.addEvent('domready', function(){

		var select = $(dropArea).getNext().getChildren()[0];
		if(select.getProperty('value')== 'add')
		    select.setProperty('value', 'cascade');

		var initLayout = select.getProperty('value');
		var options = {
			dropElements: [$(dropArea),],
			container: $(dropArea),
			notesData: [
				{title:'Note1',content: 'Welcome'},
				{title:'Note2',content: 'Welcome'},
				{title:'Note3',content: 'Welcome'},
				{title:'Note4',content: 'Welcome'},
				{title:'Note5',content: 'Welcome'}
			],
			layout:  initLayout
		};

		var sn = new StickyNotes(options);

		select.addEvent('change',function(e){
			var action = e.target.getProperty('value');
			if (action == 'add') sn.addNotes([{title:'New Ticket', content:'Great China!'},]);
			else {sn.resetLayout(action);}
		});

	});
	"""%paras
	return js

CONAINER, ACTIVEAREA, NOTE, NOTEHANDLE, NOTECLOSEBN = 'stickNoteContainer', 'droppable', 'note', 'handle', 'closeNote'
def _innerBody():
	container = DIV(**{'class':CONAINER,'id':CONAINER})

	# the area for dropping notes
	div = DIV(**{'class':ACTIVEAREA,'id':ACTIVEAREA, 'style':'width:80%;background-color:grey;height:800px;float:left;'})
	container <= div

	# add a select button to the right margin of the page
	div = DIV(**{'style':'float:right;width:20%;'})
	select = SELECT()
	for name in ('cascade', 'grid', 'circle', 'add'):
		select <= OPTION(name, value=name)

	div <= select

	container <= div

	PRINT( container)

	# js slice
	PRINT( pagefn.script(_js(), link=False))

	return
def _body(user=None):
	PRINT( "<body>")

	_innerBody()

	PRINT( "</body>")
	return

def _head():
	PRINT( '<head>')

	metAttrs = [\
		{'http':'Content-Type','content':'text/html; charset=UTF-8'},
		{'http':'X-UA-Compatible','content':'IE=8'},
		{'name': 'description', 'content': _("The portal in a desktop likely style for EasyReception")},
		{'http':'X-UA-Compatible','content':'IE=edge'}
	]
	for tag in [ META(**attr) for attr in metAttrs ]:
		PRINT( tag)

	PRINT( TITLE(_("Sticky Note Test")))

	# css links
	#for name in ("Content.css", "Core.css", "Layout.css", "Dock.css", "Tabs.css", "Window.css" ) :
		#print LINK(**{'rel':'stylesheet', 'type': 'text/css', 'href': '/'.join(('..', 'themes', 'default', 'css', name))})
	for name in ("style.css",) :
		PRINT( LINK(**{'rel':'stylesheet', 'type': 'text/css', 'href': '/'.join(('..', name))}))

	# google font
	#print LINK(**{'href':'http://fonts.googleapis.com/css?family=Reenie+Beanie:regular', 'rel':'stylesheet', 'type':'text/css'})
	#print \
	"""
	<!--[if IE]>
		<script type="text/javascript" src="scripts/excanvas_r43.js"></script>
	<![endif]-->
	"""

	# javascript files' links
	for name in ('mootools-1.2.4-core.js', 'mootools-1.2.4.2-more.js') :
		PRINT( SCRIPT(**{'type':'text/javascript', 'src': '/'.join(('..', '..','..', 'lib', 'mootools', name))}))


	# mootools Assets tools
	#print pagefn.script( '/'.join(('..', 'lib','tools','assetsmanager.js')), link=True)
	PRINT( pagefn.script( '/'.join(('..', '..', '..', 'lib','rotate','Fx.Rotate.js')), link=True))
	PRINT( pagefn.script( '/'.join(('..', '..', '..', 'lib','stickyNotes','stickyNotes.js')), link=True))

	# page initial js
	PRINT( '</head>')

	return

def index(**args):
	PRINT( '''<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">''')
	PRINT( '<html xmlns="http://www.w3.org/1999/xhtml">')

	_head()

	# body
	_body()

	PRINT( '</html>')
	return


