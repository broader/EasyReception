['getData', 'editData']
import os
import yaml

CONFIGFILE = os.sep.join((rootdir, 'fileManagement', 'fileConfig.yaml'))

# the dictionary object which holds the default values for initial config file
INIDATA = {}
INIDATA['VirtualFolder'] = [\
	{'name':'论文',},
	{'name':'诸葛亮', 'parent':'论文'},
	{'name':'庞统', 'parent':'论文'},
	{'name':'奏章'},
	{'name':'王允', 'parent':'奏章'},
	{'name':'曹操', 'parent':'奏章'},
]

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
		if not configObject:
			_init({field:value})
		else:
			configObject[field] = value
			_init(configObject)

	return

