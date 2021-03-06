#import datetime, calendar, locale, sys, copy, time
import datetime, calendar, locale, sys, time

from HTMLTags import *

# show local year, month in calendar
reload(sys)
sys.setdefaultencoding('utf8')
locale.setlocale(locale.LC_ALL,'')

APPATH = 'broadcast/info.ks'
relPath = lambda p : p.split('/')[0]
model = Import('/'.join((relPath(THIS.baseurl), 'model.py')), REQUEST_HANDLER=REQUEST_HANDLER)

modules = {'pagefn' : 'pagefn.py',  'JSON' : 'demjson.py'}
[locals().update({k : Import('/'.join(('',v)))}) for k,v in modules.items() ]

so = Session()
if not hasattr(so, 'user'):
	so.user = None 
	

EDITROLE = ('Admin',)
def _permissionCheck( ):
	''' Check whehter the user has the permission to edit agenda item.
	'''
	return len(set(so.useroles) & set(EDITROLE) ) >= 1
	
def _mtMessage(message):
	''' Render a message item in microformat 'event'.
	Parameters:
		message - a dictionary holding all the values of items to show.
	'''		
	# render item title, including duration and title
	title = H4( Sum(( TEXT(6*'&nbsp;'),\
				   TEXT(message.get('title') or ''))), \
		           **{'href' : '#'})	
	
	# render item inner content, including description, speakers and location
	inner = []
	for prop in ('content', 'creation', 'duration') :
		attr = {}
		if prop == 'content':
			attr['class'] = 'summary'	
		
		if prop == 'duration':
			start = message.get('start')
			start = time.strptime(start, "%m/%d/%Y")[:3]
			duration = int(message.get('duration') or '0')
			end = datetime.datetime(*start) + datetime.timedelta(duration)
			end = end.timetuple()	
			end = time.strftime("%Y-%m-%d", end)
			txt = ' '.join((_('Broacasting Before:'), end))
		else:
			txt = ''.join((FIELD2INFO.get(prop) , ' : ', message.get(prop) or ''))			
		inner.append(DIV(txt, **attr))
	
	# Add a edit link tag for the user whose user roles has 'Admin'. 
	if _permissionCheck():
		attrs = { 'href' : '#', \
				'ref' : message.get('serial'), \
				'style' : 'font-weight:bold;text-decoration:underline;'}		
		
		bnsInfo = [ {'txt' : _('Edit'), 'class' : EDITBUTTON},\
				   {'txt' : _('Delete'), 'class' : DELBUTTON}]		
		
		for bn in bnsInfo :
			attrs['class'] = bn.get('class')
			inner.append( A(bn.get('txt'), **attrs))
		
	inner = DIV(Sum(inner), **{'class' : 'vevent'})		
	return Sum((title, inner))
	

ACCORDIONID = 'accordion'
LISTID = 'mlist'
EDITBUTTON = 'editMessage'
DELBUTTON='deleteMessage'
SHOWFIELDS = ( 'start', 'duration', 'title', 'content', 'serial', 'creation')
def _messageList(day=None, backPage=True):
	if not day :
		txt = H4(_('Please select a day and click it in the left calendar to show the messages broadcasting in the day.'))
		content = [txt, DIV('', **{'id': ACCORDIONID, 'style':'width: 70%;'})]			
		return DIV( Sum(content), \
				     **{'id': LISTID, 'class' : 'subcolumns'}) 	
	
	txt = SPAN( PRE( ' '.join((day, _('News'))) ), \
			    **{'style' : 'font-weight:bold;font-size:1.3em;font-style:italic;'})
	content = [BR(),txt, ]
		
	day = day.split('-')
	day = [day[i] for i in (1, 2, 0)]
	day = '/'.join( [ s.zfill(2) for s in day] )
	aProps = SHOWFIELDS
	messages =  _getMessages( day,  aProps)
	iDuration = list(aProps).index('duration')
	# sort agenda itmes by start time		
	messages.sort( key=lambda item : int(item[iDuration]))
	
	# render the agenda items of this day
	divs = [ _mtMessage(dict(zip(aProps,item)))  for item in messages ]
	
	listDiv = DIV(Sum(divs), **{'id': ACCORDIONID, 'style':'width: 70%;'})
	content.append(listDiv)
	
	# javascript for accordion function
	content.append(pagefn.accordion(ACCORDIONID, 'h4'))	
	
	# add callback function to edit button of each item in agenda
	if _permissionCheck():
		#script = _editDialog( EDITBUTTON )	
		[ content.append(script) for script in (_editDialog( EDITBUTTON ), _delMessageItem(DELBUTTON )) ]
		
	content = Sum(content)
	'''	
	if backPage :
		content = DIV( content, \
					**{'id': LISTID, 'class' : 'subcolumns' })
	''' 
	return content

