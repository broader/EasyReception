['valid_dir', 'create_client', 'get_client', 'login', 'get_classes', 'get_item', 'get_items', 'get_items_ByString', 'get_key', 'get_keyValues', 'getUserDossier', 'filterByFunction', 'fuzzyQuery', 'filterByLink', 'filterByPropValues', 'get_file', 'edit_item', 'edit_linkcsv', 'edit_user_info', 'get_adminlist', 'get_userlist', 'get_issues', 'get_reservations', 'create_item', 'create_items', 'delete_item', 'delete_items', 'edit_issue', 'get_class_props', 'editcsv', 'permissionCheck', 'userCheck', 'passwordReset', 'action', 'csv2dict', 'serial2id', 'time2local', 'stringFind', 'reserve_detailParser', 'reserveSort', 'getItemId']
""" Holds all the interfaces to the roundup tracker model, which  consists of ajaxInstance, ajaxClient and
ajaxActions.
"""
import os, sys, csv, StringIO

import roundup
from roundup import  __version__ as roundup_version
from roundup.i18n import _

from roundup.ajax import ajaxInstance, ajaxClient

try:
	INITCONFIG = Import( 'config.py', rootdir=CONFIG.root_dir)
except:
	INITCONFIG = Import( '../config.py', rootdir=CONFIG.root_dir)


def valid_dir(path):
    """ Check wether the path is a correct directory located data.
    """
    try:
        tracker = ajaxInstance.open(path)
    except:
        tracker = None
        PRINT( sys.exc_info())
    return tracker

######################### database ###########################################
# get the path of database, here 'CONFIG' is the global variable of Karrigell
DBPATH  = os.path.join(CONFIG.data_dir, 'roundup')
#############################################################################

def create_client( ):
	tracker = valid_dir(DBPATH )
	if not tracker:
		PRINT( _("There is no correct roundup data directory!"))
		client = (CONFIG.data_dir, DBPATH)
	else:
		try:
			client = ajaxClient.Client(instance=tracker)
		except:
			client = None

	return client


def get_client( ):

	#handler = REQUEST_HANDLER

	#if hasattr(handler, 'ajaxclients'):
	#	ajaxclients = getattr(handler, 'ajaxclients')
	#	for client in ajaxclients:
	#		if hasattr(client, 'db') and client.db_open == 0 :
	#			[setattr(client,attr,None) for attr in ('form','user','userid')]
	#			return client
	#	client = create_client()
	#else:
	#	client = create_client()
	#	setattr(handler, 'ajaxclients', [] )

	#handler.ajaxclients.append(client)

	client = create_client()
	return client


def _getSuperAdmin():
	""" Return the super administrator for system."""
	superAdmin = INITCONFIG.getData('superAdmin')
	return superAdmin

def login(usr=None, pwd=None):
	client = get_client()
	client.set_user(_getSuperAdmin())
	form = { 'action' : 'login', 'context' : 'user', 'username' : usr, 'password' : pwd }
	client.form = form
	return action(client)

def get_classes(operator, needKey=False):
	""" Return a list of the names of all existing classes. """
	client = get_client()
	client.set_user(operator)
	klasses = client.db.getclasses()
	if needKey:
		klasses = [klass for klass in klasses if client.db.getclass(klass).getkey()]
	return klasses

def get_item(operator, klass, key, props=None, keyIsId=False):
	""" Get the propvalues of a item of a class stored in database.
	   Return a dictionary holding the properties and their values.
	"""
	client = get_client()
	if not client:
		return None

	client.set_user(operator)
	form = { 'action': 'getitem', 'propnames': props}

	if keyIsId:
		form['context'] = (klass, int(key))
	else:
		form['context'] = klass
		form['keyvalue'] = key

	client.form = form
        res = client.main()
        if res['success']:
        	data = res.get('data')
        	if props:
        		#d = {}
        		#[d.update({name:value}) for name,value in zip(props,data)]
        		#data = d
        		data = dict([(k,v) for k,v in zip(props,data)])
        else:
        	data = None
        return data

