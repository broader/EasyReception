import copy

from HTMLTags import *

# import other moules
relPath = lambda p : p.split('/')[0]
model = Import('/'.join((relPath(THIS.baseurl), 'model.py')), REQUEST_HANDLER=REQUEST_HANDLER)

modules = { 'pagefn' : 'pagefn.py', 'formRender' : 'formRender.py' }
[ locals().update({k : Import('/'.join((relPath(THIS.baseurl), v)))}) for k,v in modules.items() ]

so = Session()
if not hasattr(so, 'user'):
	so.user = None 

APPATH = 'service/accommodation/app.ks'
PAGEATTR = {'class' : 'subcolumns', 'style' : 'margin-left:4.5em;width: 80%;'}

def _getService(serviceId, props=None):
	if not props :
		props=('serial', 'price', 'detail', 'description')
				
	values = model.get_item( so.user, \
					      	  'service', \
					          serviceId, \
					          props, \
					          keyIsId=True)
	#service = dict(zip(props, values))
	if 'detail' in props:
		detail = filter( None, values.pop('detail').split(';'))
		[ values.update(dict([item.split(':'),])) for item in detail ]
	return values
	
def _sortReservations(reserves):
	sorted = {}
	for item in reserves :
		values = dict(zip( REGISTRATIONPROP, item ))
		# get the values of target service		
		serviceValues = _getService( values.pop('target') )				
		[ values.update( { name : serviceValues.get(prop) or '' } ) \
		  for name, prop \
		  in zip( ('sSerial', 'sPrice', 'sParent', 'sName' ,'sDes'), \
		  	       ( 'serial', 'price', 'parent', 'alias', 'description') \
		  	     )\ 
		] 		
		
		# parse name and parent info from the 'detail' field		
		serviceParent = values.get('sParent')
		if serviceParent in sorted.keys() :
			sorted[ serviceParent ].append(values)
		else:
			# get service parent's information
			pid = model.serial2id(serviceParent)
			service = _getService(pid)
			parent = {}
			[ parent.update( { name : service.get(prop) or '' } ) \
			  for name, prop in zip( ('sSerial', 'sName' , 'sDes' ), ( 'serial', 'alias', 'description' ) ) ]
			  
			sorted[ serviceParent ] = [ parent, values ]
		
	return sorted
	
def _judge(bookerId, serviceId):
	isNeed = False
	category = model.get_item( so.user, 'service', serviceId, props=('category',), keyIsId=True).get('category')
	userId = model.getItemId('user', so.user)
	if category == CATEGORYNAME and bookerId == userId :
		isNeed = True
	return isNeed
	
REGISTRATIONPROP = ['serial', 'target', 'amount', 'memo']
def _filterReservations( ):
	# get all the resevations of this user
	fnArgs = ('booker', 'target')	
	reserved = model.filterByFunction(so.user, 'reserve', REGISTRATIONPROP, _judge, fnArgs)
	if reserved :		
		reserved = _sortReservations(reserved)
	#print reserved	
	return reserved

RESERVETITLES = (_('Serial'), _('Name'), _('Description'), _('Unit Price'), _('Amount'), _('Sub'), _('Addendum'))
RTITLE2PROP = { _('Serial') : 'sSerial', \
			    _('Name') : 'sName', 
			    _('Description') : 'sDes',\ 
			    _('Unit Price') : 'sPrice', \
			    _('Amount') : 'amount', \
			    _('Addendum') : 'memo' }
