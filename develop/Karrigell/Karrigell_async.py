import os
import sys
import socket
import select
import cStringIO
import tempfile

# read command line and load configuration
import config_loader

import k_config
import HTTP

sockets = {}
buf_size = 2<<16

class CloseRequest(Exception):
    pass

def _log(*data):
    sys.stderr.write("\n".join([str(d) for d in data])+"\n")

class handler(HTTP.HTTP):

    def __init__(self,server,client_address):
        HTTP.HTTP.__init__(self,server,client_address)
        # buffer for incoming data (HTTP request + post data)
        self.incoming = cStringIO.StringIO()
        self.writable = False # set to True when processing is done
        self.request_complete = False

    def handle_read(self):
        if not self.request_complete:
            self.read_request()
        elif self.method=="POST":
            if self.read<self.clength:
                post_data = self.sock.recv(buf_size)
                self.post_data.write(post_data)
                self.read += len(post_data)
                if self.read >= self.clength:
                    self.post_data.seek(0)
                    self.rfile = self.post_data
                    self.process_request()
    
    def read_request(self):
        _read = 0
        while _read<1024:
            car = self.sock.recv(1)
            _read += 1
            if not car:
                raise CloseRequest
            self.incoming.write(car)
            if self.incoming.getvalue().endswith("\r\n\r\n"):
                self.request_line,self.header_text = \
                    self.incoming.getvalue().split("\r\n",1)
                self.parse_request()
                if self.method == "POST":
                    self.post_data = tempfile.TemporaryFile()
                    self.read = 0
                    self.clength = int(self.headers["content-length"])
                else:
                    self.process_request()
                self.request_complete = True
                break
        
    def send_result(self):
        self.output.seek(0) # ready to read output
        self.writable = True # server ready to send the response

    def handle_write(self):
        """Send data to the client"""
        if self.response:
            # status line and response headers
            try:
                sent = self.sock.send(self.response)
                self.response = self.response[sent:]
            except socket.error:
                raise CloseRequest
        if not self.response:
            try:
                data = self.output.read(buf_size)
                self.sock.sendall(data)
                if len(data)<buf_size:
                    if not self.keep_alive:
                        raise CloseRequest
                    else:
                        # keep connection alive, reset values for new request
                        self.incoming = cStringIO.StringIO()
                        self.writable = False
                        self.request_complete = False
                        self.reading_post_data = False
            except socket.error:
                raise CloseRequest

class Server:

    def __init__(self,address,request_handler):
        # address = a tuple (hostname,post)
        self.host,self.port = address
        self.sock = socket.socket(socket.AF_INET,socket.SOCK_STREAM)
        # for 'Address already in use' 
        self.sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1) 
        self.sock.setblocking(0)
        self.sock.bind(address)
        self.sock.listen(5)
        self.request_handler = request_handler

    def accept_new_client(self):
        try:
            client_address = self.sock.accept()
            sock,port = client_address
            sock.setblocking(0)
        except socket.error:
            return
        sockets[sock] = self.request_handler(self,client_address)

    def run(self):
        while True:
            r = [self.sock] + sockets.keys()
            w = [ handler.sock for handler in sockets.itervalues()
                if handler.writable ]
            r,w,e = select.select(r,w,[],2)
            for sock in r:
                if sock is self.sock:
                    self.accept_new_client()
                else:
                    try:
                        sockets[sock].handle_read()
                    except socket.error:
                        del sockets[sock]
                    except CloseRequest:
                        del sockets[sock]
                        sock.close()
            for sock in w: 
                try: 
                  if sock in sockets: 
                    sockets[sock].handle_write() 
                except CloseRequest: 
                  del sockets[sock] 
                  try: 
                    sock.shutdown (socket.SHUT_RDWR) 
                    sock.close() 
                  except: 
                    sys.stderr.write("Karrigell asynchronous server: "
                        "Error closing socket.\n") 

    def close(self):
        self.sock.close()

# set context : root directory, port
port = k_config.port

if __name__ == "__main__":
    server = Server(('',port),handler)
    sys.stderr.write("HTTP %s asynchronous server running on port %s\n" 
        %(HTTP.__version__,port))

    try:
        server.run()
    except KeyboardInterrupt:
        server.close()
        sys.stderr.write("Ctrl+C pressed. Shutting down.\n")