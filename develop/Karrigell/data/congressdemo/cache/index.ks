['index']
""" A demostration page for congress portal  """
from HTMLTags import *

#modules = {'pagefn': 'pagefn.py', 'JSON': 'demjson.py', 'formFn':'form.py'}
#[locals().update({k : Import('/'.join(('',v)))}) for k,v in modules.items() ]


RELPATH = '/'.join(THIS.baseurl.split('/'))
#DATA = Import( '/'.join((RELPATH, 'hotelConfig.py')), rootdir=CONFIG.root_dir)

def _css():
	#style = STYLE(_innerCss(),**{'type':'text/css', 'media':'screen'})
	tags = []
	tags.append( LINK(**{'href': '../style.css', 'rel':'stylesheet', 'type': 'text/css'}) )
	return tags

def _js():
	#paras = []
	#paras = tuple(paras)
	js = \
	"""
	"""

	return js

def _headTempl():
	head = HEAD()
	metAttrs = [\
		{'http':'Content-Type','content':'text/html; charset=UTF-8'},
		{'http':'X-UA-Compatible','content':'IE=8'}
	]
	metaTags = [ META(**attr) for attr in metAttrs ]

	s = _("A demostration for congress portal !")
	misc = [TITLE(s), ]

	css = _css()

	names = ('mootools-1.2.2-core.js', 'mootools-1.2.2.2-more.js')
	prefix = '/'.join(4*['..'])
	scripts = [SCRIPT(**{'type':'text/javascript', 'src':'/'.join((prefix, 'scripts',name))}) for name in names ]

	for group in [metaTags, misc, css, scripts]	:
		for tag in group:
			head <= tag
	return head


def _head():
	head = _headTempl()

	head <= SCRIPT(_js(), **{'type':'text/javascript'})

	return head

def _navBar():
	headerDiv = DIV(**{'id': 'header'})

	leftLogo = H1(**{'id': 'sitename'})
	for value, klass in (('I', 'big'),('Impression', 'logosmall')) :
		leftLogo <= SPAN(value, **{'class': klass})
	headerDiv <= leftLogo

	nav = DIV(**{'id': 'navigation'})
	ul = UL()
	menus = (\
		{'label':'Home', 'href':'index.html'},\
		{'label':'Tables', 'href':'tables.html'},\
		{'label':'Blog Entries', 'href':'blog.html'},\
		{'label':'Forms', 'href':'forms.html'},\
	)

	for index,item in enumerate(menus):
		li = LI()
		a = A( item.get('label'), href= item.get('href'))
		if index == 0 :
			li.attrs['class'] = 'active'
		li <= a
		ul <= li
	nav <= ul
	headerDiv <= nav
	headerDiv <= DIV(**{'class':'clear'})
	return headerDiv

def _innerBody():
	contents = [_navBar(),]
	# header which contains navgation bar

	return Sum(contents)

def _footer():
	copyright = [ TEXT('Copyright &copy; Yoursite.com') ]
	aTags = [A(label, href='#') for label in ('Lorem', 'Ipsum', 'Dolar', 'etc')]
	copyright.extend(aTags)
	copyright = TEXT( ' | '.join([ str(tag) for tag in copyright ]) )

	templInfo = DIV(\
		A('CSS Template', href='http://www.ramblingsoul.com')+TEXT(' by Rambling Soul'), \
		**{'id':'templateinfo'}\
	)

	return copyright+templInfo

def _body():
	body = BODY()

	# the main container for content
	div = DIV(_innerBody(), **{'id':'wrap'})
	body <= div

	# the footer
	div = DIV(_footer(), **{'id':'footer'})
	body <= div

	return body

def index(**args):
	PRINT( '''<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">''')


	page = HTML(**{'xmlns':"http://www.w3.org/1999/xhtml"})

	# head
	page <= _head()

	# body
	page <= _body()

	PRINT( page)

	return



