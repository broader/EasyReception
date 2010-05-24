# jQuery File Tree Python Connector
# output a list of files for jQuery File Tree
import os
import cgi
import urllib

from HTMLTags import *

rel_folder = QUERY.get('dir','')
if rel_folder:
    rel_folder = urllib.unquote(rel_folder[:-1])

folder = os.path.join(CONFIG.root,rel_folder)

if os.path.exists(folder):
    paths = os.listdir(folder)
    paths.sort(lambda x,y: cmp(x.lower(),y.lower()))
    dirs,files = [],[]
    for path in paths:
        abs_path = os.path.join(folder,path)
        if os.path.isdir(abs_path):
            dirs.append(LI(A(path,href="#",rel=cgi.escape(abs_path+'/')),
                Class="directory collapsed"))
        else:
            ext = os.path.splitext(path)[1]
            if ext:
                ext = ext[1:]
            files.append(A(path,href="/editScript/index?editable=1&script=%s" 
                %urllib.quote_plus(abs_path),
                target="right",Class="file")+BR())

    print UL(Sum(dirs+files),Class="jqueryFileTree",style="display: none;")
    