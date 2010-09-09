['page_fileUpload', 'page_folder', 'index']
from HTMLTags import *
from tools import treeHandler

modules = {'pagefn': 'pagefn.py', 'JSON': 'demjson.py', } #'formFn':'form.py'}
[locals().update({k : Import('/'.join(('',v)))}) for k,v in modules.items() ]

RELPATH = '/'.join((THIS.script_url.split('/')[:-1]))
DATA = Import( '/'.join((RELPATH, 'fileConfig.py')), rootdir=CONFIG.root_dir)

def _renderFolderNode(nodes, node):
	li = LI()
	li.attrs['class'] = 'closed'
	if node.depth() == 2 :
		li.attrs['style'] = 'display:none;'

	span = SPAN(**{'class':'expander'})
	aLink = A( node.id, **{'id': node.id})

	li <= span + aLink
	if node.children:	# has sub folders
		ul = UL()
		for child in node.children:
			ul <= _renderFolderNode(nodes,child)
			nodes.remove(child)

		li <= ul

	return li

ULCSS = 'folderTree'
def _folderHtml(data):
	''' Constructs the file folders tree recursively. '''
	idFn = lambda i : i.get('name')
	pidFn = lambda i : i.get('parent')
	handler = treeHandler.TreeHandler(data, idFn, pidFn)
	nodes = handler.flatten()[1:]	# delete the first 'root' node

	# now recursively render the folder tree into html
	ul = UL(**{'class':ULCSS})
	while nodes :
		node = nodes.pop(0)
		li = _renderFolderNode(nodes, node)
		#print li
		ul <= li

	return ul

def page_fileUpload(**args):
	import os, shutil
	name = args.get('Filedata')
	f = name.file
	dest = os.sep.join(('tmp', os.path.basename(name.filename)))
	outfile = open(dest, 'wb')
	shutil.copyfileobj(f, outfile)
	outfile.close()

	#res = {'status':1, 'args':args.get('Filedata') or '' }
	res = {'status':1, 'args':[args[name] for name in ('Upload', 'Filename')]}
	PRINT( JSON.encode(res, encoding='utf-8'))
	return

def _folderJs():
	paras = [CONTAINERS[1], ]
	paras.extend([\
		'/'.join((RELPATH, name ))
		for name in ('fancyUpload/index.html', 'fancyUpload/script.js','fancyUpload/style.css')])
	paras = tuple(paras)
	js = \
	"""
	var bnContainer="%s",
	    uploaderUrl="%s", uploaderJs="%s", uploaderCss="%s";

	// toggle the status between opening and closed
	function expanderToggle(spanTag){
		var liTag = spanTag.getParent('li'), closed=false;
		if(liTag.hasClass('closed')) closed = true;
		liTag.toggleClass('closed');

		var ulTag = liTag.getChildren('ul');
		if(ulTag.length == 0) return;

		ulTag[0].getChildren('li')
		.each(function(liTag, index){
			switch(closed){
				case true:
					liTag.setStyle('display', 'block');
					break;
				case false:
					liTag.setStyle('display', 'none');
					break;
			};
		});
	};

	// uplod file
	function uploadFile(){
		var el = $(bnContainer).getNext();
		el.empty();
		var options = {};
		el.set('load', options).load(uploaderUrl);

		// import css file
		var css = new Asset.css(uploaderCss);
		var js = new Asset.javascript(uploaderJs);

	};

	// refresh file list
	function refreshList(){
		alert('China');
	};

	// config the layout of the file list
	function layoutConfig(){alert('China');};

	// help information
	function helpInfo(){alert('China');};

	var actionFns = [uploadFile, refreshList, layoutConfig, helpInfo ];
	// handle selected folder
	function folderSelect(aTag){
		// change background color
		$$('.folderTree')[0]
		.getElements('li')
		.map(function(liTag,index){
			liTag.getChildren().slice(0,2)
			.map(function(el,index){
				el.setStyle('background-color','white');
			});
		});
		aTag.getParent('li').getChildren().slice(0,2).map(function(el,index){
			el.setStyle('background-color','gainsboro');
		});

		// enable button's action
		$(bnContainer).getElements('input').each(function(bn,index){
			bn.removeProperty('disabled');
			bn.removeEvents('click');
			bn.addEvent('click', function(e){
				new Event(e).stop();
				actionFns[index]();
			});
		});
	};

	var fnames = [expanderToggle, folderSelect];
	$$('.folderTree')[0].getElements('li').each(function(item,index){
		item.getChildren().slice(0,2).map(function(tag,index){
			tag.addEvent('click', function(e){
				new Event(e).stop();
				fnames[index](e.target);
			});
		});

	});

	"""%paras
	return js

