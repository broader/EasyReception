import os
import sys
import thread
import socket
import urllib

# ugly hacks to make "import Karrigell" work
this_dir = os.path.dirname(__file__)
server_dir = os.path.dirname(os.path.dirname(os.path.dirname(__file__)))
sys.path.append(server_dir)
os.chdir(server_dir)
sys.argv[0] = os.path.join(server_dir,"Karrigell.py")
sys.argv.append(server_dir)

# aaah !
import Karrigell

config = Karrigell.k_config.config[None]
PORT = 8088
server = Karrigell.ThreadingServer('',PORT,Karrigell.handler)
thread.start_new_thread(server.run,())

class Response:

    def __init__(self,s):
        res = ''
        while True:
            buff = s.recv(1024)
            if not buff:
                break
            res += buff
        self.resp_line,self.headers,self.body = self.parse_response(res)

    def parse_response(self,resp):
        lines = resp.split('\n')
        resp_line = lines[0].rstrip()
        if len(lines)==1:
            return resp_line,None,None
        headers = []
        for i,line in enumerate(lines[1:]):
            if line.strip():
                headers.append(line.rstrip())
            else:
                break
        body = '\n'.join(lines[i+2:])
        return resp_line,headers,body

s = socket.socket(socket.AF_INET,socket.SOCK_STREAM)
while True:
    try:
        s.connect(('localhost',PORT))
        break
    except:
        pass
s.close()

s = socket.socket(socket.AF_INET,socket.SOCK_STREAM)
s.connect(('localhost',PORT))

s.send('UNKNOWN bla bla\r\n\r\n')
res = Response(s)

print 'BAD REQUEST'

s = socket.socket(socket.AF_INET,socket.SOCK_STREAM)
s.connect(('localhost',PORT))
s.send('HEAD / HTTP/1.1\r\n')
s.send('\r\n')
res = Response(s) 

print 'HEAD /',res.resp_line

s = socket.socket(socket.AF_INET,socket.SOCK_STREAM)
s.connect(('localhost',PORT))
s.send('GET /index.html HTTP/1.1\r\n')
s.send('\r\n')
res = Response(s)
print res.body == file(os.path.join(config.root_dir,'index.py'),'rb').read()
print 'GET /index.ks',res.resp_line

s = socket.socket(socket.AF_INET,socket.SOCK_STREAM)
s.connect(('localhost',PORT))
s.send('GET /demo/calendar/delete.gif HTTP/1.1\r\n')
s.send('\r\n')
res = Response(s)
print res.headers
print 'GET /demo/calendar/delete.gif',res.resp_line

s = socket.socket(socket.AF_INET,socket.SOCK_STREAM)
s.connect(('localhost',PORT))
s.send('HEAD /demo/calendar/delete.gif HTTP/1.1\r\n')
s.send('\r\n')
res = Response(s)
print 'HEAD /demo/calendar/delete.gif',res.resp_line
print 'headers',res.headers

s = socket.socket(socket.AF_INET,socket.SOCK_STREAM)
s.connect(('localhost',PORT))
s.send('HEAD /index.html HTTP/1.1\r\n')
s.send('\r\n')
res = Response(s)
print 'HEAD /index.html',res.resp_line

s = socket.socket(socket.AF_INET,socket.SOCK_STREAM)
s.connect(('localhost',PORT))
s.send('HEAD /index1.html HTTP/1.1\r\n')
s.send('\r\n')
res = Response(s)
print 'HEAD /index1.html',res.resp_line

res = urllib.urlopen('http://localhost:%s/index.html' %PORT)
print len(res.read())

body = urllib.urlencode({'spam':'lqhglg'})
res = urllib.urlopen('http://localhost:%s/demo/myScript.py' %PORT,body)
print res.info()

s = socket.socket(socket.AF_INET,socket.SOCK_STREAM)
s.connect(('localhost',PORT))
s.send('HEAD /index.html HTTP/1.1\r\n')
s.send('\r\n')
res = Response(s) 
print 'HEAD /'
print res.resp_line