def page_messageList(day):
	print _messageList(day, backPage=False)
	

def _delMessageItem(bnClass):
	''' Add 'delete' action callback for 'delete' button in agenda item
	'''
	script = \
	'''
	var actionBn = ".%s", actionUrl = "%s";
	actionUrl += '?action=delete' ;
	$(actionBn).click(function(){
		serial=$(this).attr("ref");
		actionUrl += "&serial=x".replace(/x/i, serial) ;
		$.getScript(actionUrl);			
	});
	'''%( DELBUTTON, '/'.join((APPATH, 'page_postEdit')) )
	return pagefn.script(script, link=False)

	
FORMFIELDS = ('title', 'content', 'start', 'duration' ) 			
FIELD2INFO = \
{'title' : _('Title'), \
'content' : _('Message Content'), \
'start': _('Start Date'), \
'duration':_('Duration '),\
'creation' : _('Created Time') }

POSTEDIT = '/'.join(( APPATH, 'page_postEdit' ))
EDITFORMURL = '/'.join((APPATH, 'page_editForm' ))
def _editDialog(button):
	''' Render the javascript to render a popup dialog to edit message.
	'''
	# Add edit form widget, which is a popup dialog and 
	# has some interactive widghet for html components, calendar, time picker, etc.
	paras = [ pagefn.AJAXLOADING, EDITFORM ]
	paras.extend([ POSTEDIT, button,  EDITFORMURL, _('OK'), _('Cancel') ])		
	paras = tuple(paras)
			
	script = \
	'''
	$(document).ready(function(){
		var ajaxLoading = "%s";
		var formId = "%s", formSelector = "#" + formId; 
		var editUrl="%s", actionBn = ".%s";		
		var formUrl = "%s";
			
		// add click callback function to add agenda action		 
		function formValid(v,m){
			if(!v){ return true }
			else{				
				return $(formSelector)
				.validate({
					errorClass: "highlight", 
					errorElement: "div"
				})
				.form()				
			}
		}
		
		function formAction(v,m,f){
			// for 'cancel' button, do nothing
			if(!v){return true};
			
			var paras = [];					
			$.each(f, function(k,v){				
				paras.push([k,v].join('=') );
			});			
			paras = paras.join('&');			
			if(serial != undefined){
				paras += '&action=edit';
			}
			else{
				paras += '&action=create';
			}
			url = [editUrl, paras].join('?')
			$.getScript(url);			
		}
		
		function setForm(){
			var url = formUrl; 			
			if (serial != undefined){				
				// set old values to form's fields 
				url += '?serial=x'.replace(/x/i, serial); 
			}
			$(formSelector).load(url);
		}
		
		var serial = ''
		// a html slice which just renders a form whose id is 'formId'		
		var html = '<form id="x"><img src="url"></form>'.replace(/x/i, formId).replace(/url/i, ajaxLoading);
		$(actionBn).click(function(){
			serial=$(this).attr("ref");
			option = 	{ prefix: "cleanblue",			  		   	
			  		   buttons: { %s : true, %s : false},
			  		   top: 30,		  		   			  		   
			       		   submit: formValid,
			       		   loaded: setForm,
			       		   zIndex: 0,
			       		   callback : formAction,
			  		   opacity : 0.9};			
			
			$.prompt(html, option);
		});
	});	
	'''%paras	 
	return pagefn.script(script, link=False)

