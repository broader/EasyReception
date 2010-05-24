from HTMLTags import *
import os, sys, cStringIO

model = Import("../model.py", REQUEST_HANDLER=REQUEST_HANDLER)

modules = {'config' : 'backgroundConfig.py', 'JSON' : 'demjson.py', 'formRender' : 'formRender.py', 'pagefn' : 'pagefn.py'}
[locals().update({k : Import('/'.join(('..', v)))}) for k,v in modules.items() ]

so = Session()
if not hasattr(so, 'user'):
	so.user = None 

def page_showProps(klass, target):
	props = model.get_class_props(so.user, klass, protected=1)
	curpath = THIS.script_url.split('/')[1]
	block = []		
	if klass not in ('service',):
		url = '/'.join((curpath, 'sysadmin.ks', 'page_edit')) + '?' + 'klass=%s'%klass		
		editstyle = {'style': 'text-decoration:underline;', 'href': url, 'target': target}
	else:
		editstyle = {'style': 'text-decoration:underline;'}
		
	edit = DIV(A(klass, **editstyle) , style="font-weight:bold; font-size:2.5em")	
	block.append(edit)		
	table = []
	propnames = props.keys()
	propnames.sort()		
	d = {'style':'font-weight:bold;font-size:1.2em;color:#86B50D'}
	for propname in propnames:			
		prop = TD(propname,**d)			
		des = TD(repr(props[propname]).strip('<>'))
		tr = TR(Sum((prop, des)))
		table.append(tr)			
	block.append(TABLE(TBODY(Sum(table))))
	print Sum(block)
	
def page_showClass(**args):
	name = args.get('name')
	if not name :
		print H2('No Class')
		return
	
	target = 'classEdit'
	props_suffix = 'page_showProps?klass=%s&target=%s'%(name, target)
	edit_suffix = 'page_edit'
	if name == 'service':
		edit_suffix += '?klass=%s'%name
	prefix =  THIS.script_url.split('/')[1]
	props_url, edit_url = [  '/'.join((prefix, 'sysadmin.ks', suffix))	\
						for suffix in (props_suffix, edit_suffix ) ]
	
	leftId = 'classprops'
	js_1 = "$('#%s').hide().show('slow')"%leftId
	style_1 = "border:1px solid #8B8378;"
	d1 = {'id': leftId, 'class':'dimmed c38l', 'onload':js_1, 'style':style_1, 'src' : props_url}
	left = DIV(**d1)
	
	# right users base info Div component
	js_2 = "$('#classEdit').hide().show('slow')"
	style_2 = "width:58%;border:1px solid #8B8378;"
	d2 = {'id':'classEdit','class':'info c62r','src' : edit_url, 'onload':js_2,'style':style_2}
	right = DIV(**d2)		
	
	print Sum((left,right))
	
	# now initial jframe
	pagefn.jframe()
	
def index(**args):	
	admin = so.user
	if not admin:
		return
	klassnames = config.web_edited_classes
	klassnames.sort()
	
	curpath = THIS.script_url.split('/')[1]	
	li = []
	for klass in klassnames:
		url = '/'.join((curpath, 'sysadmin.ks', 'page_showClass')) + '?' + 'name=%s'%klass
		attr = {'href': url}
		li.append(LI(A(klass, **attr)))		
	print UL(Sum(li))
	
def _filter_ks(kslist, dirname, files):
	[kslist.append(os.sep.join((dirname, f))) for f in files if os.path.splitext(f)[-1] == '.ks']

def _getNewActions(oldactions):
	from k_target import translate_func
	from transform_script import transform
	
	apps = config.apps
	apps.sort()
	root = CONFIG.root_dir
	actions = []
	for app in apps :
		# 'app' is application relative path	
		# 'group' is a list to hold the relative path of a ks file 
		# and the functions in this ks file. 	
		group = [app]
		#actions.append(app)
				
		path = os.sep.join((root, app))
		if not os.path.isdir(path):
			continue
		
		toSet = []	
		# iterate the directory and save the .ks files' names
		os.path.walk(path, _filter_ks, toSet)	
		toSet.sort()			
		for ks in toSet :
			fn = '/'.join((app, ks.split('/')[-1]))					
			obj = cStringIO.StringIO(open(ks).read())
        		out = cStringIO.StringIO()        		
        		# get the functions name in this ks file, the name must inlude 'index' or 'page' charactors
    			functions =  transform(obj,out,func=translate_func,debug=False).functions
    			functions.sort()
    			pages = ['/'.join((fn, function)) \
    					for function in functions if 'page'  in function or 'index' in function ]
			group.extend( pages )					  			
    			newactions = list(set(group) - set(oldactions))
    			actions.extend(newactions)
    			
    	return actions


