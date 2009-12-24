# find all imports with non-builtin modules
import os
import cStringIO
import token
import imp

import transform_script

class imports:
    def __init__(self):
        self.modules = []
        self.old_names = []
        self.flag = False

def trans_import(tokens,state):
    if state is None:
        state = imports()
    # print imports
    token_type,token_string,(srow,scol),(erow,ecol),line_str = tokens
    typ = token.tok_name[token_type]

    if typ == "NAME" and token_string == "import":
        if not state.flag:
            state.flag = "import"
        elif state.flag == "from": # syntax "from module import something"
            state.flag = False
    elif typ == "NAME" and token_string == "from":
        state.flag = "from"
    elif typ == "NAME" and token_string == "as":
        state.flag = False
    elif typ == "NEWLINE" and state.flag == "import":
        state.flag = False
    elif typ == "OP" and token_string == ";":
        state.flag = False

    elif state.flag and typ=="NAME":
        # token_string is a module name
        if not token_string in ["HTMLTags"]:
            try:
                imp.find_module(token_string)
            except ImportError:
                state.modules.append("[line %s : %s] %s" %(srow,token_string,line_str))

    return token_string,state

def diag2to3(top,dirpath,file_name,out):

    name = os.path.join(dirpath,file_name)
    py_code = cStringIO.StringIO()
    ext = os.path.splitext(name)[1]
    if ext in [".py",".ks"]:
        src = open(name)
    elif ext == ".pih":
        import PythonInsideHTML
        pih = PythonInsideHTML.PIH(name)
        src = pih.output
        src.seek(0)
    elif ext == ".hip":
        import HIP
        pih = HIP.HIP(name)
        src = pih.output
        src.seek(0)
    else:
        return

    # transform Python script and get function names
    result = transform_script.transform(src,py_code,trans_import)
    if result.modules:
        out.write("File %s\n" %name[len(top):])
        out.write("1. import of user-defined modules\n")
        for module in result.modules:
            out.write(module.rstrip()+"\n")
        out.write("\n")

# select directory where old files are
from tkFileDialog import *

if os.path.exists("old_dir.txt"):
    default = open("old_dir.txt").read()
    dirname = askdirectory(initialdir = default)
else:
    dirname = askdirectory()
if dirname:
    out = open("old_dir.txt","w")
    out.write(dirname)
    out.close()
    out = open("report.txt","w")
    out.write("Migration from Karrigell version 2.4.0 to 3.0\n")
    out.write("Directory %s\n" %dirname)
    for dirpath, dirnames, filenames in os.walk(dirname):
        for name in filenames:
            diag2to3(dirname,dirpath,name,out)
    out.close()
