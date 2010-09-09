['page_folder', 'index', 'page_fileUpload']
from HTMLTags import *

def _renderMenuNode(nodes, node, prefix):
	li = LI()
	aLink = A( node.data.get('text'), **{'id': '-'.join(( prefix, node.id))})
	li <= aLink
	if node.children:	# has submenus
		ul = UL()
		for child in node.children:
			ul <= _renderMenuNode(nodes,child, prefix)
			nodes.remove(child)

		li <= ul

	return li

def _menuHtml(data, prefix):
	''' Constructs the menus list recursively. '''
	idFn = lambda i : i.get('id')
	pidFn = lambda i : i.get('parent')
	handler = treeHandler.TreeHandler(data, idFn, pidFn)
	nodes = handler.flatten()[1:]	# delete the first 'root' node

	# now recursively render the menu tree into html
	while nodes :
		node = nodes.pop(0)
		li = _renderMenuNode(nodes, node, prefix)
		PRINT( li)

	return

def page_folder(**args):
	menuType = args.get(MENUTYPETAG)
	if MENUTYPE.index(menuType) == 0 :
		data = pagefn.USERMENUS['data']
	else:
		data = pagefn.ADMINMENUS['data']

	_menuHtml(data,menuType)

	return

def _innerCss():
	css = \
	"""

	"""

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

	for group in [metaTags, misc, scripts]	:
		for tag in group:
			head <= tag
	return head

def _js():
	paras = []
	paras.extend(CONTAINERS)
	paras = tuple(paras)
	js = \
	"""
	var folder="%s", actions="%s", fileList="%s";

	window.addEvent('domready', function(){
		alert($(folder));

	});

	"""%paras

	return js
def _head():
	head = _headTempl()

	head <= SCRIPT(_js(), **{'type':'text/javascript'})

	return head

def _body():
	body = BODY()
	action = '../demo.ks/page_fileUpload'
	form = FORM(**{'action':action, 'method':'post', 'enctype':'multipart/form-data'})
	body <= form

	div = DIV()
	label = LABEL('File to upload:')
	div <= label + BR()

	input = INPUT(**{'name':'myfile','type':'file'})
	input2 = INPUT(**{'name':'myfile2','type':'file'})
	div <= input + BR() + input2 + BR()
	div <= INPUT(**{'type':'submit', 'value': 'Send'})
	form <= div

	container = DIV(**{'style':'border:2px solid gainsboro;width:1000px;height:400px;', 'id': CONTAINERS[0] })
	# left folder tree
	folderTree = DIV("文件树", **{'id': CONTAINERS[1] })
	style = {'float':'left', 'width':'30%', 'border':'1px solid grey', 'height':'400px'}
	style = [':'.join((key,value)) for key,value in style.items() ]
	style = ';'.join(style)+';'
	folderTree.attrs['style'] = style
	container <= folderTree

	# right file list in a specified folder and actions buttons
	rightDiv = DIV("操作区", **{'id': CONTAINERS[2] })
	style = {'float':'right', 'width':'60%', 'border':'1px solid grey', 'height':'400px'}
	style = [':'.join((key,value)) for key,value in style.items() ]
	style = ';'.join(style)+';'
	rightDiv.attrs['style'] = style
	container <= rightDiv
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


def page_fileUpload(**args):
	import os, shutil
	for name in ( _myfile, _myfile2):
		f = name.file
		dest = os.sep.join(('tmp', os.path.basename(name.filename)))
		outfile = open(dest, 'wb')
		shutil.copyfileobj(f, outfile)
		outfile.close()
	return