def get_items(operator, klass, props=None, link2key=False,ids=None):
	""" Get the specified propterties' values of all the items of a Class.
	"""
	client = get_client()
	if not client:
		return None

	client.set_user(operator)
	form = {
		'action': 'getitems',\
              	'context': klass,\
              	'ids' : ids,\
              	'propnames': props,\
              	'link2key': link2key\
               }
	client.form = form
	return action(client)

def get_items_ByString(operator, klass, search, propnames=None, needId=False,link2key=False):
	""" Get items by specified string value of the class's String properties.
	Parameters:
	  	search - a dictionary holding the values of multiful 'String' properties;
	  	propnames - a list or tuple which holds the properties' names;
	  	needId - if True, the 'id' property will be added to the '0' index of the result list;
	"""
	client = get_client()
	if not client:
		return None

	client.set_user(operator)
	form = {\
		'action': 'gibs',\
              	'context': klass,\
              	'filter' : search,\
              	'needId' : needId,\
		'link2key': link2key,\
              	'propnames': propnames\
   	}

	client.form = form
	return action(client)

def get_key(operator, klass):
	""" Return the key property's name of a roundup.Class."""
	client = get_client()
	client.set_user(operator)
	key = client.db.getclass(klass).getkey()
	return key

def get_keyValues(operator, klass):
	"""
	Return a list  that holds the values of 'key' property of each item in this class instance.
	"""
	client = get_client()
	client.set_user(operator)
	key = client.db.getclass(klass).getkey()
	values = get_items(operator, klass, (key,))
	values = values and type(values)==type([]) and [i[0] for i in values] or []
	return values

def getUserDossier(operator, user):
	"""
	Return the dossier data which is saved in a csv formatted file on server side.
	"""
	# get link id
	prop = 'info'
	values = get_item( operator, 'user', user, (prop,))
	nodeId = values.get(prop)
	if not nodeId :
		content = {}
	else:
		# get file content
		content = get_file( operator, 'dossier', nodeId)

	data = csv2dict(content)
	return data

def filterByFunction(operator, klass, props, fn, fnArgs):
	client = get_client()
	if not client:
		return None

	#Parameters:
	# 'context' - the class name
	# 'propnames' - the properties whose values should be returned
	# 'filterFn' - a function to filter the item of the class
	# 'filterArgs' - the properties' names that should be passed to 'filterFn' as arguments.
	#                Note, 'filterArgs' colud be different with 'propnames'.

	client.set_user(operator)
	form = {	\
		'action': 'filterfunction',\
		'context': klass,\
		'propnames' : props,\
		'filterFn' : fn,\
		'filterArgs': fnArgs\
	}
	client.form = form
	return action(client)

def fuzzyQuery(operator, klass, search, props=None, require=None):
	"""
	Filter Class's items by 'require' which is a dictionary holding the
   required values, and return the properties' values specified by 'props'.
	"""
	client = get_client()
	if not client:
		return None

	client.set_user(operator)
	# Parameters:
	# 'search' - a text value that to be queried
	# 'require' - a dictionary holds property names and needed values
	form = {\
		'action': 'filtertext',\
		'context': klass,\
		'search' : search,\
		'require' : require,\
		'propnames': props\
	}

	client.form = form
	return action(client)

def filterByLink(operator, klass, linkclass, linkvalue,propnames,linkprop=None):
	""" Get the items' values by specified link property's value.
	"""
	client = get_client()
	if not client:
		return None

	client.set_user(operator)
	form = {\
		'action': 'filterbylink',\
		'context': klass,\
		'propnames': propnames,\
		'linkclass' : linkclass,\
		'linkvalue' : linkvalue\
	}

	if linkprop:
		form['linkprop'] = linkprop

	client.form = form
	return action(client)

def filterByPropValues(operator, klass, propnames, conditions):
	"""
	Get the items by filtering conditons.
	Parameters:
	    conditions - {'propname': 'value',...}
	"""
	client = get_client()
	if not client:
		return None

	client.set_user(operator)
	form = {\
		'action': 'filterbyprop',\
		'context': klass,\
		'propnames': propnames,\
		'filter' : conditions\
	}

	client.form = form
	return action(client)


def get_file(operator, klass, id):
	""" Get the content of a FileClass in database.
	"""
	client = get_client()
	form = {\
		'action': 'getfile',\
		'context': klass,\
		'id': id,\
		'user': operator\
	}

	client.form = form
	res = client.main()
	return action(client)

