['index']
"""
A data feeder file for smartlist lib test
"""
from HTMLTags import *

# 'THIS.script_url' is a global variable in Karrigell system
APPATH = THIS.script_url[1:]
RELPATH = (lambda p : p.split('/')[0])(THIS.baseurl)

modules = {'pagefn': 'pagefn.py', 'JSON': 'demjson.py', 'formFn':'form.py'}
[locals().update({k : Import('/'.join(('',v)))}) for k,v in modules.items() ]

TESTDATA = [\
	{'name':'broader', 'title':'test'},
	{'name':'tom', 'title':'hotel'},
	{'name':'jerry', 'title':'eat'},
	{'name':'pluto', 'title':'travel'},
	{'name':'obama', 'title':'Nothing can do!'},
	{'name':'clinton', 'title':'play without heart!'},
	{'name':'silary', 'title':'attempts to be calm.'},
	{'name':'gazi', 'title':'game over'},
	{'name':'braker', 'title':'loose soul.'},
	{'name':'brown', 'title':'foolish bean'},
	{'name':'sacury', 'title':'foolish boy'},
]


def index(**args):
	perPage = args.get('itemsPerPage') or 3
	page = args.get('currentPage') or 1
	begin = int(perPage)*int(page)-1
	end = begin + int(perPage)
	data = { 'currentPage': 1, 'data': TESTDATA[begin:end] }
	data['total'] = len(TESTDATA)
	PRINT( JSON.encode(data, encoding='utf8'))
	return