EDITFORM = 'editForm'
FIELD2ID = { 'start' : 'startId' }  
NEEDUI= ('start', )
def page_editForm(**args):
	fields = FORMFIELDS
	field2info = FIELD2INFO	 
	required = ('title', 'start', 'period', 'content')
	# render fields
	table = [ CAPTION(SPAN(_('Edit Message'), **{'style' : 'font-weight:bold;font-size: 1.5em;'})), ]
	tbody = []
	serial = args.get('serial')
	if serial:
		nid = model.serial2id(serial)
		values = model.get_item( so.user, 'news', nid, props=fields, keyIsId=True)	
		
	for field in fields :
		label = TD(LABEL(field2info.get(field)))
		attr = {'name' : field}
		if field in required :
			attr['class'] = 'required'
		
		if field == 'duration' : 
			value = attr.get('class') or ''
			value = ' '.join((value, 'digits')) 
			attr['class'] = value
				
		if field in NEEDUI:
			attr['id'] = FIELD2ID.get(field)
		
		value = ''		
		if serial:
			value = values.get(field) or ''		
			
		if field != 'content' :
			attr['type'] = 'text'	
			attr['value'] = value		
			input = SPAN(INPUT(**attr))
		else:
			attr.update( {'tyep' : 'textarea'})
			input = SPAN(TEXTAREA(value, **attr))
		input = TD(input)
			
		tbody.append(TR(Sum((label, input))))
	
	if serial:
		tbody.append(TR( TD(INPUT(name='serial',value=serial,type='hidden'))))
		
	table.append(Sum(tbody))
	
	# add javascripts for input UI
	paras = [ FIELD2ID.get(field) for field in NEEDUI]
	paras.extend([_('OK'),]) 
	paras = tuple(paras)
	
	script = \
	'''
	$(document).ready(function(){
		var startId="#%s", closeBn="%s";
		$(startId).datepicker();
	});
	'''%paras
	table.append(pagefn.script(script, link=False))
	# render form	
	print TABLE(Sum(table))
	
ADDBN='addMessage'
SEARCHBN='searchMessage'
SEARCHTXT='searchTxt'
def _editActions( ):	
	''' Search and Add tags for searching and adding actions. 
	'''
	style =  'font-weight:bold;font-size:1.5em;margin-left:0.2em;text-decoration:underline;'	
	tipUrl = '/'.join((APPATH, 'page_searchTip'))
	search = [ 		 
			 INPUT( **{'id': SEARCHTXT, 'type':'text', 'size':'20', 'name':'asearch'}),
			 A( _('< Search >'),  **{ 'href': tipUrl, 'rel': tipUrl, 'for' : 'aid', 'style': style, 'id': SEARCHBN})			 
		       ]
	
	# add callback function for the seach button
	script = \
	'''
	$(document).ready(function(){
		var button="#%s", div="#%s", input="#%s";		
		var ajaxLoading ="%s";
		
		$(button).cluetip({	
			insertionType: 'insertAfter',		 
			cluetipClass: 'rounded', 
			dropShadow: false,			 
			positionBy: 'mouse',
			topOffset: 30,			
			arrows: true,
			hoverClass: 'highlight'			
		})		
		.click(function(){			
			var para = ['txt', $(input).attr('value') ].join('=');			
			var actionUrl="%s" ;			
			actionUrl = [actionUrl, para].join('?');
			$(div).html( 
				'<img src="url"/>'.replace(/url/i, ajaxLoading)
			).load(actionUrl);			
		});
	});
	'''%(SEARCHBN, LISTID, SEARCHTXT, pagefn.AJAXLOADING, '/'.join((APPATH, 'page_fuzzySearch')) )
	search.append( pagefn.script(script, link=False) )
		
	divs = [ DIV(SPAN(Sum(search)), **{'class':'c50l'})]	
	
	span = SPAN( A( _('< Add New Message >'), href='#'),\
			      **{ 'class': ADDBN,\
				    'style': style,\
			      } )
	divs.append( DIV( \
					Sum( (span, _editDialog( ADDBN ) )), \
					**{'class' : 'c50r'}\
				    )\
			    )
		
	div = DIV(Sum((divs)), **{'style': 'border-bottom:0.1em solid grey;', 'class':'subcolumns'})
	return div

