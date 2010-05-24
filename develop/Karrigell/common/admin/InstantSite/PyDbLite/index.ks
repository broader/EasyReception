# -*- coding: iso-8859-1 -*-
import os
import re
from urllib import quote_plus,unquote_plus
import csv

import PyDbLite
from HTMLTags import *

Login(role=["admin","edit"],add_user=True)

user = COOKIE['login'].value

if not os.path.exists(REL(user)):
    # new user
    os.mkdir(REL(user))
    import shutil
    for fname in os.listdir(REL("applications")):
        if fname.startswith('.'):
            continue
        shutil.copyfile(REL("applications",fname),REL(user,fname))

utils = Import('utils')
ext_dbs = utils.ext_dbs

field_pattern = re.compile('^[_a-zA-Z]\w*$')

check_type = Import("check_type")

def index():
    print HEAD(LINK(rel="stylesheet",href="../default.css"))
    existing = [ db for db in os.listdir(REL(user))
        if db.endswith(".pdl") ]
    lines = [A(_("Home"),href="/")]
    lines += [H3("PyDbLite management")]
    if existing:
        lines += [TEXT("Existing databases")]
    lines += [BR(A(db,
        href="manager?db_name=%s" %quote_plus(os.path.splitext(db)[0]))) 
        for db in existing]
    lines += [FORM(TEXT("New database - don't specify any extension")+
        INPUT(name="db")+
        INPUT(Type="submit",value="Ok"),
        action="create",method="post")]
    lines += [A("Create new base from CSV file",href="../import")]
    print BODY(Sum(lines))

def create(**kw):

    db_name = unquote_plus(kw["db"])
    if os.path.splitext(db_name)[1]:
        print "Don't specify an extension to the name, the program generates "\
            "the extension .pdl"
        raise SCRIPT_END
    path = REL(user,db_name)+".pdl"
    db = PyDbLite.Base(path)
    # create database
    db.create()
    db.commit()
    # create info file
    csv.writer(open(REL(user,db_name)+".txt","wb"))
    print "New database %s created" %path
    print BR()+A('Manage',href='manager?db_name=%s' %kw["db"])

def manager(db_name):
    print FRAMESET(FRAME(name="menu",src="menu?db_name=%s" %db_name)+
        FRAME(name="panel",src="empty"),rows="10%,*")

def menu(db_name):
    # if database and info file exist, check if management script also exists
    # may not be the case for a database created from a CSV file
    db_name = unquote_plus(db_name)
    if not os.path.exists(REL(user,db_name+".ks")):
        _gen_script(db_name)
    print HEAD(LINK(rel="stylesheet",href="../default.css"))
    line = TD(A("Home",href="index",target="_top"))
    line += TD(B("Database %s" %db_name))
    line += TD(A("Edit records",
        href="../%s/%s.ks" %(user,quote_plus(db_name)),
        target="panel"))
    line += TD(A("Database structure",
        href="edit_structure?db_name=%s" %quote_plus(db_name),
        target="panel"))

    print BODY(TABLE(TR(line)))

def empty():
    pass

def _get_fields(db_name):
    reader = csv.DictReader(open(REL(user,db_name)+".txt"),
        ['name','type','allow_empty','default'])
    return [ row for row in reader ]    

def _save_fields(db_name,fields):
    writer = csv.DictWriter(open(REL(user,db_name)+".txt","w"),
                ['name','type','allow_empty','default'])
    for f in fields:
        writer.writerow(f)
        
