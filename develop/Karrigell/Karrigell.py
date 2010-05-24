import os
import sys
import threading
import socket

# read command line and load configuration
import config_loader
server_config = config_loader.load()
server_config["server_type"] = "Thread"
server_config["rlock"] = threading.RLock()
#config_loader.init_config("Async", threading.RLock())

import k_config
k_config.init(server_config)

import HTTP

import k_version

class ThreadingServer:
    
    def __init__(self,host,port,request_handler,use_ipv6):
        self.host = host
        self.port = port
        self.sock = socket.socket((socket.AF_INET, socket.AF_INET6)[use_ipv6],socket.SOCK_STREAM)
        self.sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.sock.bind((host,port))
        self.sock.listen(5)
        self.request_handler = request_handler

    def run(self):
        while True:
            try:
                client_address = self.sock.accept()
                while threading.activeCount() > k_config.max_threads:
                    pass
                self.request_handler(self,client_address).start()
            except KeyboardInterrupt:
                sys.exit()

    def close(self):
        self.sock.close()
        for thread in threading.enumerate():
            print thread.sock
        
class handler(HTTP.HTTP,threading.Thread):

    def __init__(self,server,client_address):
        HTTP.HTTP.__init__(self,server,client_address)
        threading.Thread.__init__(self)

# set context : root directory, port
port = k_config.port
ip_version = ("ipv4", "ipv6")[k_config.use_ipv6]

if __name__ == "__main__":
    server = ThreadingServer('',port,handler, k_config.use_ipv6)
    if not k_config.silent:
        sys.stderr.write("Karrigell %s running on port %s (%s)\n" %(k_version.__version__,port,ip_version))
        sys.stderr.write("Press Ctrl+C to stop\n")

    try:
        server.run()
    except KeyboardInterrupt():
        server.close()
