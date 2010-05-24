['page_month', 'page_searchTip', 'page_fuzzySearch', 'page_agendaList', 'index', 'page_editForm', 'page_postEdit']
import datetime, calendar, locale, sys, copy, time

from HTMLTags import *

# show local year, month in calendar
reload(sys)
sys.setdefaultencoding('utf8')
locale.setlocale(locale.LC_ALL,'')

relPath = lambda p : p.split('/')[0]
model = Import('/'.join((relPath(THIS.baseurl), 'model.py')), REQUEST_HANDLER=REQUEST_HANDLER)

modules = {'pagefn' : 'pagefn.py',  'JSON' : 'demjson.py' }
[locals().update({k : Import('/'.join(('',v)))}) for k,v in modules.items() ]

so = Session()
if not hasattr(so, 'user'):
	so.user = None

def _getAgenda(search=None, props=None):
	''' Get the agenda of the specified day.
	  If no specified day, return all the agenda items.
	  return agenda items' format is:
	  [[year, month, day],...]
	'''
	if not search :
		# get all agenda items
		days = model.get_items(so.user, 'agenda', props=('day',))
		if type(days) == type('') :
			days = None
		else:
			days = [i[0] for i in days]
			days = [ [int(day.split('/')[x]) for x in (2, 0, 1)] for day in days ]
			days.sort(key=lambda d : calendar.datetime.date(*d))
	else:
		if 'day' not in props:
			props = list(props)
			props.insert(0, 'day')
			days = model.fuzzySearch(so.user, 'agenda', search, props)
			if days :
				[item.pop(0) for item in days]
			else:
				days = None
		else:
			days = model.fuzzySearch(so.user, 'agenda', search, props)
			if type(days) == type('') :
				days = None
	return days

def _monthDeduce(month=None):
	current, pre, next = 3*[None]

	# get the sorted days that has agenda items
	days = _getAgenda()

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
		url = 'agenda/agenda.ks/page_month?month='
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
	'''%(MONTHARROW, CDAY, CMONTH, LISTID, 'agenda/agenda.ks/page_agendaList')
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
	PRINT( _showMonth(days, cur, pre, next, backPage=False))
	return

def _permissionCheck( ):
	''' Check whehter the user has the permission to edit agenda item.
	'''
	return len(set(so.useroles) & set(EDITROLE) ) >= 1

def page_searchTip(**args):
	''' The tooltip html slice for search button.
	'''
	info = '''\
	<div align="left"><span>%s</span><BR>\
	<span>%s</span><BR>\
	<span style="font-size:1.em;font-weight:bold;">%s</span>\
	</div>\
	'''%( _('Fuzzy search in agenda items!'), \
	      _('The format of the input day is :'), \
	      _('month/day/year, such as 12/24/2009'))

	PRINT( DIV(info))
	return

ADDBUTTON='addAgenda'
SEARCHBN='searchAgenda'
SEARCHTXT='searchTxt'
EDITROLE = ('Admin',)
def _editActions(**args):
	style =  'font-weight:bold;font-size:1.5em;margin-left:0.2em;text-decoration:underline;'
	tipUrl = 'agenda/agenda.ks/page_searchTip'
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
	'''%(SEARCHBN, LISTID, SEARCHTXT, pagefn.AJAXLOADING, 'agenda/agenda.ks/page_fuzzySearch')
	search.append( pagefn.script(script, link=False) )

	divs = [ DIV(SPAN(Sum(search)), **{'class':'c50l'})]
	if _permissionCheck() :
		span = SPAN( A( _('< Add New Agenda >'), href='#'),\
				      **{ 'class': ADDBUTTON,\
					    'style': style,\
				      } )
		divs.append( DIV( \
						Sum( (span, _editDialog( ADDBUTTON ) )), \
						**{'class' : 'c50r'}\
					    )\
				    )

	div = DIV(Sum((divs)))
	return DIV(div, **{'class' : 'subcolumns', 'style':'border-bottom: 1px #ddd solid;'})

