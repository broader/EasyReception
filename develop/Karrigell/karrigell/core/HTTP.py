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
import gc

import k_version

buf_size = 2<<16

class HTTP:

    log = True
    managed_extensions = ".htm",".html",".py",".pih",".hip",".ks"
    version = k_version.__version__

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
        self.sock.close()

    def handle_request(self):
        try:
            self.request_line = self.rfile.readline()
        except socket.error:
            self.keep_alive = False
            return
        if not self.request_line.strip():
            self.keep_alive = False
            return
        if self.read_request():
            self.process_request()
        else:
            # bad request
            self.keep_alive = False
            return

    def read_request(self):
        # read request lines
        # set default values
        self.protocol = ""
        self.resp_headers = {}
        self.cookies = {}
        self.header_text = ""
        self.config = k_config.get_host_conf(None)
        # initialize log info
        info = datetime.datetime.now().strftime("%Y/%m/%d %H:%M:%S - ")
        info += str(self.client_address[0]) + (" - ")
        info += self.request_line.strip()
        self.info = info

        # read headers
        while True:
            line = self.rfile.readline(size=8192)
            if len(line) == 8192:
                return False # too long line = attack
            self.header_text += line
            if not line.strip():
                break
        return self.parse_request()

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
            elif fs[k].filename: # file upload : keep value as is
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
            return False

        if not self.method in ("HEAD","GET","POST"):
            return False
        
        # request headers
        self.headers = email.message_from_string(self.header_text)
        return True

    def process_request(self):
        import k_target

        # initialise namespace
        self.ns = {"REQUEST_HANDLER":self,
            "SCRIPT_END":SCRIPT_END,
            "HTTP_REDIRECTION":HTTP_REDIRECTION,
            "Session":self.Session,
            "Role":self.get_log_level,
            "PRINT":self._print,
            "STDOUT":self._sys_stdout,
            "LOG":self._log
            }

        self.output = cStringIO.StringIO()
        info = self.info

        # defaults
        self.output_encoding = sys.getdefaultencoding()
        self.resp_headers = email.message_from_string("")
        self.cookies = {}

        # keep connection alive after this request ?
        conn_header = self.headers.get("connection","")
        self.keep_alive = (self.protocol == "HTTP/1.1") \
             and (conn_header.lower().startswith("keep-alive"))

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
            traceback.print_exc(file=sys.stderr)
            msg.write("</pre>")
            self.send_error(500,explain,msg.getvalue())
            return

        # encoding
        self.ouput_encoding = self.config.output_encoding

        self.SET_COOKIE = Cookie.SimpleCookie()
        try :
            self.COOKIE=Cookie.SimpleCookie(self.headers["cookie"])
        except (KeyError, Cookie.CookieError) :
            self.COOKIE=Cookie.SimpleCookie()

        # script execution namespace
        self.ns.update({"ACCEPTED_LANGUAGES":self.headers.get("accept-language",None),
            "HEADERS":self.headers,
            "RESPONSE":self.resp_headers,
            "COOKIE":self.COOKIE,
            "SET_COOKIE":self.SET_COOKIE,
            "CONFIG":self.config
            })

        self.is_script = False

        # resolve URL into a path in the file system
        try:
            target = k_target.Target(self,self.url)
            self.target = target
            if target.is_dir():
                self.send_status(200,"Ok")
                restrict = self.config.allow_directory_listing
                if None in restrict or self.get_log_level() in restrict:
                    import k_utils
                    dir_list = k_utils.dirlist(target.name,target.url)
                    self.send_message(dir_list)
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
            try:
                self.hook("static_files")
            except SCRIPT_END,msg:
                self.send_error(403,"Forbidden",msg)
                return
            # use browser cache if possible
            if self.config.cache and "If-Modified-Since" in self.headers:
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

        try:
            # execute Python script in namespace
            target.parse_script()
            self.cwd = os.path.dirname(target.name) # target directory
            # run script
            target.run(self.ns)
            # namespace may be changed by script (RESPONSE, SET_COOKIE)
            self.ns.update(target.ns)
            # save session object
            self.save_session()
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
            try:
                self.save_session()
                self.redirect(url)
                self._log(info,302,url)
                return
            except:
                self.ns["RESPONSE"] = {}
                self.handle_exception(sys.exc_info(),
                    "Error in %s" %target.script_url)
                # don't know why but server blocks otherwise...
                self.keep_alive = False
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
            if self.output_encoding is not None:
                ctype = self.resp_headers["Content-type"]
                del self.resp_headers["Content-type"]
                self.resp_headers["Content-type"] = ctype + \
                    "; charset=%s" %self.output_encoding
        self.cookies = self.ns["SET_COOKIE"]
        self.send_status(200,"Ok")
        self.send_headers()
        self.send_result()
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

    def handle_exception(self,exc_info,header):
        #sys.stderr.write("\n\n COLLECT \n\n")
        gc.collect()
        import k_traceback
        self._print(k_traceback.trace(self,exc_info,header,self.config))

    def _print(self,*data):
        res = []
        for d in data:
            if self.output_encoding and isinstance(d,unicode):
                res.append(d.encode(self.output_encoding))
            else:
                res.append(str(d))
        self.output.write(" ".join(res)+"\n")

    def _sys_stdout(self,*data):
        """No space or line breaks"""
        res = []
        for d in data:
            if self.output_encoding and isinstance(d,unicode):
                res.append(d.encode(self.output_encoding))
            else:
                res.append(str(d))
        self.output.write("".join(res))

    def get_log_level(self):
        if "role" in self.COOKIE:
            return self.COOKIE["role"].value
        else:
            return None

    def Session(self,expires=15*60,path='/'):
        """Function called in scripts, retrieves the session object
        expires is the time (in seconds) after which the session object
        is removed from the session database if it has not been used
        path is the path where the session id cookie is valid
        """
        if hasattr(self,"sessionObj"):
            #sys.stderr.write("HTTP self.sessionObject %s" %str(self.sessionObj))
            return self.sessionObj
        elif self.COOKIE.has_key("sessionId"):
            sessionId = self.COOKIE["sessionId"].value
            #sys.stderr.write("HTTP self.config %s" %dir(self.config))
            self.sessionObj = self.config.get_session_object(self.config,
                sessionId,expires)
            #sys.stderr.write("\nHTTP cookie sessionId %s at %s " %(str(sessionId), str(self.sessionObj)))
        else:
            self.sessionObj = self.config.make_session_object(self.config,expires)
            self.SET_COOKIE["sessionId"] = self.sessionObj._id
            self.SET_COOKIE["sessionId"]["path"] = path
            #sys.stderr.write("HTTP new sessionObj %s at %s " % (str(self.sessionObj._id), str(self.sessionObj)))
        return self.sessionObj


    def save_session(self):
        # save changes in session object
        if hasattr(self,"sessionObj"):
            self.config.save_session_object(self.config, self.sessionObj)
            delattr(self, "sessionObj")
                
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
        self.keep_alive = False

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
        #if not self.keep_alive:
        #    self.sock.close()
        if hasattr(self,"config") and self.config.capture and self.is_script:
            capture_db = k_capture.open_db(self.config)
            k_capture.save(self,capture_db)
            self._log("%s requetes capturees" %len(capture_db))

    def version_string(self):
        return "Karrigell %s" %k_version.__version__

    def address_string(self):
        host, port = self.client_address[:2]
        return socket.getfqdn(host)

    def hook(self,step):
        k_modules.run(self,step)