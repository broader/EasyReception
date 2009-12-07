import os
import yaml

INICONFIG = os.sep.join((rootdir, 'config.yaml'))
INIDATA = {}
INIDATA['userBaseInfo'] = \
{
	'fields':( 'prefix', 'firstname', 'lastname', 'gender', \
				  'organization', 'phone', 'fax', 'aperson', \
				  'address', 'city', 'country', 'postcode'),
	'labels':{ 'prefix': _("Prefix :"), 'firstname': _("First Name :"),\
  				  'lastname': _("Last Name :"), 'gender': _("Gender :"),\
  				  'organization': _("Organization :"),\
  				  'phone' : _("Phone :"), 'fax': _("Fax :"),\ 
  				  'aperson': _("Accompany Person :"),\				    
  				  'address': _("Address :"),  
  				  'city': _("City :"), 'country': _("Country :"),\
  				  'postcode': _("Postal Code :")\
				}
}

def _init(fieldsName):	
	stream = open(INICONFIG, 'wb')
	yaml.dump(INIDATA,stream,explicit_start=True)
	stream.close()
	return	

def _getConfig():
	stream = open(INICONFIG, 'rb')
	config = yaml.load(stream)
	stream.close()
	return config
	
def getData(fieldsName):
	config = _getConfig()
	if not config or not config.get(fieldsName):
		_init(fieldsName)
	return _getConfig()
	