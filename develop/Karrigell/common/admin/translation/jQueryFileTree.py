# jQuery File Tree Python Connector
# output a list of files for jQuery File Tree
import os
import cgi
import urllib

import k_pygettext

from HTMLTags import *
Login(role=["admin"],valid_in="/")

rel_folder = QUERY.get('dir','')
if rel_folder:
    rel_folder = urllib.unquote(rel_folder[:-1])

folder = os.path.join(CONFIG.root_dir,rel_folder)

if os.path.exists(folder):
    paths = os.listdir(folder)
    import sys
    paths.sort(lambda x,y: cmp(x.lower(),y.lower()))
    dirs,files = [],[]
    if not rel_folder:
        # aliases
        if CONFIG.alias:
            dirs.append(B("Alias"))
        for alias in CONFIG.alias:
            dirs.append(LI(A(alias,href="#",
                rel=cgi.escape(CONFIG.alias[alias]+'/')),
                Class="directory collapsed"))
        dirs.append(B("Root directory"))
    for path in paths:
        abs_path = os.path.join(folder,path)
        if os.path.isdir(abs_path):
            dirs.append(LI(A(path,href="#",rel=cgi.escape(abs_path+'/')),
                Class="directory collapsed"))
        else:
            ext = os.path.splitext(path)[1]

            # for scripts, search if there are strings to translate
            mark = False
            if ext in [".py",".pih",".hip",".ks"]:
                try:
                    if k_pygettext.get_strings(abs_path):
                        mark = True
                except:
                    pass
            elif ext == ".kt":
                try:
                    if KT.get_strings(abs_path):
                        mark = True
                except:
                    pass
            if mark:
                files.append(A(path,href="translator.ks/index?script=%s" 
                    %urllib.quote_plus(abs_path),
                    target="right",Class="file")+BR())
            else:
                files.append(TEXT(path)+BR())
        
    print UL(Sum(dirs+files),Class="jqueryFileTree",style="display: none;")
    