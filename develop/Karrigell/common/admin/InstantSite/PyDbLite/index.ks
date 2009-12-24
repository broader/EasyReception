# -*- coding: iso-8859-1 -*-
import os
import cPickle
from urllib import quote_plus,unquote_plus
import PyDbLite
from HTMLTags import *

ext_dbs = Import("utils").ext_dbs

check_type = Import("check_type")

def index():
    print HEAD(LINK(rel="stylesheet",href="../default.css"))
    existing = [ db for db in os.listdir(REL("applications"))
        if db.endswith(".pdl") ]
    lines = [A(_("Admin"),href="/admin")]
    lines += [H3("PyDbLite management")]
    if existing:
        lines += [TEXT("Existing databases")]
    lines += [BR(A(db,
        href="edit?db=%s" %quote_plus(os.path.splitext(db)[0]))) 
        for db in existing]
    lines += [FORM(TEXT("New database - don't specify any extension")+
        INPUT(name="db")+
        INPUT(Type="submit",name="new",value="Ok"),
        action="edit",method="post")]
    lines += [A("Create new base from CSV file",href="../import")]
    print BODY(Sum(lines))

def edit(**kw):

    db_name = unquote_plus(kw["db"])
    if os.path.splitext(db_name)[1]:
        print "Don't specify an extension to the name, the program generates "\
            "the extension .pdl"
        raise SCRIPT_END
    path = REL("applications",db_name)+".pdl"
    db = PyDbLite.Base(path)
    if "new" in kw: # new database
        # create database
        db.create()
        db.commit()
        # create info file
        info_file = open(REL("applications",db_name)+"_infos.dat","wb")
        cPickle.dump({"fields":[],"form":{},"requests":{},"views":{}},info_file)
        info_file.close()

    print FRAMESET(FRAME(name="menu",src="menu?db_name=%s" %quote_plus(db_name))+
        FRAME(name="panel",src="empty"),rows="10%,*")

def menu(db_name):
    # if database and info file exist, check if management script also exists
    # may not be the case for a database created from a CSV file
    db_name = unquote_plus(db_name)
    if not os.path.exists(REL("applications",db_name+".ks")):
        _gen_script(db_name)
    print HEAD(LINK(rel="stylesheet",href="../default.css"))
    line = TD(A("Home",href="index",target="_top"))
    line += TD(B("Database %s" %db_name))
    line += TD(A("Edit records",
        href="../applications/%s.ks" %quote_plus(db_name),
        target="panel"))
    line += TD(A("Database structure",
        href="edit_structure?db_name=%s" %quote_plus(db_name),
        target="panel"))
    line += TD(A("Form",
        href="../form.py?db_name=%s" %quote_plus(db_name),
        target="_blank"))
    line += TD(A("Requests",
        href="../requests.ks/requests?db_name=%s" %quote_plus(db_name),
        target="panel"))
    line += TD(A("Views",href="../views.ks/views?db_name=%s" %quote_plus(db_name),
        target="panel"))

    infos = cPickle.load(open(REL("applications",db_name)
        +"_infos.dat"))
    views = infos["views"]
    for view in views:
        line += TD(A(view,href="show_view?db_name=%s&view=%s" 
            %(quote_plus(db_name),view),target="panel"))

    print BODY(TABLE(TR(line)))

def empty():
    pass