DAYACCORDION= 'dAccordion'
def page_fuzzySearch(**args):
	''' Search fuzzy word in message items, including all String properties.
	  Return a dictionary whose format is :
	  {day: [item,...], ...} 
	'''	
	txt = args.get('txt')	
	notResult = H2('No result for searching action!') 
	if not txt :
		print notResult
		return
	
	mprops = SHOWFIELDS
	mItems = _getMessages(txt, mprops)	
	if not mItems:
		print notResult
		return
		
	sort = {}
	for item in mItems :
		day = item[0]
		if day in sort.keys():
			sort[day].append(item)
		else:
			sort[day] = [item,]	
	
	# now render the search results into html
	keys = list(sort.keys())
	keys.sort(key=lambda t : time.strptime(t, "%m/%d/%Y"))
	divs = []
	prefix = 6*'&nbsp;'
	for key in keys:
		children = [ _mtMessage(dict(zip(mprops, item))) for item in sort.get(key) ]
		showDay = time.strftime('%Y-%m-%d', time.strptime(key, "%m/%d/%Y") )
		divs.append(H3(prefix+showDay))				
		#divs.append(H3(prefix+key))
		innerId = ''.join(key.split('/'))		
		divs.append(DIV( Sum(children), **{'id' : innerId}))		
		divs.append(pagefn.accordion(innerId) )

	# add callback function to edit button of each item in agenda
	if _permissionCheck():			
		[ divs.append(script) for script in (_editDialog( EDITBUTTON ), _delMessageItem(DELBUTTON )) ]
	
	print DIV(Sum(divs), **{'id': DAYACCORDION, 'style':'width: 70%;'})
	print pagefn.accordion(DAYACCORDION, 'h3')	
	return
	
def page_searchTip(**args):
	info = '''\
	<div align="left"><span>%s</span><BR>\
	<span>%s</span><BR>\
	<span style="font-size:1.em;font-weight:bold;">%s</span>\
	</div>\
	'''%( _('Fuzzy search in messages!'), \
	      _('The format of the input day is :'), \
	      _('month/day/year, such as 12/24/2009'))
	
	print DIV(info)
	return

def _getMessages(search=None, props=None):
	''' Get the news of the specified day.
	  If no specified day, return all the agenda items.
	  return agenda items' format is:
	  [[year, month, day],...]
	'''
	# the date property name
	keyProp = 'start'
	
	if not search :
		# get all agenda items
		days = model.get_items(so.user, 'news', props=(keyProp,))
		if type(days) == type('') :		
			days = None
		else:			
			days = [i[0] for i in days]
			days = [ [int(day.split('/')[x]) for x in (2, 0, 1)] for day in days ]
			days.sort(key=lambda d : calendar.datetime.date(*d))
	else:		
		if keyProp not in props:
			props = list(props)
			props.insert(0, keyProp)
			days = model.fuzzySearch(so.user, 'news', search, props)
			if days :
				[item.pop(0) for item in days]
			else:
				days = None
		else:
			days = model.fuzzySearch(so.user, 'news', search, props)
			if type(days) == type('') :		
				days = None
	return days
	
