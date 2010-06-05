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
	perPage, page = [\
		int(args.get(name) or number) \
		for name, number in zip(('itemsPerPage','currentPage'),(3,1))]

	search = args.get('search')
	items = TESTDATA
	if search:
		items = filter(lambda i: search in ','.join(i.values()), items)
		#page = 1

	data = {'total': len(items)}
	data['pageNumber'] = (lambda x,y: x/y + (x%y != 0 and 1 or 0) )(data['total'], perPage)
	begin = perPage*(page-1)
	end = begin + perPage
	data.update( {'currentPage': page, 'data': items[begin:end] })
	PRINT( JSON.encode(data, encoding='utf8'))
	return