def edit_structure(db_name):
    db_name = unquote_plus(db_name)
    print HEAD(LINK(rel="stylesheet",href="../default.css"))
    infos = cPickle.load(open(REL("applications",db_name)
        +"_infos.dat"))
    db_fields = infos["fields"]

    fields = [TR(TH("Current fields",colspan=6))]
    fields += [TR(TH("Field name")+TH("Type")+
        TH("Allow empty")+TH("Default value")+TD(" "))]
    for v in db_fields:
        f = v["name"]
        if v["type"].startswith("external"):
            type_options = SELECT(
                    Sum([OPTION(v["type"],value=v["type"],selected=True)]+
                    [OPTION(typ,value=typ) for typ in check_type.types]),
                    name="typ")
        else:
            type_options = SELECT(Sum([OPTION(typ,value=typ,selected=typ==v["type"]) 
                    for typ in check_type.types]),name="typ")
        line = TR(TD(f)+
               TD(type_options)+
               TD(SELECT(OPTION("Yes",value=1,selected=v["allow_empty"])+
                         OPTION("No",value=0,selected=not v["allow_empty"]),
                name="allow_empty"))+
               TD(INPUT(name="default",value=v["default"]))+
               TD(INPUT(Type="submit",name="action",value="Update"))+
               TD(INPUT(Type="submit",name="action",value="Drop"))+
               TD(INPUT(Type="submit",name="action",
                value="Store in other database...")))
        fields += [FORM(
            INPUT(Type="hidden",name="db_name",value=quote_plus(db_name))+
            INPUT(Type="hidden",name="code",value=v["code"])+ line,
            action="edit_field",method="post")]
    fields += [TR(TH("Add new field",colspan=6))]
    fields += [TR(TH("Field name")+TH("Type")+
        TH("Allow empty")+TH("Default value")+TD(" "))]
    new_field = FORM(
            INPUT(Type="hidden",name="db_name",value=quote_plus(db_name))+
            TR(TD(INPUT(name="field"))+
               TD(SELECT(Sum([OPTION(typ,value=typ,selected=typ=="string") 
                for typ in check_type.types]),name="typ"))+
               TD(SELECT(OPTION("Yes",value=1)+OPTION("No",value=0),
                name="allow_empty"))+
               TD(INPUT(name="default"))+
               TD(INPUT(Type="submit",value="Add"))),
                action="new_field",method="post")
    fields += [new_field]

    lines = [H2("Editing base %s" %db_name)]
    lines += [TABLE(Sum(fields))]
    
    print BODY(Sum(lines))

def _make_code(fields,field_name):
    # generate a db field name for the field
    if not fields:
        return "f1"
    ix = max([int(v["code"][1:]) for v in fields])
    return "f%s" %(ix+1)

def new_field(field,db_name,allow_empty,typ,default=None):
    # update info file
    db_name = unquote_plus(db_name)
    infos = cPickle.load(open(REL("applications",db_name)
        +"_infos.dat"))
    fields = infos["fields"]
    ix = None
    for i,f in enumerate(fields):
        if f["name"]==field:
            ix = i
            break
    code = _make_code(fields,field)
    if ix is None:
        fields.append({"name":field,
                "code":code,
                "type":typ,"allow_empty":bool(int(allow_empty)),
                "default":default})
    else:
        fields[ix].update({"code":code,
        "type":typ,"allow_empty":bool(int(allow_empty)),
        "default":default})
    infos["fields"] = fields
    form = {"widget":"input"}
    if typ == "date":
        form.update({"popup":True,"dsep":0,"dord":0})
    infos["form"][code] = form
    cPickle.dump(infos,open(REL("applications",db_name)
        +"_infos.dat","wb"))

    # update database
    path = REL("applications",db_name)+".pdl"
    pydb = PyDbLite.Base(path).open()
    pydb.add_field(code,default=default)
    
    # generate script and redirect
    _gen_script(db_name)
    raise HTTP_REDIRECTION,"edit_structure?db_name=%s" %quote_plus(db_name)

def edit_field(code,db_name,typ,allow_empty,default,action):
    db_name = unquote_plus(db_name)
    infos = cPickle.load(open(REL("applications",db_name)
        +"_infos.dat"))
    fields = infos["fields"]
    form = infos["form"]
    ix,field = [ (i,f) for i,f in enumerate(fields)
        if f["code"]==code ][0]

    if action=="Drop":
        del fields[ix]
        del form[field["code"]]
        path = REL("applications",db_name)+".pdl"
        # update database
        pydb = PyDbLite.Base(path).open()
        pydb.drop_field(code)
    elif action=="Update":
        fields[ix].update({"type":typ,
            "allow_empty":bool(int(allow_empty)),
            "code":code,
            "default":default})
        if typ=="date":
            form[field["code"]] = {"popup":True,"dsep":0,"dord":0}
    elif action.startswith("Store"):
        # store field values in another database
        # in this db, replace values by index in the other database
        raise HTTP_REDIRECTION,"ext_store?db_name=%s&code=%s"\
            %(quote_plus(db_name),code)
    infos["fields"] = fields
    infos["form"] = form
    cPickle.dump(infos,open(REL("applications",db_name)
        +"_infos.dat","wb"))
    
    _gen_script(db_name)
    raise HTTP_REDIRECTION,"edit_structure?db_name=%s" %quote_plus(db_name)

