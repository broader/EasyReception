"""Karrigell configuration loader
This script doesn't define any configuration option

It determines the directory for the server configuration script : either supplied
in the command line, or the same directory as this script's

It then loads the server configuration script, adds folders "core" and "package"
to sys.path, then sets values in k_config.py
"""
import sys
import os
import getopt

def usage():
    print "Usage : python Karrigell.py [-h] ConfigurationDirectory"
    print "\n\th = help (shows this message)"
    print "\n\tConfigurationDirectory = the directory where the server configuration script is located."

# get command-line options
try:
    _opts, _args = getopt.getopt(sys.argv[1:], "h",["processing-fork="])
except getopt.GetoptError:
    # print usage information and exit:
    usage()
    raise

# command-line options
for o, a in _opts:
    if o in ("-h"):
        usage()
        sys.exit()

server_dir = os.getcwd()

# if an argument is given at the end of the command line, it is
# the path to the server configuration file
if _args:
    server_conf_dir = _args[0]
else:
    server_conf_dir = os.getcwd()

# load server configuration
# adds names in server_config to namespace
execfile(os.path.join(server_conf_dir,"server_config.py"))

# add core and package to sys.path
for _dir in ["core","package"]:
    path = os.path.join(karrigell_dir,_dir)
    if not path in sys.path:
        sys.path.append(path)

# set server options in k_config
import k_config
for option in ["server_dir","karrigell_dir","host_conf_dir",
               "persistent_sessions",
               "max_threads","process_num",
               "port","silent",
               "modules"]:
    setattr(k_config,option,globals()[option])
k_config.init()
