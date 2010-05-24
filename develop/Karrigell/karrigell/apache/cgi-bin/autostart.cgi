#!python
print "Content-type: text/html\r\n\r\n"
print """<html><head><META HTTP-EQUIV="Refresh" CONTENT="10; 
      URL=/"></head><body>Restarting site ...<a href="/">click 
      here<a></body></html>"""
import os
import sys
#os.setpgid(os.getpid(), 0)
server_script = r"c:\Karrigell\20090614\Karrigell.py"
conf_dir = os.path.dirname(server_script)

line = sys.executable + ' '+server_script +' %s &' %conf_dir

try:
    os.system(line)
except:
    import traceback
    traceback.print_exc(file=out)
