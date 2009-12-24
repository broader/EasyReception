# Configuration is split into two parts
# - server configuration
# - host configuration

import os
import sys
import imp
import copy
import socket

import k_users_db
from k_exceptions import *

karrigell_dir = None
conf_dir = None
persistent_sessions = True
process_num = 3

mono_host = True

config = {}
default_conf = {}

# test if sqlite is installed or raise exception
sqlite = None
try:
    from sqlite3 import dbapi2 as sqlite
except ImportError:
    try:
        from pysqlite2 import dbapi2 as sqlite
    except ImportError:
        pass

class Config:

    def __init__(self,kw):
        self.modules = {}
        self.update(kw)

    def update(self,kw):
        for key,value in kw.iteritems():
            if key == "global_modules":
                self.global_modules = {}
                for m_file_name in kw["global_modules"]:
                    module_name,module_obj,m_time = self.load_module(m_file_name)
                    self.global_modules[module_name] = module_obj,m_file_name,m_time
            else:
                setattr(self,key,value)

    def load_module(self,m_file_name):
        module_name = os.path.splitext(os.path.basename(m_file_name))[0]
        path = os.path.dirname(m_file_name)
        _file, pathname, descr = imp.find_module(module_name,[path])
        return (module_name,
            imp.load_module(module_name,_file,pathname,descr),
            os.stat(pathname).st_mtime)

    def update_modules(self):
        """Check if module source changed before last loading,
        update if necessary"""
        for module_name in self.global_modules:
            module_obj,m_file_name,m_time = self.global_modules[module_name]
            if not os.stat(m_file_name).st_mtime == m_time:
                module_name,module_obj,m_time = self.load_module(m_file_name)
                self.global_modules[module_name] = module_obj,m_file_name,m_time
                
            # add by ZG
            #module_name,module_obj,m_time = self.load_module(m_file_name)
            #self.global_modules[module_name] = module_obj,m_file_name,m_time

def init():

    global config,mono_host
    mono_host = False
    config = {}
    # hosts definition
    # adds dictionary conf in namespace
    hosts_file = os.path.join(host_conf_dir,"hosts")
    if not os.path.exists(hosts_file):
        hf = open(hosts_file,"w")
        cf = os.path.join(server_dir,'data','www','conf.py')
        hostname = socket.gethostname()

        names = ['localhost','127.0.0.1',hostname.lower()]

        for name in socket.gethostbyname_ex(hostname):
            if name:
                if type(name) is type([]):
                    names.append(name[0])
                else:
                    names.append(name)

        for name in names:
            hf.write("%s %s\n" %(name,cf))
        hf.close()

    # load default host configuration
    global default_conf
    for option in ["sqlite",
        "server_dir","karrigell_dir","host_conf_dir",
        "persistent_sessions",
        "max_threads","process_num",
        "port","silent"]:
        default_conf[option] = globals()[option]

    default_file = os.path.join(server_dir,"default_host_conf.py")
    execfile(default_file,globals(),default_conf)
    default_conf.update(
        {"root_dir":os.path.join(server_dir,"www"),
        "data_dir" : os.path.join(server_dir,"data","www"),
        })
    config[None] = Config(default_conf)
    config[None].__file__ = default_file
    # Precharge configurations (This allows error detection at startup)
    for line in open(hosts_file):
        host,conf_file = line.strip().split(" ",1)
        set_host_conf(host,conf_file)

def init_apache(options):

    global config,mono_host
    mono_host = True
    options['sqlite'] = sqlite
    config = {None : Config(options)}

def get_host_conf(host):
    if mono_host:
        return config[None]
    # set host-specific configuration
    if ":" in host:
        host = host[:host.find(":")]
    config[host].update_modules()
    return config[host]

def set_host_conf(host,conf_file):
    # set host-specific configuration
    _conf = copy.copy(default_conf) # default values
    # update with values in host config script
    execfile(conf_file,globals(),_conf)
    # initiate config object to default
    config[host] = Config(_conf)
    # set __file__ to host config script (used in admin/config)
    config[host].__file__ = conf_file
    # test if admin is set for this host
    #if host != None :
    #    if not k_users_db.has_admin(config[host]) :
    #        print host, "doesn't have admin set. Please set admin login/password."
