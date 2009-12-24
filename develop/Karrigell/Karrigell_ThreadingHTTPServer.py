import os
import sys
import threading
import socket

# read command line and load configuration
import config_loader

import k_config
import HTTP

class ThreadingServer:
    
    def __init__(self,host,port,request_handler):
        self.host = host
        self.port = port
        self.sock = socket.socket(socket.AF_INET,socket.SOCK_STREAM)
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
                break

    def close(self):
        self.sock.close()
        
class handler(HTTP.HTTP,threading.Thread):

    def __init__(self,server,client_address):
        HTTP.HTTP.__init__(self,server,client_address)
        threading.Thread.__init__(self)

# set context : root directory, port
port = k_config.port

if __name__ == "__main__":
    server = ThreadingServer('',port,handler)
    if not k_config.silent:
        sys.stderr.write("Karrigell %s running on port %s\n" %(HTTP.__version__,port))
        sys.stderr.write("Press Ctrl+C to stop\n")

    try:
        server.run()
    except KeyboardInterrupt():
        server.close()
