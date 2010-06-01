"""
A data feeder file for smartlist lib test
"""
from HTMLTags import *

# 'THIS.script_url' is a global variable in Karrigell system
APPATH = THIS.script_url[1:]
RELPATH = (lambda p : p.split('/')[0])(THIS.baseurl)

modules = {'pagefn': 'pagefn.py', 'JSON': 'demjson.py', 'formFn':'form.py'}
[locals().update({k : Import('/'.join(('',v)))}) for k,v in modules.items() ]


def index(**args):
	data = [\
		{'name':'broader', 'title':'test'},
		{'name':'tom', 'title':'hotel'},
		{'name':'jerry', 'title':'eat'},
		{'name':'pluto', 'title':'travel'},
	]	
	print JSON.encode(data, encoding='utf8')
	return