def edit_structure(db_name):
    db_name = unquote_plus(db_name)
    print HEAD(LINK(rel="stylesheet",href="../default.css"))

    db_fields = _get_fields(db_name)
    ex_fields = [TR(TH("Current fields",colspan=6))]
    ex_fields += [TR(TH("Field name")+TH("Type")+
        TH("Allow empty")+TH("Default value")+TD(" "))]

    # external dbs
    types = check_type.types.keys()
    for filename in os.listdir(REL(user)):
        name,ext = os.path.splitext(filename)
        if ext.lower() == '.pdl' and not name==db_name:
            types.append('external:%s' %filename)

    for num,v in enumerate(db_fields):
        f = v["name"]
        type_options = SELECT(Sum([OPTION(typ,value=typ,selected=typ==v["type"]) 
                for typ in types]),name="typ")
        line = TR(TD(INPUT(name="field",value=f))+
               TD(type_options)+
               TD(SELECT(OPTION("Yes",value=1,selected=v["allow_empty"]=='True')+
                         OPTION("No",value=0,selected=v["allow_empty"]=='False'),
                name="allow_empty"))+
               TD(INPUT(name="default",value=v["default"].replace('"','&quot;')))+
               TD(INPUT(Type="submit",name="action",value="Update"))+
               TD(INPUT(Type="submit",name="action",value="Drop"))+
               TD(INPUT(Type="submit",name="action",
                value="Store in other database...")))
        ex_fields += [FORM(
            INPUT(Type="hidden",name="db_name",value=quote_plus(db_name))+
            INPUT(Type="hidden",name="field_num",value=num)+
            line,action="edit_field",method="post")]

    add_fields = [TR(TH("Add new field",colspan=6))]
    add_fields += [TR(TH("Field name")+TH("Type")+
        TH("Allow empty")+TH("Default value")+TD(" "))]
    new_field = FORM(
            INPUT(Type="hidden",name="db_name",value=quote_plus(db_name))+
            TR(TD(INPUT(name="field"))+
               TD(SELECT(Sum([OPTION(typ,value=typ,selected=typ=="string") 
                for typ in types]),name="typ"))+
               TD(SELECT(OPTION("Yes",value=1)+OPTION("No",value=0),
                name="allow_empty"))+
               TD(INPUT(name="default"))+
               TD(INPUT(Type="submit",value="Add"))),
                action="new_field",method="post")
    add_fields += [new_field]

    lines = [H2("Editing base %s" %db_name)]
    if db_fields:
        lines += [TABLE(Sum(ex_fields+add_fields))]
    else:
        lines += [TABLE(Sum(add_fields))]
    print BODY(Sum(lines))

def _bad_field_name(field):
    msg = "Invalid field name : <b>%s</b>" %field
    return HTML(HEAD(LINK(rel="stylesheet",href="../default.css"))+
        BODY(msg))

def new_field(field,db_name,allow_empty,typ,default=None):

    if not field_pattern.match(field):
        print _bad_field_name(field)
        raise SCRIPT_END
    db_name = unquote_plus(db_name)
    fields = _get_fields(db_name)

    ix = None
    for i,f in enumerate(fields):
        if f["name"]==field:
            ix = i
            break
    if ix is None:
        fields.append({"name":field,
                "type":typ,"allow_empty":bool(int(allow_empty)),
                "default":default})
    else:
        fields[ix].update({"type":typ,
            "allow_empty":bool(int(allow_empty)),
            "default":default})

    # update info file
    _save_fields(db_name,fields)

    # update database
    path = REL(user,db_name)+".pdl"
    pydb = PyDbLite.Base(path).open()
    pydb.add_field(field,default=default)
    
    # generate script and redirect
    _gen_script(db_name)
    raise HTTP_REDIRECTION,"edit_structure?db_name=%s" %quote_plus(db_name)

def edit_field(db_name,field,field_num,typ,allow_empty,default,action):
    db_name = unquote_plus(db_name)
    fields = _get_fields(db_name)
    field_num = int(field_num)

    if action=="Drop":
        del fields[field_num]
        path = REL(user,db_name)+".pdl"
        # update database
        pydb = PyDbLite.Base(path).open()
        pydb.drop_field(pydb.fields[field_num])
    elif action=="Update":
        fields[field_num].update({"name":field,
            "type":typ,
            "allow_empty":bool(int(allow_empty)),
            "default":default})
    elif action.startswith("Store"):
        # store field values in another database
        # in this db, replace values by index in the other database
        raise HTTP_REDIRECTION,"ext_store?db_name=%s&code=%s"\
            %(quote_plus(db_name),code)

    _save_fields(db_name,fields)    
    _gen_script(db_name)
    raise HTTP_REDIRECTION,"edit_structure?db_name=%s" %quote_plus(db_name)

