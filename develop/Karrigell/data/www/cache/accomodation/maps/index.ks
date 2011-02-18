['page_hotelAction', 'page_hoteList', 'page_hotelDetail', 'index', 'page_infoForm', 'page_infoAction']
""" A demostration page for definition of hotel coordinates on a map.  """
from HTMLTags import *

modules = {'pagefn': 'pagefn.py', 'JSON': 'demjson.py', 'formFn':'form.py'}
[locals().update({k : Import('/'.join(('',v)))}) for k,v in modules.items() ]


RELPATH = '/'.join(THIS.baseurl.split('/'))
DATA = Import( '/'.join((RELPATH, 'hotelConfig.py')), rootdir=CONFIG.root_dir)

def _innerCss():
	paras = [MAPCONTAINER, CURSOR]
	paras = tuple(paras)
	css = \
	"""
	#%s {
		/*background-image: url('../../../accomodation/maps/haidian_hotel_900.jpg'); */
		background-image: url('../../../accomodation/maps/haidian_hotel_900_minized.jpg');
		background-repeat: no;
		width: 900px;
		height: 668px;
		position: relative;
		z-index: 0;
	}

	#%s {
		width: 32px;
		height: 32px;
		background-image: url('../../../accomodation/maps/agency_32.png');
		margin-left: 0px;
		margin-top: 0px;
		position: absolute;
		z-index: 0;
	}
	"""%paras

	return css

def _css():
	style = STYLE(_innerCss(),**{'type':'text/css', 'media':'screen'})
	return style

def page_hotelAction(**args):
	action,hotel = [args.get(field) for field in ('action', 'hotel')]

	res = {'action':action,}
	actions = [i.get('value') for i in ACTIONS ]
	if actions.index(action) == 2:	#delete action
		hotels = DATA.getData('Hotel')

		item = filter( lambda i : i.get('name') == hotel, hotels)
		if item :
			item = item[0]
			hotels.remove(item)
			DATA.editData('Hotel', hotels)
			res = { 'success':1, 'info': ('%s 已被删除'%hotel).decode('utf-8')}
	else:	# display action
		pass

	PRINT( JSON.encode(res))
	return

def page_hoteList(**args):
	hotels = DATA.getData('Hotel') or []
	res = []
	for hotel in hotels:
		name = hotel['name'].decode('utf-8')
		res.append({\
			'label': name,\
			'value': name,\
			'coordinate':','.join([hotel.get(name) for name in ('x','y')])\
		})

	PRINT( JSON.encode(res, encoding='utf-8'))
	return

def page_hotelDetail(**args):
	PRINT( H3('Hotel Detail'),HR())
	hotel = args.get('hotel') or ''
	hotels = DATA.getData('Hotel')

	for h in hotels:
		if not h.get('name') == hotel:
			continue
		imgUrl = h.get('mapInfo')
		break

	div = DIV()
	css = { \
		#'background-image': "url('../haidian_hotel_900.jpg');",
		'background-repeat': 'no-repeat;',
		'width': '900px;',
		'height': '668px;',
		'position': 'relative;'
	}
	css['background-image'] = "url('../%s');"%imgUrl
	css = [':'.join((key,value)) for key,value in css.items()]
	css = ' '.join(css)
	div.attrs['style'] = css
	PRINT( div)

	return

