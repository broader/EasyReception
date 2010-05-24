######################### Web UI For User##################################################

## For menubar in application main page
_getPath = lambda name : '/'.join(('#navigation.ks', name))  
_menus = ( \
		   ('profile?path=portal/portal.ks/index', _("Portal")),\	          
		   ('profile?path=service/accommodation/app.ks/index', _("Accommodation Service")),\
		   ('profile?path=service/travel/app.ks/index', _("Travel Service")),\	  	          
	      ('profile?path=service', _("Service")),\
	      ('profile?path=issue', _("Need Help")),
	      ('profile?path=user', _("Personal Info"))\	          
	      )
	          
menus = [ (_getPath(path), text) for path, text in _menus ]	        
## For 'register' module
# The attributes of the labels of tab widget.
# Each tab label has 3 attributes: 
#   first item is the text value shown on the tab label;
#   second item is the page loaded to the tab container;
#   third item is the form action handler function in register.ks module.
tabs = ( (_("Login Account Information"), 'step_1.hip?step=0', 'step0'), \
			(_("Base Information"), 'step_2.hip?step=1','step1'), \
			(_("Finish"), 'step_3.hip', '#'))

# the fields stored in database
login_fields = ('username', 'password', 'email')
login_fields_names = (_("User Name :"), _("Password :"), _("Email :"))

# the fields stored in file
base_fields_dict = { 'prefix': _("Prefix :"), 'firstname': _("First Name :"),\
				    'lastname': _("Last Name :"), 'gender': _("Gender :"),\
				    'organization': _("Organization :"),\
				    'phone' : _("Phone :"), 'fax': _("Fax :"),\ 
				    'aperson': _("Accompany Person :"),\				    
				     'address': _("Address :"),  
				     'city': _("City :"), 'country': _("Country :"),\
				    'postcode': _("Postal Code :")\
				  }
				  
base_fields = ( 'prefix', 'firstname', 'lastname', 'gender', 'organization', 'phone',\
			   'fax', 'aperson', 'address', 'city', 'country', 'postcode')
			  
base_fields_names = [ base_fields_dict.get(name) for name in base_fields]

base_fields_form = \
[ \
  # select type
  [ _("Prefix :"), \
   {'id':'prefix', 'name':'prefix'}, \
   [({'value': '0', 'selected':''}, _("Mr")), ({'value': '1'}, _("Mrs")), ({'value': '2'}, _("Ms")) ], 'select'],\
   # end
  [_("First Name :"), {'id':'fname', 'name':'firstname', 'type':'text'}, 'input'],\
  [_("Last Name :"), {'id':'lname', 'name':'lastname', 'type': 'text'}, 'input'],\
  # radio type input
  [_("Gender:"), \
   [ [_("Male"), {'id':'gender_male', 'type': 'radio', 'name': 'gender','value': '0' }],\
     [_("Female"), {'id':'gender_female', 'type': 'radio', 'name': 'gender','value': '1'}] ], 'radio' ],\
  # end
  [_("Organization :"), {'id':'org','name':'organization', 'rows':'3', 'cols':'17'}, 'textarea'],\
  [_("Street/Po.Box :"), {'id':'address','name':'address', 'rows':'3', 'cols':'17'}, 'textarea'],\
  [_("Postal Code :"), {'id':'pc','name':'postcode', 'type':'text'}, 'input'],\
  [_("Country/Region :"), {'id':'country','name':'country', 'type':'text'}, 'input'],\
  [_("City :"), {'id':'city','name':'city', 'type':'text'}, 'input'],\
  [_("Phone :"), {'id':'phone','name':'phone', 'type':'text'}, 'input'],\
  [_("Fax :"), {'id':'fax','name':'fax', 'type':'text'}, 'input'],\
  # select type
  [_("Accompany Persons :"),\
   {'id':'aperson','name':'aperson'},\
    [ ({'value':'0' }, '0'), ({'value':'1'}, '1'), ({'value':'2'}, '2') ], 'select'],\
  # end
]		     

user_form_selects = \
{'gender': (_("Male"), _("Female")),\
  'prefix': (_("Mr"), _("Mrs"), _("Ms")),\
  'aperson': (0, 1, 2)\
 }

user_form_buttons = [_("OK"), _("Cancel")]


