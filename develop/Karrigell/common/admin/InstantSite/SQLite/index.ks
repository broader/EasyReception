# -*- coding: iso-8859-1 -*-
import os
import re
from urllib import quote_plus,unquote_plus
import csv
import codecs

from PyDbLite import SQLite
from HTMLTags import *

Login(role=["admin","edit"],valid_in='/',add_user=True)

user = COOKIE['login'].value

if not os.path.exists(REL(user)):
    # new user
    os.mkdir(REL(user))
    import shutil
    for fname in os.listdir(REL("applications")):
        if fname.startswith('.'):
            continue
        shutil.copyfile(REL("applications",fname),REL(user,fname))

sqlite_utils = Import('sqlite_utils')
field_pattern = re.compile('^\D\w*$')

check_type = Import("check_type")
types = check_type.types.keys()

# formats for display and entry
formats = ['default','DATE (YYYY-MM-DD)',
    'TIME (HH:MM:SS)','TIMESTAMP (YYYY-MM-DD HH:MM:SS)']

header = HEAD(LINK(rel="stylesheet",href="../default.css")+
              SCRIPT(src="../sqlite.js"))

def index():

    existing = [ db for db in os.listdir(REL(user))
        if db.endswith(".sqlite") ]

    body = A(_("Home"),href="/")
    body += H3("SQLite management")
    if existing:
        body += "Existing databases"+BR()
    for db in existing:
        body += A(db,
            href="open_db?db=%s" %quote_plus(os.path.splitext(db)[0]))
        body += BR()
    
    form = FORM(action="open_db",method="post")
    form <= "New database - don't specify any extension"
    form <= INPUT(name="db")+INPUT(Type="submit",name="new",value="Ok")

    body += form
    body += BR()+A("Create new base from CSV file",href="../import")

    print HTML(header+BODY(body))

def _reset_db(db_name):
    file_name = REL(user,db_name)+'.sqlite'
    Session().db = os.path.basename(db_name)
    Session().path = db_name
    Session().realpath = file_name

    # get info from database introspection
    tables = {}
    db = SQLite.Database(file_name)
    for _table in db.tables():
        table = SQLite.Table(_table,db).open()
        tables[table.name] = []
        for field in table.fields:
            info = table.field_info[field]
            if info.get('DEFAULT',None) in SQLite.DEFAULT_CLASSES:
                info['DEFAULT'] = info['DEFAULT'].__name__
            tables[table.name].append({'name':field,
                'type':info['type'],
                'not_null':info['NOT NULL'],
                'default':info['DEFAULT'],
                'format':'DEFAULT'
                })

    # additional info in .txt files
    for fname in os.listdir(REL(user)):
        fpath = REL(user,fname)
        if os.path.isfile(fpath) and os.path.splitext(fpath)[1]=='.txt':
            elts = os.path.splitext(fname)[0].split('_')
            if len(elts)==2 and elts[0]==db_name:
                tables[elts[1]] = _get_fields(db_name,elts[1])

    # if .txt files and .ks scripts are missing, create them
    # this is the case if the SQLite database was not created or edited
    # with this interface
    for table in tables:
        path = REL(user,'%s_%s' %(db_name,table))+".txt"
        if not os.path.exists(path):
            writer = csv.DictWriter(open(path,"w"),
                        ['name','type','not_null','default','format'])
            for f in tables[table]:
                dico = {}
                for key,item in f.iteritems():
                    if isinstance(item,unicode):
                        dico[key] = item.encode('utf-8')
                    else:
                        dico[key] = item
                import sys
                sys.stderr.write(str(dico)+'\n')
                writer.writerow(dico)

    return tables

def open_db(db,new=False):

    db_name = unquote_plus(db)

    title = A("Home",href="index",target="_top")
    title += H3("Database %s" %db_name)

    tables = _reset_db(db)

    for table in tables:
        path = REL(user,'%s_%s' %(db_name,table))+".ks"
        if not os.path.exists(path):
            _gen_script(db_name,table)

    lines = TABLE()
    if tables:
        lines <= TR() <= TH("Table")+3*TD("&nbsp;")
    for table in tables:
        line = TR()
        line <= TD(table)
        line <= TD() <= A("Edit structure",href="edit?db=%s&table=%s" %(db,table))
        line <= TD() <= A("Drop",href="drop_table?db=%s&table=%s" %(db,table))
        line <= TD() <= A("Edit records",href="../%s/%s_%s.ks" %(user,db,table),
                        target="_new")
        lines <= line

    new = FORM(action="edit",method="post")
    new <= INPUT(name="table")
    new <= INPUT(Type="hidden",name="db",value=db)
    new <= INPUT(Type="submit",name="new",value="New table")

    print HTML(header+BODY(title+lines+new))

