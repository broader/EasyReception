import os
import yaml

INICONFIG = os.sep.join((rootdir, 'config.yaml'))
INIDATA = {}
INIDATA['userAccountInfo'] = \
[
	{ 'name':'username', 'prompt':_('Login Name :'), 'type':'text'},\
	{ 'name':'email', 'prompt':_('Email address :'), 'type':'text'},\
	{ 'name':'password' , 'prompt':_('Password :'), 'type':'text'},\
]

#{
#	'fields':( 'username', 'email', 'password' ),
#}

INIDATA['userBaseInfo'] = \
[ 
	{ 'name':'prefix', 'prompt':_("Prefix :"), 'type':'radio',\
	  'class':'', 'required':False,'validate':[],\
	  'options':[{'value': '0', 'label':_("Mr")},\
					 {'value': '1', 'label':_("Mrs")},\
					 {'value': '2', 'label': _("Ms")} ]\  
	},\
	
	{ 'name':'firstname', 'prompt':_("First Name :"), 'type':'text',\
	  'class':'', 'required':False, 'validate':[] },\
	  
	{ 'name':'lastname',	'prompt':_("Last Name :"), 'type':'text', 'validate':[] },\
	
	{ 'name':'gender', 'prompt':_("Gender :"), 'type':'radio',\
	  'class':'', 'required':False,'validate':[],\
	  'options':[{'value': '0','label':_('Male')},\
	  				 {'value': '1','label':_('Female')}]\	
	},\
	
	{ 'name':'organization', 'prompt': _("Organization :"), 'type':'textarea',\
	  'class':'', 'required':False, 'validate':[] },\
	  
	{ 'name':'phone',	'prompt':_("Phone :"), 'type':'text',\
	  'class':'', 'required':False,'validate':[] },\
	  
	{ 'name':'fax', 'prompt':_("Fax :"), 'type':'text',\
	  'class':'', 'required':False, 'validate':[] },\
	
	{ 'name':'aperson',	'prompt':_("Accompany Person :"), 'type':'select',\
	  'class':'', 'required':False, 'validate':[],\
	  'options':[ {'value':'0', 'label':'0'},\
	  				  {'value':'1', 'label':'1'},\
	  				  {'value':'2', 'label':'2'}]\
	},\
	
	{ 'name':'address',	'prompt':_("Address :"), 'type':'textarea',\
	  'class':'', 'required':False, 'validate':[] },\
	  
	{ 'name':'city',	'prompt':_("City :"), 'type':'text',\
	  'class':'', 'required':False, 'validate':[] },\
	  
	{ 'name':'country',	'prompt':_("Country :"), 'type':'text',\
	  'class':'', 'required':False, 'validate':[] },\
	  
	{ 'name':'postcode', 'prompt': _("Postal Code :"), 'type':'text',\
	  'class':'', 'required':False,'validate':[] }\
]


def _init(field):	
	stream = open(INICONFIG, 'wb')
	yaml.dump(INIDATA,stream,explicit_start=True)
	stream.close()
	return	

def _getConfig(field):
	stream = open(INICONFIG, 'rb')
	config = yaml.load(stream)
	stream.close()
	res = None
	if config:
		res = config.get(field)	 	
	return res
	
def getData(field):
	config = _getConfig(field)
	if not config :
		_init(field)
	return _getConfig(field)
	