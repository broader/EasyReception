import os

# directory with the core and package folders
karrigell_dir = os.path.join(server_dir,"karrigell")
# directory with the host-specific configuration files
host_conf_dir = server_dir

# indicates if session data should be stored on disk (True)
# or in memory (False)
#persistent_sessions = True
persistent_sessions = False

# server port
port = 8080

# maximum number of threads (for multi threaded server only)
max_threads = 150

# number of processes to launch (for multi process server only)
process_num = 10

# silent mode : if True, no log is printed in the console
silent = False

# modules
modules = {"host_filter":["host_filter"]}
