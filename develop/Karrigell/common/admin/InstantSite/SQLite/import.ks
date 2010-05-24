"""Create a database from a CSV file
The file is typically created from an Excel sheet
"""

import os

import k_databases
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

    db_name = os.path.splitext(os.path.basename(source.filename))[0]
    db_name = db_name.replace(' ','_')

    sqlite = k_databases.get_engines()['SQLite']

    reader = csv.reader(source.file,delimiter=delimiter)
    local_copy_file = open(os.path.join(user,db_name+'.csv'),'w')
    local_copy = csv.writer(local_copy_file,delimiter=delimiter)

    raw_field_names = reader.next()
    local_copy.writerow(raw_field_names)
    # replace raw field names by normalized names
    import string
    import unicodedata
    field_names = []
    non_ascii = []
    for raw in raw_field_names:
        raw1 = raw
        if raw1[0] in string.digits:
            raw1 = '_'+raw1
        raw1 = raw1.replace(' ','_')
        norm = unicode(raw1,csv_encoding)
        if not raw1 == norm.encode('ascii','ignore'):
            # field name has non ASCII characters
            non_ascii.append(unicode(raw,csv_encoding))
        field_names.append(norm)
    if non_ascii:
        SET_UNICODE_OUT(csv_encoding)
        print "Error - these fields have non-ASCII characters : ",','.join(non_ascii)
        return
    
    dest_file = REL(user,db_name+".sqlite")
    if os.path.exists(dest_file):
        print 'Database %s already exists' %dest_file
        return
    conn = sqlite.connect(dest_file)
    cursor = conn.cursor()
    # try to guess field types
    types = dict([(f,{}) for f in field_names])
    import guess_type
    for line in reader:
        conv_line = [guess_type.guess_type(x).__class__ for x in line]
        for field_name,_type in zip(field_names,conv_line):
            types[field_name][_type] = None
        local_copy.writerow(line)
    import cgi
    _type = {}
    for f in types:
        if len(types[f].keys())>1:
            _type[f]='TEXT'
        else:
            _type[f]={str:'TEXT',int:'INTEGER',float:'REAL'}[types[f].keys()[0]]

    sql = 'CREATE TABLE %s (' %db_name
    sql += ','.join(['%s %s' %(f.encode('utf-8'),_type[f]) for f in field_names])+')'
    cursor.execute(sql)
    
    sql = 'INSERT INTO %s (%s) VALUES (%s)' %(db_name,
        ','.join(field_names),','.join(['?' for f in field_names]))

    local_copy_file.close()
    local_copy_file = open(os.path.join(user,db_name+'.csv'),'r')
    local_copy = csv.reader(local_copy_file,delimiter=delimiter)
    local_copy.next()
    for line in local_copy:
        conv_line = [guess_type.guess_type(x) for x in line]
        line1 = []
        for item in conv_line:
            if isinstance(item,str):
                line1.append(unicode(item,csv_encoding))
            else:
                line1.append(item)
        try:
            cursor.execute(sql,line1)
        except:
            print sql,'<br>',conv_line
            return
    conn.commit()
    
    print 'ok'