DAYACCORDION= 'dAccordion'
def page_fuzzySearch(**args):
	''' Search fuzzy word in agenda items, including all String properties.
	  Return a dictionary whose format is :
	  {day: [item,...], ...}
	'''
	txt = args.get('txt')
	notResult = H2('No Results')
	if not txt :
		PRINT( notResult)
		return

	aprops = SHOWFIELDS
	aItems = _getAgenda(txt, aprops)
	if not aItems:
		PRINT( notResult)
		return

	sort = {}
	for item in aItems :
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
		children = [ _mtAgendaItem(dict(zip(aprops, item))) for item in sort.get(key) ]
		showDay = time.strftime('%Y-%m-%d', time.strptime(key, "%m/%d/%Y") )
		divs.append(H3(prefix+showDay))
		innerId = ''.join(key.split('/'))
		divs.append(DIV( Sum(children), **{'id' : innerId}))
		divs.append(pagefn.accordion(innerId) )

	# add callback function to edit button of each item in agenda
	if _permissionCheck():
		[ divs.append(script) for script in (_editDialog( EDITBUTTON ), _delAgendaItem(DELBUTTON )) ]

	PRINT( DIV(Sum(divs), **{'id': DAYACCORDION, 'style':'width: 70%;'}))
	PRINT( pagefn.accordion(DAYACCORDION, 'h3'))

	return

# a temporary funtion to format input string into time
def _cmpStart(stime):
	# stime format is "xx:xx AM|PM"
	start, delta = stime.split(' ')
	delta = {'AM' : 0, 'PM' : 12}.get(delta)
	hour, minute = [int(i) for i in start.split(':') ]
	hour  += delta
	start = ':'.join( [ str(i) for i in (hour, minute) ] )
	return time.strptime(start, '%H:%M')

ACCORDIONID = 'accordion'
LISTID = 'alist'
EDITBUTTON = 'editAgenda'
DELBUTTON='deleteAgenda'
SHOWFIELDS = ( 'day', 'start', 'end', 'title', 'des', 'speakers', 'location', 'serial')
def _agendaList(day=None, backPage=True):
	if day :
		day = day.split('-')
		day = [day[i] for i in (1, 2, 0)]
		day = '/'.join( [ s.zfill(2) for s in day] )
	else:
		days = _getAgenda()
		if days :
			day = time.strftime( '%m/%d/%Y', datetime.date(*days[0]).timetuple() )
		else:
			txt = H4(_('Please select a day and click it in the left calendar to show the agenda of the day.'))
			content = [txt, DIV('', **{'id': ACCORDIONID, 'style':'width: 70%;'})]
			return DIV( Sum(content), \
					     **{'id': LISTID, 'class' : 'subcolumns'})

	aProps = SHOWFIELDS
	agenda =  _getAgenda( str(day),  aProps)

	txt = SPAN( PRE( ' '.join((str(day), _('Agneda'))) ), \
			    **{'style' : 'font-weight:bold;font-size:1.3em;font-style:italic;'})
	content = [BR(),txt, ]

	iStart = list(aProps).index('start')
	# sort agenda itmes by start time
	agenda.sort( key=lambda item : _cmpStart(item[iStart]))

	# render the agenda items of this day
	divs = [ _mtAgendaItem(dict(zip(aProps,item)))  for item in agenda ]

	listDiv = DIV(Sum(divs), **{'id': ACCORDIONID, 'style':'width: 70%;'})
	content.append(listDiv)

	# javascript for accordion function
	content.append(pagefn.accordion(ACCORDIONID, 'h4'))

	# add callback function to edit button of each item in agenda
	if _permissionCheck():
		#script = _editDialog( EDITBUTTON )
		[ content.append(script) for script in (_editDialog( EDITBUTTON ), _delAgendaItem(DELBUTTON )) ]

	content = Sum(content)
	if backPage :
		content = DIV( content, \
					**{'id': LISTID, 'class' : 'subcolumns', 'style':'border-bottom: 1px #ddd solid;'})
	return content

