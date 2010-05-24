import os
import cPickle
import cgi
import urllib
import datetime

from HTMLTags import *
import date_formats
import guess_type

Login(role=['admin','edit'])

SET_UNICODE_OUT('utf-8')

from PyDbLite import SQLite
db_name = 'forums.sqlite'
db_dir = os.path.join(CONFIG.data_dir,"forum")
if not os.path.exists(db_dir):
    os.mkdir(db_dir)
db_path = os.path.join(db_dir,'forums.sqlite')
table = SQLite.Table('forums',db_path)
table.create(('name','TEXT'),('owner','TEXT'),mode="open")

class FieldInfo:

    def __init__(self,typ,not_null=False,default=''):
        self.typ = typ
        self.not_null = not_null
        self.default = default

field_info = [
    ('name',FieldInfo(typ='TEXT',not_null=True,default='')),
    ('owner',FieldInfo(typ='TEXT',not_null=True,default='')),
    ]

def entry_name(val):
    return INPUT(name='name',Id='name',value=val)+FONT('*',color='red')

def entry_owner(val):
    return INPUT(name='owner',Id='owner',value=val)+FONT('*',color='red')

entry_widget={
    'name':entry_name,
    'owner':entry_owner,
}


# entry widgets can be customized in a script
try:
    custom = Import('forums_custom.py',REL=REL,SQLite=SQLite)
    for fname in db.fields:
        if 'entry_%s' %fname in dir(custom):
            entry_widget[fname] = getattr(custom,'entry_%s' %fname)
except ImportError:
    pass
# number of records per page
nbrecs = 20

def make_form(record={}):
    """Build the whole line to display and edit a record"""
    return [TH(fname)+TD(entry_widget[fname](record.get(fname,'')))
          for fname,info in field_info]

def _header(title):
    return HEAD(TITLE(title)+
        LINK(rel="stylesheet",href="../agenda.css")+
        LINK(rel="stylesheet",href="../default.css")+
        SCRIPT(src="../calendar.js"))

def index(start=0):
    name = os.path.basename(table.name)
    print _header(_("Managing database %s - table %s") %(db_name,table.name))
    body = H2(_("Managing database %s - table %s") %(db_name,table.name))
    start=int(start)

    f1=f2=TEXT("&nbsp;")
    if not start==0:
        f1 = A("< Previous",Class="navig",href="../%s/index?start=%s" 
            %(urllib.quote_plus(THIS.basename),start-nbrecs))
    if not start+nbrecs>=len(table):
        f2 = A("Next >",href="../%s/index?start=%s" 
            %(urllib.quote_plus(THIS.basename),start+nbrecs),Class="navig")
    navig = TABLE(TR(TD(f1)+TD(f2,align="right")))

    lines = TR(TD("&nbsp;")+Sum([TH(f) for f in table.fields])+TD("&nbsp;")*2)
    recs = table()[start:start+nbrecs]
    for i,r in enumerate(recs):

        cells = [TH(A(i,Class="edit_line",href="edit?rec_id=%s" %r["__id__"]))]
        for fname,info in field_info:
            cells += [TD(A(r[fname],Class="edit",
                href="edit?rec_id=%s&fname=%s" %(r["__id__"],fname)))]
        lines += TR(Sum(cells))

    new = A("New record",href="new")
    print BODY(body+navig+TABLE(lines)+BR(new))

def _cells(record):
    return [TR(TH(fname)+
            TD(entry_widget[fname](record[fname])))
              for fname,info in field_info]

def edit(rec_id,fname=None):
    print _header(_("Editing a record"))
    r = table[int(rec_id)]
    print FORM(INPUT(Type="hidden",name="__id__",value=r["__id__"])+
        TABLE(Sum(_cells(r)))+
        INPUT(name="subm",Type="submit",value=_("Update"))+
        INPUT(name="subm",Type="submit",value=_("Delete"))+
        INPUT(name="subm",Type="submit",value=_("Cancel")),
        action="insert",method="post")
    if fname:
        print SCRIPT('document.getElementById("%s").focus()' %fname)

def new():
    print _header ("New record")
    title = H2("New record")
    hidden = INPUT(name="__id__",Type="hidden",value=-1)
    lines = [TR(line) for line in make_form()]
    lines.append(TR(TD(INPUT(name="subm",Type="submit",value="Ok"),colspan="2")))
    lines = title + FORM(hidden+TABLE(Sum(lines)),action="insert",method="post")
    print lines

def delete(rec_id):
    print _header("Delete record")
    try:
        record = table[int(rec_id)]
    except KeyError:
        _error("This record was deleted by another user since you selected it")
        raise SCRIPT_END
    print H2("Delete this record ?")
    yes = FORM(INPUT(Type="hidden",name="rec_id",value=rec_id)+
        INPUT(Type="submit",value=_("Yes")),
        action = "confirm_delete")
    no = FORM(INPUT(Type="submit",value=_("No")),
        action = "index")

    print TABLE(TR(TD(yes)+TD(no)))
    print TABLE(Sum(_cells(record)))

def confirm_delete(rec_id):
    del table[int(rec_id)]
    table.commit()
    raise HTTP_REDIRECTION,"index"

def _error(message):
    print _header("Error")
    print H2(_("Error"))
    print message
    print P(A(_("Home"),href="index"))

def insert(**kw):
    recid = int(kw["__id__"])
    del kw["__id__"]
    action = kw["subm"] # can be "Insert", "Update", "Delete" or "Cancel"
    if action == _("Delete"):
        delete(recid)
        raise SCRIPT_END
    if action == _("Cancel"):
        raise HTTP_REDIRECTION,"index"
    del kw["subm"]
    for fname,info in field_info:
        ftype = info.typ
        if fname in kw:
            guess = guess_type.guess_type(kw[fname])
            if (ftype == "INTEGER" and not isinstance(guess,int)) \
                or (ftype == "REAL" and not isinstance(guess,float)):
                print "Bad value for %s : expected %s, got %s (type %s)" \
                    %(fname,ftype,kw[fname],guess.__class__)
                raise SCRIPT_END
            else:
                kw[fname] = guess
    if recid >= 0:
        table.update(table[recid],**kw)
    else:
        table.insert(**kw)
    table.commit()
    raise HTTP_REDIRECTION,"index"
