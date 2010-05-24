import urllib, copy, time, datetime

from HTMLTags import *

# import other moules
relPath = lambda p : p.split('/')[0]
model = Import('/'.join((relPath(THIS.baseurl), 'model.py')), REQUEST_HANDLER=REQUEST_HANDLER)

modules = {'pagefn' : 'pagefn.py' }
[locals().update({k : Import('/'.join(('',v)))}) for k,v in modules.items() ]

so = Session()
if not hasattr(so, 'user'):
	so.user = None 

CONTAINER_STYLE = \
{ 'class' : 'subcolumns',\
  'style' : 'border-bottom: 1px #ddd solid; margin: 1em; width:auto;'}
  
TOP, CENTER_LEFT, CENTER_MIDDLE, CENTER_RIGHT, BOTTOM = \
('eTop', 'eCenterLeft', 'eCenterMiddle', 'eCenterRight', 'eBottom')

TITLEATTRS = {'font-size' : '1.6em', 'font-weight' : 'bold', 'color' : 'cadetBlue'}
STYLEADAPTER = lambda d : ';'.join([':'.join([k,v]) for k,v in d.items()]) 

def _centerLeftDiv(**args):
	attrs = copy.copy(TITLEATTRS)
	attrs['color'] = '#D6EB9A'
	style = STYLEADAPTER( attrs )
	title = SPAN(_('Congress Notes'), **{'style' : style})
	props = ('start', 'title', 'content', 'duration')
	messages = _showMessage(props)
	lis = []
	if messages :
		for item in messages :
			values = dict(zip(props, item))
			inner = []
			for prop in ( 'title', 'content') :
				attr = {}
				if prop == 'title':
					attr['class'] = 'summary'			
				txt = values.get(prop) or ''			
				inner.append(SPAN(txt, **attr))
			lis.append( DIV(Sum(inner), **{'class' : 'vevent'}) )	
	messages = UL(Sum(lis))
	content = Sum( [title, HR(), messages ] )
	
	content = DIV(DIV( content, \
				       **{'class' : 'subc', 'id': CENTER_LEFT }),\
				**{'class' : 'c33l', 'style': 'border-right: 1px #ddd solid;'})
	return content

def _centerRightDiv(**args):
	attrs = copy.copy(TITLEATTRS)
	attrs['color'] = '#ff0000'
	style = STYLEADAPTER( attrs )
	title = SPAN(_('Issues'), **{'style' : style})
	content = [ title, HR()]
	
	content = DIV(DIV( Sum(content), \
				       **{'class' : 'subc', 'id': CENTER_RIGHT }),\
				**{'class' : 'c33r'})
	return content

