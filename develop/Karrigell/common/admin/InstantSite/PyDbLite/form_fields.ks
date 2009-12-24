"""Edit infomation on the form to enter or edit records
For each field, define how it should be entered
Depends on the field type :
    - integer or float : enter it in an INPUT field
    - string : INPUT or TEXTAREA
    - date : define date format ; enter in an INPUT field
      and/or with the pop up calendar
"""
import cPickle
from HTMLTags import *

def form(db_name):
    print HEAD(LINK(rel="stylesheet",href="../default.css"))
    # open info file
    infos = cPickle.load(open(REL("applications",db_name)
        +"_infos.dat"))
    fields = infos["fields"]
    lines = H3("Fields")
    for field in fields:
        lines += A(field["name"],href="../edit_form.ks/edit?db_name=%s&code=%s" %(db_name,field["code"])
            ,target="edit")+BR()
    print BODY(lines)
