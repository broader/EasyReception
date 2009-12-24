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

make_form = Import("make_form",REL=REL)

def _header(title):
    return HEAD(TITLE(title)+style+
        LINK(rel="stylesheet",href="../agenda.css")+
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

    lines = TR(Sum([TH(fnames[f]) for f in db.fields])+TD("&nbsp;")*2)
    recs = db()[start:start+nbrecs]
    for r in recs:
        cells = [TD(make_form.make_widget(f["name"],f["code"],f["type"],
                  forms[f["code"]],
                  ext_dbs,
                  r[f["code"]],r["__id__"]))
                  for f in field_info]
        cells.append(TD(INPUT(name="subm",Type="submit",value=_("Update"))))
        cells.append(TD(INPUT(name="subm",Type="submit",value=_("Delete"))))
        lines += FORM(INPUT(Type="hidden",name="__id__",value=r["__id__"])+
            INPUT(Type="hidden",name="__version__",value=r["__version__"])+
            TR(Sum(cells)),
            action="insert",method="post")
    new = A("New record",href="new")
    print BODY(body+navig+TABLE(lines)+BR(new))

def new():
    print _header ("New record")
    title = H2("New record")
    hidden = INPUT(name="__id__",Type="hidden",value=-1)
    lines = [TR(line) for line in make_form.make_form(field_info,forms,ext_dbs)]
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
    for fname,ftype in ftypes.iteritems():
        if fname in kw:
            if ftype != "date":
                guess = guess_type.guess_type(kw[fname])
                if (ftype == "integer" and not isinstance(guess,int)) \
                    or (ftype == "float" and not isinstance(guess,float)):
                    print "Bad value for %s : expected %s, got %s (type %s)" \
                        %(fname,ftype,kw[fname],guess.__class__)
                    raise SCRIPT_END
                else:
                    kw[fname] = guess
            else:
                elts = date_formats.date_abr[forms[fname]["dord"]]
                sep = forms[fname]["dsep"]
                sep = date_formats.date_seps[sep]
                guess = date_formats.str_to_date(kw[fname],elts,sep)
                if guess is None:
                    print "%s is not a valid date : expected format %s" \
                        %(kw[fname],sep.join(elts))
                    raise SCRIPT_END
                else:
                    kw[fname] = guess
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
