from HTMLTags import *
import sys

model = Import("../model.py", REQUEST_HANDLER=REQUEST_HANDLER)
config = Import("../admin_config.py")
JSON = Import('../demjson.py')	 

so = Session()
if not hasattr(so, 'user'):
	so.user = None 

def index(**args):
	print SCRIPT(type='text/javascript',\
				language='javascript',\
				src='lib/dataTable/js/jquery.dataTables.js') 
	
	# set the language text in web table 
	lan = [l for l in ACCEPTED_LANGUAGES if l in ('zh', 'zh-cn', 'cn')]
	if len(lan):
		txt = 'lib/dataTable/i18n/cn_CN.txt'
	else:
		txt = ''
			
	script= '''$(document).ready(function() {
				// call back function for show row info in a editable Div component
				function initialFrame(responseText, textStatus, XMLHttpRequest){					
					$(this).activateJFrame();
				};
				
				// the call back function for each row in table body
				function rowcb(nRow, aData, iDisplayIndex){					
					$(nRow).each(function(){
						$(this).click(function(){
							url = "manage/userlist.ks/page_account"+"?"+"username="+aData[0]+"&columns="+2;							
							$("#base_info").load(url, "", initialFrame);													
						});
					});
					return nRow;
				};
				
				uTable = $('#usersList').dataTable( {
					"bProcessing": true,
					"bServerSide": true,					
					"sAjaxSource": "manage/userlist.ks/getData",
					"sPaginationType": "full_numbers",	
					"fnRowCallback": rowcb,							
					"oLanguage": {"sUrl": "%s"}
				} );
				$("#usersList").css("width", "50em");
			} );'''%txt	
	
	print SCRIPT(script, **{'type': 'text/javascript' , 'charset': 'utf-8'})	
	print H1(_("Registered Users List"))
	print HR()
	table = []
	# add table head 
	th_content = config.userlist_th_content
	
	th = [TH(item[1], **item[0]) for item in th_content]
	tr = TR(Sum(th))
	table.append(THEAD(tr))
	
	# add table body
	table.append(TBODY())
	
	# add table footer
	th =  [TH(item[1]) for item in th_content]
	tr = TR(Sum(th))
	table.append(TFOOT(tr))
			
	table_props = {'id': 'usersList', 'class':'display'}
	table = TABLE(Sum(table), **table_props)
	print DIV(table, **{'id': 'dynamic', 'class': 'example_alt_pagination'})
	print DIV(**{'style': 'height: 20px;clear: both;'})	
	
def getData(**args):
	admin = so.user			
	# paging arguments
	start = int(args.get('iDisplayStart'))
	step = int(args.get('iDisplayLength'))	
	# searching value
	search = args.get('sSearch').strip()	
	# order arguments
	# how many columns to be ordered 
	columns = args.get('iSortingCols')
	
	# column's property name
	propnames = [item[-1] for item in config.userlist_th_content]
	order = []
	if columns:		
		for i in range(int(columns)):
			cindex = '_'.join(('iSortCol', str(i)))
			cindex = int(args.get(cindex))
			prop = propnames[cindex]
			corder =  '_'.join(('iSortDir', str(i)))
			if args.get(corder) == 'asc' :
				corder = '+'
			else:
				corder = '-'
			order.append((prop, corder))
	else:
		order.append((propnames[0], '+'))	
	
	total, data = model.get_userlist(admin, propnames, search)	
	# restruct the properties values	
	res = {}
	# the total items number in result
	res['iTotalRecords'] = total
	# the filtered items number to be displayed 
	res['iTotalDisplayRecords'] =  len(data)
	res['aaData'] = []
	# set python default encoding to 'utf8'
	reload(sys)
	sys.setdefaultencoding('utf8')
	
	if data :		
		# sort and order
		# set sort keys		
		keys = [propnames.index(item[0]) for item in order]		
		data.sort(key=lambda row : tuple([row[i] for i in keys] ))		
		if order[0][1] == '-':
			data.reverse()
			
		# get the data of the displayed page
		end = start + step
		# get data slice in the displayed page from the data 	
		rslice = 	data[start : end]
		
		# if ascii chars mixins with no ascii chars will result
		# JSON.encode error, so decode all the data items to unicode. 
		d = [[i.decode('utf8') for i in row] for row in rslice]
		res['aaData'] = d
		
	print JSON.encode(res, encoding='utf8')		


def page_account(**args):
	if args and args.get('username'):		
		url = '&'.join(['='.join((name,args.get(name))) for name in ('username', 'columns') ])
		url = '?'.join(('../user/info.ks', url))
		print Include(url)
	else:
		print H1(_('User Base Information Edit Area'))
		print HR()