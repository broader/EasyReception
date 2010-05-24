"""Karrigell configuration loader for mod_cgi
"""
import sys
import os

options = {
    'cgi_dir': None, # cgi scripts are managed by Apache
    'persistent_sessions' : True,
    'cache':False,
    'modules' : {"host_filter":[]}
    }

execfile("conf.py",options)

# add core and package to sys.path
for _dir in ["core","package"]:
    path = os.path.join(options['karrigell_dir'],_dir)
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
