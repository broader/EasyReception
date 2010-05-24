"""
Edit form to edit records
Information is stored in a dictionary indexed by database field codes
For each field in the database, the information is the widget type
and attributes (size for INPUT, rows, cols for TEXTAREA)
For date fields, also stores the date format (DDMMYYYY etc.) and a
flag to indicate if a popup calendar should be displayed
"""
import cPickle
from HTMLTags import *

Login(role=["admin","edit"],add_user=True)
user = COOKIE['login'].value

import date_formats
day = _('DD')
month = _('MM')
year = _('YYYY')

def index(db_name,code):
    print HEAD(LINK(rel="stylesheet",href="../default.css")+
        SCRIPT(src="../edit_form.js"))
    infos = cPickle.load(open(REL(user,db_name)
        +"_infos.dat"))
    fields = infos["fields"]
    form = infos["form"]
    field = [ f for f in fields if f["code"]==code ][0]
    typ = field["type"]
    form_opts = form[field["code"]]
    lines = TR(TD(H3(field["name"]),colspan=2))
    lines += TR(TH("Type")+TD(typ))
    if typ=="string":
        lines += _edit_string(db_name,code)
    elif typ=="date":
        lines += _edit_date(db_name,code)
    lines += INPUT(Type="hidden",name="db_name",value=db_name)
    lines += INPUT(Type="hidden",name="code",value=code)
    print BODY(FORM(TABLE(lines,id="stringoptions")+INPUT(Type="submit",value="Update"),
        action="update",method="post"),
        onLoad="preview('%s')" %db_name)

def _edit_string(db_name,code):
    infos = cPickle.load(open(REL(user,db_name)
        +"_infos.dat"))
    fields = infos["fields"]
    field = [ f for f in fields if f["code"]==code ][0]
    form = infos["form"].get(field["code"],{})
    widget = form.get("widget","input")
    line = TR(TH("Widget")+
              TD(SELECT(
                OPTION("input",value="input",
                    selected=widget=="input")+
                OPTION("textarea",value="textarea",
                    selected=widget=="textarea"),
                  onChange="string_widget(this)",
                  name="widget",id="widget")))
    if widget == "input":
        line += TR(TD("size")+TD(INPUT(name="size",value=form.get("size",5))),
            id="attr1")
    elif widget == "textarea":
        line += TR(TD(TEXT("rows"))+
                TD(INPUT(name="rows",value=form.get("rows",10))),id="attr1")
        line += TR(TD(TEXT("cols"))+
                TD(INPUT(name="cols",value=form.get("cols",60))),id="attr2")
    return line

def _edit_date(db_name,code):
    infos = cPickle.load(open(REL(user,db_name)
        +"_infos.dat"))
    fields = infos["fields"]
    field = [ f for f in fields if f["code"]==code ][0]
    form = infos["form"].get(field["code"],{})

    line = TR(TH("Order")+
              TD(SELECT(Sum(
                [OPTION(df,value=i,selected=form.get("dord",-1)==i) 
                    for i,df in enumerate(date_formats.date_abr)]),
                width=15,name="dord")))
    line += TR(TH("Separator")+
               TD(SELECT(Sum([OPTION(df,value=i,selected=form.get("dsep",-1)==i) 
               for i,df in enumerate(date_formats.date_seps)]),
                name="dsep")))
    popup = form.get("popup",True)
    line += TR(TH("Calendar pop-up ?")+
        TD(TEXT("Yes")+INPUT(Type="radio",name="popup",value=1,checked=popup)+BR()+
           TEXT("No")+INPUT(Type="radio",name="popup",value=0,checked=not popup)))
    line += INPUT(Type="hidden",name="widget",value="input")
    return line

def update(**kw):
    db_name = kw["db_name"]
    code = kw["code"]
    del kw["db_name"]
    del kw["code"]
    infos = cPickle.load(open(REL(user,db_name)
        +"_infos.dat"))
    fields = infos["fields"]
    form = infos["form"]
    field = [ f for f in fields if f["code"]==code ][0]
    typ = field["type"]
    if typ=="string":
        form[code] = kw
    elif typ=="date":
        form[code] = {"widget":"input",
                       "dord":int(kw["dord"]),
                       "dsep":int(kw["dsep"]),
                       "popup":bool(int(kw["popup"]))
                       }
    infos["form"] = form
    cPickle.dump(infos,open(REL(user,db_name)+"_infos.dat","wb"))
    raise HTTP_REDIRECTION,"index?db_name=%s&code=%s" %(db_name,code)