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

FORMFIELDS = \
[\
	{'name':'user','label':_('Login Name'),'class':'validate[required]'},\
	{'name':'pwd','label':_('Password'),'class':'validate[required]'}\
]  

DEMOSELECT = 'demoSelect'

FORMBUTTONS = 'loginFormbns'

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
	# render fields
	table = [ CAPTION(SPAN(_('User Info'), **{'style' : 'font-weight:bold;font-size: 1.5em;'})), ]
	tbody = []		
	# append demostartion selection
	if VERSION.version == 'demo' :		
		tbody.append(TR(TD(_autoDemo(), colspan='2',style='border-bottom:black 1px;')))
	
	# append account inputs	
	for field in FORMFIELDS :
		name = field.get('name')
		label = TD(LABEL(field.get('label'),style='width:100%;'))
		attr = {'name':name}
		attr['class'] = ' '.join((field.get('class'), 'type-text'))
		
		if name != 'pwd':		
			attr['type'] = 'text'
		else:
			attr['type'] = 'password'
		input = SPAN(INPUT(**attr))
		input = TD(input)			
		tbody.append(TR(Sum((label, input))))
	
	table.append(Sum(tbody))
	table = TABLE(Sum(table))
	# append submit buttons
	bns =[ BUTTON( _("OK"), **{'class':'MooTrans', 'type':'submit'}),\
			 BUTTON( _("Cancel"), **{'class':'MooTrans', 'type':'button'})]
			 
	bns = [ SPAN(bn) for bn in bns ] 
	bns = DIV(Sum(bns),**{'id':FORMBUTTONS,'style':'position:relative;float:right;'})
	form = Sum([table, bns])
	# render form		
	print FORM(form,**{'id':LOGINFORM, 'class':'yform'})
	print pagefn.script(_formJs(),link=False)
	return
		
def _autoDemo( ):
	""" Render a html slice to select a type of user to demostrate the function of this system.
	"""
	options = [ OPTION(_('Select a type of user'), disabled='', selected=''), ]
	for user, des in VERSION.demoUsersDes.items() :
		name, pwd = [ VERSION.demoUsers[user].get(field) for field in ('name', 'pwd') ] 
		options.append(OPTION(des, **{'value' : name, 'ref' : pwd}))
	
	select = SELECT(Sum(options), **{'id' : DEMOSELECT})
	prompt = SPAN(VERSION.demoPrompt,style='font-size:15px;',**{'class':'highlight'})
	return Sum(( prompt, BR(), select, HR(style='padding:0 0 0.2em;')))
	
def _formJs():
	# callback function for slect action
	paras = [ LOGINFORM, DEMOSELECT, FORMBUTTONS]
	paras = tuple(paras)
	script = \
	"""
	window.addEvent('domready', function() {
		var loginForm='%s', select='%s',
		bnsContainer='%s';
		
		// add callback function to select changing
		$(select).addEvent('change',function(e){
			var selected = e.target;
			var selector = 'option[value=x]'.replace(/x/i, selected.getProperty('value'));
			option = selected.getElement(selector);
			new Event(e).stop();
			var a = [ option.getProperty('value'),option.getProperty('ref')]
			$(loginForm).getElements('input').each(function(input){
				input.setProperty('value', a.shift());
			});
		});
		
		// add mouseover effect to buttons
		new MooHover({container:bnsContainer,duration:800});
      
		// add callback functions to submit buttons
		var buttons = $(loginForm).getElements('button');
		
		// submit button
		buttons[0].addEvent('click',function(e){
			new Event(e).stop();
			MUI.notification('ok');
		});
		
		// cancel button
		buttons[1].addEvent('click',function(e){
			new Event(e).stop();
			MUI.closeModalDialog();
		});
		
		// add validations to form fields
	});
	"""%paras
	return script
	
	