def _mtAgendaItem(agenda):
	''' Render a agenda item in microformat 'event'.
	Parameters:
		agenda - a dictionary holding all the values of items to show.
	'''
	# render item title, including start time, end time and title
	prefix = TEXT(6*'&nbsp;')
	start, end = [ agenda.get(name) for name in ('start', 'end') ]
	start, end = [  t.replace(t.split(' ')[-1], pagefn.HALFDAY.get(t.split(' ')[-1])) \
				for t in (start, end ) ]

	timebucket = SPAN(' - '.join((start, end)))
	title = SPAN(agenda.get('title') or '')
	title = H4(Sum((prefix, timebucket, TEXT(6*'&nbsp;'), title)), **{'href' : '#'})
	# render item inner content, including description, speakers and location
	inner = []
	for prop in ('des', 'speakers', 'location') :
		attr = {}
		if prop == 'des':
			attr['class'] = 'summary'
		elif prop == 'location':
			attr['class'] = 'location'

		txt = ''.join((FIELD2INFO.get(prop) , ' : ', agenda.get(prop) or ''))
		inner.append(SPAN(txt, **attr))

	# Add a edit link tag for the user whose user roles has 'Admin'.
	if _permissionCheck():
		attrs = { 'href' : '#', \
				'ref' : agenda.get('serial'), \
				'style' : 'font-weight:bold;text-decoration:underline;'}

		bnsInfo = [ {'txt' : _('Edit'), 'class' : EDITBUTTON},\
				   {'txt' : _('Delete'), 'class' : DELBUTTON}]

		for bn in bnsInfo :
			attrs['class'] = bn.get('class')
			inner.append( A(bn.get('txt'), **attrs))

	inner = DIV(Sum(inner), **{'class' : 'vevent'})
	return Sum((title, inner))

def page_agendaList(day):
	PRINT( _agendaList(day, backPage=False))
	return

def _agenda(**args):
	divs = [_editActions(), _agendaList()]
	content = DIV(Sum(divs), **{'class':'subcolumns'})
	return DIV(content, **{'class' : 'c66r'})


CONTAINER_STYLE = \
{ 'class' : 'subcolumns',\
  'style' : 'border-bottom: 1px #ddd solid; margin: 1em; width:auto;'}

RELPATH = (lambda p : p.split('/')[0])(THIS.baseurl)

def index(**args):
	''' The reservations, help issues and system messages,
	   all these are hold in a 'subcolumns' Div component.
	'''
	# import css and javascript files at first

	# css
	srcs = ('lib/ui/css/flick/jquery-ui-1.7.2.custom.css', 'lib/timepicker/jquery.ptTimeSelect.css')
	for src in srcs :
		PRINT( pagefn.css(src))

	# javascript, inluding accordion, calendar, time picker, form validate, etc.
	srcs = ('lib/ui/js/jquery-ui-1.7.2.custom.min.js', 'lib/validate/jquery.validate.js', \
		    'lib/validate/validation_messages.js.pih', 'lib/timepicker/jquery.ptTimeSelect.js')
	for src in srcs :
		PRINT( pagefn.script(src, link=True))

	# render the content
	PRINT( DIV(Sum((_showMonth(), _agenda())), **CONTAINER_STYLE))

	# hide the no needed time picker info
	script = \
	'''
	$(document).ready(function(){
		$("#ptTimeSelectCntr").css("display", "none");
	});
	'''
	PRINT( pagefn.script(script, link=False))


FORMFIELDS = ('title', 'des', 'speakers', 'day', 'start', 'end', 'location')
FIELD2INFO = {'title' : _('Title'), 'des' : _('Desscription'), 'speakers': _('Speakers'),\
			'day':_('Day'), 'start':_('Start Time'), 'end':_('End Time'), 'location': _('Location')}
