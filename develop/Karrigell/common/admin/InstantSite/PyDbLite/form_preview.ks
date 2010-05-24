import datetime
import cPickle
from urllib import quote_plus,unquote_plus

from HTMLTags import *
import PyDbLite

Login(role=["admin","edit"],add_user=True)

user = COOKIE['login'].value

make_form = Import("%s/make_form" %user,REL=REL)

def make_edit_form(db_name,field_info,formats,ext_dbs):
    """Build the whole line to display and edit a record"""
    res = []
    for k in field_info:
        widget = make_form.make_widget(k["name"],k["code"],k["type"],
                  formats[k["code"]],
                  ext_dbs,
                  '','')
        widget += A("Edit",
            href="../edit_form.ks?db_name=%s&code=%s" %(db_name,k["code"]),
            target="edit"
            )
        res.append(TH(k["name"])+TD(widget))
    return res

def preview(db_name):
    db_name = unquote_plus(db_name)
    infos = cPickle.load(open(REL(user,db_name)
        +"_infos.dat"))
    field_info = infos["fields"]
    formats = infos["form"]
    ext_dbs = {}
    for f in field_info:
        if f["type"].startswith("external"):
            ext_db_name = f["type"].split(" ",1)[1]
            ext_dbs[f["code"]] = \
                PyDbLite.Base(REL(user,ext_db_name+".pdl")).open()
    print HEAD(LINK(rel="stylesheet",href="../%s/agenda.css" %user)+
        LINK(rel="stylesheet",href="../%s/default.css" %user)+
        SCRIPT(src="../%s/calendar.js" %user)+
        SCRIPT(src="../edit_form.js"))
    lines = make_edit_form(db_name,field_info,formats,ext_dbs)
    print BODY(TABLE(Sum([TR(line) for line in lines])))