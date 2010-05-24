import os
import sys
import email
import datetime

from mod_python import apache,Cookie

import config_loader

import HTTP

class Server:

    def __init__(self,server):
        self.host = server.server_hostname
        self.port = server.port

class mp_handler(HTTP.HTTP):

    def __init__(self,request):
        self.request = request
        self.client_address = request.connection.remote_addr
        #self.sock = sock
        self.rfile = request
        self.wfile = request
        self.keep_alive = True
        self.server = Server(request.server)

    def read_request(self):
        # parse request line
        self.request_line = self.request.the_request
        self.method = self.request.method
        self.url = self.request.unparsed_uri
        self.protocol = self.request.protocol
        # initialize log info
        info = datetime.datetime.now().strftime("%Y/%m/%d %H:%M:%S - ")
        info += str(self.client_address[0]) + (" - ")
        info += self.request_line.strip()
        self.info = info
        # request headers
        self.headers = email.message_from_string("")
        for (k,v) in self.request.headers_in.items():
            self.headers[k] = v

        self.post_data_source = self.rfile

    def send_result(self):
        """send result"""
        
        for (k,v) in self.resp_headers.items():
            self.request.headers_out[k] = str(self.resp_headers[k])
        self.request.headers_out["Date"] = self.date_time_string()
        for morsel in self.cookies.values():
            cookie = Cookie.Cookie(morsel.key,morsel.value)
            cookie.path = morsel["path"]
            Cookie.add_cookie(self.request,cookie)
        self.request.content_type = self.resp_headers["Content-type"] \
            or "text/html"
        self.output.seek(0)
        sent = 0
        while True:
            buff = self.output.read(HTTP.buf_size)
            if not buff:
                break
            try:
                self.wfile.write(buff)
                sent += len(buff)
            except socket.error:
                self.sock.close()
                return

    def send_status(self,code,msg):
        """Initialize response with status line"""
        self.response = ""
        self.code = code

def handler(req):
    k_handler = mp_handler(req)
    k_handler.read_request()
    k_handler.process_request()
    req.status = k_handler.code
    return apache.OK
