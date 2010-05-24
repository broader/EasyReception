##
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Library General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
##

''' Initialize the ajax client to a roundup tracker model, which  consists of ajaxInstance, ajaxClient and
ajaxActions.
ajaxClient
'''
import os, sys
import roundup

from roundup.ajax import ajaxInstance, ajaxClient
#mport Constants

def valid_dir(path):    
    ''' Check wether the path is a correct directory located data.
    '''    
    print 'valid_dir'
    try:        
        tracker = ajaxInstance.open(path)                
    except:
        tracker = None
        print sys.exc_info()
    return tracker

        	
#The real action to valid user's longin
def _valid(client, name=None,pwd=None):
	form = { 'action' : 'login', 'context' : 'user', 'username' : name, 'password' : pwd }
        client.form = form
	print client.form
        try:
        	res = client.main()        	
        	data = res['data']              
        except:         	
         	data = (0, 'Login Fail')
		print sys.exc_info()
	return data                 

def valid_action(path):
	tracker = valid_dir(path )    
	if not tracker:
		print "There is no correct roundup data directory!"
		client = None        
	else:	             
		try:
        		client = ajaxClient.Client(instance=tracker)        	
	        except:
        		client = None
			print sys.exc_info()
	if client:
		name = 'demo'
		pwd = ''
		data = _valid(client, name, pwd)
	else:
		data = None
	return data

def register_action(path):	
	tracker = valid_dir(path )    
	if not tracker:
		print "There is no correct roundup data directory!"
		client = None        
	else:	             
		try:
        		client = ajaxClient.Client(instance=tracker)        	
	        except:
        		client = None
			print sys.exc_info()
	letters = "abcdefghijklmnopqrstuvwxyz"
        letters += "0123456789"
       	# The random starts out empty, then 40 random possible characters
       	# are appended.
       	import random
       	uname = ''
       	for i in range (6):
      		uname += random.choice (letters)	
	
	data = None
	if client:		
		form = {   'action': 'register',\
				'user' : None,
                    		'context': 'user',\
                    		'all_props': {('user', None): {'username': '%s'%uname,\
                    							     'password':'990508',\
                    							     'email':'byllan@yahoo.com.cn'}} }
        	client.form = form
		print client.form
        	try:
        		res = client.main()        	
        		data = res['data']              
        	except:         	
         		data = (0, 'Login Fail')
			print sys.exc_info()
		try :
			user_id = int(data)
		except:
			user_id = None
		print 'register action, new user id is ',user_id		
		filename = '_'.join(("user", str(user_id), "info" ))		
		if type(user_id) == int :
			form = {'content' : {'firstname':'Broader', 'lastname':'ZHONG'},
				     'context' : ('user', user_id),
				     'linkprop' : 'info',
				     'action' : 'linkcsv',
				     'actiontype': 'create',
				     'filename' : filename
				    }
			client.form = form
			try:
				res = client.main()
				data = res['data']
			except:
				print sys.exc_info()
	return data
	

import cmd

class Test(cmd.Cmd):
	"""Simple command processor example."""
    	def do_dbPath(self, path):
        	"""roundupDb [path]
        		get the roundup database directory"""
        	if path:
            		print valid_action(path)            		
        	else:
            		print 'Please input a roundup database located path.'
    
	def do_register(self, args):
		if not args:
			path = '/home/broader/develop/R@K/CMS/Karrigell/data/cms/roundup'
			data = register_action(path)
			print 'new user nodeid is ', data    	
    		else:
    			print 'Action end.'
    			
    	def do_EOF(self, line):
        	return True
    
    	def postloop(self):
        	print
        
    	def complete(self, text, state):
    		""" Perfer Link:
    			http://bbs.chinaunix.net/viewthread.php?tid=614952&extra=&page=1
    		"""
        	if state == 0:
        		import readline
            		readline.set_completer_delims(' \t\n`~!@#$%^&*()-=+[{]}\\|;:\'",<>;?')
            		origline = readline.get_line_buffer()
            		line = origline.lstrip()
            		stripped = len(origline) - len(line)
            		begidx = readline.get_begidx() - stripped
            		endidx = readline.get_endidx() - stripped
            		if begidx > 0 :
                   		cmd, args, foo = self.parseline(line)                	
                		if r'/' in text:
                    			compfunc = self.path_matches

                		elif cmd == '':
                    			compfunc = self.completedefault
                		else:
                    			try:
                        			compfunc = getattr(self, 'complete_' + cmd)
                    			except AttributeError:
                        			compfunc = self.completedefault
            		else:
                		compfunc = self.completenames
            		self.completion_matches = compfunc(text, line, begidx, endidx)
        	try:
           		return self.completion_matches[state]
        	except IndexError:
            		return None 
	
	def path_matches(self, text, *ignored):
		import os       
        	at = text.rfind('/')
        	if at > 0:
            		path = text[0]
            		filist = os.listdir(path)
        	else:
            		path = ''
            		filist = os.listdir('/')
        	f = text[at+1:]
        	matches = []
        	n=len(f)
        	for word in filist:
            		if word == f:
                    		matches.append("%s/%s" % (path, word))
        	return matches

	

if __name__ == '__main__':	 	
	Test().cmdloop()

	