EDITACTIONS = ( 'edit', 'delete')
def _registrationList( ):
	#data = _getData()
	data = _filterReservations()	
	# the caption for the table
	attrs = {'style' : 'text-align: left; font-size: 1.5em;font-weight:bold;' }
	caption = CAPTION( _('Your Hotel Reservations'), **attrs)

	# the table's heaaders	
	title2prop = RTITLE2PROP
	titles = RESERVETITLES
	titles = list(titles)
	titles.append(_('Action'))
	
	thead = [TH(title) for title in titles]
	thead = THEAD(TR(Sum(thead)))
	
	# the table's body
	tbody = []
	if data :
		for pserial, hotel in data.items() :		
			# For distinguishing from hotel list tree table, 
			# here we get parent service id
			pid = model.serial2id(pserial)						
			for i, room in enumerate(hotel) :	
				if i == 0 :
					sid = '-'.join(('node', pid))
				else:
					sid = '-'.join(('node', room.get('serial')))
				attr = {'id': sid}		
				parent = room.get('sParent') 
				if parent:
					suffix = '-'.join(('node', pid))			
					attr['class'] = '-'.join(('child-of', suffix))	
				else:
					attr['class'] = SUBCATEGORY_TAG
				
				tds = []				
				for title in titles : 
					# append action tag to this row
					if title == _('Action') and i != 0 :						
						buttons = [IMG(**{'src': pagefn.ICONS.get(name), 'ref' : name}) for name in EDITACTIONS ]
						#buttons.insert(1, TEXT('/'))
						tds.append(TD(Sum(buttons)))
						continue
					
					prop = RTITLE2PROP.get(title)
					value = room.get(prop) or ''
					if prop == 'sSerial' :
						style = {'class' : prop}
						style['style'] = 'display:none;'
						content = [ SPAN(value or '', **style), ]
						style['class'] = 'serial'
						content.append(SPAN( room.get('serial') or '', **style) )
						tds.append(TD( Sum(content) ))
					elif prop == 'amount':
						try:
							value = int(float(value))
							if value == 0:
								value =''
						except:
							value = ''
						tds.append(TD(SPAN(value, **{'class' : prop})))
					elif prop == 'memo':
						tds.append(TD(SPAN(value or '', **{'class' : prop}), style='width:20em;'))
					else:
						tds.append(TD(SPAN(value or '', **{'class' : prop})))
				
									
				# render the hotel row and all types of rooms of the hotel 			
				tbody.append(TR(Sum(tds), **attr))	
			
	tbody = TBODY(Sum(tbody))
	
	table = (caption, thead, tbody)
	table = [ TABLE(Sum(table)), ]
	
	# now set table to be shown as a tree likely style 
	src = \
	'''
	$(document).ready(function(){
		var listDiv="#%s", parentNode=".%s", dialogUrl="%s";
		
		// initialize the tree table
		$(listDiv + " table").treeTable();	  	
		
	  	// set css style of the service list table  	 
	  	$(listDiv + " .expander").each(function(){
	  		$(this).css('margin-left', '0px');
	  	});
	  	
	  	// set click callback function for each reservation row
	  	$(listDiv + " table tbody tr img")
	  	.click(function(){
	  		var act = $(this).attr("ref");
	  		var values = [];
	  		$($(this).parents()[1])
	  		.find("span[class != expander]")
	  		.each(function(){		
				var attrClass = $(this).attr("class");
				var txt = encodeURIComponent($(this).text());
				var a = [ attrClass, txt ].join("=");
				values.push(a);
			});	
			values.push("action=" + act);
			var url = dialogUrl + '?' + values.join("&");
			$.getScript(url);				
	  	});
	});
	'''%( RESERVEDDIV, SUBCATEGORY_TAG,  '/'.join((APPATH, 'page_editControl')) )
	table.append(pagefn.script(src, link=False))
	return Sum(table)

def page_editControl(**args):
	action = args.pop('action')
	if action == EDITACTIONS[0] :
		_editDialog(**args)
	else:
		pass

EDITFORM = 'reserveEdit'
SERVICEINFO = 'serviceInfo'
def _editDialog(**args):
	paras = [ EDITFORM, '/'.join((APPATH, 'page_editForm')), \
			SERVICEINFO, '/'.join((APPATH, 'page_serviceInfo')) ]
	paras.extend( [ args.get(name) for name in ( 'serial', 'sSerial') ] )
	paras.append('/'.join((APPATH, 'page_reserveEdit')))
	paras.append(	pagefn.AJAXLOADING )
	paras.extend(pagefn.FORM_BNS)
	paras = tuple(paras)
	script = \
	'''
	var formId="%s", formSelector = "#"+formId;
	var formUrl="%s";
	var infoId = "%s", infoSelector="#" + infoId;
	infoUrl="%s";
	var rSerial="%s", sSerial="%s";
	var editUrl="%s";
	var ajaxLoading="%s";
	
	// edit action
	function formAction(v,m,f){
		// for 'cancel' button, do nothing
		if(!v){return true}
		
		var paras = [];					
		$.each(f, function(k,v){	
			v = encodeURIComponent(v);			
			paras.push([k,v].join('=') );
		});			
		paras = paras.join('&');			
		url = [editUrl, paras].join('?')
		$.getScript(url);			
	}

	// add validation function to form		 
	function formValid(v,m){
		// "Cancel" button, do nothing
		if(!v){ return true };								
		return $(formSelector).valid();								
	}
	
	// set edit form
	function setForm(){
		infoUrl = infoUrl + "?serial=" +sSerial;
		$(infoSelector).load(infoUrl);
		formUrl = formUrl + "?serial=" +rSerial;
		$(formSelector).load(formUrl);
		$(formSelector).validate({
			onkeyup : false,							
			errorClass: "highlight",
			errorElement: "div"
		});
	}

	var html = '<div id="y"></div><form id="x" class="yform"><img src="url"></form>'
	html = html.replace(/y/i, infoId).replace(/x/i, formId).replace(/url/i, ajaxLoading);
	option = 	{ prefix: "cleanblue",			  		   	
	  		   buttons: { %s : true, %s : false},
	  		   top: 30,		  		   			  		   
	       		   submit: formValid,
	       		   loaded: setForm,
	       		   zIndex: 0,
	       		   callback : formAction,
	  		   opacity : 0.9};			
	
	$.prompt(html, option);
	'''%paras
	print script	
	return	

