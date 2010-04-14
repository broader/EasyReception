import os
import yaml

INICONFIG = os.sep.join((rootdir, 'config.yaml'))
INIDATA = {}
INIDATA['userAccountInfo'] = \
[
	{ 'name':'username', 'prompt':_('Login Name'), 'type':'text'},\
	{ 'name':'email', 'prompt':_('Email address'), 'type':'text'},\
	{ 'name':'password' , 'prompt':_('Password'), 'type':'password'},\
]

#{
#	'fields':( 'username', 'email', 'password' ),
#}

INIDATA['userBaseInfo'] = \
[ 
	{ 'name':'prefix', 'prompt':_("Prefix"), 'type':'radio',\
	  'class':'', 'required':False,'validate':[],\
	  'options':[\
		{'value': '0', 'label':_("Mr")},\
		{'value': '1', 'label':_("Mrs")},\
		{'value': '2', 'label': _("Ms")}\
		]\  
	},\
	
	{ 'name':'firstname', 'prompt':_("First Name"), 'type':'text',\
	  'class':'', 'required':False, 'validate':[] },\
	  
	{ 'name':'lastname',	'prompt':_("Last Name"), 'type':'text', 'validate':[] },\
	
	{ 'name':'gender', 'prompt':_("Gender"), 'type':'radio',\
	  'class':'', 'required':False,'validate':[],\
	  'options':[\
		{'value': '0','label':_('Male')},\
	  	{'value': '1','label':_('Female')}\
		]\	
	},\
	
	{ 'name':'organization', 'prompt': _("Organization"), 'type':'textarea',\
	  'class':'', 'required':False, 'validate':[] },\
	  
	{ 'name':'phone',	'prompt':_("Phone"), 'type':'text',\
	  'class':'', 'required':False,'validate':[] },\
	  
	{ 'name':'fax', 'prompt':_("Fax"), 'type':'text',\
	  'class':'', 'required':False, 'validate':[] },\
	
	{ 'name':'aperson',	'prompt':_("Accompany Person"), 'type':'select',\
	  'class':'', 'required':False, 'validate':[],\
	  'options':[\
		{'value':'0', 'label':'0'},\
	  	{'value':'1', 'label':'1'},\
	  	{'value':'2', 'label':'2'}\
		]\
	},\
	
	{ 'name':'address',	'prompt':_("Address"), 'type':'textarea',\
	  'class':'', 'required':False, 'validate':[] },\
	  
	{ 'name':'city',	'prompt':_("City"), 'type':'text',\
	  'class':'', 'required':False, 'validate':[] },\
	  
	{ 'name':'country',	'prompt':_("Country"), 'type':'text',\
	  'class':'', 'required':False, 'validate':[] },\
	  
	{ 'name':'postcode', 'prompt': _("Postal Code"), 'type':'text',\
	  'class':'', 'required':False,'validate':[] }\
]

# app name for 'Hotel'
INIDATA['service'] = \
{
	'hotel': {
		'categoryInService': 'Hotel',
		'configProperty':[
			{
				'name': 'reservePermission',
				'prompt': 'status that could be reserved',
				'property': 'status',
				'value': ''
			},
		],
	}
}

def _init(value=None):	
	stream = open(INICONFIG, 'wb')
	if value:
		yaml.dump(value,stream,explicit_start=True)
	else:
		yaml.dump(INIDATA,stream,explicit_start=True)
	
	stream.close()
	return	

def _openStream():
	stream = open(INICONFIG, 'rb')
	config = yaml.load(stream)
	stream.close()
	return config

def _getConfig(field):
	configObject = _openStream()	
	res = None
	if configObject:
		res = configObject.get(field)	 	
	return res
	
def getData(field):
	initValue = _getConfig(field)
	if not initValue :
		# when there is no value, it's need to initialize config file again.
		_init()

	return _getConfig(field)
	
def editData(field, value):
	"""
	Edit speccified config field's value.
	Parameters:
	field - the name of the field to be edit
	value - the new value of the field
	"""
	old = getData(field)
	if value != old:
		# dump new value to yaml file
		configObject = _openStream()
		configObject[field] = value
		_init(configObject)
		 
	return
