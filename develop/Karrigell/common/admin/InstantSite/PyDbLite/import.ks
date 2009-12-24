"""Create a database from a CSV file
The file is typically created from an Excel sheet
"""

import os
from HTMLTags import *

def index():
    print HEAD(LINK(rel="stylesheet",href="../default.css")+
        SCRIPT(src="../edit_form.js"))
    print H2("Create a new database from a CSV file")
    lines = [TR(TD("Field delimiter in CSV file")+
        TD(SELECT(OPTION(",",value=",")+OPTION(";",value=";"),name="delimiter")))]
    lines += [TR(TD("CSV file")+
        TD(INPUT(Type="file",name="source")))]
    lines += [TR(TD(INPUT(Type="submit",value="Ok"),colspan="2"))]
    print FORM(TABLE(Sum(lines)),method="post",enctype="multipart/form-data",
        action="upload")

def upload(delimiter,source):
    import csv
    import urllib
    import PyDbLite

    reader = csv.reader(source.file,delimiter=delimiter.value)
    field_names = reader.next()
    field_codes = ["f%s"%(i+1) for i in range(len(field_names))]
    
    db_name = os.path.splitext(os.path.basename(source.filename))[0]
    dest_file = REL("applications",db_name+".pdl")
    db = PyDbLite.Base(dest_file)
    
    field_codes = ["f%s"%(i+1) for i in range(len(field_names))]
    
    fields = []
    for name,code in zip(field_names,field_codes):
        fields.append({"name":name,
                        "code":code,
                        "type":"string",
                        "allow_empty":False,
                        "default":""})
    form = dict([(code,{"widget":"input"}) for code in field_codes])
    
    import cPickle
    infos = {"fields":fields,"form":form,"views":{}}
    info_file = open(REL("applications",db_name)+"_infos.dat","wb")
    cPickle.dump(infos,info_file)
    info_file.close()
    
    try:
        db.create(*field_codes)
    except IOError:
        print H3("Error"),"Database %s already exists" %dest_file
        raise SCRIPT_END

    import guess_type
    for line in reader:
        conv_line = [guess_type.guess_type(x) for x in line]
        db.insert(*conv_line)
    
    db.commit()
    
    redir = urllib.quote_plus(db_name)
    raise HTTP_REDIRECTION,"../index.ks/edit?db=%s" %redir