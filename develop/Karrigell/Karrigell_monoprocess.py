import os
import sys
import socket
import cStringIO
import threading

# read command line and load configuration
import config_loader
server_config = config_loader.load()
server_config["server_type"] = "Monoprocess"
server_config["rlock"] = threading.RLock()
#config_loader.init_config("Async", threading.RLock())

import k_config
k_config.init(server_config)

import HTTP

import k_version


DEBUG = False #True

class handler(HTTP.HTTP):
    """For some reason persistent connections don't work with this
    monoprocess server. SimpleHTTPServer in Python standard distribution
    doesn't support them either"""

    def run(self):
        self.handle_request()
        if not self.wfile.closed:
            self.wfile.flush()
        self.wfile.close()
        self.rfile.close()
        self.sock.close()

class Server (object):

    def __init__(self,host,port,request_handler, use_ipv6):
        self.host = host
        self.port = port
        self.sock = socket.socket((socket.AF_INET, socket.AF_INET6)[use_ipv6],
                                  socket.SOCK_STREAM)
        self.sock.bind((host,port))
        self.sock.listen(5)
        self.request_handler = request_handler

    def run(self):
        while True:
            try:
                client_address = self.sock.accept()
                if DEBUG : 
                    print "client_address = ", client_address
                client = self.request_handler(self,client_address)
                client.run()
            except KeyboardInterrupt:
                sys.exit()

    def close(self):
        self.sock.close()
        
    def __del__(self):
        print 'destructor of class Server is called'
        self.sock.close()


if __name__ == '__main__':
    port = k_config.port
    ip_version = ("ipv4", "ipv6")[k_config.use_ipv6]
    if DEBUG : 
        print "port = ", port
    server = Server('',port,handler,k_config.use_ipv6)
    sys.stderr.write("Karrigell %s running on port %s (%s)\n" %(k_version.__version__,port,ip_version))

    try:
        server.run()
    except KeyboardInterrupt():
        server.close()