def _js():
	paras = [ACTIONCONTAINER, MAPCONTAINER, CURSOR, ]
	urls = [ \
		'/'.join((THIS.script_url, name ))\
	  	for name in ('page_infoForm', 'page_hotelAction', 'page_hoteList', 'page_hotelDetail') \
	]
	paras.extend(urls)

	paras.extend([i.get('value') for i in ACTIONS ])
	paras = tuple(paras)
	js = \
	"""
	var actionContainer="%s", mapContainer="%s", cursor="%s",
	    positionUrl="%s", actionUrl="%s", hoteListUrl="%s",	hotelDetailUrl="%s",
	    actions=["%s", "%s", "%s"];


	function selectRefresh(select){
	    var req = new Request.JSON( {
		url: hoteListUrl,
		onComplete: function(arr){
		    select.empty();
		    var el = new Element('option', {html: "全部酒店", value:0});
		    el.inject( select, 'top');
		    var options = arr.map(function(item,index){
			var option = new Element('option', {html:item.label, value:item.value});
			option.store('coordinate', item.coordinate);
			return option
		    });
		    select.adopt(options);
		}
	    });
	    var q = $H();
	    req.get(q);
	};

	function bnAdapter(){
	    var selects = $(actionContainer).getElements('select');

	    $(actionContainer).getElements('input')[0]
	    .addEvent('click', function(e){
		new Event(e).stop();

		var action = selects[1].get('value'),
		    hotelName = selects[0].get('value');

		var actionIndex = actions.indexOf(action);
		switch(actionIndex){
		    case 0 :	// display action
			var option = selects[0].getFirst('[value={value}]'.substitute({'value':hotelName}));
			var coordinate = option.retrieve('coordinate').split(',');
			var iconStyle = {
			    'width': '32px', 'height':'32px',
			    'background-image':"url('../../../accomodation/maps/agency_32.gif')",
			    'position':'absolute',
			    'margin-left': coordinate[0]+'px',
			    'margin-top': coordinate[1]+'px'
			};
			var alink = new Element('span');
			alink.setStyles(iconStyle);

			// add popup window to show the detail information of this hotel
			alink.addEvent('click', function(e){
			    //alert(pos.x+','+pos.y);
			    var q = $H();
			    q['hotel'] = hotelName;
			    var url = [hotelDetailUrl, q.toQueryString()].join('?');
			    //window.open(url, "hotelInstruction","menubar=no,width=900,height=480,toolbar=no");
			    new MUI.Window({
				id: 'htmlpage', type:'modal', content: 'Hello World', width: 700, height: 520,
				contentURL: url
			    });

			});

			$(mapContainer).adopt(alink);
			runShinning.periodical(1800, {el:alink});
			break;

		    case 1 :	// position action
			break;
		    case 2 :	// delete action
			if (hotelName == '0') return;

			var req = new Request.JSON( {
			    url: actionUrl,
			    async: false,
			    onComplete: function(json){
				alert(json.info);
			    }
			});
			var q = $H();
			q['action'] = action, q['hotel'] = hotelName;
			req.get(q);

			selectRefresh(selects[0])
			break;
		    default: alert('china');
		};

	    });
	};

	function runShinning(){
	    var el = this.el;
	    new Fx.Morph(el, {
		duration:500,
		onComplete:function(morph){
		    var fadeOut = new Fx.Morph(el, {duration:500}).start({
			opacity:0,
		    });
		}
	    }).start({'opacity':1});
	};

	window.addEvent('domready', function(){
	    // initialize hotel list
	    selectRefresh($(actionContainer).getElements('select')[0]);

	    // initialize buttons
	    bnAdapter();

	    var img = $(cursor).setStyles({
		display:'block',
		//opacity: 0
		opacity: 1
	    });

	    img.makeDraggable({
		container: mapContainer,
		onDrop: function(element, droppable, event){
		    var pos = {"x": element.getStyle('left').toInt()+1, "y": element.getStyle("top").toInt()};
		    //alert(pos.x+','+pos.y);
		    var q = $H(pos);
		    url = [positionUrl, q.toQueryString()].join('?');
		    window.open(url, "testWindow","menubar=no,width=430,height=360,toolbar=no");
		}
	    });

	});

	"""%paras

	return js

def _headTempl():
	head = HEAD()
	metAttrs = [\
		{'http':'Content-Type','content':'text/html; charset=UTF-8'},
		{'http':'X-UA-Compatible','content':'IE=8'}
	]
	metaTags = [ META(**attr) for attr in metAttrs ]

	misc = [TITLE("A demostration for map functions !"), _css()]

	names = ('mootools-1.2.4-core.yuc.js', 'mootools-1.2.4.2-more.yuc.js')
	prefix = '/'.join(4*['..'])
	scripts = [SCRIPT(**{'type':'text/javascript', 'src':'/'.join((prefix, 'lib','mootools',name))}) for name in names ]

	for group in [metaTags, misc, scripts]	:
		for tag in group:
			head <= tag
	return head

