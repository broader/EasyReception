#!python

import os
import sys
import CGIHTTPServer
import cgi
import email
import cStringIO
import datetime

class Server:
    pass

try:

    # read command line and load configuraion
    import config_loader
    
    import HTTP
    import k_config

    class RequestHandler(HTTP.HTTP,
        CGIHTTPServer.CGIHTTPRequestHandler):

        def __init__(self, request, client_address):
            env = os.environ
            self.server = Server()
            self.server.host = os.environ["SERVER_NAME"]
            self.server.port = os.environ["SERVER_PORT"]
            self.server_version = os.environ["SERVER_SOFTWARE"]
            self.sys_version = sys.version
            self.request, self.client_address = request, client_address
            self.sock = request
            self.wfile = sys.stdout
            self.rfile = sys.stdin

            # headers
            self.header_lines = []
            for k in os.environ:
                if k.startswith("HTTP_"):
                    header = k[5:].replace('_','-')
                    self.header_lines.append("%s: %s" %(header,os.environ[k]))
            self.header_text = "\r\n".join(self.header_lines)
            self.headers = email.message_from_string(self.header_text)

            self.url = os.environ["REQUEST_URI"]
            self.request_version = env["SERVER_PROTOCOL"]
            self.protocol = env["SERVER_PROTOCOL"]
            self.method = env["REQUEST_METHOD"]
            self.request_line = "%s %s %s" %(env["REQUEST_METHOD"],
                env["REQUEST_URI"],env["SERVER_PROTOCOL"])

            # initialize log info
            info = datetime.datetime.now().strftime("%Y/%m/%d %H:%M:%S - ")
            info += str(self.client_address[0]) + (" - ")
            info += self.request_line.strip()
            self.info = info

        def send_status(self, code, message=None):
            """Don't send response code : Apache sends 200 Ok, 
            except if a Status header is sent
            """
            self.response = ""
            if code==304:
                self.send_header('Status','304 Not modified')
            elif code==302:
                self.send_header('Status','302 Found')
            elif code==401:
                self.send_header('Status','401 Unauthorized')
            elif code==403:
                self.send_header('Status','403 Forbidden')

    request = sys.stdin
    client_address = (os.environ["REMOTE_ADDR"],int(os.environ["REMOTE_PORT"]))
    handler = RequestHandler(request,client_address)

    # on windows all \n are converted to \r\n if stdout is a terminal 
    # and is not set to binary mode
    # this will then cause an incorrect Content-length.
    if sys.platform == "win32":
        import  msvcrt
        msvcrt.setmode(sys.stdout.fileno(), os.O_BINARY)

    handler.process_request()

except:
    import traceback
    import cStringIO
    out = cStringIO.StringIO()
    traceback.print_exc(file=out)
    print "Content-Type: text/plain;"
    print
    print out.getvalue()

    print "\n".join(sys.path)