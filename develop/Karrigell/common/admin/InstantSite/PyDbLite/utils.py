import PyDbLite

def ext_dbs(REL,field_info):
    # return a dictionary of external databases used by main db
    ext_dbs = {}
    for f in field_info:
        if f["type"].startswith("external"):
            ext_db_name = f["type"].split(" ",1)[1]
            ext_dbs[f["code"]] = PyDbLite.Base(REL("applications",ext_db_name+".pdl")).open()
    return ext_dbs

def get_val(ext,key,value):
    if not key in ext:
        return value
    else:
        return ext[key][value]["value"]