def _head():
	head = _headTempl()

	head <= SCRIPT(_js(), **{'type':'text/javascript'})

	return head

MAPCONTAINER = 'mapContainer'
CURSOR = 'cursor'
ACTIONCONTAINER = 'actionsContainer'
ACTIONS = [{'label':'显示', 'value':'display'}, {'label':'重定位', 'value':'position'}, {'label':'删除', 'value':'delete'},]
def _body():
	body = BODY()

	# action container
	div = DIV(**{'id':ACTIONCONTAINER})

	# select button
	div <= LABEL("宾馆：")
	select = SELECT()

	div <= select

	# action select
	div <= LABEL("操作：")
	select = SELECT()

	for action in ACTIONS:
		select <= OPTION(action['label'], **{'value':action['value']})

	div <= select

	div <= INPUT(**{'type':'button', 'value':'执行'})

	body <= div
	body <= HR()

	# map container
	container = DIV(**{'id':MAPCONTAINER})
	# a draggable cursor to point out the coordinates of the hotel
	cursor = SPAN(4*"&nbsp;", **{'id':CURSOR})
	container <= cursor

	body <= container
	return body

def index(**args):
	PRINT( '''<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">''')


	page = HTML(**{'xmlns':"http://www.w3.org/1999/xhtml"})

	# head
	page <= _head()

	# body
	page <= _body()

	PRINT( page)

	return

def _infoFormJs():
	paras = [FORMID,]
	paras = tuple(paras)
	js = \
	"""
	var formId="%s";

	window.addEvent('domready', function(){
	    var inputEls = $(formId).getElements('input');
	    inputEls[inputEls.length-1].addEvent('click', function(e){
		new Event(e).stop();
		window.close();
	    });

	});

	"""%paras
	return js

FORMID = 'hotelInfo'
def page_infoForm(**args):
	page = HTML(**{'xmlns':"http://www.w3.org/1999/xhtml"})
	page <= _headTempl()

	body = BODY()

	script = SCRIPT(_infoFormJs(), **{'type':'text/javascript'})
	body <= script

	# form fields
	url = '/'.join((THIS.script_url,'page_infoAction'))
	form = FORM(**{'action':url, 'id':FORMID })
	table = TABLE()
	fields = [\
		{'label':'酒店名称 :', 'name':'hotel'},\
		{'label':'左边距 :', 'name':'x', 'value':args.get('x') or ''},\
		{'label':'右边距 :', 'name':'y', 'value':args.get('y') or ''}\
	]

	for field in fields :
		tr = TR()
		tr <= TD(LABEL(field.pop('label')))
		tr <= TD(INPUT(**field))
		table <= tr

	form <= table

	form <= INPUT(**{'type':'submit', 'value':'确认'})
	form <= INPUT(**{'type':'button', 'value':'取消'})
	body <= form

	page <= body

	PRINT( page)

	return

def page_infoAction(**args):
	name, x, y = [args.get(field) for field in ('hotel', 'x', 'y') ]

	refresh = True
	hotels = DATA.getData('Hotel')
	if not hotels:
		hotels = [{'name':name, 'x':x , 'y': y},]
	else:
		hotel = filter( lambda i : i.get('name') == name, hotels)

		if hotel:
			hotel = hotel[0]
			if hotel.get('x') == x and hotel.get('y') == y:
				refresh = False
			else:
				hotel['x'] = x
				hotel['y'] = y
		else:
			hotels.append({'name':name, 'x':x, 'y':y})

	if refresh:
		DATA.editData('Hotel', hotels)

	hotels = DATA.getData('Hotel')
	for hotel in hotels :
		PRINT( '''酒店名称：%s, 左坐标：%s, 右坐标：%s <br/>'''%tuple([hotel.get(name) for name in ('name','x','y')]))

	PRINT( A('关闭', **{'href':"javascript:self.close(); opener.location.reload();"}))
	js = \
	"""

	"""

	return