def page_serviceInfo(**args):
	# get the serial of this reservation
	serial = args.get('serial')	
	# get service information	
	values = _getService(model.serial2id(serial), props=('detail', 'price', 'description'))	
	props = (('alias', _('Room Type')), ('description', _('Description')), ('price', _('Room Price')))	
	# the caption for the table
	attrs = {'style' : 'text-align: center; font-size: 1.5em;font-weight:bold;' }
	# get hotel name
	hotelSerial = values.get('parent')
	pValues = _getService(model.serial2id(hotelSerial), props=('detail',))
	hotel = pValues.get('alias')
	caption = CAPTION( hotel, **attrs)
	# render information
	tbody = []
	for prop, title in props :		
		label = TD(LABEL(title), **{'style' : 'width:20%;'})
		info = TD(values.get(prop) or '')
		tbody.append(TR(Sum((label, info))))
	print TABLE(Sum( (caption, Sum(tbody)) ))

EDITPROPS = ( 'amount', 'memo')
EDITPROPS2TITLE = {'amount' : _('Amount'), 'memo' : _('Addendum')} 
def page_editForm(**args):		
	# get the serial of this reservation
	serial = args.get('serial')
	reserveId = model.serial2id(serial)
	# get the information of this reservation
	props = EDITPROPS 
	prop2title = EDITPROPS2TITLE 
	oldvalues = model.get_item( so.user, \
					      	  'reserve', \
					          reserveId, \
					          props, \
					          keyIsId=True)
	# render edit form
	# the required fields to be input	
	required = ['amount',]	
	
	# set amount to a int number
	oldvalues['amount'] = int(float(oldvalues.get('amount') or 0))
	
	# set other needed fields
	[oldvalues.update({name : value}) for name, value in zip(('action', 'serial'), ('edit', serial))]
			
	hidden = [ 'action', 'serial' ]
	props = list(props)
	props.extend(hidden)
	template = []
	for prop in props:
		if prop in hidden :
			ptype = 'hidden'
			template.append([prop2title.get(prop),{'id': prop, 'name': prop, 'type':ptype}, 'text'])
		elif prop == 'memo' :
			ptype = 'textarea'
			template.append([prop2title.get(prop),{'id': prop, 'name': prop}, 'textarea'])
		elif prop == 'amount' :
			ptype = 'text'
			template.append([prop2title.get(prop),{'id': prop, 'name': prop, 'type':ptype, 'class' : 'digits'}, 'text'])
	
	form = formRender.render_rows(template, oldvalues, required)	
	print Sum(form)

def page_reserveEdit(**args):
	action = args.get('action')
	if action == 'edit' :
		rid = model.serial2id(args.get('serial')) 
		props = {}
		[ props.update({field : args.get(field) or ''}) for field in EDITPROPS ]
		model.edit_item(so.user, 'reserve', rid, props, actionType='edit', keyIsId=True)		 
		info = ','.join( [ ':'.join([k , v]) for k,v in props.items() ] )
		info = ' '.join((_('Reservation item'), rid, _('has updated below values:<br>'), str(info)))
		info = info.replace('\n', '')
	elif action == 'create' :
		pass	
	
	print pagefn.prompt(info) 
	# refresh the reservation list
	print _refreshReservation()
	return

def _refreshReservation( ):
	# return the js scirpt to refresh the agenda calendar
	script = \
	'''
	$(document).ready(function(){
		var ajaxLoading="%s";
		var listDiv="#%s", listUrl="%s";		
		$(listDiv)	
		.html("<img src='x'/>".replace(/x/i, ajaxLoading))
		.load(listUrl);		 
	});
	'''%( pagefn.AJAXLOADING, RESERVEDDIV, '/'.join((APPATH, 'page_reservationList')) )
	return script

def page_reservationList(**args):
	print  _registrationList()

RESERVEDDIV = 'reserveList'	
def _bottomDiv( ):	
	content = [ _registrationList(),]
	attr = copy.copy(PAGEATTR)
	attr['id'] = RESERVEDDIV
	attr['class'] += ' note'
	print DIV(Sum(content), **attr)

