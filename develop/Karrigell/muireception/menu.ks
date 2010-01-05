"""
The pages and functions for menu setup
"""

from HTMLTags import *

# 'THIS.script_url' is a global variable in Karrigell system
APPATH = THIS.script_url[1:]
RELPATH = (lambda p : p.split('/')[0])(THIS.baseurl)
model = Import( '/'.join((RELPATH, 'model.py')), REQUEST_HANDLER=REQUEST_HANDLER )
modules = {'pagefn' : 'pagefn.py',  'JSON' : 'demjson.py', 'formFn':'form.py'}
[locals().update({k : Import('/'.join(('',v)))}) for k,v in modules.items() ]

VERSION = Import('/'.join((RELPATH, 'version.py')))

# ********************************************************************************************
# Page Variables
# ********************************************************************************************

# get the relative url slice as the application name
#APP = pagefn.getApp(THIS.baseurl,1)

# the session object for this page
SO = Session()

# config data object
CONFIG = Import( '/'.join((RELPATH, 'config.py')), rootdir=CONFIG.root_dir)

LOGINFORM = 'loginForm'
FORMFIELDS = ( 'user', 'pwd')
FIELD2INFO = {'user': _('Login Name'), 'pwd' : _('Password') }  
DEMOSELECT = 'demoSelect'

# form fields' names in CONFIG file
#ACCOUNTFIELDS = 'userAccountInfo'

# The id for the 'Account' form
#ACCOUNTFORM = 'AccountForm'

# the id for the SPAN component in the account form page which holds buttons 
#ACCOUNTFORMBNS = 'accountBns'

# End*****************************************************************************************


# ********************************************************************************************
# The page functions begining 
# ********************************************************************************************

def index(**args):
	pass
	return


def page_loginForm(**args):
	fields = required = FORMFIELDS
	field2info = FIELD2INFO	 
	# render fields
	table = [ CAPTION(SPAN(_('User Info'), **{'style' : 'font-weight:bold;font-size: 1.5em;'})), ]
	tbody = []		
	# append demostartion
	if VERSION.version == 'demo' :
		tbody.append(TR(TD(_autoDemo(), colspan='2')))		
		
	for field in fields :
		label = TD(LABEL(field2info.get(field)))
		attr = {'name' : field, 'class':'required'}
		if field != 'pwd':		
			attr['type'] = 'text'
		else:
			attr['type'] = 'password'
		input = SPAN(INPUT(**attr))
		input = TD(input)			
		tbody.append(TR(Sum((label, input))))
		
	table.append(Sum(tbody))
	# render form	
	print TABLE(Sum(table))
	return
		
def _autoDemo( ):
	""" Render a html slice to select a type of user to demostrate the function of this system.
	"""
	label = LABEL(VERSION.demoPrompt)
	options = [ OPTION(_('Select a type of user'), disabled='', selected=''), ]
	for user, des in VERSION.demoUsersDes.items() :
		name, pwd = [ VERSION.demoUsers[user].get(field) for field in ('name', 'pwd') ] 
		options.append(OPTION(des, **{'value' : name, 'ref' : pwd}))
	
	select = SELECT(Sum(options), **{'id' : DEMOSELECT})
	
	# callback function for slect action
	paras = [ LOGINFORM, DEMOSELECT ]
	paras = tuple(paras)
	script = \
	"""
	window.addEvent('domready', function() {
		var loginForm='%s', select='%s';
		$(select).addEvent('change',function(e){
			new Event(e).stop();
			var seleted = this.getElement(':checked');
			var a = [ selected.getProperty('html'),selected.getProperty('ref')]
			$(loginForm).getElements('input').each(function(input){
				inpurt.setProperty('html', a.shift());
			});
		});
	});
	"""%paras
	return Sum((label, BR(), select, pagefn.script(script, link=False))) 