def edit_item(operator, klass, key, props=None, actionType='edit', keyIsId=False):
	""" Parameters:
	 	props -a dictionary holds propterties and their values to be changed
	 """
	client = get_client()
	if not client or not props :
		return None
	elif not isinstance(props, dict):
		return None

	client.set_user(operator)
	form = { 'action' : actionType, 'context' : klass }

	if keyIsId:
		form['all_props'] = {(klass, key) : props}
	else:
		form['all_props'] = {(klass, None): props}
		form['keyvalue'] = key

        client.form = form
        return action(client)

def edit_linkcsv(client, klass, nodeid, linkprop, actionType, content, filename=None):
	""" Edit the linked csv file content.
	   Parameters:
	   	client -a ajaxClient instance
	   	klass -the name of the class to be edit
	   	nodeid -the item's id of the klass in database
	   	linkprop -the 'Link' type property's name
	   	actionType - 'edit', 'create'
	   	content - a dictionary, holds the properties names and values
	   	filename - for 'create' action, a file name should be assigned first
	"""
	form = {'context' : (klass, nodeid),
		     'linkprop' : linkprop,
		     'action' : 'linkcsv',
		     'actiontype': actionType,
		     'filename' : filename,
		     'content': content
		    }
	client.form = form
	return action(client)

def edit_user_info(operator, user, actionType, content, filename=None, client=None):
	""" Edit User's 'info' property which is a link csv file.
	"""
	if not client:
		client = get_client()
		client.set_user(operator)

	if not client.db_open :
		client.set_user(operator)

	userId = client.db.user.lookup(user)
	if not filename:
		filename = '_'.join(('user', str(userId), 'info' ))

	return edit_linkcsv(client, 'user', userId, 'info', actionType, content, filename)

def get_adminlist(operator, props, search=None):
	"""
	Parameters:
		search - [[property name, property value], [property name, property value, 'AND' or 'OR'], ...]
	"""
	client = get_client()
	client.set_user(operator)
	# action
	form = {\
		'context': 'user',
		'action': 'getbysql',
		'sql_type' : 'LIKE',
		'conditions' : search,
		'propnames' : props,
	}

	client.form = form
	data = action(client)
	if not data :
		data = []
	return data

def get_userlist(operator, props, search=None):
	client = get_client()
	client.set_user(operator)
	user_props = client.db.user.getprops()
	propnames = [prop for prop in props if prop in user_props]
	propnames.append('info')
	# action
	form = {\
		'context': 'user',
		'action': 'filtertext',
		'search' : search,
		'require': {'roles':'User'},
		'propnames' : propnames,
		'link2contentProps' : ['info',]
	}

	client.form = form
	data = action(client)
	if not data :
		total = 0
		data = []
	else:
		total = client.form.get('total')
		for rowindex, row in enumerate(data):
			# transformat the content from csv format to a dict object
			propsinfile = csv2dict(row[-1])
			new = []
			for prop in props:
				# the property of User Class
				if prop in user_props:
					index = propnames.index(prop)
					value = row[index]
					new.append(value)
				# propterty in the content of linked file
				else:
					new.append(propsinfile.get(prop))
			data[rowindex] = new
	return total,data

def get_issues(operator, props, search=None, filterFn=None, filterArgs=None):
	"""
	Get the issues that related with 'operator'.
	"""
	client = get_client()
	client.set_user(operator)

	# action
	# Here using 'filterfunction' action is just for filtering specified issues
	# for special 'user'
	form = {
		'context': 'issue',
		'action': 'filterfunction',
		'propnames' : props,
		'link2key': True,
		'search' : search,
		# these properties will be converted from link class item's id to its key value
		'link2contentProps': ['keyword', 'status'],
		'filterFn' : filterFn,
		'filterArgs': filterArgs
	}

	client.form = form
	data = action(client)
	if not data :
		total = 0
		data = []
	else:
		total = len(data)
	return total,data

def get_reservations(operator, booker, props=None):
	""" Get the properties' values of the items of 'reserve' Class in shcema.
	"""
	reserves = filterByLink( operator, 'reserve', 'user', booker, props, 'booker')
	return reserves

