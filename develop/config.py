import os
import yaml

INICONFIG = os.sep.join((rootdir, 'config.yaml'))
INIDATA = {}
INIDATA['userAccountInfo'] = \
{
	'fields':( 'username', 'usermail', 'password' ),
}

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

def _init(field):	
	stream = open(INICONFIG, 'wb')
	yaml.dump(INIDATA,stream,explicit_start=True)
	stream.close()
	return	

def _getConfig(field):
	stream = open(INICONFIG, 'rb')
	config = yaml.load(stream)
	stream.close()
	return config.get(field)
	
def getData(field):
	config = _getConfig(field)
	if not config or not config.get(field):
		_init(field)
	return _getConfig(field)
	