PAGEMAIN = 'main'	
def _centerMiddleDiv(**args):
	''' Render the reservations information for user.
	'''	
	editId = 'reserveEdit'
	attrs = {'style': STYLEADAPTER( TITLEATTRS), 'id' : editId}
	content = [ SPAN(A(_('Edit Your Rservations:' )), **attrs),\
			   HR() ]
	
	script = \
	'''
	$(document).ready(function(){				
		$('#%s').click(function(){
			$('#%s').load('%s');
	 	});				
	});'''%(editId, PAGEMAIN, 'service/index.hip')
	print pagefn.script(script, link=False)
				
  	props = ['serial', 'target', 'amount', 'memo']
	reserves = model.filterByLink( so.user, 'reserve', 'user', so.user, props, 'booker')
	
	# A temporary function to construct a Div component,
	# this function will be called to return content to html page.
	backContent = lambda c : DIV(DIV( Sum(c), \
				       				**{'class' : 'subcl' ,\
				       				     'style': 'border-left: 1px #ddd solid;',\
				              			     'id' : CENTER_MIDDLE}),\
							 **{'class' : 'c33l'})
	if not reserves :
		content.append(H5(_('No Reservations!')))
		return backContent(content)
	
	slDivs , slId = ( [], 'sl' )
	# the smartlist's select box and pager box
	for suffix in ('flag-dropdown', 'pagination' ):		
		content.append(SPAN('', **{'id' : '-'.join((slId, suffix))}))
		
	toRender = model.reserveSort(  [dict(zip(props, reserve)) for reserve in reserves],\
							   so.user )

	categories, categoryCost = (toRender.keys(), {})
	for category in categories :
		categoryCost[category] = 0
		items = toRender.get(category)
		subcategories = items.keys()
		subcategories.sort()		
		ids = [model.serial2id(s) for s in subcategories]		
		values = model.get_items(so.user, 'service', props=('detail',), ids=ids)
		for subcategory, value, pid in zip(subcategories,values, ids) :									
			subcategoryName = model.reserve_detailParser(value[0],('alias',)).get('alias')			
			
			# render the children
			children = items.get(subcategory)			
			for child in children :				
				# title
				txt = ','.join((subcategoryName, child.pop('alias')))								
				spans = [ SPAN(txt, **{'style':'font-weight:bold;'}), BR()]
				
				# service description	
				des = child.get('description') or '/'
				txt = [SPAN(_('Description : ')), SPAN(des), BR()]			
				spans.extend( txt)
				
				# reservations' fee
				title4prop = { 'price' : _('Unit Price : '), 'amount' : _('Reserved Amount : '), 'sub' : _('Cost : ') }
				showProps = ('price', 'amount')
				values = [child.pop(i) for i in showProps ]
				sub = reduce(lambda x,y : x*y, values)
				categoryCost[category] += sub				
				money = []
				for prop,value in zip(showProps, values) :
					money.append(Sum([ TEXT(title4prop.get(prop)), TEXT(str(value))])) 
					money.append(TEXT(' , '))
				money.pop(-1)				
				money.extend([BR(), TEXT(title4prop.get('sub')), TEXT(str(sub)), BR() ])				
				spans.append(SPAN(Sum(money)))
				
				# tags for grouping
				tagInfo = SPAN(_('Category: '), **{'style' : 'color: red;font-size:1.2em;'})				
				txt = category
				tags = SPAN(txt, **{'class' : 'flags'})												
				spans.append(SPAN(Sum([tagInfo, tags] )))
				
				# append this item to smartlist
				slDivs.append(DIV(Sum(spans), **{'class' : 'item'}))
	
	# render smart list	
	content.append(DIV(Sum(slDivs), **{'id' : slId}))
	
	# the subtotal of reservations' fee
	costDes = [HR(), TEXT(_('Subtotal: ')), BR()]		
	for category in categories :
		prefix = ' '.join((_(category), _('Cost : ') ))
		row = Sum(( TEXT(prefix), SPAN(str(categoryCost.get(category)), **{'style' : 'font-size: 1.5em;'}) ))		
		[ costDes.append( i ) for i in ( SPAN(row) , TEXT(' , ') ) ]
	costDes.pop(-1)
	content.append( DIV(Sum(costDes)))		
	
	txt = urllib.quote(_("Select Reserved Service"))
	js = 'lib/smartlists/smartlists.js.pih?listId=%s&prompt=%s&pageItems=%s'%(slId, txt, 3)				
	script = '''$(document).ready(function(){				
				$.getScript('%s');				
			});'''%js				
	[ content.append(c) for c in (pagefn.script(script,link=False), HR()) ]
	
	return backContent(content)

def _centerDiv(**args):
	contents = [ function() for function in (_centerLeftDiv, _centerMiddleDiv, _centerRightDiv) ] 
	attr = copy.copy(CONTAINER_STYLE)
	#attr['style'] += 'border-top:1px solid #EEEEEE;'
	print DIV(Sum(contents), **attr)	
	return

def _bottomDiv(**args):
	content = H2('App Pointer')
	attrs = {'id' : BOTTOM}
	attrs.update(CONTAINER_STYLE)
	print DIV(content, **attrs)
	return

def _inToday(start, duration):	
	''' Judge whether today is in the show days of one message.
	'''
	start = time.strptime(start, "%m/%d/%Y")[:3]
	start = datetime.date(*start)
	duration = int(duration or '0')
	end = start + datetime.timedelta(duration)
	# get current date
	now=datetime.date.today()
	res = False
	if now >= start and now <= end :
		res = True
	return res	
	
def _showMessage(props):	
	fnArgs = ('start', 'duration')
	days = model.filterByFunction(so.user, 'news', props, _inToday, fnArgs)
	return days
		
def _topDiv(**args):
	print '''<div class="subcolumns" id="%s">'''%TOP
	Include('agenda/agenda.ks/index')
	print '''</div>''' 
	
	
def index(**args):
	''' The reservations, help issues and system messages, 
	   all these are hold in a 'subcolumns' Div component.
	'''
	# The 'introduce' content
	_topDiv()
	
	# The info div which holds reservation, help issues and system messages
	_centerDiv()
	
	# The 'introduce' content
	_bottomDiv()