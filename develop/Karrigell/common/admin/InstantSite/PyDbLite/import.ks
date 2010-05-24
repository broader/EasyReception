"""Create a database from a CSV file
The file is typically created from an Excel sheet
"""

import os
from HTMLTags import *

Login(role=["admin","edit"],add_user=True)
user = COOKIE['login'].value

encodings = ['utf-8','iso-8859-1','utf-16','ascii','utf-32']

def index():
    print HEAD(LINK(rel="stylesheet",href="../default.css")+
        SCRIPT(src="../edit_form.js"))
    print H2("Create a new database from a CSV file")
    lines = [TR(TD("Field delimiter in CSV file")+
        TD(SELECT(OPTION(",",value=",")+OPTION(";",value=";"),name="delimiter")))]
    lines += [TR(TD("CSV file")+
        TD(INPUT(Type="file",name="source")))]
    lines += [TR(TD("Encoding of CSV file")+
        TD(SELECT(Sum([OPTION(enc,value=enc) for enc in encodings]),
            name="csv_encoding")))]
    lines += [TR(TD(INPUT(Type="submit",value="Ok"),colspan="2"))]
    print FORM(TABLE(Sum(lines)),method="post",enctype="multipart/form-data",
        action="upload")

def upload(delimiter,source,csv_encoding):
    import csv
    import urllib
    import PyDbLite

    reader = csv.reader(source.file,delimiter=delimiter)
    field_names = reader.next()
    field_names = [ f.replace(' ','_') for f in field_names ]
    
    db_name = os.path.splitext(os.path.basename(source.filename))[0]
    dest_file = REL(user,db_name+".pdl")
    db = PyDbLite.Base(dest_file)
    
    fields = [{"name":name,
                        "type":"string",
                        "allow_empty":False,
                        "default":""}
               for name in field_names]
    writer = csv.DictWriter(open(REL(user,db_name)+".txt","w"),
                ['name','type','allow_empty','default'])
    for f in fields:
        writer.writerow(f)
    
    try:
        db.create(*field_names)
    except IOError:
        print H3("Error"),"Database %s already exists" %dest_file
        raise SCRIPT_END

    import guess_type
    for line in reader:
        conv_line = [guess_type.guess_type(x) for x in line]
        encoded_line = []
        # convert bytestrings to utf-8 encoding
        for item in conv_line:
            if isinstance(item,str):
                encoded_line.append(unicode(item,csv_encoding).encode('utf-8'))
            else:
                encoded_line.append(item)
        db.insert(*encoded_line)
    
    db.commit()

    redir = urllib.quote_plus(db_name)
    raise HTTP_REDIRECTION,"../index.ks/manager?db_name=%s" %redir