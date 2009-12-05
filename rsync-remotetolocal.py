#!/usr/bin/python
#
#    Copyright (c) 2004 Colin Stewart (http://www.owlfish.com/)
#    All rights reserved.
#    
#    Redistribution and use in source and binary forms, with or without
#    modification, are permitted provided that the following conditions
#    are met:
#    1. Redistributions of source code must retain the above copyright
#        notice, this list of conditions and the following disclaimer.
#    2. Redistributions in binary form must reproduce the above copyright
#        notice, this list of conditions and the following disclaimer in the
#        documentation and/or other materials provided with the distribution.
#    3. The name of the author may not be used to endorse or promote products
#        derived from this software without specific prior written permission.
#    
#    THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
#    IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
#    OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
#    IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
#    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
#    NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
#    DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
#    THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
#    (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
#    THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
#
#    EXAMPLE SCRIPT - Modify to suit
#
# Script to backup home directories and MySQL databases to a spare hard-drive
#
# Will be run every hour by cron - it will then determine whether a backup has been
# done in the last 24 hours.
#
import RSyncBackup
import logging, logging.handlers

#LOG_FILE="/var/log/cospar2006-local-backup.log"
LOG_FILE="/home/developer/rsync-remotetolocal-scripts/cospar2006tolocal.log"
#LAST_RUN_FILE="/var/state/cospar2006-local-backup.lrf"
LAST_RUN_FILE="/home/developer/rsync-remotetolocal-scripts/cospar2006tolocal.lrf"

# Logging to a file done here
rootLogger = logging.getLogger()
loggingHandler = logging.FileHandler (LOG_FILE)
loggingFormatter = logging.Formatter ('%(asctime)s %(levelname)s %(name)s %(message)s')
loggingHandler.setFormatter (loggingFormatter)
rootLogger.setLevel (logging.DEBUG)
rootLogger.addHandler (loggingHandler)

# Logging to email of any errors
#emailHandler = logging.handlers.SMTPHandler ("localhost", "byllan@newenjoy.com", ["byllan@newenjoy.com"], "Backup error.")
#emailHandler.setFormatter (loggingFormatter)
#emailHandler.setLevel (logging.ERROR)
#rootLogger.addHandler (emailHandler)

# Create a backup object.  Remove testRun once you've debugged it.
backup = RSyncBackup.RSyncBackup (lastRunFile = LAST_RUN_FILE, rsync="/usr/bin/rsync", testRun=0)
try:
	if (backup.timeToBackup()):
		# It's time to perform a backup.
		
		# Exclude the media directory - it's too large to backup.
		# Backup all the home directories to /backup/current/ with archives to /backup/archives/
		#exclude = ['colin/media']
#		backup.backup (source="/var/www/html", destination="/home/developer/backup/cospar2006-website/" )
		backup.backup (source="/home/developer/backup/cospar2006-website/html/",destination="/var/www/html/")
		
		# Backup MySQL with no archives
#		backup.backup (source="/var/lib/mysql", destination="/home/developer/backup/cospar2006-mysql/")
		backup.backup (source="/home/developer/backup/cospar2006-mysql/mysql/", destination="/var/lib/mysql/")

		# Backup apache,php,mysql config files

		# mysql
		# backup.backup (source="/etc/my.cnf", destination="/home/developer/backup/cospar2006-config/")
		backup.backup (source="/home/developer/bakcup/cospar2006-config/my.cnf", destination="/etc/my.cnf")

		# php.ini
		backup.backup (source="/home/developer/bakcup/cospar2006-config/php.ini", destination="/etc/php.ini")
		# backup.backup (source="/etc/php.ini", destination="/home/developer/backup/cospar2006-config/")

		#httpd.conf
		#backup.backup (source="/etc/httpd/conf/httpd.conf", destination="/home/developer/backup/cospar2006-config/")
		backup.backup (source="/home/developer/bakcup/cospar2006-config/httpd.conf", destination="/etc/httpd/conf/httpd.conf")

		# Only keep 5 days worth of evolution archives - it changes too rapidly and is big!
		# This demonstrates the use of the filter regular expression - use with great care!
		# backup.trimArchives ('/backup/cospar2006/archives', filter="evolution$", entriesToKeep=5)
		
		# Only keep 60 backups worth of archives for all files
		# backup.trimArchives ('/backup/cospar2006/archives', entriesToKeep=60)
		
		# Backup finished
		backup.finish()
except Exception, e:
	logging.error ("Exception occured during backup: %s" % str (e))

# Close the logging out.
loggingHandler.close()

