"""Defines function get_py_code(file_name)
Returns a 2-element tuple python_code,line_mapping:

python_code = the Python code for this file :
    - the raw source code if file_name extension is .py
    - the translation of source code into Python code if source is
      Python Inside HTML (.pih) or HIP (.hip)
line_mapping = for .pih files, a dictionnary mapping line numbers in
Python code to line number in pih source
"""

import os

def get_py_code(file_name,encoding=None):
    ext = os.path.splitext(file_name)[1]
    line_mapping = {}
    if ext in [".py",".ks"]:
        src = open(file_name)
    elif ext == ".pih":
        import PythonInsideHTML
        pih = PythonInsideHTML.PIH(file_name,encoding)
        src = pih.output
        line_mapping = pih.lineMapping
        src.seek(0)
    elif ext == ".hip":
        import HIP
        pih = HIP.HIP(file_name)
        src = pih.output
        src.seek(0)
    else:
        raise ValueError,"Extension of %s not in py, pih, hip" %file_name
    # normalize line breaks to \n
    lines = [ line.rstrip() for line in src.readlines() ]
    pycode = "\n".join(lines)+"\n"
    return pycode,line_mapping

def get_py_code_from_string(code_string,ext):
    import cStringIO
    line_mapping = {}
    if ext in [".py",".ks"]:
        src = cStringIO.StringIO(code_string)
    elif ext == ".pih":
        import PythonInsideHTML
        pih_src = cStringIO.StringIO(code_string)
        pih_src.seek(0)
        pih = PythonInsideHTML.PIH()
        pih.parse(pih_src)
        src = pih.output
        line_mapping = pih.lineMapping
    else:
        raise ValueError,"Extension of %s not in py, ks, pih" %file_name
    src.seek(0)
    return src.getvalue(),line_mapping