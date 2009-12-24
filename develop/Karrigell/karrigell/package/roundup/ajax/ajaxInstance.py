#
# Copyright (c) 2001 Bizar Software Pty Ltd (http://www.bizarsoftware.com.au/)
# This module is free software, and you may redistribute it and/or modify
# under the same terms as Python, so long as this copyright message and
# disclaimer are retained in their original form.
#
# IN NO EVENT SHALL BIZAR SOFTWARE PTY LTD BE LIABLE TO ANY PARTY FOR
# DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING
# OUT OF THE USE OF THIS CODE, EVEN IF THE AUTHOR HAS BEEN ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#
# BIZAR SOFTWARE PTY LTD SPECIFICALLY DISCLAIMS ANY WARRANTIES, INCLUDING,
# BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
# FOR A PARTICULAR PURPOSE.  THE CODE PROVIDED HEREUNDER IS ON AN "AS IS"
# BASIS, AND THERE IS NO OBLIGATION WHATSOEVER TO PROVIDE MAINTENANCE,
# SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
#
# $Id$

''' Tracker handling (open tracker).

A tracker is a instance of a roundup 

'''
__docformat__ = 'restructuredtext'

import os
import sys
from roundup import configuration, mailgw
from roundup import hyperdb, backends
#from roundup.cgi import client, templating
# New for initialise the security of GUI Client
import ajaxClient

class Vars:
    def __init__(self, vars):
        self.__dict__.update(vars)

class Tracker:
    def __init__(self, tracker_home, optimize=0):
        """New-style tracker instance constructor

        Parameters:
            tracker_home:
                tracker home directory
            optimize:
                if set, precompile html templates

        """
        self.tracker_home = tracker_home
        self.optimize = optimize
        self.config = configuration.CoreConfig(tracker_home)
        self.ajax_actions = {}        
        self.load_interfaces()        
        self.backend = backends.get_backend(self.get_backend_name())
        if self.optimize:
            #libdir = os.path.join(self.tracker_home, 'lib')
            #if os.path.isdir(libdir):
            #    sys.path.insert(1, libdir)
            #self.templates.precompileTemplates()
            
            # initialize tracker extensions
            for extension in self.get_extensions('extensions'):
                extension(self)
            # load database schema
            schemafilename = os.path.join(self.tracker_home, 'schema.py')
            # Note: can't use built-in open()
            #   because of the global function with the same name
            schemafile = file(schemafilename, 'rt')
            self.schema = compile(schemafile.read(), schemafilename, 'exec')
            schemafile.close()
            # load database detectors
            self.detectors = self.get_extensions('detectors')
            # db_open is set to True after first open()
            self.db_open = 0
            
            #if libdir in sys.path:
            #    sys.path.remove(libdir)

    def get_backend_name(self):
        o = __builtins__['open']
        f = o(os.path.join(self.tracker_home, 'db', 'backend_name'))
        name = f.readline().strip()
        f.close()
        return name

    def open(self, name=None):
        # load the database schema
        # we cannot skip this part even if self.optimize is set
        # because the schema has security settings that must be
        # applied to each database instance
        backend = self.backend
        vars = {
            'Class': backend.Class,
            'FileClass': backend.FileClass,
            'IssueClass': backend.IssueClass,
            'String': hyperdb.String,
            'Password': hyperdb.Password,
            'Date': hyperdb.Date,
            'Link': hyperdb.Link,
            'Multilink': hyperdb.Multilink,
            'Interval': hyperdb.Interval,
            'Boolean': hyperdb.Boolean,
            'Number': hyperdb.Number,
            'db': backend.Database(self.config, name)
        }
        
        
        # New from roundup.instance, we have to initialise the security of ajaxClient
        # here to avoid hack the roundup.backends.rdbms_common.Database.__init__.
        # At the end of roundup.backends.rdbms_common.Database.__init__(), 
        # the security of Both the Web client and the MianGW client has been
        # initialized.
        ajaxClient.initialiseSecurity(vars['db'].security)       
        
        if self.optimize:
            # execute preloaded schema object
            exec(self.schema, vars)
            # use preloaded detectors
            detectors = self.detectors
        else:
            #libdir = os.path.join(self.tracker_home, 'lib')
            #if os.path.isdir(libdir):
            #    sys.path.insert(1, libdir)
            
            # execute the schema file
            self._load_python('schema.py', vars)
            # reload extensions and detectors
            for extension in self.get_extensions('extensions'):
                extension(self)
            detectors = self.get_extensions('detectors')
            
            #if libdir in sys.path:
            #    sys.path.remove(libdir)
            
        db = vars['db']
        # apply the detectors
        for detector in detectors:
            detector(db)
        # if we are running in debug mode
        # or this is the first time the database is opened,
        # do database upgrade checks
        if not (self.optimize and self.db_open):
            db.post_init()
            self.db_open = 1
        return db

    def load_interfaces(self):
        """load interfaces.py (if any), initialize Client and MailGW attrs"""
        vars = {}
        #if os.path.isfile(os.path.join(self.tracker_home, 'interfaces.py')):
        #    self._load_python('interfaces.py', vars)
        self.ajaxClient = vars.get('ajaxClient', ajaxClient.Client)
        self.MailGW = vars.get('MailGW', mailgw.MailGW)

    def get_extensions(self, dirname):
        """Load python extensions

        Parameters:
            dirname:
                extension directory name relative to tracker home

        Return value:
            list of init() functions for each extension

        """
        extensions = []
        dirpath = os.path.join(self.tracker_home, dirname)
        if os.path.isdir(dirpath):
            sys.path.insert(1, dirpath)
            for name in os.listdir(dirpath):
                if not name.endswith('.py'):
                    continue
                vars = {}
                self._load_python(os.path.join(dirname, name), vars)
                extensions.append(vars['init'])
            sys.path.remove(dirpath)
        return extensions

    def init(self, adminpw):
        ''' The method to initialize tracker's priority and status values 
        and create the corresponding fields in database. That means this 
        method maybe only used in creating the tracker database.
        '''
        db = self.open('admin')
        self._load_python('initial_data.py', {'db': db, 'adminpw': adminpw,
            'admin_email': self.config['ADMIN_EMAIL']})
        db.commit()
        db.close()

    def exists(self):
        return self.backend.db_exists(self.config)

    def nuke(self):
        self.backend.db_nuke(self.config)

    def _load_python(self, file, vars):
        file = os.path.join(self.tracker_home, file)
        execfile(file, vars)
        return vars

    def registerAction(self, name, action):
        self.ajax_actions[name] = action

class TrackerError(Exception):
    pass

def open(tracker_home, optimize=0):
    return Tracker(tracker_home, optimize=optimize)

# vim: set filetype=python sts=4 sw=4 et si :
