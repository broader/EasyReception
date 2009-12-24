"""HTTP request handler
Serves static files and runs Python scripts responding to GET and
POST requests
"""

import sys
import os
import time
import datetime
import traceback
import cStringIO
import re

import socket
import mimetypes
import email
import Cookie
import cgi
import urllib
import rfc822

import k_config
import k_modules
import k_capture
import k_environ
import k_gzip
import k_sessions
from k_exceptions import *

__version__ = "3.0"

buf_size = 2<<16

class HTTP:

    log = True
    managed_extensions = ".htm",".html",".py",".pih",".hip",".ks"

    def __init__(self,server,(sock,client_address)):
        self.server = server
        self.client_address = client_address
        self.sock = sock
        self.rfile = sock.makefile('rb', -1)
        self.wfile = sock.makefile('wb', 0)
        self.keep_alive = True

    def run(self):
        while self.keep_alive:
            self.handle_request()
        if not self.wfile.closed:
            self.wfile.flush()
        self.wfile.close()
        self.rfile.close()

    def handle_request(self):
        try:
            self.request_line = self.rfile.readline()
        except socket.error:
            self.keep_alive = False
            return
        if not self.request_line.strip():
            self.keep_alive = False
            return
        self.read_request()
        self.process_request()

    def read_request(self):
        # read request lines
        self.header_text = ""
        while True:
            line = self.rfile.readline()
            self.header_text += line
            if not line.strip():
                break
        self.parse_request()

    def get_post_data(self):
        # get POST data from source
        post_data = {}
        fs = cgi.FieldStorage(fp = self.rfile,
            headers = self.headers,
            environ={"REQUEST_METHOD":"POST"},
            keep_blank_values = True)
        # prepare data dictionary
        for k in fs.keys():
            if isinstance(fs[k],list):
                post_data[k] = fs.getlist(k)
            elif fs[k].file: # file upload : keep value as is
                post_data[k] = fs[k]
            else:
                post_data[k] = fs.getlist(k)
        self.post_data = post_data
        return post_data

    def parse_request(self):
        # parse request line
        try:
            self.method,self.url,self.protocol = self.request_line.strip().split()
        except:
            self._log("error parsing request line [%s]" %self.request_line)
            raise
        # Allow spaces and other quoted characters 
        self.url = urllib.unquote(self.url)
        # request headers
        self.headers = email.message_from_string(self.header_text)

    def process_request(self):
        import k_target

        # initialise namespace
        self.ns = {"REQUEST_HANDLER":self,
            "SCRIPT_END":SCRIPT_END,
            "HTTP_REDIRECTION":HTTP_REDIRECTION,
            "Session":self.Session,
            "_":self.translation,
            "Role":self.get_log_level,
            "PRINT":self._print,
            "STDOUT":self._sys_stdout,
            "LOG":self._log
            }

        self.output = cStringIO.StringIO()

        # defaults
        self.output_encoding = None
        self.resp_headers = email.message_from_string("")
        self.cookies = {}

        # keep connection alive after this request ?
        conn_header = self.headers.get("connection","")
        self.keep_alive = (self.protocol == "HTTP/1.1") \
             and (conn_header.lower().startswith("keep-alive"))

        # initialize log info
        info = datetime.datetime.now().strftime("%Y/%m/%d %H:%M:%S - ")
        info += str(self.client_address[0]) + (" - ")
        info += self.request_line.strip()
        self.info = info

        # set host-specific configuration
        self.host = self.headers.get('host',None)
        # hook "host_filter"
        try:
            self.hook("host_filter")
            self.config = k_config.get_host_conf(self.host)
        except HTTP_REDIRECTION, url :
            self.redirect(url)
            self._log(info,302,url)
            return
        except:
            self.config = k_config.config[None]
            msg = cStringIO.StringIO()
            explain = "Error loading configuration file for host %s" \
                %self.host
            msg.write("<pre>")
            import traceback
            traceback.print_exc(file=msg)
            msg.write("</pre>")
            self.send_error(500,explain,msg.getvalue())
            return

        # encoding
        self.charsets = None
        if self.config.encode_input:
            if "accept-charset" in self.headers:
                charsets = self.headers["accept-charset"]
                self.charsets = charsets.split(";")[0].split(",")

        self.SET_COOKIE = Cookie.SimpleCookie()
        if self.headers.has_key("cookie"):
            self.COOKIE=Cookie.SimpleCookie(self.headers["cookie"])
        else:
            self.COOKIE=Cookie.SimpleCookie()

        # script execution namespace
        self.ns.update({"ACCEPTED_LANGUAGES":self.headers.get("accept-language",None),
            "HEADERS":self.headers,
            "RESPONSE":self.resp_headers,
            "COOKIE":self.COOKIE,
            "SET_COOKIE":self.SET_COOKIE,
            "CONFIG":self.config,
            })

        self.is_script = False

        # resolve URL into a path in the file system
        try:
            target = k_target.Target(self,self.url)
            self.target = target
            if target.is_dir():
                self.send_status(200,"Ok")

                if self.config.allow_directory_listing:
                    self.send_message(target.dirlist())
                else:
                    self.send_message("You don't have permission for %s"
                        %target.name)
                self._log(info,200)
                return
        except k_target.Redir,new_url:
            self.redirect(new_url)
            self._log(info,302,new_url)
            return
        except k_target.NotFound:
            self.send_error(404,"File not found",
                "No file matches url %s" %self.url)
            return
        except k_target.Duplicate,msg:
            self.send_message("<h3>Duplicate error</h3>"+str(msg))
            return
        except:
            # if other error or exception, print trace
            if self.config.debug:
                import traceback
                self.resp_headers["Content-type"] = "text/plain"
                self._print("<pre>")
                traceback.print_exc(file=self.output)
                self._print("</pre>")
                self.send_message()
            else:
                msg = "<H3>Error</H3>The request could not be completed"
                self.send_message(msg)
            self._log(info,200,"Error")
            return

        # don't show files with some extensions
        if target.ext in self.config.hide_extensions:
            self.send_error(403,"Forbidden",
                "Files with extension %s are not served" %target.ext)
            return

        # don't show files matching some patterns
        for pattern in self.config.ignore:
            if re.match(pattern,target.script_url):
                self.send_error(404,"File not found","")
                return

        # static files : guess content type, set output to the file object
        if not (target.is_script() or target.is_cgi()):
            # use browser cache if possible
            if "If-Modified-Since" in self.headers:
                ims_tuple = rfc822.parsedate(self.headers["If-Modified-Since"])
                if ims_tuple is not None:
                    ims_datetime = datetime.datetime(*ims_tuple[:7])
                    ims_dtstring = ims_datetime.strftime("%d %b %Y %H:%M:%S")
                    last_modif = datetime.datetime.utcfromtimestamp(
                        os.stat(target.name).st_mtime).strftime("%d %b %Y %H:%M:%S")
                    if last_modif == ims_dtstring:
                        self.send_status(304,"Not Modified")
                        self.send_headers()
                        self.send_result()
                        self._log(info,304)
                        return
            self.resp_headers["Content-type"] = \
                mimetypes.types_map.get(target.ext,'text/plain')
            self.resp_headers["Last-modified"] = \
                self.date_time_string(os.stat(target.name).st_mtime)

            if not k_gzip.test_gzip(self,self.config):
                self.output = open(target.name,'rb')
                self.resp_headers["Content-length"] = os.stat(target.name).st_size
            else: # use gzip to compress text files
                self.output = k_gzip.do_gzip(open(target.name,'rb'))
                self.resp_headers["Content-length"] = self.output.tell()
                self.resp_headers["Content-Encoding"] = "gzip"
                self.output.seek(0)
            self.send_status(200,"Ok")
            self.send_headers()
            self.send_result()
            self._log(info,200)
            return

        # scripts
        self.is_script = True

        # environment variables (same as os.environ for CGI scripts)
        env = k_environ.make_environ(self,target)
        
        # CGI scripts
        if target.is_cgi():
            os.environ.update(env) # set environment variables
            sys.stdin = self.rfile
            sys.stdout = self.output

            try:
                execfile(target.name)
                self.send_status(200,"Ok")
                # no control on Content-length header, so close connection
                self.keep_alive = False
                self.send_result()
                self._log(info,200)
            except:
                import traceback
                out = cStringIO.StringIO()
                out.write("<h3>Error in CGI script %s</h3><pre>" 
                    %target.name)
                traceback.print_exc(file=out)
                out.write("</pre>")
                self.send_message(out.getvalue())
                self._log(info,500)
            return
        
        self.ns["ENVIRON"] = env       

        if self.config.output_encoding:
            self.output_encoding = self.config.output_encoding
        elif target.data_encoding:
            self.output_encoding = target.data_encoding

        try:
            # execute Python script in namespace
            target.parse_script()
            self.cwd = os.path.dirname(target.name) # target directory
            # run script
            target.run(self.ns)
            # namespace may be changed by script (RESPONSE, SET_COOKIE)
            self.ns.update(target.ns)
        except k_target.Redir,new_url:
            self.redirect(new_url)
            self._log(info,302,new_url)
            return
        except k_target.NotFound,url:
            # might occur with Include
            self.send_error(404,"File not found",
                "Included url %s not found" %url)
            return
        except k_target.RecursionError,msg:
            # might occur with Include
            self.send_error(200,"Ok","Recursion error %s" %msg)
            return
        except k_target.NoFunction,function:
            # a function was specified in the url and doesn't exist
            # in matching script
            self.send_error(404,"File not found",
                "Function %s not defined in script %s"
                %(function,target.name))
            return
        except k_target.K_ImportError,(module,url,exc_info):
            header = "Exception in module %s imported by %s" \
                %(url,target.script_url)
            self.target = module
            self.handle_exception(exc_info,header)
        except SCRIPT_END:
            pass
        except HTTP_REDIRECTION,url:
            self.cookies = self.ns["SET_COOKIE"]
            self.save_session()
            self.redirect(url)
            self._log(info,302,url)
            return
        except:
            # if other error or exception, print trace
            self.ns["RESPONSE"] = {}
            self.handle_exception(sys.exc_info(),
                "Error in %s" %target.script_url)

        # end of request
        self.resp_headers["Content-length"] = self.output.tell()
        if not "Content-type" in self.resp_headers:
            self.resp_headers["Content-type"] = "text/html"
        if not "charset" in self.resp_headers["Content-type"]:
            if self.output_encoding:
                ctype = self.resp_headers["Content-type"]
                del self.resp_headers["Content-type"]
                self.resp_headers["Content-type"] = ctype + \
                    ";charset:%s" %self.output_encoding
        self.cookies = self.ns["SET_COOKIE"]
        self.send_status(200,"Ok")
        self.send_headers()
        self.send_result()
        self.save_session()
        self._log(info,200)

    # RFC 822 date time formatting
    # copied from SimpleHTTPServer

    weekdayname = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']

    monthname = [None,
                 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']

    def date_time_string(self, timestamp=None):
        """Return the current date and time formatted for a message header."""
        if timestamp is None:
            timestamp = time.time()
        year, month, day, hh, mm, ss, wd, y, z = time.gmtime(timestamp)
        s = "%s, %02d %3s %4d %02d:%02d:%02d GMT" % (
                self.weekdayname[wd],
                day, self.monthname[month], year,
                hh, mm, ss)
        return s

    def send_static(self,fileName):
        """
        25/01/2005 Luca Montecchian <l.montecchiani@teamsystem.com>
        Http optimization, cache and headers for static files
        """
        s = os.stat(fileName)
        mdt = time.gmtime(s.st_mtime)
        lastModified = time.strftime("%a, %d %b %Y %H:%M:%S GMT", mdt)
        size = str(s.st_size)
        ims = self.HEADERS.get('if-modified-since',None)

        if lastModified and ims == lastModified :
            self.send_response(304)
            return True
        else:
            # populate the header  ;) 
            self.RESPONSE["Last-Modified"] = lastModified
            self.RESPONSE["Content-Length"] = size
        return False

    def handle_exception(self,exc_info,header):
        import k_traceback
        self._print(k_traceback.trace(self,exc_info,header,self.config))

    def _print(self,*data):
        if self.output_encoding and isinstance(data,unicode):
            self.output.write(" ".join([str(d).encode(self.output_encoding)
                for d in data]))
        else:
            self.output.write(" ".join([str(d) for d in data]))
        self.output.write("\n")

    def _sys_stdout(self,*data):
        """No space or line breaks"""
        if self.output_encoding and isinstance(data,unicode):
            self.output.write("".join([str(d).encode(self.output_encoding)
                for d in data]))
        else:
            self.output.write("".join([str(d) for d in data]))

    def translation(self,src):
        import k_translation
        trans = k_translation.Translation(self.config)
        return trans.translation(src,self.headers)

    def get_log_level(self):
        if "role" in self.COOKIE:
            return self.COOKIE["role"].value
        else:
            return None

    def Session(self,expires=15*60):
        """Function called in scripts, retrieves the session object
        expires is the time (in seconds) after which the session object
        is removed from the session database if it has not been used"""
        if hasattr(self,"sessionObj"):
            return self.sessionObj
        elif self.COOKIE.has_key("sessionId"):
            self.sessionId = self.COOKIE["sessionId"].value
            self.sessionObj = k_sessions.get_session_object(self.config,
                self.sessionId,expires)
        else:
            self.sessionId,self.sessionObj = \
                k_sessions.make_session_object(self.config,expires)
            self.SET_COOKIE["sessionId"] = self.sessionId
        return self.sessionObj

    def save_session(self):
        # save changes in session object
        if hasattr(self,"sessionId"):
            k_sessions.save_session_object(self.config,self.sessionId,
                self.sessionObj)

    def _log(self,*data):
        import k_logging
        try :
            k_logging.log(self.config,*data)
        except AttributeError :
            print data

    def redirect(self,url):
        # force keep_alive to False ; redirection loops otherwise
        self.keep_alive = False
        self.send_status(302,"Found")
        self.resp_headers = email.message_from_string("")
        self.resp_headers["Location"] = url
        self.send_headers()
        self.output = cStringIO.StringIO() # no output
        self.send_result()

    def send_status(self,code,msg):
        """Initialize response with status line"""
        self.response = "%s %s %s\r\n" %(self.protocol,code,msg)

    def send_headers(self):
        self.resp_headers["Server"] = self.version_string()
        self.resp_headers["Date"] = self.date_time_string()
        headers = [ "%s: %s" %(k,v)
            for (k,v) in self.resp_headers.items()]
        for morsel in self.cookies.values():
            headers.append('Set-Cookie: %s'
                %morsel.output(header='').lstrip())
        self.response += "\r\n".join(headers) + "\r\n\r\n"

    def send_message(self,msg=None):
        """Send a string or an instance of StringIO
        If msg is not specified, use current output"""
        if isinstance(msg,str):
            self.output = cStringIO.StringIO(msg)
        elif msg is not None:
            self.output = msg
        if not "Content-type" in self.resp_headers:
            self.resp_headers["Content-type"] = "text/html"
        self.resp_headers["Content-length"] = len(self.output.getvalue())
        self.send_status(200,"Ok")
        self.send_headers()
        self.send_result()

    def send_error(self,code,explain,msg):
        self.send_status(code,explain)
        self.resp_headers["Content-type"] = "text/html"
        self.resp_headers["Connection"] = "close"
        info = "<h3>%s</h3>%s" %(explain,msg)
        self.resp_headers["Content-length"] = len(info)
        self.send_headers()
        self.output = cStringIO.StringIO(info)
        self.send_result()
        self._log(self.info,code,self.url,explain)

    def send_result(self):
        """send result"""
        try:
            self.wfile.write(self.response)
        except socket.error:
            pass
        self.output.seek(0)
        sent = 0
        while True:
            buff = self.output.read(buf_size)
            if not buff:
                break
            try:
                self.wfile.write(buff)
                sent += len(buff)
            except socket.error:
                self.sock.close()
                return
        if not self.keep_alive:
            self.sock.close()
        if self.config.capture and self.is_script:
            capture_db = k_capture.open_db(self.config)
            k_capture.save(self,capture_db)
            self._log("%s requetes capturees" %len(capture_db))

    def version_string(self):
        return "Karrigell %s" %__version__

    def address_string(self):
        host, port = self.client_address[:2]
        return socket.getfqdn(host)

    def hook(self,step):
        k_modules.run(self,step)