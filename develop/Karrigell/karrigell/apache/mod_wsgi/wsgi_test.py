import os,sys
this_dir = os.path.dirname(__file__)
if not this_dir in sys.path:
    sys.path.append(this_dir)

import wsgi_config_loader

def application(environ,start_response):
    start_response('200 Ok',[('Content-type','text/plain')])
    res = ['current dir %s' %os.getcwd()]
    for path in sys.path:
        res.append('\n%s' %path)
    return res