def create_item(operator, klass, props, autoSerial=True):
	client = get_client()
	if not client :
		return None

	if not operator or not klass or not props:
		return

	client.set_user(operator)
	all_props = {(klass, None): props}
	form = { \
		'action' : 'new',\
	      	'needId': True,
		'context' : klass,\
		'all_props': all_props
	}

	# if class has 'serial' property and needed to be auto created,
	# set form['autoSerial'] to True.
	if autoSerial :
		form['autoSerial'] = True

	client.form = form
	action(client)
	newId = None
	# dictionary 'form' has been set the value for key 'needId' duing roundup action
	needId = form.get('needId')
	if needId:
		newId = needId.get(klass)
	return newId

def create_items(operator, klass, props, values):
	client = get_client()
	if not client :
		return None
	elif not operator or not klass or not props:
		return None

	client.set_user(operator)
	form = {
		'action' : 'newitems',\
		'context' : klass,\
		'propnames': props,\
		'propvalues': values\
	}
        client.form = form
	ids = action(client)
	return ids

def delete_item(operator, klass, key, isId=True):
	""" Retires a item of a Class,
	  this item can be retored from databse when thers's need anytime.
	"""
	client = get_client()
	if not client :
		return None
	client.set_user(operator)
	klass = client.db.getclass(klass)
	if isId:
		nodeid = key
	else:
		nodeid = klass.lookup(key)
	try:
		klass.retire(nodeid)
		client.db.commit()
	finally:
		client.db.close()
	return

def delete_items(operator, klass, keys, isId=True):
	""" Retires some items of a roundup.Class by their key values or ids. """
	client = get_client()
	if not client:
		return False

	client.set_user(operator)
	klass = client.db.getclass(klass)
	actionRes = False
	try:
		for key in keys:
			nodeid = isId and key or klass.lookup(key)
			klass.retire(nodeid)
		client.db.commit()
		actionRes = True
	except:
		pass
	finally:
		client.db.close()
	return  actionRes

def edit_issue(operator, iprops, mprops, serial=None, isId=False):
	""" A function to do 'CRUD' actions for issue class.
	  Parameters:
	  	operator-operator name
	  	iprops-a dictionary holds 'issue' class proerties' values
	  	mprops-a dictionary holds 'message' class proerties' values, this will be used to set a 'message' class
	  		     item which was linked to the property 'messages' of this issue
	  	serial-the value of 'serial' property of this issue
	"""
	if serial:
		if not isId:
			issueId = serial2id(serial)
		else:
			issueId = serial
		edit_item(operator, 'issue', issueId, iprops, keyIsId=True)
	else:
		# create a new issue
		issueId = str(create_item(operator, 'issue', iprops))

	if mprops:
		# create a new msg
		msgId = str(create_item(operator, 'msg', mprops))
		# add the message's id to the property 'messages' of Issue Class
		props = {'messages': ''.join(('+', msgId))}
		edit_item(operator, 'issue', issueId, props, keyIsId=True)
	else:
		msgId = ''
	return issueId, msgId

def get_class_props(operator,name,protected=0):
	client = get_client()
	client.set_user(operator)
	db = client.db
	klass = db.getclass(name)
	props = klass.getprops(protected)
	return {'props':props,'key':klass.getkey()}

def editcsv(operator, klass, content):
	client = get_client()
	client.set_user(operator)
	form = {'context': klass,
	     'content' : content,
	     'action' : 'editcsv'
	}
	client.form = form
	return action(client)

def permissionCheck(user, roles, path):
	""" Check the permission of the user to this page path.
	"""
	client = get_client()
	# get a super user who has full permissions
	operator = _getSuperAdmin()

	if user == operator:
		# super administrator colud do anything
		return True

	permission = False
	# get all the related definitions in database that have been stored as items of 'relation' roundup.Class
	items = filterByPropValues(user, 'relation', ('klassvalue','relatevalue'), {'klassname':'role','relateclass':'webaction'})
	if items :
		for item in items:
			if set(roles).intersection(item[0].split(',')) and path in item[1].split(','):
				permission = True
				break

	return permission

