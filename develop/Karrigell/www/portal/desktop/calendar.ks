from HTMLTags import *

def _indexJs():
	paras = [CALENDARID, ]
	paras = tuple(paras)
	js = \
	"""
	var calendarTable="%s";

	var assetOptions = {
		'url': "lib/calendar/calendar.js",
		'app':'', 'type':'js'
	};
		
	var onloadOptions = {
		onload: function(){
			var calendar = new CalendarTable(calendarTable,{
				cssFile:"lib/calendar/calendar.css"
			});	
		}
	};
			
	// load js slice
	MUI.assetsManager.import( assetOptions, onloadOptions );
	"""%paras
	return js

CALENDARID = 'calendarTableWrapper'
def index(**args):
	print DIV(**{'id':CALENDARID})
	print SCRIPT(_indexJs(), **{'type':'text/javascript'})
	return

