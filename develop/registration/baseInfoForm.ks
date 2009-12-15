"""
The module for registration application. 
"""

from HTMLTags import *

# 'THIS.script_url' is a global variable in Karrigell system
#APPATH = THIS.script_url[1:]
RELPATH = (lambda p : p.split('/')[0])(THIS.baseurl)
model = Import( '/'.join((RELPATH, 'model.py')))
modules = {'pagefn' : 'pagefn.py',  'JSON' : 'demjson.py', 'formFn':'form.py'}
[locals().update({k : Import('/'.join(('',v)))}) for k,v in modules.items() ]
 

# ********************************************************************************************
# Page Variables
# ********************************************************************************************

# the session object for this page
SO = Session()

# config data object
CONFIG = Import( '/'.join((RELPATH, 'config.py')), rootdir=CONFIG.root_dir)

# account information fields' names in CONFIG file
ACCOUNTFIELDS = 'userAccountInfo'

# base information fields' names in CONFIG file
BASEINFOFIELDS = 'userBaseInfo'

# the id for the SPAN component in the form page which holds buttons 
FORMBNS = 'baseInfoBns'

# End*****************************************************************************************

# ********************************************************************************************
# The page functions begining 
# ********************************************************************************************


def index(**args):	
	render = CONFIG.getData(BASEINFOFIELDS)		
	#rember = {}	
	rember = dict([ (field.get('name'), getattr(SO, field.get('name'), None))  for field in render ])
	# Add other properties for each field, these properties are 'id','required','oldvalue'
	for element in render :
		name = element.get('name')
		# Add 'id' property for each field		
		element.update({'id':name})
      # Add required property to the needed fields, 
      # here means all the fields will be added the 'required' property.
		element.update({'required':True})
      # add maybe old value
		element.update({'oldvalue':rember.get(name)})	
	
	
	# render the fields to the form
	form = []
   # get the OL content from formRender.py module	
	yform = formFn.yform
	# calculate the fields' number showing in each column of the form	
	interval = int(len(render)/3)			
	left = DIV(Sum(yform(render[:interval])), **{'class':'c33l'})
	next = 2*interval
	center = DIV(Sum(yform(render[interval:next])), **{'class':'c33r'})
	right = DIV(Sum(yform(render[next:])), **{'class':'c33r'})
	divs = DIV(Sum((left, center, right)), **{'class':'subcolumns'})	
	
   # add the <Legend> tag
	legend = LEGEND(TEXT('Base Information'))    
	form.append(FIELDSET(Sum((legend,divs))))
	
	# add buttons to this form	
	buttons = \
	[ BUTTON( name, **{'class':'MooTrans', 'type':'button'}) \
	  for name in [_("Back"), _("Next"), _("Cancel")] ]
	
	span = DIV(Sum(buttons), **{ 'id':FORMBNS, 'style':'position:absolute;left:18em;'})    
	form.append(span)
	 
	form = FORM( Sum(form), 
                 **{
                   'action': '', 
                   'id': '', 
                   'method':'get',                   
                   'class':'yform'
                 }
               )
	print DIV(form, **{'class':'subcolumns'})
	
	# javascript functions for this page
	paras = [ pagefn.REGISTERDLG, FORMBNS ]
	js = \
	"""
	
	var dialogName='%s', buttonsContainer='%s';
	
	// Backforward function
	function back(event){
		alert('back button clicked');
	};
	 
	// Next step function
	function next(event){
		alert('next button clicked');
	};
	 
	// Cancel function
	function closeDialog(event){
	 	window[dialogName].close();
	 	delete window[dialogName];
	};
		 
	function pageInit(event){
		 
      // add mouseover effect to buttons
      new MooHover({container:buttonsContainer,duration:800});
		 
      // Add click callback functions for buttons
      var bns = $(buttonsContainer).getElements('button');       
       
      $(bns[0]).addEvent('click', back);
      $(bns[1]).addEvent('click', next);

      // Add callback function to 'Cancel' button
      $(bns[2]).addEvent('click', closeDialog);
   };

   window.addEvent('domready', pageInit);
	"""%tuple(paras)
		
	print pagefn.script(js, link=False)
	return
	