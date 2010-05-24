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
    name = os.path.basename(db.name)
    print _header(_("Managing database %s") %name)
    body = H2(_("Managing database %s") %name)
    start=int(start)

    f1=f2=TEXT("&nbsp;")
    if not start==0:
        f1 = A("< Previous",Class="navig",href="../%s/index?start=%s" 
            %(urllib.quote_plus(THIS.basename),start-nbrecs))
    if not start+nbrecs>=len(db):
        f2 = A("Next >",href="../%s/index?start=%s" 
            %(urllib.quote_plus(THIS.basename),start+nbrecs),Class="navig")
    navig = TABLE(TR(TD(f1)+TD(f2,align="right")))

    lines = TR(TD("&nbsp;")+Sum([TH(f) for f in db.fields])+TD("&nbsp;")*2)
    recs = db()[start:start+nbrecs]
    for i,r in enumerate(recs):

        cells = [TH(A(i,Class="edit_line",href="edit?rec_id=%s" %r["__id__"]))]
        for fname,info in field_info:
            if r[fname] is None:
                r[fname] = '&nbsp;'
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
    r = db[int(rec_id)]
    print FORM(INPUT(Type="hidden",name="__id__",value=r["__id__"])+
        INPUT(Type="hidden",name="__version__",value=r["__version__"])+
        TABLE(Sum(_cells(r)))+
        INPUT(name="subm",Type="submit",value=_("Update"))+
        INPUT(name="subm",Type="submit",value=_("Delete")),
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
        record = db[int(rec_id)]
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
    del db[int(rec_id)]
    db.commit()
    raise HTTP_REDIRECTION,"index"

def _error(message):
    print _header("Error")
    print H2(_("Error"))
    print message
    print P(A(_("Home"),href="index"))

def insert(**kw):
    recid = int(kw["__id__"])
    version = int(kw.get("__version__",1))
    del kw["__id__"]
    action = kw["subm"] # can be "Insert", "Update" or "Delete"
    if action == _("Delete"):
        delete(recid)
        raise SCRIPT_END
    del kw["subm"]
    for fname,info in field_info:
        ftype = info.typ
        if fname in kw:
            if not kw[fname]:
                if info.allow_empty:
                    kw[fname] = None
                else:
                    print "You must enter a value for field %s" %fname
                    raise SCRIPT_END
            else:
                guess = guess_type.guess_type(kw[fname])
                if (ftype == "integer" and not isinstance(guess,int)) \
                    or (ftype == "float" and not isinstance(guess,float)):
                    print "Bad value for %s : expected %s, got %s (type %s)" \
                        %(fname,ftype,kw[fname],guess.__class__)
                    raise SCRIPT_END
                else:
                    kw[fname] = guess
    if recid >= 0:
        try:
            r = db[recid]
            # concurrency control
            if r.setdefault("__version__",-1) != version:
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
