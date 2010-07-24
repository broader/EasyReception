['checkNewActions']
"""
Functions for handling 'webaction' roundup.Class
"""
import os, cStringIO
# import two Karrigell modules for filtering functions' names from ks files
from k_target import translate_func
from transform_script import transform

from tools import treeHandler

# 'THIS' is a variable trnasfered to this module file
RELPATH = (lambda p : p.split('/')[0])(THIS.baseurl)

def _iterDirectory(oldActions, propnames):
	'''
	Iterate the specified application directories and store the new web actions to
	database, these web actions are functions supplied by '.ks' files .

	Steps:
	1 Iterate directories specified in config file 'config.py',
	  filtere all the '.ks' file and functions in '.ks' files whose has prefix string
	  'page' or 'index';
	2 Then the '.ks' files' names list will be constructed into a tree;
	3 Flatten the tree and check each node should has a serial br contrasting with
   	  the old actions which is a argument transfered to this function.
	  If the node has serial, then add it to its 'serial' attribute, if the node
	  has no serial, that means it's a new created action, set the node's serial
	  attribute to be None;
	4 Iterate the flatten tree again and filter the nodes that have no serial attribute,
	  create serial for each no serial node;
	5 Add those new created actions to database .

	Parameters:
	    oldActions - the properties' values of items of 'webaction' in database
	    actionIndex - the index of 'action' in each item of oldActions
	'''
	# config data object, 'CONFIG' is a variable trnasfered to this module file
	config = Import( '/'.join((RELPATH, 'config.py')), rootdir=CONFIG.root_dir)
	root, ksFiles = CONFIG.root_dir, []
	for appdir in config.getData('appdirs'):
		path = os.sep.join((root, appdir))
		if not os.path.isdir(path):
			continue

		# get all the '.ks' files under this directory
		toSet = []
		# Parameters:
		# path- the directory to be scaning
		# _filterKs- the function to handle the file name
		# toSet- a list to hold the result of _filterKs function
		os.path.walk(path, _filterKs, toSet)
		toSet.sort()
		ksFiles.extend(toSet)

	# construct a nodes list by the ks filenames list
	nodesList = []
	for ks in ksFiles:
		fnSplit = ks.split('/')
		app = fnSplit[-2]
		if app not in nodesList:
			nodesList.append(app)

		page = '/'.join(fnSplit[-2:])
		nodesList.append(page)
		fileObj= cStringIO.StringIO(open(ks).read())
		out = cStringIO.StringIO()
		# get functions' names in the ks file
		fns = transform(fileObj, out, func=translate_func, debug=False).functions
		fns.sort()
		pages = ['/'.join((page, function))
			  for function in fns if 'page' in function or 'index' in function ]
		nodesList.extend(pages)

	# construct a tree from the nodes list
	# by Class Node definition each node has three important attributes,
	# 'id', 'prent', 'children'
	tree = treeHandler.TreeHandler(nodesList, lambda name : name, lambda name: '/'.join(name.split('/')[:-1]))
	flattenTree = tree.flatten()

	# add 'serial' attribute to each node
	if oldActions :
		actionIndex, serialIndex = [propnames.index(prop) for prop in ('action', 'serial')]
		for node in flattenTree:
			node.serial = None
			action = node.id
			isExisted = None
			for oldAction in oldActions :
				if oldAction[actionIndex] == action :
					node.serial = oldAction[serialIndex]
					oldActions.remove(oldAction)
					break


	newActions = []
	for node in flattenTree[1:]:
		if not node.serial:
			node.serial = _createSerial(node)
			newActions.append([node.id, node.serial])

	return newActions, oldActions

def _filterKs(kslist, dirname, files):
	[ \
		kslist.append(os.sep.join((dirname,f))) \
		for f in files \
		if os.path.splitext(f)[-1] == '.ks' \
	]
	return

def _isRoot(node):
	return node.id == 'root'

def _createSerial(node):
	parent = node.parent
	if not parent :
		# it's root node, do nothing
		return

	if _isRoot(parent) :
		# this node is the first level node, so just using the level serial
		serial =  _levelSerial(node)
	else :
		if parent.serial :
			parentSerial = parent.serial
		else:
			# create branch nodes' serial recursively
			parentSerial = _createSerial(parent)

		levelSerial = _levelSerial(node)
		serial = parentSerial + levelSerial

	return serial

def _levelSerial(node) :
	siblings = node.parent.children
	serials = filter(None, [n.serial for n in siblings ])
	if serials:
		serials.sort(key=lambda i : int(i))
		serial = str(int(serials[-1][-2:])+1).zfill(2)
	else:
		serial = '00'
	return serial

def checkNewActions(user, props):
	''' Return the items of 'webaction' roundup.Class '''
	if not props:
		return

	# check the directory to find new added web actions
	# load the items of 'webaction' in roundup database,
	# 'REQUEST_HANDLER' is a variable trnasfered to this module file
	model = Import( '/'.join((RELPATH, 'model.py')), REQUEST_HANDLER=REQUEST_HANDLER )
	oldActions = model.get_items(user, 'webaction', props)
	oldActions = type(oldActions)==type('') and [] or oldActions
	PRINT( 'checkNewActions',oldActions)

	"""
	# constructs a tree by iterating the application modules' directory
	newActions, oldActions = _iterDirectory(oldActions, props)

	if oldActions :
		# there is some web actions need to be deleted
		nodeIds = [old[props.index('id')] for old in oldActions]
		model.delete_items(user, 'webaction', nodeIds)

	if newActions:
		model.create_items(user, 'webaction',('action', 'serial'), newActions)
	"""

	return



