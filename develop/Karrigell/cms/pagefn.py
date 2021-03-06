# karrigell modules
from HTMLTags import *

# #
# Web Icons
#---------------------------------------------------------------------------
_relPath = lambda p : '/'.join(('images/icons', p))
ICONS = {'edit' : _relPath('edit.png'), 'delete' : _relPath('delete.png')}
#---------------------------------------------------------------------------


# #
#International Words
#---------------------------------------------------------------------------
WEEKDAYS = ( _('Monday'), _('Tuesday'), _('Wednesday'), _('Thursday'), _('Friday'), _('Saturday'), _('Sunday') )
HALFDAY = {'AM' : _('AM'), 'PM': _('PM')}

# form confirm buttons and its css sytle 
FORM_BNS = [_("OK"), _("Cancel")]
BUTTON_CSS = {'float':'center',\
				  'width':'7.5em',\
				  'height':'2.6em',\
				  'color': 'white',\
				  'font-weight':'bold',\
				  'border-style':'none',\
				  'background-color': 'transparent',\
				  'background-image': 'url(images/buttons/button_s.png)'}

# Some services' name
SERVICENAMES = {'Hotel' : _('Hotel'), 'Travel' : _('Travel')}
#--------------------------------------------------------------------------

##
# Some  liberary path
#--------------------------------------------------------------------------
JSLIBS = {'treeTable': {'js' : 'lib/treeTable/jquery.treeTable.js', 'css' : ' lib/treeTable/jquery.treeTable.css'}}
#--------------------------------------------------------------------------

# the waiting image for ajax action
AJAXLOADING = 'images/ajax_loading.gif'

# the css style for 'select' tag in page's form 
SELECT_CSS = 'height: 1.5em;\
			 line-height: 15px;\
			 border: 1px solid #CCCCCC;\
			 background-color: #FFF;\
			 overflow:hidden;\
			 z-index:100;\
			 font-size: 1.2em;\
			 text-align: left;'

def jframe( ):
	''' a function for initializing jframe in a page.
	'''
	body = ''' $(document).ready(function() {
				$(document).find("div[src]").each(function(i) {
            				$(this).loadJFrame(undefined, undefined, true);
    				} );
			  } );
		       '''
	print script(body, link=False)			 

def css(src):
	''' Return a pair of '<LINK></LINK>' tags to html page.
	'''
	d = { 'rel' : 'stylesheet', 'type' : 'text/css', 'href': src, 'media' : 'screen' }
	html = LINK(**d)
	return html 
			 
def script(src, link=True):
	''' A function to import javascript slice in a html page.
	'''
	if not src:
		return ''
	
	if not link:		
		script = SCRIPT(src, type='text/javascript')
	else:
		script =  SCRIPT(type='text/javascript', src=src)
	return script
	
def prompt(info='', needJs=True):	
	txt =  '$.prompt("%s", {prefix: "cleanblue", buttons: {%s : true}});' \
					%(info, _("OK"))	
	if not needJs :
		txt = script(txt, link=False)
	return txt

def accordion( elementId, header=None):
	if not header :
		header = 'h4'
		
	js = \
	'''
	$(document).ready(function(){
		var alist="#%s", headerTag="%s";		
		// apply accordion style to agenda list 		
		$(alist).accordion({
			    active: true, 
			    autoheight : true,
			    header: headerTag,	
			    collapsible: true,		     
			    //event: 'mouseover',
			    clearStyle : true 
		});		
	});
	'''%(elementId, header)	
	return script(js, link=False)