def _sortHotels(data):
	sorted = {}
	for hotel in data :
		values = dict(zip(PROPS4TABLE, hotel))
		detail = filter( None, values.get('detail').split(';') )
		temp = {}
		[ temp.update( dict([ i.split(':'), ]) ) for i in detail]
		[ values.update( { name : temp.get(name) } ) for name in ('parent', 'alias') ]
		parent, alias = [ values.get( name ) for name in ('parent', 'alias') ]
		serial = values.get('serial')
		if not parent:
			if serial not in sorted.keys() :
				sorted[serial] = [values,]
			else:
				if values != sorted[serial][0] :
					sorted[serial].insert(0, values)
		else:
			if parent in sorted.keys() :
				sorted[parent].append(values)
			else:
				sorted[parent] = [values,]
	return sorted

CATEGORYNAME = 'Hotel'	
def _getHotels( ):
	''' Get all the hotel service items from database.
	'''
	fnArgs = ('category', )
	fn = (lambda c : c == CATEGORYNAME)
	hotels = model.filterByFunction(so.user, 'service', PROPS4TABLE, fn, fnArgs)
	if hotels :		
		hotels = _sortHotels(hotels)
	return hotels

PROPS4TABLE =  ['serial', 'detail', 'description', 'price', 'amount']
TITLES = [ _('Serial'), _('Room Type'), _('Description'), _('Unit Price'), _('Amount'), _('Left') ]
TITLE2PROP = { _('Serial') : 'serial', \
			  _('Room Type') : 'detail', \
			  _('Description') : 'description',\
			  _('Unit Price') : 'price', \
			  _('Amount') : 'amount'}
SUBCATEGORY_TAG = 'hasChildren'			  
def _hotelList( ):
	''' Get all a list for all capable hotel.
	'''
	data = _getHotels()	
	# the caption for the table
	attrs = {'style' : 'text-align: left; font-size: 1.8em;font-weight:bold;' }
	caption = CAPTION( _('Hotel List'), **attrs)

	# the table's heaaders	
	title2prop = TITLE2PROP
	titles = TITLES
	
	thead = [TH(title) for title in titles]
	thead = THEAD(TR(Sum(thead)))
	
	# the table's body
	tbody = []
	if data :
		for pserial, hotel in data.items() :			
			for i, room in enumerate(hotel) :				
				sid = '-'.join(('node', room.get('serial')))
				attr = {'id': sid}		
				parent = room.get('parent') 
				if parent:
					suffix = '-'.join(('node', parent))			
					attr['class'] = '-'.join(('child-of', suffix))	
				else:
					attr['class'] =SUBCATEGORY_TAG
				
				tds = []				
				for title in titles : 
					prop = TITLE2PROP.get(title)
					value = room.get(prop) or ''
					if prop == 'serial' :
						style = {'class' : prop}
						style['style'] = 'display:none;'
						tds.append(TD(SPAN(value or '', **style)))
					elif prop == 'detail':						
						alias =  SPAN(room.get('alias') or '', **{'class' : 'alias'})
						parent = SPAN(room.get('parent') or '', **{'style': 'display:none;', 'class' : 'parent'})
						tds.append(TD(Sum((alias, parent))))
					elif prop == 'amount':
						try:
							value = int(float(value))
							if value == 0:
								value =''
						except:
							value = ''
						tds.append(TD(SPAN(value, **{'class' : prop})))
					else:
						tds.append(TD(SPAN(value or '', **{'class' : prop})))
				# render the hotel row and all types of rooms of the hotel 			
				tbody.append(TR(Sum(tds), **attr))	
			
	tbody = TBODY(Sum(tbody))
	
	table = (caption, thead, tbody)
	table = [ TABLE(Sum(table)), ]
	
	# now set table to be shown as a tree likely style 
	src = \
	'''
	$(document).ready(function(){
		var listDiv="#%s";
		$(listDiv + " table").treeTable();	  	
	  	// set css style of the service list table  	 
	  	$(listDiv + " .expander").each(function(){
	  		$(this).css('margin-left', '0px');
	  	});
	});
	'''%HOTELISTDIV
	table.append(pagefn.script(src, link=False))
	return Sum(table)

HOTELISTDIV = 'hotelist'	
def _topDiv( ):
	content = [ _hotelList(),]
	attr = copy.copy(PAGEATTR)
	#attr['style'] += 'border-bottom: 1px solid #8B8378;'
	attr['id'] = HOTELISTDIV
	print DIV(Sum(content), **attr)

def index(**args):
	''' The entrance page for accommodation service.
	'''
	# Include js,css files
	js, css = [ pagefn.JSLIBS.get('treeTable').get(name) for name in ('js', 'css') ]
	print pagefn.css(css)
	print pagefn.script(js, link=True) 
	
	# The hotel list content
	_topDiv()
	
	# The user's registration list 
	_bottomDiv()
	
	