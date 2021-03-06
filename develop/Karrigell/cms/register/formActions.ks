model = Import('../model.py', REQUEST_HANDLER=REQUEST_HANDLER)

so = Session()

def index(**args):
	print 'A ks file for handle different form submit actions of registration steps.'

# get ajax client
def _getClient( ):			
	client = model.get_client()
	return client
		
JSON = Import('../demjson.py')	 
def step0(**args):
	import sys
	reload(sys)
	sys.setdefaultencoding('utf8')
	for k,v in args.items():				
		setattr(so, k, v)
	
	print JSON.encode({'type':1, 'session': args})
	return 

config = Import('../config.py')	
def step1(**args):
	account_info = {}
	for key in config.login_fields :
		account_info[key] = getattr(so, key, None)
	
	client = _getClient()	
	# create the account in database
	form = {'action': 'register','context': 'user','all_props': {('user', None): account_info}}
	client.form = form
	try:
		user_id = int(client.main()['data'])
	except:
		#print sys.exc_info()
		user_id = None
	finally:
		pass
	
	if user_id:
		client.user = account_info.get('username')	
	
	# set the user's info which is stored in a csv format file on server side	
	baseinfo = args
	filename = '_'.join(("user", str(user_id), "info" ))	
	admin = user = client.user 
	res = model.edit_user_info(admin, user, 'create', baseinfo, filename, client)
	if res:
		[setattr(so, name, baseinfo.get(name, None)) for name in baseinfo.keys()]
	
	print JSON.encode(res)
	return

def existName(**args):
	try:
		username = _username
	except:
		username = None	
	finally:
		pass	
	
	client = _getClient()
	if not hasattr(client, 'db') or client.db_open == 0:
		# now client has no 'db' attribute or the db has been closed, 
		# so open the database as 'anonymous' user
		client.opendb('anonymous')		
	
	try:
		# try to find the username in database
		userid = client.db.user.lookup(username)		
	except (KeyError, TypeError):
	   userid = None
	finally:
		pass
			
	if not userid :
		print 'true'
	else:
		print 'false'
	
	return
	
Captcha = Import('Captcha.py')		
def validCaptcha(**args):
	try:
		key = _key
	except:
		key = None
	finally:
		pass
	
	try:
		captcha = _captcha
	except:
		captcha = None
	finally:
		pass
				
	if Captcha.testSolution(key, captcha):
		print 'true'
	else:
		print 'false'
	
	return
			
def switchImage(**args):
	key = Captcha.getChallenge()			
	image = '/'.join(('register',Captcha.getImageFile(key)))
	# replace the captcha key	
	print '$("#ckey").attr({"value": "%s"});'%key
	# replace the image source 
	print '$(".captcha").attr({"src": "%s"});' %image
	# replace the validation rule for captcha	
	url = 'register/formActions.ks/validCaptcha?key=%s' %key
	print '$("#captcha").rules("add", {remote: "%s"});' %url 
	return
		