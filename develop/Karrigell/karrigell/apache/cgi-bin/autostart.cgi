#!/usr/bin/python
print "Content-type: text/html\r\n\r\n"
print """<html><head><META HTTP-EQUIV="Refresh" CONTENT="10; 
      URL=/"></head><body>Restarting site ...<a href="/">click 
      here<a></body></html>"""
import os
import sys
#os.setpgid(os.getpid(), 0)
server_script = os.path.join("c:\\","Karrigell","20081129","Karrigell.py")
conf_dir = os.path.join("c:\\",'Karrigell','conf_proxy')
try:
    os.system(sys.executable + ' '+server_script +' -P 8081 -S %s &' %conf_dir)
except:
    import traceback
    traceback.print_exc(file=sys.stdout)