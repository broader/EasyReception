import os, yaml

CONFIGFILE = os.sep.join((rootdir, 'config.yaml'))

# the dictionary object which holds the default values for initial config file
INIDATA = {}
INIDATA['userAccountInfo'] = \
[
	{ 'name':'username', 'prompt':'Login Name', 'type':'text'},\
	{ 'name':'email', 'prompt':'Email address', 'type':'text'},\
	{ 'name':'password' , 'prompt':'Password', 'type':'password'},\
]


INIDATA['userBaseInfo'] = \
[ 
	{ 'name':'prefix', 'prompt':"Prefix", 'type':'radio',\
	  'class':'', 'required':False,'validate':[],\
	  'options':[\
		{'value': '0', 'label':"Mr"},\
		{'value': '1', 'label':"Mrs"},\
		{'value': '2', 'label': "Ms"}\
		]\  
	},\
	
	{ 'name':'firstname', 'prompt':"First Name", 'type':'text',\
	  'class':'', 'required':False, 'validate':[] },\
	  
	{ 'name':'lastname','prompt':"Last Name", 'type':'text', 'validate':[] },\
	
	{ 'name':'gender', 'prompt':"Gender", 'type':'radio',\
	  'class':'', 'required':False,'validate':[],\
	  'options':[\
		{'value': '0','label':'Male'},\
	  	{'value': '1','label':'Female'}\
		]\	
	},\
	
	{ 'name':'organization', 'prompt': "Organization", 'type':'textarea',\
	  'class':'', 'required':False, 'validate':[] },\
	  
	{ 'name':'phone', 'prompt':"Phone", 'type':'text',\
	  'class':'', 'required':False,'validate':[] },\
	  
	{ 'name':'fax', 'prompt':"Fax", 'type':'text',\
	  'class':'', 'required':False, 'validate':[] },\
	
	{ 'name':'aperson', 'prompt':"Accompany Person", 'type':'select',\
	  'class':'', 'required':False, 'validate':[],\
	  'options':[\
		{'value':'0', 'label':'0'},\
	  	{'value':'1', 'label':'1'},\
	  	{'value':'2', 'label':'2'}\
		]\
	},\
	
	{ 'name':'address', 'prompt':"Address", 'type':'textarea',\
	  'class':'', 'required':False, 'validate':[] },\
	  
	{ 'name':'city', 'prompt':"City", 'type':'text',\
	  'class':'', 'required':False, 'validate':[] },\
	  
	{ 'name':'country', 'prompt':"Country", 'type':'text',\
	  'class':'', 'required':False, 'validate':[] },\
	
	{ 'name':'postcode', 'prompt': "Postal Code", 'type':'text',\
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
				'value': ['toBeReserve',]
			},
		],
	}
}

INIDATA['superAdmin'] = {'role':'SuperAdmin', 'user':'admin'}

# these directories will be scaned in 'sysadmin/webaction.py' to add new web actions to database
INIDATA['appdirs'] = ['issue', 'portal', 'portfolio', 'register', 'service', 'sysadmin', 'user']

# i18n information

def _init(value=None):	
	stream = open(CONFIGFILE, 'wb')
	if value:
		yaml.dump(value,stream,explicit_start=True)
	else:
		# dump all the values in "INIDATA" dict to config file
		yaml.dump(INIDATA,stream,explicit_start=True)
	
	stream.close()
	return	

def _openStream():
	stream = open(CONFIGFILE, 'rb')
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
	'''
	Parameters:
	  field - the variable's name
	'''
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

def i18nStrings():
    """ Return the strings which is need to be translated in this page."""
    strings = []
    for name in ('userAccountInfo', 'userBaseInfo'):
	fields = INIDATA.get(name)
	for field in fields:
	    if field.get('prompt'):
		strings.append(field.get('prompt'))

	    if field.get('options'):
		for s in field.get('options'):
		    toSave = s.get('label')
		    try:
			int(toSave)
		    except:
			strings.append(s.get('label'))
    return strings 