def edit(**kw):

    db_name = unquote_plus(kw["db"])
    table = kw["table"]
    if os.path.splitext(db_name)[1]:
        print "Don't specify an extension to the name, the program generates "\
            "the extension .sqlite"
        raise SCRIPT_END
    path = REL(user,db_name)+".sqlite"
    db = SQLite.Base(table,path)
    if "new" in kw: # new table
        # create info file
        csv.writer(open(REL(user,'%s_%s' %(db_name,table))+".txt","wb"))
        
    raise HTTP_REDIRECTION, \
        "edit_structure?db_name=%s&table=%s" %(quote_plus(db_name),table)
    
def drop_table(db,table):
    h_db = INPUT(Type="hidden",name="db",value=db)
    h_table = INPUT(Type="hidden",name="table",value=table)
    body = H2(db)
    body += "Are you sure you want to drop table %s ?" %table
    body += BR("This will erase all data in this table")+BR()

    line = TR()
    line <= TD() <= FORM(action="confirm_drop",method="post") <= \
        h_db + h_table + INPUT(Type="submit",value=_("Yes"))
    line <= TD() <= FORM(action="open_db",method="post") <= \
        h_db + INPUT(Type="submit",value=_("No"))

    print HTML(header+BODY(body+TABLE(line)))

def confirm_drop(db,table):
    db_name = unquote_plus(db)
    path = REL(user,'%s_%s' %(db_name,table))+".txt"
    os.remove(path)
    path = REL(user,'%s_%s' %(db_name,table))+".ks"
    if os.path.exists(path):
        os.remove(path)
    try:
        _table = SQLite.Table(table,REL(user,db_name+'.sqlite')).open()
        _table.drop()
    except IOError:
        pass
    raise HTTP_REDIRECTION,"open_db?db=%s" %db

def _get_fields(db_name,table):
    path = REL(user,'%s_%s' %(db_name,table))+".txt"
    reader = csv.DictReader(open(path),
            ['name','type','not_null','default','format'])
    return [ row for row in reader ]

def _save_fields(db_name,table,fields):
    path = REL(user,'%s_%s' %(db_name,table))+".txt"
    writer = csv.DictWriter(open(path,"w"),
                ['name','type','not_null','default','format'])
    for f in fields:
        writer.writerow(f)
        
