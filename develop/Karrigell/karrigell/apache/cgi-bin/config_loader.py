"""Karrigell configuration loader for mod_cgi
"""
import sys
import os


options = {
    'cgi_dir': None, # cgi scripts are managed by Apache
    'persistent_sessions' : True,
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