def _action_import(oldactions):
	''' This function is used to import new page actions to 'webaction' class.
	   Parameters:
	   	oldacton -[{'action':..., 'serial':...},]
	'''
	# Constructs a tree which is stored into a dictionary,
	# it's keys represend nodes and it's values represned children number.	
	tree = {'root':0}	
	
	for i,old in enumerate(oldactions) :
		# 'old' format is {'action':..., 'serial':...} 
		action, serial = [old[key] for key in ('action', 'serial')]
		action = action.split('/')
		app = action[0]
		
		if not tree.get(app):
			# records the first two bits number of this 'app', 
			# the children number of this 'app' now is 0,
			# the children number of 'root' in tree now increased 1.
			tree[app] = {'serial': serial[0:2], 'children' : 0}
			tree['root'] += 1	
		
		if len(action) == 1 :
			# this action is a 'app'
			pass
		elif len(action) == 3:
			# this action is a function of a ks page in a 'app' module
			# get the relative path of this ks file
			ks = '/'.join(action[0:2])			
			if not tree.get(ks):
				# Now there is no record of this page in tree,
				# add this ks node to tree variable,
				# the information of this node inludes 'serial' and 'children'				 				
				tree[ks] = {'serial': serial[0:4], 'children' : 1}
				# the children of the 'app' which this page belonged to increased 1.
				try:
					tree[app]['children'] += 1
				except:
					print "_action_import, tree is  %s, action is %s, serial is %s, oldactions count is %s"\
							%(tree,action,serial, i)
					return				
			else:				
				# This ks has been stored in tree variable,
				# the children of this ks increased 1.
				tree[ks]['children']  += 1
			
	
	# get new page actions
	if oldactions:
		oal = [i['action'] for i in oldactions]
	else:
		oal = []
	newactions = _getNewActions(oal)	
	
	# creat new 'webaction' items and import new actions into 'tree' variable
	toSet = []
	for action in newactions:		
		l = action.split('/')
		app = l[0]		
		if not tree.get(app):
			# tree has no  'app' , add it.										
			start = str(tree.get('root')).zfill(2)						
			tree[app] = {'serial': start, 'children':0}
			# tree['root'] conts based 0
			tree['root'] += 1			
		
		if len(l) == 1 :
			# this action is a new 'app' module			
			serial = start + '0000'				
		elif len(l) == 3:
			ks = '/'.join(l[0:2])
			if tree.get(ks):
				prefix, children = [tree.get(ks)[name] for name in ('serial', 'children')]
				# app/ks/function counts based 0
				serial = prefix + str(children).zfill(2)				
				tree[ks]['children'] += 1				 
			else:
				tree[app]['children'] += 1								
				prefix, children = [tree[app][name] for name in ('serial', 'children')]
				# app/ks counts based 1
				serial = prefix + str(children).zfill(2) + '00'
				# add ks to tree variable
				tree[ks] = {'serial': serial[0:4], 'children' : 1}				
				
		toSet.append((action, serial))
		
	# Now creating this webactions    	
	if toSet :
    		ids = model.create_items(so.user, 'webaction', ('action', 'serial'), toSet)
		
def page_edit(**args):
	klass = args.get('klass')
	name = '%s'%(klass or '')
	if klass == "service":
		Include('../service/service.ks/page_showService')
		return	
		
	print H1('Edit %s '%name)
	print HR()	
	if not klass :
		return
				
	# get class' properties
	admin = so.user
	props = model.get_class_props(admin, klass).keys()
	props.sort()
	props.insert(0, 'id')	
	if klass == 'user':
		props.remove('password')
			
	rows = model.get_items(admin, klass, props)	
			
	if not rows or type(rows) == type('') :
		rows = []				
	
	if klass == 'webaction':
		if rows:
			action_index, serial_index = [props.index(name) for name in ('action', 'serial')] 
			#rows = [(row[action_index], row[serial_index]) for row in rows ]			
			rows = [{'action': row[action_index], 'serial':row[serial_index]} for row in rows ]
			
		#_action_init(rows)
		_action_import(rows)
		# Maybe new 'webaction' has been created, so get all the items again.
		rows = model.get_items(admin, klass, props)
	
	def _judge(i):
		if type(i) == type([]):
			i = ','.join([str(j) for j in i])
		elif not i:
			i = ''		
		return i
		
	if rows:		
		rows = [ map(_judge, row) for row in rows]
			
	# sorts the rows by the 'id' value	
	rows.sort(key=lambda x : int(x[0]) )	
	
	# inner [i or '' for i in row] ,just for replacing None to ''
	#itemsvalues = [', '.join([str(i) or '' for i in row]) for row in rows]	
	# Note, ';' is the 'delimiter' character of the fields in each row in the csv formatted content
	itemsvalues = ['; '.join([str(i) or '' for i in row]) for row in rows]
	itemsvalues = '\r\n'.join(itemsvalues)
	#print itemsvalues		
	remember = {'content': itemsvalues, 'klass':klass}
	# constructs the form
	
	caption = _('Total %s records'%len(rows)) +str(BR()) + ','.join(props)  
	
	style = 'width:90%;font-size:1.1em;overflow-x:hidden;overflow-y:scroll;'
	template = [ [caption, \
			     {'id':'klass','name':'content', 'rows':'8', 'style': style}, \
			     'textarea'],\
			     [None,{'name':'klass', 'type':'hidden'}, 'input']]
			    
	form = formRender.render_rows(template, remember)
	values = config.form_buttons
	sbn = INPUT(**{'id': 'submit',\
				 'type':'button', \				 
				 'value': values[0], \				 
				 'style': 'width:7.6em;height:2.6em;font-weight:bold;font-size:1.1em;', \
				 'target':'classEdit'})

	cbn = INPUT(**{'type':'button', \
				'name':'cancel',\
				'value': values[1], \
				'style': 'width:7.6em;height:2.6em;font-weight:bold;font-size:1.1em;'})
				
	buttons = DIV(Sum((sbn, cbn)), **{'class':'type-button'})	
	form.append(buttons)	 	
	curpath = THIS.script_url.split('/')[1]
	action_url = '/'.join((curpath, 'sysadmin.ks', 'postedit'))	
	print FORM(Sum(form), **{'id':'issue_new', 'class': 'yform', 'action': action_url,'method':'post'})

def postedit(**args):
	buttons = config.form_buttons
	submit = args.get('submit')
	if buttons.index(submit) == 1:
		# 'Cancel' form action
		print H2('Edit Action Canceled!')
		return
						
	klass = args.get('klass')
	
	print H2('Edit \"%s\" Successfully!'%klass)
	content = args.get('content')	
	
	if not content or not klass:
		# no input
		return
	
	model.editcsv(so.user, klass, content)
	
	
