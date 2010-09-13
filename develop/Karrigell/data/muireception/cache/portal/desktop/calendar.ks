['index']


from HTMLTags import *

def _indexJs():
	paras = [CALENDARID, ]
	paras = tuple(paras)
	js = \
	"""
	var calendarTable="%s";

	MUI.assetsManager.import({
		'url': "../../../lib/calendar/calendar.css",
		'app': '',
		'type': 'css'
	}, {});

	var assetOptions = {
		'url': "../../../lib/calendar/calendar.js",
		'app':'',
		'type':'js'
	};

	var onloadOptions = {
		onload: function(){
			var calendar = new CalendarTable(calendarTable,{});
		}
	};

	// load js slice
	MUI.assetsManager.import( assetOptions, onloadOptions );
	"""%paras
	return js

CALENDARID = 'calendarTableWrapper'
def index(**args):
	PRINT( DIV(**{'id':CALENDARID}))
	PRINT( SCRIPT(_indexJs(), **{'type':'text/javascript'}))
	return


