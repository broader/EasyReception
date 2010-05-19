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

import k_sessions

karrigell_dir = None
conf_dir = None
persistent_sessions = True
process_num = 3

mono_host = True

config = {}
default_conf = {}

class Config:

    def __init__(self,kw):
        self.modules = {}
        self.update(kw)
        self.load_extensions()

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
        # TODO: Add a lock protection ?
        for module_name in self.global_modules:
            module_obj,m_file_name,m_time = self.global_modules[module_name]
            if not os.stat(m_file_name).st_mtime == m_time:
                module_name,module_obj,m_time = self.load_module(m_file_name)
                self.global_modules[module_name] = module_obj,m_file_name,m_time

    def load_extensions(self):
        self.ext_modules = {}
        extensions_dir = os.path.join(self.karrigell_dir,'package','extensions')
        if os.path.exists(extensions_dir):
            for filename in os.listdir(extensions_dir):
                if os.path.splitext(filename)[1]=='.py' \
                    and not filename.startswith('_'):
                    m_file_name = os.path.join(extensions_dir,filename)
                    module_name,module_obj,m_time = self.load_module(m_file_name)
                    self.ext_modules[module_name] = module_obj

def init(server_config):
    #print "k_config.init()"
    # Init module globals with dictionnary content
    g = globals()
    for k,v in server_config.iteritems() :
        g[k] = v
        
    global config,mono_host
    mono_host = False
    config = {}

    # load default host configuration
    global default_conf
    for option in [
        "server_dir","karrigell_dir","host_conf_dir",
        "cache",
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
    config[None].host_name = "None"

    # hosts definition
    # Precharge configurations (This allows error detection at startup)
    hosts_file = os.path.join(host_conf_dir,"hosts")
    localhost_script = None
    if not os.path.exists(hosts_file):
        out = open(hosts_file,"w")
        # default config file for localhost
        # store relative name in hosts file
        localhost_script = os.path.join('data','www','conf.py')
        out.write("localhost %s\n" %localhost_script)
        # use absolute path for CONFIG.__file__
        localhost_script = os.path.join(server_dir,localhost_script)
        out.close()
    else:
        for line in open(hosts_file):
            host,conf_file = line.strip().split(" ",1)
            if host == "localhost":
                conf_file = os.path.join(server_dir,conf_file)
                localhost_script = conf_file
            set_host_conf(host,conf_file)
        if localhost_script is None:
            localhost_script = os.path.join(server_dir,'data','www','conf.py')
    
    # set config for localhost names
    hostname = socket.gethostname()
    names = ['localhost','127.0.0.1',hostname.lower()]

    for name in socket.gethostbyname_ex(hostname):
        if name:
            if isinstance(name,list):
                names.append(name[0])
            else:
                names.append(name)
    #print "names =", names
    for name in names:
        set_host_conf(name,localhost_script)

def init_apache(options):
    # used by config_loader for Apache modes (CGI or mod_python)
    global config,mono_host
    mono_host = True
    config = {None : Config(options)}
    config[None].__file__ = os.path.join(options['data_dir'],'conf.py')

def get_host_conf(host):
    if mono_host:
        #sys.stderr.write("\n use None host config\n")
        return config[None]
    # set host-specific configuration
    if host is not None and ":" in host:
        host = host[:host.find(":")]
    if host in config:
        config[host].update_modules()
        #sys.stderr.write("\n use %s host config\n" % host)
        return config[host]
    else:
        # use local host conf
        #sys.stderr.write("\n use local host config\n")
        return config['localhost']

def set_host_conf(host,conf_file):
    # set host-specific configuration
    _conf = copy.copy(default_conf) # default values
    # update with values in host config script
    execfile(conf_file,globals(),_conf)
    # initiate config object to default
    config[host] = Config(_conf)
    # set __file__ to host config script (used in admin/config)
    config[host].__file__ = conf_file
    config[host].host_name = host
    config[host].rlock = rlock
    config[host].server_type = server_type
    k_sessions.init_config_session(config[host])