def _monthDeduce(month=None):
	current, pre, next = 3*[None]
	
	# get the sorted days that has agenda items
	days = _getMessages()
	
	if not days :
		now=datetime.date.today()
		day, month, year = now.day, now.month, now.year
		return [None, '-'.join((str(year), str(month))), None, None]
	
	# a temporary function to format month output to xxxx-xx-xx
	_f = lambda l : '-'.join([ str(n) for n in l] )	
	if not month:
		month = days[0][:2]
		showDays = [day for day in days if day[:2]==month ]		
		if len(days) > len(showDays) :			
			next = _f(days[len(showDays)][:2]) 
	else:		
		month = [int(i) for i in month.split('-') ]
		showDays = [day for day in days if day[:2]==month ]		
		if days.index(showDays[0]) != 0 :
			# get left start day
			i = days.index(showDays[0]) -1 
			# set the value of left tag 
			pre = _f(days[ i ] [:2]) 
		
		prelen = days.index(showDays[0]) + len(showDays)		
		if prelen < len(days) :
			# get right start day
			i = days.index(showDays[0] )+len(showDays)
			# set the value of right tag				
			next = _f(days[ i ] [:2])
		
	current = _f(showDays[0][:2])	
	showDays = [ i[-1] for i in showDays ]	
	return showDays, current, pre, next

MONTHDIV = 'monthDiv'	
MONTHARROW = 'mArrow'
CMONTH = 'cmonth'
CDAY = 'cday'
def _showMonth(days=None, current=None, pre=None, next=None, backPage=True):		
	if not current :
		days, current, pre, next = _monthDeduce(current)
	
	year, month = [int(i) for i in current.split('-') ]

	# all the days in the month and these days are divided into groups each has seven days.
	weeks = calendar.monthcalendar(year,month)
	# the locale description of this month and this year	
	headerMonth = calendar.month(year,month).split('\n')[0]
	headerMonth = SPAN(headerMonth, **{'ref': current, 'id': CMONTH})
	# the link to previous and next month
	tds = []
	for m,s in zip( (pre, next), ('<<', '>>') ) :		
		url = '/'.join((APPATH, 'page_month?month='))
		if m :
			url += m
			attr = {'href':url, 'target': MONTHDIV, 'class' : MONTHARROW}
			tds.append(TD(LABEL(s, **attr)))
		else:
			tds.append(TD(''))
	tds.insert(1, TD(headerMonth, colspan=5, align='center'))
	thead = [ TR( Sum(tds),\
		              style='border-bottom: 0.1em solid black;border-top: 0.25em solid black;font-weight:bold;')\
		     ]		
	tds = [ TD(i) for i in pagefn.WEEKDAYS ]
	thead.append( TR(Sum(tds), style='border-bottom: 0.1em solid black;'))
	
	# add callback function to highlighted day cell 
	script = \
	'''
	$(document).ready(function(){
		var mArrow=".%s", dayClass=".%s";
		var currentMonth = "#%s";
		var listId = "#%s", listUrl = "%s";
		
		// set callback function for the link in the div that shows month calendar
		$(mArrow).unbind().click(function(){
			var div = '#' + $(this).attr('target');			
			var url = $(this).attr('href');
			$(div).load(url);			
		});
		$(dayClass).click(function(){
			var month = $(currentMonth).attr('ref');
			var day = $(this).text(); 
			day = [month, day].join('-');
			var url = listUrl + '?day=' + day;			
			$(listId).load(url);
		});
	});
	'''%(MONTHARROW, CDAY, CMONTH, LISTID, '/'.join((APPATH, 'page_messageList')) )
	thead.append(pagefn.script(script, link=False))	
	
	thead = THEAD(Sum(thead))
	# render the month calendar
	tbody = []
	# a temporary function to replace '0' to ''
	_replaceNone = lambda z : ( z != 0 and z) or ''
	for w in weeks :		
		tds = [] 
		for i in w :			
			attr = {}		
			if i in days :
				attr.update( {'style' : 'background:gainsboro;', 'class' : CDAY})			 
			tds.append(TD(SPAN( _replaceNone(i)), **attr))
			
		tbody.append( TR(Sum(tds)))
			
	tbody = Sum(tbody)
	content = TABLE(Sum((thead, tbody)))
	if backPage:
		content = DIV(content, **{'style': 'margin-left: 2em;', 'id' : MONTHDIV})
		content = DIV( content, \
					 **{'class' : 'c33l', 'style': 'border-right: 1px #ddd solid;margin-left: 1em;width:30%;'})	 	    
	return content