def _gen_script(db):
    # generate database management script
    path = os.path.join(CWD,user,db)+".pdl"
    pydb = PyDbLite.Base(path).open()

    params = {'db_name':'"%s"' %db,
        'db_fields':','.join(['"%s"' %name for name in pydb.fields]),
        'db_engine':'PyDbLite'}
    _in = open("generic.tmpl","rb").read()
    ks = _in %params

    out = open(os.path.join(CWD,user,db)+".ks","wb")
    out.write(ks)

    out.write('\nfield_info = [\n')
    for f in _get_fields(db):
        out.write("    ('%s',FieldInfo(typ='%s',allow_empty=%s,default='%s')),\n" 
            %(f['name'],f['type'],f['allow_empty'],
                f['default'].replace("'","\\'")))
    out.write("    ]\n")

    for i,f in enumerate(_get_fields(db)):
        out.write("\ndef entry_%s(val):\n" %i)
        out.write('    if val is None:\n')
        out.write("        val = '%s'\n" %f['default'])
        if f['type'] in ['string','float','integer']:
            cell = "    cell = INPUT(name='%s',Id='%s',value=val)\n" \
                %(f['name'],f['name'])
            if f['allow_empty']=='False':
                cell += "    return cell + '*'\n"
            else:
                cell += "    return cell\n"
            out.write(cell)
        elif f['type'] == 'date':
            cell = "    cell = INPUT(name='%(name)s',Id='%(name)s',value=val)\n"
            cell += '    cell += IMG(Id="%(name)s_button",\n'
            cell += '        src="../calendar.gif",\n'
            cell += '        onClick="calendar(this,\'DD/MM/YYYY\')" )\n'
            if f['allow_empty']=='False':
                cell += "    return cell + '*'\n"
            else:
                cell += "    return cell\n"
            out.write(cell %{'name':f['name']})
        elif f['type'].startswith("external:"):
            ext_db_name = f['type'][9:]
            ext_db_fields = PyDbLite.Base(REL(user,ext_db_name)).open().fields
            cell = "    val = val or 0\n"
            cell += "    ext_db = PyDbLite.Base(REL('%s')).open()\n" %ext_db_name
            cell += "    options = []\n"
            cell += "    for rec in ext_db:\n"
            cell += "        options.append(OPTION(rec['%s']," %ext_db_fields[0]
            cell += "value=rec['__id__'],\n"
            cell += "            SELECTED=int(val)==rec['__id__']))\n"
            cell += "    return SELECT(Sum(options),name='%s')\n" %f['name']
            out.write(cell)

    out.write('\nentry_widget={\n')
    for i,f in enumerate(_get_fields(db)):
        out.write("    '%s':entry_%s,\n" %(f['name'],i))
    out.write('}\n\n')

    out.write("""
# entry widgets can be customized in a script
try:
    custom = Import('%s_custom.py',REL=REL,PyDbLite=PyDbLite)
    for i,fname in enumerate(db.fields):
        if 'entry_%%s' %%i in dir(custom):
            entry_widget[fname] = getattr(custom,'entry_%%s' %%i)
except ImportError:
    pass
""" %db)

    _in = open("generic.ks","rb").read()
    out.write(_in)
    out.close()

def ext_store(db_name,code):
    # store values for code in another database
    db_name = unquote_plus(db_name)
    print HEAD(LINK(rel="stylesheet",href="../default.css"))
    path = REL(user,db_name)+".pdl"
    db = PyDbLite.Base(path).open()
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
    db = PyDbLite.Base(path).open()
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
        newdb = PyDbLite.Base(newpath).create("value")
    except IOError:
        print H2("Error"),"A base with this name already exists"
        raise SCRIPT_END

    for val in vals:
        newdb.insert(val)

    newdb.commit()

    # create info file for new db
    new_fields = [{"code":"value","name":"value","type":"integer",
        "allow_empty":True,"default":""}]
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
    pydb = PyDbLite.Base(path).open()
    db_name = os.path.splitext(os.path.basename(pydb.name))[0]
    menu.menu(db_name,"index.ks/layout")
    print pydb.fields
    