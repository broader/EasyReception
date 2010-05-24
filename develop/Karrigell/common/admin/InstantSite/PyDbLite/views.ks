import cPickle
from urllib import quote_plus,unquote_plus

from HTMLTags import *

import PyDbLite
utils = Import("utils")
ext_dbs = utils.ext_dbs

Login(role=["admin","edit"],add_user=True)

user = COOKIE['login'].value

def views(db_name):
    db_name = unquote_plus(db_name)
    print HEAD(LINK(rel="stylesheet",href="../default.css"))
    # open views file
    infos = cPickle.load(open(REL(user,db_name)+"_infos.dat"))
    views = infos["views"]
    title = H2("Views")
    lines = []
    for view in views:
        line = TD(H4(view))
        line += TD(A("Edit",href="edit_view?db_name=%s&view=%s"
            %(quote_plus(db_name),view)))
        line += TD(A("Show",href="show_view?db_name=%s&view=%s"
            %(quote_plus(db_name),view)))
        lines.append(TR(line))
    lines = TABLE(Sum(lines))

    lines += BR(FORM(INPUT(Type="hidden",name="db_name",
        value=quote_plus(db_name))+
        INPUT(name="view")+
        INPUT(Type="submit",name="new",value="New view"),
        action="edit_view"))
    print BODY(title + lines)
        
def edit_view(**kw):
    print HEAD(LINK(rel="stylesheet",href="../default.css"))
    view = kw["view"]
    db_name = unquote_plus(kw["db_name"])

    if "new" in kw:
        print H2("New view")
    else:
        print H2("View %s" %view)

    infos = cPickle.load(open(REL(user,kw["db_name"])+"_infos.dat"))
    views = infos["views"]
    requests = infos["requests"]
    fields = infos["fields"]

    view_fields = views.get(view,[])
    request = ""
    if view_fields:
        request = view_fields.pop(0)

    info = INPUT(Type="hidden",name="db_name",value=quote_plus(db_name))
    info += INPUT(Type="hidden",name="view",value=view)

    req_line = H3("Associated request")
    req_line += SELECT(Sum([OPTION(req,value=req,selected=req==request)
        for req in requests]),name="request")
    req_line += INPUT(Type="submit",name="subm",value="Update")
    
    # show already selected fields, propose to delete them
    del_fields = H3("Fields")
    cells = []
    for view_field in view_fields:
        field = [ f for f in fields if f["code"] == view_field ][0]
        cells.append( TD(field["name"])+
            TD( INPUT(Type="hidden",name="del_code",value=field["code"])+
                INPUT(Type="submit",name="subm",value="Delete")
                ))
    del_fields += TABLE(Sum([TR(cell) for cell in cells]))
    db_fields = infos["fields"]

    # can only add view_fields which are not already in the view
    remaining_fields = [f for f in db_fields if not f in view_fields]
    if remaining_fields:
        add_field = SELECT(Sum([
            OPTION(field["name"],value=field["code"]) 
                for field in remaining_fields ]),
            name="code")
        add_field += INPUT(Type="submit",name="subm",value="Add")
    else:
        add_field = TEXT("")
    print BODY(FORM(info+req_line+del_fields+P()+add_field,
        action="edit_view1"))

def edit_view1(**kw):
    db_name,view,request = unquote_plus(kw["db_name"]),kw["view"],kw["request"]
    action = kw["subm"]
    if action == "Add":
        _add_field(db_name,view,request,kw["code"])
    elif action == "Delete":
        _del_field(db_name,view,request,kw["del_code"])
    elif action == "Update":
        _update_request(db_name,view,request)
    raise HTTP_REDIRECTION,"edit_view?db_name=%s&view=%s" \
        %(quote_plus(db_name),view)

def _add_field(db_name,view,request,code):
    infos = cPickle.load(open(REL(user,db_name)+"_infos.dat"))
    views = infos["views"]
    view_fields = views.get(view,[])
    if not view_fields:
        view_fields = [request,code]
    else:
        view_fields.pop(0)
        view_fields = [request]+view_fields+[code]
    views[view] = view_fields
    infos["views"] = views
    cPickle.dump(infos,open(REL(user,db_name)+"_infos.dat","wb"))

def _del_field(db_name,view,request,del_code):
    infos = cPickle.load(open(REL(user,db_name)+"_infos.dat"))
    views = infos["views"]
    fields = views[view]
    fields.pop(0)
    fields.remove(del_code)
    views[view] = [request]+fields
    infos["views"] = views
    cPickle.dump(infos,open(REL(user,db_name)
        +"_infos.dat","wb"))

def _update_request(db_name,view,request):
    infos = cPickle.load(open(REL(user,db_name)+"_infos.dat"))
    views = infos["views"]
    fields = views[view]
    fields.pop(0)
    views[view] = [request]+fields
    infos["views"] = views
    cPickle.dump(infos,open(REL(user,db_name)+"_infos.dat","wb"))

def show_view(db_name,view):
    print HEAD(LINK(rel="stylesheet",href="../default.css"))
    path = REL(user,db_name)+".pdl"
    db = PyDbLite.Base(path).open()
    infos = cPickle.load(open(REL(user,db_name)+"_infos.dat"))
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
        lines += TR(Sum([TD(utils.get_val(external_dbs,field,value)) 
            for (field,value) in zip(view_fields,record)]))
    print TABLE(lines)

