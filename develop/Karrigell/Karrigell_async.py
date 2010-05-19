import os
import sys
import threading

# read command line and load configuration
import config_loader
server_config = config_loader.load()
server_config["server_type"] = "Async"
server_config["rlock"] = threading.RLock()
#config_loader.init_config("Async", threading.RLock())

import k_config
k_config.init(server_config)

from Async_core import *

import k_version

# set context : root directory, port
port = k_config.port
ip_version = ("ipv4", "ipv6")[k_config.use_ipv6]

if __name__ == "__main__":
    server = Server(('',port),handler, k_config.use_ipv6)
    sys.stderr.write("HTTP %s asynchronous server running on port %s (%s)\n" 
        %(k_version.__version__,port,ip_version))

    try:
        server.run()
    except KeyboardInterrupt:
        server.close()
        sys.stderr.write("Ctrl+C pressed. Shutting down.\n")