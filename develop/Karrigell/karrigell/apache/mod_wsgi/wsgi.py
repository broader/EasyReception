import sys
import datetime
import email

from wsgiref import simple_server,util

import os,sys
this_dir = os.path.dirname(__file__)
if not this_dir in sys.path:
    sys.path.append(this_dir)

import wsgi_config_loader

import HTTP

class WSGIHandlerClass(simple_server.WSGIRequestHandler):
    """Logging is managed by Karrigell"""

    def log_message(self,*args):
        return

class Server:
    """Fake server class for interface compatibility"""

    def __init__(self,host,port):
        self.host = host
        self.port = port

class k_handler(HTTP.HTTP):

    def __init__(self,environ):
        """Build Karrigell-specific attributes from the environ
        prepared by the WSGI server"""
        self.server = Server(environ["SERVER_NAME"],environ["SERVER_PORT"])
        self.server_version = environ["SERVER_SOFTWARE"]

        self.client_address = (environ["REMOTE_ADDR"],0)
        self.rfile = environ['wsgi.input'] # for POST requests

        # headers
        self.headers = email.message_from_string('')
        if 'CONTENT_TYPE' in environ:
            self.headers['Content-type'] = environ['CONTENT_TYPE']
        if 'CONTENT_LENGTH' in environ:
            self.headers['Content-length'] = environ['CONTENT_LENGTH']
        for k in environ:
            if k.startswith("HTTP_"):
                header = k[5:].replace('_','-')
                self.headers[header] = environ[k]

        self.url = environ["PATH_INFO"]
        if environ["QUERY_STRING"]:
            self.url += '?'+environ["QUERY_STRING"]
        self.request_version = environ["SERVER_PROTOCOL"]
        self.protocol = environ["SERVER_PROTOCOL"]
        self.method = environ["REQUEST_METHOD"]

        # initialize log info
        self.info = datetime.datetime.now().strftime("%Y/%m/%d %H:%M:%S - ")
        self.info += "%s - %s %s %s" %(self.client_address[0],
            self.method,self.url,self.protocol)

    def send_status(self,code,msg):
        """Initialize response with status line"""
        self.response = "%s %s" %(code,msg)

    def send_headers(self):
        self.resp_headers["Server"] = self.version_string()
        self.resp_headers["Date"] = self.date_time_string()
        for morsel in self.cookies.values():
            self.resp_headers['Set-Cookie'] = morsel.output(header='').lstrip()

    def send_result(self):
        # managed by start_response
        return

class File:
    """Class to manage file objects as iterators
    Used as the return value of WSGI application, to avoid having to
    store the file content in memory"""

    blocksize = 2 << 17

    def __init__(self,fileobj):
        self.fileobj = fileobj
        self.fileobj.seek(0)

    def __iter__(self):
        return self
        
    def next(self):
        buf = self.fileobj.read(self.blocksize)
        if not buf:
            raise StopIteration
        return buf

def application(environ,start_response):
    handler = k_handler(environ)
    handler.process_request() # processing by Karrigell
    resp_headers = [(k,str(v)) for (k,v) in handler.resp_headers.items() ]
    start_response(handler.response, resp_headers)
    return File(handler.output)

if __name__ == "__main__":
    httpd = simple_server.make_server('', 8000, application,
        handler_class=WSGIHandlerClass)
    sa = httpd.socket.getsockname()
    print "Serving HTTP on", sa[0], "port", sa[1], "..."
    httpd.serve_forever()
