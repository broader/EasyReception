import roundup

model = Import('../model.py', REQUEST_HANDLER=REQUEST_HANDLER)

# get ajax client
def _getClient( ):			
	# get ajax client	
	client = model.CLIENT
	return client
	
def existPwd(**args):
	username = args.get('username', None)
	pwd = args.get('oldpwd', None)	
	
	client = _getClient()
	if not hasattr(client, 'db'):
		# now client has no 'db' attribute, 
		# so open the database as 'anonymous' user
		client.opendb('anonymous')
		
	try:
		# try to find the username in database
		userid = client.db.user.lookup(username)
        except (KeyError, TypeError):
        	userid = None	
	
	result = 'false'
	if userid :
		old = client.db.user.get(userid, 'password')
		# The password value stored in database is a encrypted value,
		# so it's need to use roundup.password.Password class to compare with 
		# input and old password value.		
		if roundup.password.Password(pwd) == old :
			result = 'true'
	print result
	 
		