import os
import sys
import socket
import cStringIO

# read command line and load configuration
import config_loader

import k_config
import HTTP

DEBUG = False #True

class Server (object):

    def __init__(self,host,port,request_handler):
        self.host = host
        self.port = port
        self.sock = socket.socket(socket.AF_INET,socket.SOCK_STREAM)
        self.sock.bind((host,port))
        self.sock.listen(5)
        self.request_handler = request_handler

    def run(self):
        while True:
            client_address = self.sock.accept()
            if DEBUG : 
                print "client_address = ", client_address
            client = self.request_handler(self,client_address)
            # no persistent connection support
            client.handle_request()
            client.sock.close()

    def close(self):
        self.sock.close()
        
    def __del__(self):
        print 'destructor of class Server is called'
        self.sock.close()


if __name__ == '__main__':
    port = k_config.port
    if DEBUG : 
        print "port = ", port
    server = Server('',port,HTTP.HTTP)
    sys.stderr.write("Karrigell %s running on port %s\n" %(HTTP.__version__,port))

    try:
        server.run()
    except KeyboardInterrupt():
        server.close()
