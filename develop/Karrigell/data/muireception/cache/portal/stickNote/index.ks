['index']


from HTMLTags import *
#from tools import treeHandler
modules = {'pagefn': 'pagefn.py', } # 'JSON': 'demjson.py', } #'formFn':'form.py'}
[locals().update({k : Import('/'.join(('',v)))}) for k,v in modules.items() ]


def _js():
	paras = [CONAINER, ACTIVEAREA, NOTE]
	paras = tuple(paras)
	js = \
	"""
	var container="%s", dropArea=".%s", note=".%s";


	window.addEvent('domready', function(){

		var draggableOptions = {
			droppables: $$(dropArea),
			container: $(container),
			onStart: function(el,dr){
				el.setStyle('opacity', '0.5');
			},

			onComplete: function(el, dr){
				el.setStyle('opacity', '1');
			},
			onDrop: function(el, dr){
				if(!dr) return;
				dr.highlight('#667CA4');

			},
			onEnter: function(el, dr){
				if(!dr) return;
				dr.highlight('#FB911C');

			},
			onLeave: function(el,dr){
				if(!dr) return;
				dr.highlight('#FB911C');
			}
		};

		$$(note).each(function(item){
			item.makeDraggable(draggableOptions);
			var rotate = new Fx.Rotate(item);
			rotate.start(0, -0.00019);
		});
	});
	"""%paras
	return js

CONAINER, ACTIVEAREA, NOTE, NOTEHANDLE, NOTECLOSEBN = 'stickNoteContainer', 'droppable', 'note', 'handle', 'closeNote'
def _innerBody():
	container = DIV(**{'class':CONAINER,'id':CONAINER})

	# the area for dropping notes
	div = DIV(**{'class':ACTIVEAREA})
	container <= div

	# a sticky note
	note = DIV(**{'class':NOTE, 'style':'margin-top:2em;margin-left:2em;'})
	# add needle image and closing button
	span = SPAN(**{'class': NOTEHANDLE})
	span <= IMG(**{'class':'needle', 'src':'../needleleftyellow.png'})
	span <= IMG(**{'class':NOTECLOSEBN, 'src':'../close.png'})
	note <= span

	note <= H3('Title')+P(I('欢迎您的来访!'))

	#note <= span
	#span = SPAN(IMG(**{'src':'../close.png'}),**{'class':NOTECLOSEBN})

	div <= note

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

	# page initial js
	PRINT( '</head>')

	return

def index(**args):
	PRINT( '''<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">''')
	PRINT( '<html xmlns="http://www.w3.org/1999/xhtml">')

	_head()

	user = args.get('user') or None

	# body
	_body(user)

	PRINT( '</html>')
	return


