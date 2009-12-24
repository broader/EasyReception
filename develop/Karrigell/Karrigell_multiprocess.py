"""Multi process version of the Async Server
Requires the PyProcessing package
Adapted from a code written by ccnusjy on
http://groups.google.com/group/karrigell/browse_frm/thread/c2c949b04e0f95cd
"""

import os
import traceback
import sys

# read command line and load configuration
import config_loader

import k_config
import HTTP

import k_utils
from Karrigell_async import Server,handler
from processing import Process, currentProcess, freezeSupport,Lock

if sys.platform == 'win32':
    import processing.reduction    # make sockets pickable/inheritable

MPLock = Lock()

def kkk_serve(s,mplock,sys_args=None):
    try:
        k_utils.mplock = mplock
        if sys_args!=None:
            sys.argv = sys_args
            reload(config_loader)
        s.run()
    except KeyboardInterrupt:
        s.close()
        sys.stderr.write("Ctrl+C pressed. Shutting down.\n")

def main_start(process_num):
    # Launch the server
    port = k_config.port

    s = Server(('',port),handler)
    
    sys_args = None
    if len(config_loader._args)>0:
        sys_args = sys.argv
    
    for i in range(process_num):
        child = Process(target=kkk_serve, args=(s,MPLock,sys_args))
        child.setDaemon(True)
        child.start()

    print "Karrigell %s running on port %s, %s processes" \
        %(HTTP.__version__,port,process_num)

    print "Press Ctrl+C to stop"

    kkk_serve(s,MPLock)

if __name__ == '__main__':
    if sys.platform == 'win32':
        freezeSupport()
    main_start(k_config.process_num)
