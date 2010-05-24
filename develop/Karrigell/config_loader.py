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
    print "\n\tConfigurationDirectory = the directory where the server" \
        "configuration script is located."

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
# put them before standard distribution to make sure we have the
# updated version of PyDbLite, HTMLTags etc.
for _dir in ["core","package"]:
    path = os.path.join(karrigell_dir,_dir)
    if not path in sys.path:
        sys.path.insert(1,path)

def load():
    """
    Returns a dictionnary usable for k_config.py globals intialisation.
    """
    sc = {}
    execfile(os.path.join(server_conf_dir,"server_config.py"), globals(), sc)
    server_config={"server_dir":server_dir, "_args":_args}
    for option in ["karrigell_dir","host_conf_dir",
                   "cache",
                   "persistent_sessions",
                   "use_ipv6",
                   "max_threads","process_num",
                   "process_num_ipv6",
                   "port","silent",
                   "modules"]:
        try :
            server_config[option] = sc[option]
        except KeyError :
            raise KeyError, 'You must set "%s" option in server_config file' % option
    return server_config
    