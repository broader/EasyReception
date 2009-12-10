import os
import yaml

INICONFIG = os.sep.join((rootdir, 'config.yaml'))
INIDATA = {}
INIDATA['userAccountInfo'] = \
{
	'fields':( 'username', 'usermail', 'password' ),
}

INIDATA['userBaseInfo'] = \
[ 
	{ 'name':'prefix', 'prompt':_("Prefix :"), 'type':'text', 'validate':[] },\
	{ 'name':'firstname', 'prompt':_("First Name :"), 'type':'text', 'validate':[] },\
	{ 'name':'lastname',	'prompt':_("Last Name :"), 'type':'text', 'validate':[] },\
	{ 'name':'gender', 'prompt':_("Gender :"), 'type':'text', 'validate':[] },\
	{ 'name':'organization', 'prompt': _("Organization :"), 'type':'text', 'validate':[] },\
	{ 'name':'phone',	'prompt':_("Phone :"), 'type':'text', 'validate':[] },\
	{ 'name':'fax', 'prompt':_("Fax :"), 'type':'text', 'validate':[] },\
	{ 'name':'aperson',	'prompt':_("Accompany Person :"), 'type':'text', 'validate':[] },\
	{ 'name':'address',	'prompt':_("Address :"), 'type':'text', 'validate':[] },\
	{ 'name':'city',	'prompt':_("City :"), 'type':'text', 'validate':[] },\
	{ 'name':'country',	'prompt':_("Country :"), 'type':'text', 'validate':[] },\
	{ 'name':'postcode', 'prompt': _("Postal Code :"), 'type':'text', 'validate':[] }\
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
	