POSTEDIT = 'agenda/agenda.ks/page_postEdit'
EDITFORMURL = 'agenda/agenda.ks/page_editForm'
def _editDialog(button):
	''' Render the javascript to render a popup dialog to edit agenda item.
	'''
	# Add edit form widget, which is a popup dialog and
	# has some interactive widghet for html components, calendar, time picker, etc.
	paras = [ pagefn.AJAXLOADING, EDITFORM ]
	#[ paras.append(FIELD2ID.get(field))  for field in NEEDUI]
	#paras.extend([ _('Hour'), _('Minute'), _('OK')])
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
			if(!v){
				return true
			}
			else{
				return $(formSelector).validate({errorClass: "highlight", errorElement: "div"}).form()
			}
		}

		function formAction(v,m,f){
			// for 'cancel' button, do nothing
			if(!v){return true}
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

def _delAgendaItem(bnClass):
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
	'''%(DELBUTTON, 'agenda/agenda.ks/page_postEdit')
	return pagefn.script(script, link=False)


EDITFORM = 'editForm'
FIELD2ID = {'day': 'dayid', 'start' : 'startid', 'end': 'endid' }
NEEDUI= ('day', 'start', 'end')
def page_editForm(**args):
	fields = FORMFIELDS
	field2info = FIELD2INFO
	required = ('title', 'day', 'start', 'end', 'location')
	# render fields
	table = [ CAPTION(SPAN(_('Edit Agenda'), **{'style' : 'font-weight:bold;font-size: 1.5em;'})), ]
	tbody = []
	serial = args.get('serial')
	if serial:
		aid = model.serial2id(serial)
		values = model.get_item( so.user, 'agenda', aid, props=fields, keyIsId=True)

	for field in fields :
		label = TD(LABEL(field2info.get(field)))
		attr = {'name' : field}
		if field in required :
			attr['class'] = 'required'
		if field in NEEDUI:
			attr['id'] = FIELD2ID.get(field)

		value = ''
		if serial:
			value = values.get(field) or ''

		if field != 'des' :
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
	paras.extend([ _('Hour'), _('Minute'), _('OK')])
	paras = tuple(paras)

	script = \
	'''
	$(document).ready(function(){
		var dayId= "#%s", startId="#%s", endId="#%s";
		var hour="%s", minute="%s", closeBn="%s";
		$(dayId).datepicker();
		var option={ hoursLabel: hour,
				      minutesLabel: minute,
				      setButtonLabel: closeBn
				    }
		$(startId).ptTimeSelect(option);
		$(endId).ptTimeSelect(option);
	});
	'''%paras
	table.append(pagefn.script(script, link=False))
	# render form
	PRINT( TABLE(Sum(table)))

def page_postEdit(**args):
	fields = FORMFIELDS
	action = args.pop('action')
	if action == 'create':
		props = {}
		[ props.update({field : args.get(field) or ''}) for field in fields]
		[props.pop(key) for key in props.keys() if (props[key] in (None, '')) or (key == '_') ]
		aid = model.create_item(so.user, 'agenda', props)
		info = _('Agenda %s has been created!'%aid)
	elif action == 'edit':
		 aid = model.serial2id(args.get('serial'))
		 props = {}
		 [ props.update({field : args.get(field) or ''}) for field in fields]
		 model.edit_item(so.user, 'agenda', aid, props, actionType='edit', keyIsId=True)
		 info = ','.join( [ ':'.join([k , v.decode('utf8')]) for k,v in props.items() ] )
		 info = _('Agenda item %s has updated these values : %s'%(aid, info))
	elif action == 'delete':
		aid = model.serial2id(args.get('serial'))
		model.delete_item(so.user, 'agenda', aid)
		info = 'You have deleted agenda item %s!'%aid

	PRINT( pagefn.prompt(info))
	PRINT( _refreshAgenda())
	return

def _refreshAgenda( ):
	# return the js scirpt to refresh the agenda calendar
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
	'''%( pagefn.AJAXLOADING, LISTID, 'agenda/agenda.ks/page_agendaList?day=', MONTHDIV, 'agenda/agenda.ks/page_month')
	return script