def _gen_script(db):
    # generate database management script
    path = os.path.join(CWD,"applications",db)+".pdl"
    pydb = PyDbLite.Base(path).open()

    params = {'db_name':'"%s"' %db,
        'db_fields':','.join(['"%s"' %name for name in pydb.fields]),
        'db_engine':'PyDbLite'}
    _in = open("generic.tmpl","rb").read()
    ks = _in %params

    out = open(os.path.join(CWD,"applications",db)+".ks","wb")
    out.write(ks)
    _in = open("generic.ks","rb").read()
    out.write(_in)
    out.close()

def ext_store(db_name,code):
    # store values for code in another database
    db_name = unquote_plus(db_name)
    print HEAD(LINK(rel="stylesheet",href="../default.css"))
    path = REL("applications",db_name)+".pdl"
    db = PyDbLite.Base(path).open()
    infos = cPickle.load(open(REL("applications",db_name)+"_infos.dat"))
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
    path = REL("applications",db_name)+".pdl"
    db = PyDbLite.Base(path).open()
    infos = cPickle.load(open(REL("applications",db_name)+"_infos.dat"))
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
    newpath = REL("applications",newdb_name)+".pdl"
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
    info_file = open(REL("applications",newdb_name+"_infos.dat"),"wb")
    cPickle.dump({"fields":new_fields,"form":new_form,"views":{}},info_file)
    info_file.close()

    # update type in info file
    ix,field = [(i,f) for (i,f) in enumerate(fields) if f["code"]==code][0]
    fields[ix]["type"] = "external "+newdb_name
    infos["fields"] = fields
    info_file = open(REL("applications",db_name+"_infos.dat"),"wb")
    cPickle.dump(infos,info_file)
    info_file.close()

    # replace values in original db by record id in new db
    for r in db:
        db.update(r,**{code:val_dict[r[code]]})

    db.commit()
    
    print "Field %s had %s different values for %s records" %(field["name"],
        len(newdb),len(db))
    
def _get_val(ext,key,value):
    if not key in ext:
        return value
    else:
        return ext[key][value]["value"]

def show_view(db_name,view):
    print HEAD(LINK(rel="stylesheet",href="../default.css"))
    path = REL("applications",db_name)+".pdl"
    db = PyDbLite.Base(path).open()
    infos = cPickle.load(open(REL("applications",db_name)+"_infos.dat"))
    fields = infos["fields"]
    field_ix = dict([(f["code"],i) for i,f in enumerate(fields)])
    views = infos["views"]
    requests = infos["requests"]
    view_fields = views[view]
    request = view_fields.pop(0)
    conditions = requests[request]
    query = []

    external_dbs = ext_dbs(REL,fields)

    for condition in conditions:
        key,op,val = condition
        
        if op == "=":
            op = "=="
        try:
            int(val)
        except ValueError:
            val = '"%s"' %val.replace('"','\\"')
        if key in external_dbs:
            query.append('external_dbs["%s"][r["%s"]]["value"] %s %s' 
                %(key,key,op,val))
        else:
            query.append('r["%s"] %s %s' %(key,op,val))
    qs = " and ".join(query)

    results = ",".join(['r["%s"]' %f for f in view_fields])
    
    expr = "res = [ ["+results+"] for r in db "
    if qs:
        expr += "if "+qs
    expr += ']'
    exec(expr)

    lines = TR(Sum([TH(fields[field_ix[field]]["name"]) 
        for field in view_fields]))
    print len(res),"records"
    for record in res:
        lines += TR(Sum([TD(_get_val(external_dbs,field,value)) 
            for (field,value) in zip(view_fields,record)]))
    print TABLE(lines)

def layout(db):
    path = os.path.join(CWD,"applications",db)+".pdl"
    pydb = PyDbLite.Base(path).open()
    db_name = os.path.splitext(os.path.basename(pydb.name))[0]
    menu.menu(db_name,"index.ks/layout")
    print pydb.fields
    