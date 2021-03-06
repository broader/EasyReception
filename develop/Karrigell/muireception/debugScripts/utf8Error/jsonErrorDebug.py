import csv,StringIO,sys
import demjson as JSON

USERCOLUMNS = \
[
	{'name':'username'},\
	{'name':'firstname'},\
	{'name':'lastname'},\
	{'name':'gender'},\
	{'name':'country'},\
	{'name':'organization'},\
	{'name':'email'}\
]

showProps = [item.get('name') for item in USERCOLUMNS]

def csv2dict(content):	
	data = {}
	if content:		
		s = StringIO.StringIO()
		s.write(content)
		s.seek(0)
		reader = csv.reader(s)
		# each row is a key,value pair, such as [[key1, value1], [key2, value2],......]
		data = dict([row for row in reader])
			
	return data	
	
if __name__ == '__main__':	
	fname = 'dossier25'
	fo = open(fname,'rb')
	content = fo.read()
	fo.close()
	data = csv2dict(content)
	print data	
	data = [data,]
	
	reload(sys)
	sys.setdefaultencoding('utf8')
	#encoded = [[i.decode('utf8').encode('utf8') for i in row] for row in data]
	for row in data:
		for k,v in row.items():
			row[k] = v.decode('utf8')
	
	d = {'page':1,'data':[],'search':'test'}
	d['data'] = data
	
	print JSON.encode(d, encoding='utf8')
	#JSON.test()
	