def edit_structure(db_name,table):
    quoted = db_name
    db_name = unquote_plus(db_name)

    # hidden fields
    h_db = INPUT(Type="hidden",name="db_name",value=quoted)
    h_table = INPUT(Type="hidden",name="table",value=table)

    title = A("Home",href="index",target="_top")
    link = A(db_name,href="open_db?db=%s" %quoted,target="_parent")
    title += H3("Database %s - Table %s" %(link,table))

    db_fields = _get_fields(db_name,table)
    db = SQLite.Database(REL(user,db_name+'.sqlite'))
    
    if db.has_table(table):
        existing_fields = SQLite.Table(table,db).open().fields
    else:
        existing_fields = []

    uneditable_fields = [field for field in db_fields 
        if field['name'] in existing_fields]
    editable_fields = [field for field in db_fields 
        if not field['name'] in existing_fields]
        
    fields = TABLE()

    # other tables
    for ext_table in _reset_db(db_name):
        if not ext_table == table and not ext_table=="sqlite_sequence":
            types.append('external:%s' %ext_table)


    if uneditable_fields:
        fields <= TR() <= TD(B("Existing fields - can't be modified"),
                    colspan=6)
        fields <= TR() <= TH("Field name")+TH("Type")+ \
            TH("NOT NULL")+TH("DEFAULT")+TH("Format")+TD("&nbsp;")

        for num,field in enumerate(uneditable_fields):
            format = SELECT(name="format").from_list([field['type']]+formats[1:])
            format.select(content=field['format'])
            form = FORM(action="edit_field",method="post")
            form <= h_db + h_table
            form <= INPUT(Type="hidden",name="field_num",value=num)
            form <= INPUT(Type="hidden",name="existing",value="Yes")
            form <= INPUT(Type="hidden",name="field",value=field['name'])
            form <=  TR(TD(field['name'])+
                       TD(field['type'])+
                       TD(field['not_null'])+
                       TD(field['default'])+
                       TD(format)+
                       TD(INPUT(Type="submit",name="action",value="Update"))+
                       TD("&nbsp"))
            fields <= form
            
    if editable_fields:
        line = TR()
        line <= TD(colspan=3) <= B("Fields not yet saved in the database")
        line <= TD() <= SPAN(Class="save") <= \
            A(_("Save changes"),Class="save",
            href="save_changes?db_name=%s&table=%s" %(quoted,table))
        line <= TD("&nbsp;")*2

        fields <= line
        fields <= TR() <= TH("Field name")+TH("Type")+ \
            TH("NOT NULL")+TH("DEFAULT")+TH("Format")+TD('&nbsp;')

    for num,v in enumerate(editable_fields):
        f = v["name"]
        type_options = SELECT(name="typ").from_list(types)
        type_options.select(content=v["type"])

        line = TR()
        v["not_null"] = eval(v["not_null"]) # boolean
        not_null = SELECT(name="not_null").from_list(['False','True'])
        not_null.select(content=str(v['not_null']))
        format = SELECT(name="format").from_list(['default']+formats[1:])
        format.select(content=v['format'])
        line <= (TD(INPUT(name="field",value=f))
                + TD(type_options)
                + TD(not_null)
                + TD(INPUT(name="default",value=v["default"].replace('"','&quot;')))
                + TD(format)
                + TD(INPUT(Type="submit",name="action",value="Update"))
                + TD(INPUT(Type="submit",name="action",value="Drop"))
                )
        form = FORM(action="edit_field",method="post")
        form <= (h_db + h_table
               + INPUT(Type="hidden",name="field_num",
                    value=num+len(uneditable_fields))
               + INPUT(Type="hidden",name="existing",value="No")
               + line) 
        fields <= form

    # add new field
    fields <= TR(colspan=6) <= TD(BR()+B("Add new field"))
    fields <= TR() <= TH("Field name")+TH("Type")+ \
        TH("NOT NULL")+TH("DEFAULT")+TH("Format")+TD('&nbsp;')

    type_options = SELECT(name="typ").from_list(types)
    not_null = SELECT(name="not_null").from_list(['False','True'])
    format = SELECT(name="format").from_list(['default']+formats[1:])

    line = TR(
        TD(INPUT(name="field"))
        + TD(type_options)
        + TD(not_null)
        + TD(INPUT(name="default"))
        + TD(format)
        + TD(INPUT(Type="submit",value="Add"))
        )

    form = FORM(action="new_field",method="post") <= h_db+h_table+line

    fields <= form
    
    print HTML(header+BODY(title+fields))

def _bad_field_name(field):
    msg = "Invalid field name : <b>%s</b>" %field
    return HTML(HEAD(LINK(rel="stylesheet",href="../default.css"))+
        BODY(msg))

def new_field(db_name,table,field,not_null,typ,format,default=None):

    if not field_pattern.match(field):
        print _bad_field_name(field)
        raise SCRIPT_END
    db_name = unquote_plus(db_name)
    fields = _get_fields(db_name,table)

    for i,f in enumerate(fields):
        if f["name"]==field:
            print "Field %s already exists" %field
            raise SCRIPT_END

    typ = types[int(typ)]
    if int(format)==0:
        format = typ
    else:
        format = formats[int(format)]
    info = {"name":field,
                "type":typ,
                "not_null":bool(int(not_null)),
                "default":default,
                "format":format}
    fields.append(info)

    # update info file
    _save_fields(db_name,table,fields)
    # don't generate management script 
    # until changes are saved in the database
    
    raise HTTP_REDIRECTION,"edit_structure?db_name=%s&table=%s" \
        %(quote_plus(db_name),table)