def userCheck(name):
	"""
	Give a user's ID by its name.
	This function is offten used in checking user's name.
	"""

	try:
		client = get_client()
	except:
		res['info'] = sys.exc_info()

	if not hasattr(client, 'db') or client.db_open == 0:
		# now client has no 'db' attribute or the db has been closed,
		# so open the database as 'anonymous' user
		client.opendb('anonymous')

	try:
		# try to find the username in database
		userId = client.db.user.lookup(name)
	except (KeyError, TypeError):
		userId = None

	return userId

def passwordReset(operator, username):
	""" Reset the given user's password."""
	client = get_client()
	client.set_user(operator)
	form = {'username' : username, 'action' : 'passrst'}
	client.form = form
	return action(client)

def action(client):
	""" A encapsulated function for client.main() result.
	the format of action result is a dictionary,
	for success status, its format is :
	{'success':True, 'data':'...','ok':'...'}
	for failed status, its format is :
	{'success':False, 'error':'...'}
	"""
	try :
		res = client.main()
		if res.get('success'):
			res = res.get('data') or res.get('ok')
		else:
			PRINT( 'model.py,action(),L552,error info:',res.get('error'))
			res = None
	except:
		PRINT( sys.exc_info())
		res = None
	return res

def csv2dict(content):
	data = {}
	if content:
		s = StringIO.StringIO()
		s.write(content)
		s.seek(0)
		reader = csv.reader(s)
		# each row is a key,value pair, such as [[key1, value1], [key2, value2],......]
		data = dict([row for row in reader])

	return data

def serial2id(serial):
	""" Transform a serial of a Class' item to it's 'id' property value
	"""
	return roundup.ajax.ajaxActions.serial2id(serial)

def time2local(lan, date):
	""" Parameters:
		date- a roundup.date.Date instance
	"""
	timezone = 0
	lan = [l for l in lan if l in ('zh', 'zh-cn', 'cn')]
	if len(lan):
		timezone = 8
	return date.local(timezone)

def stringFind(klass, search):
	""" Find all the items whose String properties' values are as same as
	the specified.
	Parameters:
		klass - the class' name
		search -a dictionary holds the properties' names and their searched values
	"""
	client = get_client()
	client.set_user(_getSuperAdmin())
	instance = client.db.getclass(klass)
	return instance.stringFind(**search)

# not used
def reserve_detailParser(content, need):
	""" parse the 'detial' property's values to a dictionary,
	   whose keys is in 'need'.
	   Parameters:
	   	content -the value of 'detail' property
	   	need - the keys' names of the dictionary which will be returned.
	"""
	dprops = {}
	content = content.split(';')
	for pair in content :
		i = pair.split(':')
		if i[0] in need :
			dprops.update({i[0] : i[1]})
	return dprops

# not used
def reserveSort(reserves, booker):
	# Group by 'category' of the reserved 'service' item
	# The result will be a dictionary whose format is
	# {'category' : [item,...],..}, item is {'alias': '...',...}
	toSort = {}
	for reserveDict in reserves :
		# get the properties' values of the reserved service
		serviceId = reserveDict.pop('target')
		sprops = ['category', 'detail', 'description', 'price', 'serial']
		values = get_item(booker, 'service', serviceId, sprops, keyIsId=True)
		values['serviceSerial'] = values.pop('serial')
		# append the service's info to this reservation
		reserveDict.update(values)
		category, detail = [reserveDict.pop(name) for name in ('category', 'detail') ]
		reserveDict.update( reserve_detailParser(detail, ('alias', 'parent')) )
		if category in toSort.keys():
			toSort[category].append(reserveDict)
		else:
			toSort[category] = [reserveDict]

	# Sort these reservations
	# The sorted result is a dictionary whose format is
	# {'category' : [{'parent': ['child',...],...},...],...}
	# 'child' is {'alias':'...',...}
	toRender = {}
	keys = toSort.keys()
	keys.sort()
	for category in keys :
		items = toSort.get(category)
		temp = {}
		for item in items :
			parent = item.pop('parent')
			if parent in temp.keys() :
				temp[parent].append(item)
			else:
				temp[parent] = [ item ]
		toRender[category] = temp

	return toRender

def getItemId(klass, key):
	client = get_client()
	client.set_user(_getSuperAdmin())
	instance = client.db.getclass(klass)
	return instance.lookup(key)

