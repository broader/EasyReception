""" Supply a map view for normal user. """
from HTMLTags import *

RELPATH = (lambda p : p.split('/')[0])(THIS.baseurl)
model = Import( '/'.join((RELPATH, 'model.py')), REQUEST_HANDLER=REQUEST_HANDLER )

modules = {'pagefn': 'pagefn.py', 'JSON': 'demjson.py', }#'formFn':'form.py'}
[locals().update({k : Import('/'.join(('',v)))}) for k,v in modules.items() ]


#***************************************************************************************
#****** Page Functions *****************************************************************
#***************************************************************************************

def index(**args):
    pass

def page_initData(**args):
    res = {
	'zoomImage':{
	    #'zoomerImageUrl':'test/image_zoom/pictures/big/image_1024_minize.jpg', 
	    'zoomerImageUrl':'accomodation/maps/image_big.jpg', 
	    #'thumbUrl':'test/image_zoom/pictures/thumb/image_100.jpg'
	    'thumbUrl':'accomodation/maps/image_thumb.jpg'
	},

	'hotelData':{
	    'JadePalace':{'dimention':{'x':400,'y':600},},
	    'BTC':{'dimention':{'x':500,'y':300},},
	    'FriendShip':{'dimention':{'x':200,'y':100},},
	},

	'hotelIconCss':	{
	    'width': '32px', 'height':'32px', 
	    'position':'absolute', 'z-index': '100',
	    'background-image':"url('accomodation/maps/agency_32.gif')" 
	},

	'panelTitles':{
	    'thumbNail': _("Thumbnail Map").decode("utf8"), 
	    'reservations': _("Your Reservations").decode("utf8"), 
	    'hoteList': _("Hotel List").decode("utf8")
	}
    }
    
    print JSON.encode(res, encoding='utf8')
    return

def page_reservation(**args):
    pass
    
    
    
    


    
	
	