def edit_field(**kw): 
# db_name,table,field,field_num,typ,not_null,default,format,action
    db_name = unquote_plus(kw['db_name'])
    table = kw['table']
    fields = _get_fields(db_name,table)
    field_num = int(kw['field_num'])
    action = kw['action']

    if action=="Drop":
        del fields[field_num]
    elif action=="Update":
        info = {}
        if 'field' in kw: info['name'] = kw['field']
        if 'typ' in kw: info['type'] = types[int(kw['typ'])]
        if 'not_null' in kw: info['not_null'] = \
            bool(int(kw['not_null']))
        if 'default' in kw: info['default'] = kw['default']
        if 'format' in kw: info['format'] = formats[int(kw['format'])]
        fields[field_num].update(info)
    elif action.startswith("Store"):
        # store field values in another database
        # in this db, replace values by index in the other database
        raise HTTP_REDIRECTION,"ext_store?db_name=%s&code=%s"\
            %(quote_plus(db_name),code)

    _save_fields(db_name,table,fields)    
    if kw['existing'] == 'Yes':
        # if field exists, update management script
        _gen_script(db_name,table)
    raise HTTP_REDIRECTION,"edit_structure?db_name=%s&table=%s" \
        %(quote_plus(db_name),table)

def _gen_script(db,table):
    # generate database management script
    
    fields = []
    for row in _get_fields(db,table):
        if row['type'].startswith('external'):
            row['type'] = 'INTEGER'
        fields.append("('%s','%s')" %(unicode(row["name"],'utf-8'),
            unicode(row["type"],'utf-8')))     
    params = {'db_name':"'%s.sqlite'" %db,'table':table,
        'table_fields':','.join(fields)}
    _in = unicode(open("generic.tmpl","rb").read(),'utf-8')
    ks = _in %params

    out = open(REL(user,'%s_%s' %(db,table))+".ks","wb")
    out.write(ks.encode('utf-8'))

    out.write('\nfield_info = [\n')
    for f in _get_fields(db,table):
        out.write("    ('%s',FieldInfo(typ='%s',not_null=%s,default='%s')),\n" 
            %(f['name'],f['type'],f['not_null'],
                f['default'].replace("'","\\'")))
    out.write("    ]\n")

    for f in _get_fields(db,table):
        out.write("\ndef entry_%s(val):\n" %f['name'])
        if f['format'] == 'DATE (YYYY-MM-DD)':
            cell = "    cell = INPUT(name='%(name)s',Id='%(name)s',value=val)\n"
            cell += '    cell += IMG(Id="%(name)s_button",\n'
            cell += '        src="../calendar.gif",\n'
            cell += '        onClick="calendar(this,\'YYYY-MM-DD\')" )\n'
            if f['not_null']=='True':
                cell += '    cell += FONT("*",color="red")\n'
            cell += '    return cell\n'
            out.write(cell %{'name':f['name']})
        elif f['type'].startswith("external:"):
            ext_table = f['type'][9:]
            ext_rows = _get_fields(db,ext_table)
            cell = "    val = val or 0\n"
            cell += "    ext_db = SQLite.Table('%s',db_path).open()\n" %ext_table
            cell += "    options = []\n"
            cell += "    for rec in ext_db:\n"
            cell += "        options.append(OPTION(rec['%s']," %ext_rows[0]['name']
            cell += "value=rec['__id__'],\n"
            cell += "            SELECTED=int(val)==rec['__id__']))\n"
            cell += "    return SELECT(Sum(options),name='%s')\n" %f['name']
            out.write(cell)
        else:
            out.write("    return INPUT(name='%s',Id='%s',value=val)"
                %(f['name'],f['name']))
            if f['not_null']=='True':
               out.write("+FONT('*',color='red')")
            out.write('\n')

    out.write('\nentry_widget={\n')
    for f in _get_fields(db,table):
        out.write("    '%s':entry_%s,\n" %(f['name'],f['name']))
    out.write('}\n\n')

    out.write("""
# entry widgets can be customized in a script
try:
    custom = Import('%s_custom.py',REL=REL,SQLite=SQLite)
    for fname in db.fields:
        if 'entry_%%s' %%fname in dir(custom):
            entry_widget[fname] = getattr(custom,'entry_%%s' %%fname)
except ImportError:
    pass
""" %db)

    _in = open("generic.ks","rb").read()
    out.write(_in)
    out.close()

