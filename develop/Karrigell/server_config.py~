import os

# server port
port = 80

# directory with the core and package folders
karrigell_dir = os.path.join(server_dir,"karrigell")
# directory with the host-specific configuration files
host_conf_dir = server_dir

# indicates if session data should be stored on disk (True)
# or in memory (False)
persistent_sessions = True

# use HTTP cache ?
cache = True


# Async server : 
#    use_ipv6 = False -> ipv4 is used
#    use_ipv6 = True  -> ipv6 is used
# Thread server :
#    use_ipv6 = False -> ipv4 is used
#    use_ipv6 = True  -> ipv6 is used
# MultiProcess server :
#    use_ipv6 = False -> process_num processes use ipv4
#    use_ipv6 = True  -> process_num processes use ipv4 and process_num_ipv6 use ipv6
use_ipv6 = False

# maximum number of threads (for multi threaded server only)
max_threads = 150

# number of processes to launch (for multi process server only)
process_num = 10
process_num_ipv6 = 2


# silent mode : if True, no log is printed in the console
silent = False

# modules
modules = {"host_filter":["host_filter"]}
