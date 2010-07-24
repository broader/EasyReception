"""
A scripts to run git command in order to synchronize local source with 
remote github server.

Change Log:
2009.12.24
- Restructed files directories which is listed as below
root
->develop
----->Karrigell	All the files in Karrigell Server directory
----->MindMap		The develop freemind file
"""

__version__ = "0.0.1"

import commands, datetime
import logging, os, sys
#import os, os.path

RSYNC = 'rsync'
RSYNCOPTIONS = ( '-avzur', '--delete', '--progress' )
GIT = 'git'
LOGFILE = '%s'%os.path.sep.join((os.path.abspath(os.path.curdir), 'backup2git.log'))
KARRIGELLSRC = '/home/broader/develop/R@K/CMS/Karrigell/'
MINDMAP = '/home/broader/develop/R@K/CMS/Docs/develop/'
DIRS = ['Karrigell', 'MindMap']
LOCALGIT = '/home/broader/develop/EasyReception/develop'

def getLogger(logfile, loggerName=None):
	logger = logging.getLogger (loggerName)
	handler = logging.FileHandler(logfile)
	handler.setFormatter( logging.Formatter('%(asctime)s %(levelname)s %(message)s') )
	logger.addHandler(handler)
	logger.setLevel(logging.DEBUG)
	return logger

def action(cmd, test=True, logger=None):
	
	print 'action function, Command: \n%s\n'%cmd

	if test:
		res = [0,'Test']
	else:
		res = commands.getstatusoutput(cmd)	
	
	if logger:
		info = 'Command: \n%s\nrunning result is :%s'%(cmd,res[1])
		print 'action function,',info
		logger.info(info)
	return res

def run(test):
	logger = getLogger(LOGFILE, "GitHub update" )
	rsync = RSYNC
	git = GIT
	  
   	# delete nousing captcha images
	cmd = ['rm', '-f', ''.join((KARRIGELLSRC, 'registration/tmp/*.jpeg'))]
	cmd = ' '.join(cmd)
	logger.info('Delete nousing captcha images')
	res = action(cmd,test,logger)
	
	logger.info('Begin to backup loacl karrigell diretory and mindmap files to local git.\n')
	# synchronize 'Karrigell/ereception' to '/home/broader/EasyReception'
	for src, dir in zip( [KARRIGELLSRC, MINDMAP], DIRS ) :
		cmd = [ rsync,]
		target = '/'.join((LOCALGIT, dir))
		[ cmd.extend(a) for a in (RSYNCOPTIONS, [ src, target])]
		cmd = ' '.join(cmd)
		res = action(cmd,test,logger)
		if res[0] != 0 and not test:
			logger.info('Something is wrong!')
			return
			
	logger.info('End backup loacl karrigell diretory to local git.')
   
   # synchronize 'EasyReception' to remote github host
	logger.info('Begin to backup local github to remote github host.')    
   
   # get current date info
	now = datetime.datetime.today().isoformat()
	info = 'Update time:%s'%now
	options = [ 'add .', "commit -m '%s'"%info, 'push origin master']
	for option in options :
		cmd = ' '.join([GIT, option])
		action(cmd,test,logger)
   	
	logger.info('End backup local github to remote github host.')
	logging.shutdown()
	return
   
   
if __name__ == '__main__':	
	run(test=False) 