def save_changes(db_name,table):
    quoted = db_name
    db_name = unquote_plus(db_name)
    db = SQLite.Database(REL(user,db_name+'.sqlite'))
    
    if db.has_table(table):
        existing_fields = SQLite.Table(table,db).open().fields
    else:
        existing_fields = []

    fields = _get_fields(db_name,table)
    if not existing_fields:
        # table not created yet
        create_args = []
        for row in fields:
            if row['type'].startswith('external'):
                row['type'] = 'INTEGER'
            arg = row['type']
            if row['not_null'] == 'False':
                arg += ' NOT NULL'
            if row['default']:
                arg += SQLite.to_SQLite(row['default'])
            create_args.append((row["name"],arg))     
        _table = SQLite.Table(table,db)
        _table.create(*create_args)
    else:
        new_fields = [field for field in fields 
            if not field['name'] in existing_fields]
        _table = SQLite.Table(table,REL(user,db_name+'.sqlite')).open()
        for new_field in new_fields:
            _table.add_field((new_field['name'],new_field['type']))
    _gen_script(db_name,table)
    raise HTTP_REDIRECTION,"edit_structure?db_name=%s&table=%s" \
        %(quoted,table)

def ext_store(db_name,code):
    # store values for code in another database
    db_name = unquote_plus(db_name)
    print HEAD(LINK(rel="stylesheet",href="../default.css"))
    path = REL(user,db_name)+".pdl"
    db = SQLite.Base(path).open()
    infos = cPickle.load(open(REL(user,db_name)+"_infos.dat"))
    fields = infos["fields"]
    print "store values of field",code
    name = [ f["name"] for f in fields if f["code"]==code ][0]
    line = TD("Database name")
    line += INPUT(name="newdb_name",value=name)
    line += INPUT(Type="hidden",name="db_name",value=quote_plus(db_name))
    line += INPUT(Type="hidden",name="code",value=code)
    line += INPUT(Type="submit",value="Ok")
    print FORM(line,action="ext_store1",method="post")

def ext_store1(db_name,code,newdb_name):
    db_name = unquote_plus(db_name)
    print HEAD(LINK(rel="stylesheet",href="../default.css"))
    path = REL(user,db_name)+".pdl"
    db = SQLite.Base(path).open()
    infos = cPickle.load(open(REL(user,db_name)+"_infos.dat"))
    fields = infos["fields"]

    # compatibility with Python 2.3    
    try:
        set([])
    except NameError:
        from sets import Set as set
    
    vals = list(set([r[code] for r in db]))
    # map values to index in vals, will be the same as recid in new db
    val_dict = dict([(v,i) for i,v in enumerate(vals)])

    # store values in new db    
    newpath = REL(user,newdb_name)+".pdl"
    try:
        newdb = SQLite.Base(newpath).create("value")
    except IOError:
        print H2("Error"),"A base with this name already exists"
        raise SCRIPT_END

    for val in vals:
        newdb.insert(val)

    newdb.commit()

    # create info file for new db
    new_fields = [{"code":"value","name":"value","type":"integer",
        "not_null":True,"default":""}]
    new_form = {"value":{"widget":"input"}}
    info_file = open(REL(user,newdb_name+"_infos.dat"),"wb")
    cPickle.dump({"fields":new_fields,"form":new_form,"views":{}},info_file)
    info_file.close()

    # update type in info file
    ix,field = [(i,f) for (i,f) in enumerate(fields) if f["code"]==code][0]
    fields[ix]["type"] = "external "+newdb_name
    infos["fields"] = fields
    info_file = open(REL(user,db_name+"_infos.dat"),"wb")
    cPickle.dump(infos,info_file)
    info_file.close()

    # replace values in original db by record id in new db
    for r in db:
        db.update(r,**{code:val_dict[r[code]]})

    db.commit()
    
    print "Field %s had %s different values for %s records" %(field["name"],
        len(newdb),len(db))
    
def layout(db):
    path = os.path.join(CWD,user,db)+".pdl"
    pydb = SQLite.Base(path).open()
    db_name = os.path.splitext(os.path.basename(pydb.name))[0]
    menu.menu(db_name,"index.ks/layout")
    print pydb.fields
    