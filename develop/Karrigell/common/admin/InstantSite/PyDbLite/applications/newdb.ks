import os
import cPickle
from HTMLTags import *
import guess_type

# uncomment next line with the db declaration, like
#import PyDblite
import PyDbLite as PyDbLite
db = PyDbLite.Base(REL("newdb")+".pdl")
db.create("f1","f2",mode="open")

# specify field full names in a dictionary
infos = cPickle.load(open(REL("applications",REL("newdb"))+"_infos.dat"))
field_info = infos["fields"]
fnames = dict([(field_info[f]["code"],f) for f in field_info])

# number of records per page
nbrecs = 20

style = STYLE("""body,td,th {font-family:sans-serif;
    font-size:13}
h2 {font-family: sans-serif;}

th { font-weight: bold; 
    background-color: #D0D0D0;
}
a.navig {background-color:#FF0088;
    text-decoration:none;}
""",Type="text/css")

def _header(title):
    return HEAD(TITLE(title)+style)

def index(start=0):
    name = os.path.basename(db.name)
    print _header(_("Managing database %s") %name)
    body = H2(_("Managing database %s") %name)
    start=int(start)
    f1=f2=TEXT("&nbsp;")
    if not start==0:
        f1 = A("< Previous",Class="navig",href="index?start=%s" %(start-nbrecs))
    if not start+nbrecs>=len(db):
        f2 = A("Next >",href="index?start=%s" %(start+nbrecs),Class="navig")
    navig = TABLE(TR(TD(f1)+TD(f2,align="right")))

    lines = TR(Sum(TH(fnames[f]) for f in db.fields)+TD("&nbsp;")*2)
    recs = db()[start:start+nbrecs]
    for r in recs:
        lines += FORM(INPUT(Type="hidden",name="__id__",value=r["__id__"])+
            INPUT(Type="hidden",name="__version__",value=r["__version__"])+
            TR(Sum([TD(INPUT(name=k,value=r[k]),Class="cell") 
                for k in db.fields]) +
            TD(INPUT(name="subm",Type="submit",value=_("Update")))+
            TD(INPUT(name="subm",Type="submit",value=_("Delete")))),
            action="insert",method="post")
    new = A("New record",href="new")
    print BODY(body+navig+TABLE(lines)+BR(new))

def new():
    print _header ("New record")
    title = H2("New record")
    hidden = INPUT(name="__id__",Type="hidden",value=-1)
    lines = []
    for key in db.fields:
        lines.append(TR(TD(fnames[key])+TD(INPUT(name=key))))
    lines.append(TR(TD(INPUT(name="subm",Type="submit",value="Ok"),colspan="2")))
    lines = title + FORM(hidden+TABLE(Sum(lines)),action="insert",method="post")
    print lines

def delete(recid):
    print _header("Delete record")
    try:
        record = db[int(recid)]
    except KeyError:
        _error("This record was deleted by another user since you selected it")
        raise SCRIPT_END
    print H2("Delete this record ?")
    print TABLE(Sum([TR(TH(f)+TD(record[f])) for f in db.fields]))
    print A("Yes",href="confirm_delete?recid=%s" %recid)
    print A("No",href="index")

def confirm_delete(recid):
    del db[int(recid)]
    db.commit()
    raise HTTP_REDIRECTION,"index"

def _error(message):
    print _header("Error")
    print H2(_("Error"))
    print message
    print P(A(_("Home"),href="index"))

def insert(**kw):
    recid = int(kw["__id__"])
    kw["__version__"] = int(kw.get("__version__",1))
    del kw["__id__"]
    action = kw["subm"] # can be "Insert", "Update" or "Delete"
    if action == _("Delete"):
        delete(recid)
        raise SCRIPT_END
    del kw["subm"]
    for field in db.fields:
        kw[field] = guess_type.guess_type(kw.get(field,"")) or None
    if recid >= 0:
        try:
            r = db[recid]
            # concurrency control
            if r.setdefault("__version__",-1) != int(kw["__version__"]):
                _error("Can't update the record, "\
                    "it was modified by another user since you selected it")
                raise SCRIPT_END
        except KeyError: # record may have been destroyed since selection
            _error("Can't update the record, "\
                "it was deleted by another user since you selected it")
            raise SCRIPT_END
        db.update(r,**kw)
    else:
        db.insert(**kw)
    db.commit()
    raise HTTP_REDIRECTION,"index"
