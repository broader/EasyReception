"""Karrigell configuration loader for mod_wsgi
"""
import sys
import os

server_dir = os.path.dirname(os.path.dirname(__file__)) # folder "apache"
karrigell_dir = os.path.dirname(server_dir) # folder "karrigell"
root_dir = os.path.dirname(karrigell_dir)

options = {
    'server_dir':server_dir,
    'karrigell_dir' : karrigell_dir,
    'root_dir' : root_dir,
    'data_dir' : os.path.join(server_dir,"data"),
    'cache_dir' : os.path.join(server_dir,"data","cache"),
    'cgi_dir': None, # cgi scripts are managed by Apache
    'persistent_sessions' : True,
    'cache':False,
    'modules' : {"host_filter":[]}
    }

execfile(os.path.join(options['data_dir'],"conf.py"),options)

# add core and package to sys.path
for _dir in ["core","package"]:
    path = os.path.join(karrigell_dir,_dir)
    if not path in sys.path:
        sys.path.append(path)

# set options in k_config
import k_config
k_config.init_apache(options)
k_config.modules = options['modules']


config = k_config.config[None]
config.server_type = "Multiprocess"
# dummy locking

class dummy_lock:

    def acquire(self):
        pass

    def release(self):
        pass

config.rlock = dummy_lock()
import k_sessions
k_sessions.init_config_session(config)
