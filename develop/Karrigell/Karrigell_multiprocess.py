"""Multi process version of the Async Server
Requires the PyProcessing package
Adapted from a code written by ccnusjy on
http://groups.google.com/group/karrigell/browse_frm/thread/c2c949b04e0f95cd
"""

import os
import traceback
import sys

from multiprocessing import Process, freeze_support, RLock


if sys.platform == 'win32':
    import multiprocessing.reduction    # make sockets pickable/inheritable


def kkk_serve(server_config, use_ipv6):
    try:
        import k_config
        k_config.init(server_config)

        from Async_core import Server, handler

        s = Server(('', k_config.port), handler, use_ipv6)
        s.run()
    except KeyboardInterrupt:
        s.close()
        sys.stderr.write("Ctrl+C pressed. Shutting down.\n")


def main_start(server_config):
    try :
        # Launch all ipv4 child processes
        childs = []
        for i in range(server_config["process_num"]):
            child = Process(target=kkk_serve, args=(server_config,False))
            child.daemon= True
            child.start()
            childs.append(child)
            #import time
            #time.sleep(0.5) # To see debug messages correctly.
            
        if server_config["use_ipv6"] == True :
            # Launch all ipv6 child processes
            for i in range(server_config["process_num_ipv6"]):
                child = Process(target=kkk_serve, args=(server_config,True))
                child.daemon= True
                child.start()
                childs.append(child)
                #import time
                #time.sleep(0.5) # To see debug messages correctly.
    
        import k_version
        print "Karrigell %s running on port %s\n%s processes using ipv4" \
            %(k_version.__version__, server_config["port"], server_config["process_num"])
        if server_config["use_ipv6"] == True :
            print "%s processes using ipv6" % server_config["process_num_ipv6"]
        else :
            print ""
            
        print "Press Ctrl+C to stop"
    
        child.join()
    except KeyboardInterrupt :
        sys.stderr.write("Ctrl+C pressed. Shutting down.\n")
    
    # multiprocessing doc recommends to join all child processes on a unix system
    for c in childs:
        c.join()

if __name__ == '__main__':
    if sys.platform == 'win32':
        freeze_support()

    # read command line and load configuration
    import config_loader
    server_config = config_loader.load()
    server_config["server_type"] = "Multiprocess"
    server_config["rlock"] = RLock()
        
    main_start(server_config)
