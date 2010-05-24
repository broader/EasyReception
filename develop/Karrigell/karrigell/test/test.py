import os
import sys
import thread
import urllib
import urlparse
import httplib
import cPickle
import Cookie
import cStringIO

from Tkinter import *
from ScrolledText import ScrolledText

# clear session directory
session_dir = os.path.join(os.getcwd(),"sessions")
if not os.path.exists(session_dir):
    os.mkdir(session_dir)
for _file in os.listdir(session_dir):
    os.remove(os.path.join(session_dir,_file))

class Console(ScrolledText):

    def write(self,data,*args):
        self.insert(END,data,*args)

root = Tk()
stdout = Console(root)
stderr = Console(root)
stdout.pack(side=LEFT)
stderr.pack(side=LEFT)
stdout.tag_config("error",foreground="red")

thread.start_new_thread(root.mainloop,())

# ugly hacks to make "import Karrigell" work
this_dir = os.path.dirname(__file__)
server_dir = os.path.dirname(os.path.dirname(os.path.dirname(__file__)))
sys.path.append(server_dir)
os.chdir(server_dir)
sys.argv[0] = os.path.join(server_dir,"Karrigell.py")
sys.argv.append(server_dir)

# aaah !
import Karrigell

class BadResponse(Exception):
    pass

class Not:

    """Used to test that a string is not equal to another""" 
    
    def __init__(self,value):
        self.value = value

    def __cmp__(self,other_string):
        return not cmp(self.value,other_string)

class Contains:

    """Used to test that a string contains another one""" 
    
    def __init__(self,value):
        self.value = value

    def __cmp__(self,other_string):
        # return 0 if other_string contains self.value
        return int(other_string.find(self.value)==-1)

class CookieStore:

    def __init__(self):
        if os.path.exists("cookie_store.dat"):
            os.remove("cookie_store.dat")

    def store(self,cookie_string):
        cookie = Cookie.SimpleCookie(cookie_string)
        stored_cookies = self.load_cookies()
        for key,morsel in cookie.iteritems():
            stored_cookies[key] = morsel
        out = open("cookie_store.dat","wb")
        cPickle.dump(stored_cookies,out)
        out.close()

    def load_cookies(self):
        try:
            return cPickle.load(open("cookie_store.dat"))
        except:
            return {}

    def search(self,url):
        # return the list of valid cookies for the url
        stored_cookies = self.load_cookies()
        valid_cookies = []
        scheme,location, path, parameters, query, frag_id = \
            urlparse.urlparse(url)
        for key,morsel in stored_cookies.iteritems():
            if not morsel["path"] or morsel['path']=="/":
                valid_cookies.append((key,morsel))
                continue
            cookie_path_elts = morsel["path"].split("/")
            if url.split("/")[:len(cookie_path_elts)]==cookie_path_elts:
                valid_cookies.append((key,morsel))
        return valid_cookies
    
class URL:

    def __init__(self,url,status,data={},result=None):
        self.url = url
        self.expected_status = status
        self.data = data
        self.result = result

    def test(self):        
        cx = httplib.HTTPConnection("localhost:%s" %port)
        
        headers = {}
        valid_cookies = []
        for key,morsel in cookies.search(self.url):
            valid_cookies.append("%s=%s" %(key,morsel.value))

        if valid_cookies:
            headers["Cookie"] = "; ".join(valid_cookies)

        if self.data:
            cx.request("POST",self.url,urllib.urlencode(self.data),headers=headers)
        else:
            cx.request("GET",self.url,headers=headers)
        
        res = cx.getresponse()
        
        if "set-cookie" in res.msg:
            cookies.store(res.msg["set-cookie"])

        if not res.status == self.expected_status:
            raise BadResponse, \
             "error for %s : \nexpected status %s, \nreturned status %s\n%s" \
                %(self.url,self.expected_status,res.status,res.read())
        if self.result:
            result = res.read()
            if not self.result == result :
                raise BadResponse, \
                    "error for %s : \nexpected result [%s], \nreturned result [%s]" \
                    %(self.url,self.result,result)
        print ": ok"
    
class Config:

    def __init__(self,port,conf={},host_conf={}):
        self.port = port
        self.host = "localhost"
        self.conf = conf
        # default config
        #Karrigell.k_config.config[self.host] = Karrigell.k_config.config[None]
        # update with specified values
        Karrigell.k_config.config[self.host].update(conf)
        Karrigell.k_config.config[self.host].alias.update({"test":this_dir})
        Karrigell.k_config.config[self.host].data_dir = this_dir
        config = Karrigell.k_config.config[self.host]
        Karrigell.k_config.k_sessions.init_config_session(config)
        #print Karrigell.k_config.config[self.host].global_modules
            
    def test(self,urls):
        print "\nTesting %s %s\n" %(self.host,self.conf)
        server = Karrigell.ThreadingServer('',self.port,Karrigell.handler,False)

        if not Karrigell.k_config.config[self.host].silent:
            sys.stderr.write("Karrigell %s running on port %s\n" \
                %(Karrigell.k_version.__version__,self.port))
            sys.stderr.write("Press Ctrl+C to stop\n")

        thread.start_new_thread(server.run,())
        
        mtimes = dict([(_file,os.stat(os.path.join(session_dir,_file)).st_mtime)
            for _file in os.listdir(session_dir)])
        for url in urls:
            addr = "http://localhost:%s/%s" %(port,url[0])
            print "testing",addr,
            try:
                URL(*url).test()
            except BadResponse,msg:
                print
                sys.stdout.write(msg,"error")
                raw_input()
                sys.exit()
        # check if session files have changed
        new_mtimes = dict([(_file,os.stat(os.path.join(session_dir,_file)).st_mtime)
            for _file in os.listdir(session_dir)])
        if not Karrigell.k_config.config[self.host].persistent_sessions:
            try:
                assert mtimes == new_mtimes
            except:
                sys.stdout.write("persistent_sessions is False but "\
                    "Session files have been modified","error")
                raw_input()
                sys.exit()

port = 8082
sys.stdout = stdout
sys.stderr = stderr

# set default values for host configuration
karrigell_dir = Karrigell.k_config.config[None].karrigell_dir
default_file = os.path.join(karrigell_dir,"core","default_conf.py")

cookies = CookieStore()

urls = [("",200),("/index.py",200),("/undefined.xxx",404),
    ("/test/echo.py",200,{"name":"azertu"},"azertu\n"),
    ("/test/echo.py?name=sdfgh",200,{},"sdfgh\n"),
    ("/test/session1.py?name=pierre",200),
    ("/test/session2.py",200,{},"pierre\n"),
    ("/test/importError",200,{},Contains("ImportError")),
    ("/test/includeError",200,{},Contains("IOError")),
    ("/test/pages.pdl",403),
    ("/test/global.py",200,{},Not("azertu\n"))
    ]
c=Config(port)
c.test(urls)

Config(port,conf={"silent":True}).test(urls)


# test with global modules
conf = Config(port,conf={"global_modules":[os.path.join(this_dir,"aaa.py")],
    "silent":False})
# the last test should return a value
urls.pop()
urls.append(("/test/global.py",200,{},"azertu\n"))

conf.test(urls)

# test that session folder is unchanged when sessions are not persistent
conf = Config(port,conf={"persistent_sessions":False,
    "global_modules":[os.path.join(this_dir,"aaa.py")]})
conf.test(urls)
raw_input()
