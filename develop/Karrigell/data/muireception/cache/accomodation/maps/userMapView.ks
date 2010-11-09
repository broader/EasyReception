['index', 'page_map', 'page_thumbnail']
""" Supply a map view for normal user. """
from HTMLTags import *

modules = {'pagefn': 'pagefn.py', }#'JSON': 'demjson.py', 'formFn':'form.py'}
[locals().update({k : Import('/'.join(('',v)))}) for k,v in modules.items() ]


RELPATH = '/'.join(THIS.baseurl.split('/'))
DATA = Import( '/'.join((RELPATH, 'hotelConfig.py')), rootdir=CONFIG.root_dir)

def index(**args):
	container = DIV(**{'class':'subcolumn'})

ZOOMERMAP = 'hotelMapZoomer'
def page_map(**args):
	container = DIV('Big Image', **{'id':ZOOMERMAP})
	PRINT( container)
	return

THUMBMAP = 'hotelMapThumbnail'
def page_thumbnail(**args):
	container = DIV('Thumbnail', **{'id':THUMBMAP})
	PRINT( container)
	return