def page_folder(**args):
	data = DATA.getData('VirtualFolder')
	html = _folderHtml(data)
	PRINT( html)
	PRINT( pagefn.script(_folderJs(), link=False))
	return

def _innerCss():
	paras = []
	paras.extend([ '/'.join((RELPATH, name )) for name in ('closed.gif', 'expanded.gif', 'folder.gif', 'folderOpened.gif')])
	paras = tuple(paras)
	css = \
	"""
	.folderTree {
		padding-bottom: 5px;
		position: relative;
		z-index: 2;
	}

	.folderTree li {
		list-style-type: none;
	}

	/*
	.folderTree li.selected {
		background-color: gainsboro;
	}
	*/

	.folderTree li.closed span.expander {
		background-image: url("%s");
		float: left;
		height: 16px;
		width: 16px;
	}

	.folderTree li span.expander {
		background-image: url("%s");
		float: left;
		height: 16px;
		width: 16px;
	}

	.folderTree li.closed a {
		background-image: url("%s");
		background-repeat: no-repeat;
		padding-left: 20px;
		text-decoration: none;
		cursor: pointer;
	}

	.folderTree li a {
		background-image: url("%s");
		background-repeat: no-repeat;
		padding-left: 20px;
		text-decoration: none;
		cursor: pointer;
	}

	"""%paras

	return css

def _css():
	style = STYLE(_innerCss(),**{'type':'text/css', 'media':'screen'})
	return style

def _headTempl():
	head = HEAD()
	metAttrs = [\
		{'http':'Content-Type','content':'text/html; charset=UTF-8'},
		{'http':'X-UA-Compatible','content':'IE=8'}
	]
	metaTags = [ META(**attr) for attr in metAttrs ]

	misc = [TITLE("A demostration for file management !"), _css()]

	names = ('mootools-1.2.2-core.js', 'mootools-1.2.2.2-more.js')
	prefix = '/'.join(2*['..'])
	scripts = [SCRIPT(**{'type':'text/javascript', 'src':'/'.join((prefix, 'scripts',name))}) for name in names ]

	scripts.extend([pagefn.script('/'.join((RELPATH, '/'.join(('fancyUpload',src)) ))) \
		for src in ('Swiff.Uploader.js', 'FancyUpload2.js', 'Fx.ProgressBar.js')])
	for group in [metaTags, misc, scripts]	:
		for tag in group:
			head <= tag
	return head

def _js():
	paras = []
	paras.extend(CONTAINERS)
	urls = [ '/'.join((THIS.script_url, name)) for name in ('page_folder',) ]
	paras.extend(urls)
	paras = tuple(paras)
	js = \
	"""
	var folder="%s", actions="%s", fileList="%s",
	    folderUrl="%s";


	window.addEvent('domready', function(){
		var options = {
			//url: folderUrl
		};
		$(folder).set('load', options);
		$(folder).load(folderUrl);
	});

	"""%paras

	return js
def _head():
	head = _headTempl()

	head <= SCRIPT(_js(), **{'type':'text/javascript'})

	return head

def _body():
	body = BODY()


	# the file folder widget
	container = DIV(**{'style':'border:2px solid gainsboro;width:1000px;height:400px;'})
	# left folder tree
	folderTree = DIV(**{'id': CONTAINERS[0] })
	style = {'float':'left', 'width':'30%', 'border':'1px solid grey', 'height':'400px'}
	style = [':'.join((key,value)) for key,value in style.items() ]
	style = ';'.join(style)+';'
	folderTree.attrs['style'] = style
	container <= folderTree

	# right file list in a specified folder and actions buttons
	rightDiv = DIV()
	style = {'float':'right', 'width':'60%', 'border':'1px solid grey', 'height':'400px'}
	style = [':'.join((key,value)) for key,value in style.items() ]
	style = ';'.join(style)+';'
	rightDiv.attrs['style'] = style
	container <= rightDiv

	# actions container
	#div = DIV(**{'style':'border-bottom: 2px solid gainsboro;' })
	div = DIV()
	span = SPAN(**{'id': CONTAINERS[1]})

	buttons = [{'label':'上传',},{'label':'刷新',},{'label':'设置',},{'label':'帮助',}]
	for bn in buttons:
		span <= INPUT(**{'type':'button', 'value': bn.get('label'), 'disabled':''})

	div <= span
	div <= DIV(**{'style':'border-top: 1px solid gainsboro;border-bottom: 1px solid darkblue;' })
	rightDiv <= div + DIV(**{'id':CONTAINERS[2]})

	body <= container
	return body

CONTAINERS = ('folder', 'actions', 'fileList')
def index(**args):
	PRINT( '''<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">''')

	page = HTML(**{'xmlns':"http://www.w3.org/1999/xhtml"})

	# head
	page <= _head()

	# body
	page <= _body()

	PRINT( page)

	return