def page_month(**args):	
	days, cur, pre, next = _monthDeduce(args.get('month'))	
	print _showMonth(days, cur, pre, next, backPage=False)
	return
	
def _showMessages( ):
	divs = [_editActions(), _messageList()]	
	content = DIV(Sum(divs), **{'class':'subcolumns'})
	return DIV(content, **{'class' : 'c66r'})
		
		
CONTAINER_STYLE = \
{ 'class' : 'subcolumns',\
  'style' : 'border-bottom: 1px #ddd solid; margin: 1em; width:auto;'}  
def page_manage(**args):
	# import css and javascript files at first
				
	# css
	srcs = ('lib/ui/css/flick/jquery-ui-1.7.2.custom.css', )
	for src in srcs :
		print pagefn.css(src)
	
	# javascript, inluding accordion, calendar, time picker, form validate, etc.
	srcs = ('lib/ui/js/jquery-ui-1.7.2.custom.min.js', 'lib/validate/jquery.validate.js', \
		    'lib/validate/validation_messages.js.pih')
	for src in srcs :
		print pagefn.script(src, link=True)
	
	print DIV(Sum((_showMonth(), _showMessages())), **CONTAINER_STYLE)
	return
	
def index(**args):
	print ''
	
	
def page_postEdit(**args):	
	fields = FORMFIELDS
	action = args.pop('action')
	if action == 'create':				
		props = {}
		[ props.update({field : args.get(field) or ''}) for field in fields]		
		[props.pop(key) for key in props.keys() if (props[key] in (None, '')) or (key == '_') ]				
		nid = model.create_item(so.user, 'news', props)			
		info = _('message %s has been created!'%nid	)				
	elif action == 'edit':
		 nid = model.serial2id(args.get('serial')) 
		 props = {}
		 [ props.update({field : args.get(field) or ''}) for field in fields]
		 model.edit_item(so.user, 'news', nid, props, actionType='edit', keyIsId=True)		 
		 info = ','.join( [ ':'.join([k , v.decode('utf8')]) for k,v in props.items() ] )
		 info = _('Agenda item %s has updated these values : %s'%(nid, info))
	elif action == 'delete':
		nid = model.serial2id(args.get('serial'))
		model.delete_item(so.user, 'news', nid)
		info = 'You have deleted message item %s!'%nid

	print pagefn.prompt(info)	
	print _refreshMessage()
	return
	
def _refreshMessage( ):
	# return the js scirpt to refresh the calendar
	script = \
	'''
	$(document).ready(function(){
		var ajaxLoading="%s";
		var listId="#%s", listUrl="%s";
		var monthId="#%s", monthUrl="%s";
		$.each( [[listId,listUrl], [ monthId, monthUrl]], 
			    function(){				
				$(this[0])	
				.html("<img src='x'/>".replace(/x/i, ajaxLoading))
				.load(this[1]);
		}); 
	});
	'''%( pagefn.AJAXLOADING, LISTID, \
	      '/'.join(( APPATH, 'page_messageList?day=')), \
	      MONTHDIV, \
	      '/'.join(( APPATH, 'page_month')) )
	
	return script