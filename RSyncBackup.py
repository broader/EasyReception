""" RSyncBackup - Wrapper to perform backup management using rsync.
	--------------------------------------------------------------------
	Copyright (c) 2004 Colin Stewart (http://www.owlfish.com/)
	All rights reserved.
	
	Redistribution and use in source and binary forms, with or without
	modification, are permitted provided that the following conditions
	are met:
	1. Redistributions of source code must retain the above copyright
	   notice, this list of conditions and the following disclaimer.
	2. Redistributions in binary form must reproduce the above copyright
	   notice, this list of conditions and the following disclaimer in the
	   documentation and/or other materials provided with the distribution.
	3. The name of the author may not be used to endorse or promote products
	   derived from this software without specific prior written permission.
	
	THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
	IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
	OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
	IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
	INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
	NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
	DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
	THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
	(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
	THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

	The RSyncBackup class in this module can be used to perform automated 
	backups using the rsync program.  Be very careful how you use this code!
	It DOES delete files!
	
"""

__version__ = "1.3"

import time, commands, re
import logging
import os, os.path

class RSyncBackup:
	""" RSyncBackup is used to automate the control of the rsync utility to perform backups.
		It also has a few other features, including:
			- Record when the last backup was taken, and whether it's time to run another one
			- Delete archives once a specified number exist
	"""
	def __init__ (self, lastRunFile="/var/state/backupLastRun.lrf", rsync="/usr/bin/rsync", testRun=0):
		""" Creates an object that can perform backups using Rsync.
			lastRunFile - A file to record when the backup was last performed.
			rsync 		- Specify the location of the rsync binary
			testRun 	- Set to 1 to log out what will be done, rather than doing it.
		"""
		self.log = logging.getLogger ("RSyncBackup")
		self.lastRunFile = lastRunFile
		self.rsync = rsync
		self.testRun = testRun
		if (testRun):
			self.log.info ("TestRun detected - no file operations will be performed.")
		self.backupStarted = time.gmtime()
		
	def timeToBackup (self, backupInterval=8*60):
		""" Parse the lastRunFile and determine whether the interval specified has
			ellapsed.
			
			backupInterval - Time interval in minutes between backups
		"""
		try:
			lrf = open (self.lastRunFile, 'r')
			oldTime = lrf.read()
			lrf.close()
		except Exception, e:
			self.log.warn ("Exception occured reading the last run file %s.  Error: %s" % (self.lastRunFile, str (e)))
			self.backupStarted = time.gmtime()
			return 1
		try:
			lastTime = time.mktime (time.strptime (oldTime))
			nowTime = time.mktime (time.gmtime())
			self.log.debug ("lastTime: %s nowTime: %s" % (str (lastTime), str (nowTime)))
			if (lastTime + backupInterval * 60 < nowTime+ 8*60*60):
				self.log.info ("Time to perform backup.")
				self.backupStarted = time.gmtime()
				return 1
			else:
				self.log.info ("Not yet time to backup.")
				return 0
		except Exception, e:
			self.log.warn ("Exception occured parsing last run file %s.  Error: %s" % (self.lastRunFile, str (e)))
			self.backupStarted = time.gmtime()
			return 1
		
	def backup (self, source, destination, archive = None, excludeList = None):
		""" Perform a backup using rsync.
		
			source 		- The source directory who's contents should be backed up.
			destination - The directory that the backup should go into
			archive 	- (Optional) The directory that previous versions of the files should
						  be copied to.
			excludeList - (Optional) A list of paths that should be excluded from the backup.
			
			Returns true if successful, false if an error occurs.
		"""
		if (self.testRun):
			self.log.info ("Starting test run of backup.")
		else:
			self.log.info ("Starting backup.")
		dateTime = time.strftime ("%d%m%Y-%H%M%S")
		if (archive is not None):
			self.log.debug ("Determining archive directory.")
			thisArchive = os.path.join (archive, dateTime[4:8], dateTime[2:4], dateTime)
			self.log.debug ("Archive destination is: %s" % thisArchive)
		else:
			thisArchive = None
		
		cmnd = "%s --archive" % self.rsync
		if (thisArchive is not None):
			cmnd = "%s --backup --backup-dir=%s" % (cmnd, thisArchive)
		cmnd = "%s --delete" % cmnd
		if (excludeList is not None):
			for exclude in excludeList:
				cmnd = '%s --exclude="%s"' % (cmnd, exclude)
		cmnd = "%s '%s' '%s'" % (cmnd, source, destination)
		self.log.debug ("Running command: %s" % cmnd)
		if (self.testRun):
			self.log.warn ("TestRun - would execute command: " + cmnd)
		else:
			result = commands.getstatusoutput (cmnd)
			if (result[0]  != 0):
				self.log.error ("Error running rsync: %s" % result[1])	
				return 0
			else:
				self.log.info ("Rsync backup successful.")
				self.log.debug ("Rsync output: %s" % result[1])
		return 1
		
	def trimArchives (self, archiveDir, filter=None, entriesToKeep=10, removeParentIfEmpty=1):
		""" Delete old archives - WARNING: This deletes files, be careful with it!
		
			archiveDir			- The directory containing the archives
			filter	 			- (Optional) Regular expression used to determine which parts of an 
								  archive should be deleted.  Use with caution!
			entriesToKeep		- (Optional) The number of entries in the archive to leave, 
								  defaults to 10
			removeParentIfEmpty	- (Optional) By default if an archive directory is empty it
								  will be removed, set to 0 to disable.
		"""
		if (filter is None):
			# Default to triming the total number of archives.
			# Filter on archiveDir/yyyy/dd/ddmmyyyy-hhmmss
			filterStr = os.path.join (re.escape (archiveDir), '[0-9]{4,4}', '[0-9]{2,2}', '[0-9]{8,8}-[0-9]{6,6}$')
			self.log.debug ("Using trim filter of: %s" % filterStr)
			nameFilter = re.compile (filterStr)
		else:
			nameFilter = re.compile (filter)
		walker = pathWalker (nameFilter)
		matchingPaths = walker.walk(archiveDir)
		# Sort the paths so that the oldest archives are first
		matchingPaths.sort()
		# Trim the paths down to just the ones we care about
		pathsToTrim = matchingPaths [0:-1 * entriesToKeep]
		pathKiller = pathRemover ()
		for pathToRemove in pathsToTrim:
			if (self.testRun):
				self.log.warn ("TestRun - would remove path: " + pathToRemove)
			else:
				if (os.path.isdir (pathToRemove)):
					self.log.info ("Recursively deleting all files in %s" % pathToRemove)
					pathKiller.walk (pathToRemove)
					self.log.info ("Removing directory %s" % pathToRemove)
					os.rmdir (pathToRemove)
				else:
					self.log.error ("Removing file %s" % pathToRemove)
					os.remove (pathToRemove)
			if (removeParentIfEmpty):
				self.log.debug ("Checking to see whether parent directories are empty")
				lastParent = pathToRemove
				looking = 1
				while (looking):
					parent = os.path.split (lastParent)[0]
					if (lastParent == parent):
						self.log.info ("Reach top of hierachy when looking for parents to delete.")
						looking = 0
					else:
						if (len (os.listdir (parent)) == 0):
							if (self.testRun):
								self.log.warn ("TestRun - would remove path: " + parent)
							else:
								self.log.info ("Found that parent directory %s is empty - deleting." % parent)
								os.rmdir (parent)
							# We are going to carry on looking, so note this as the last parent
							lastParent = parent
						else:
							self.log.debug ("Parent directory is not empty - preserving.")
							looking = 0
					
	def finish (self):
		""" Write out the time the backup started to the last run file (if one used). """
		if (self.testRun):
			self.log.debug ("TestRun - not writing out last run file.")
			return
		if (self.lastRunFile is None):
			self.log.debug ("Last Run File not given, skipping writing.")
			return
		try:
			self.log.debug ("Time backup was started: %s" % time.asctime (self.backupStarted))
			lrf = open (self.lastRunFile, 'w')
			lrf.write (time.asctime (self.backupStarted))
			lrf.close()
			self.log.info ("Last Run File updated succesfully")
		except Exception, e:
			self.log.error ("Exception occured writing the last run file %s.  Error: %s" % (self.lastRunFile, str (e)))
			raise Exception ("Error writing to last run file!")
			
class pathWalker:
	def __init__ (self, regex):
		self.regex = regex
		self.foundPaths = []
		
	def walk (self, path):
		os.path.walk (path, self.walking, None)
		return self.foundPaths
		
	def walking (self, arg, dirname, names):
		for name in names:
			if (self.regex.search (os.path.join (dirname, name))):
				self.foundPaths.append (os.path.join (dirname, name))

class pathRemover:
	def __init__ (self):
		self.dirsToRemove = []
		self.log = logging.getLogger ("RSyncBackup.pathRemover")
		
	def walk (self, path):
		os.path.walk (path, self.walking, None)
		# Now remove all of the directories we saw, starting with the last one
		self.dirsToRemove.reverse()
		for dir in self.dirsToRemove:
			os.rmdir (dir)
		self.dirsToRemove = []
		
	def walking (self, arg, dirname, names):
		for name in names:
			#self.log.debug ("Would delete file: %s" % os.path.join (dirname, name))
			target = os.path.join (dirname, name)
			if (os.path.isdir (target)):
				self.dirsToRemove.append (target)
			else:
				os.remove (target)
