def add_ns(target):
    languageHeader = target.handler.headers.get("accept-language",'')
    langs=[]
    if languageHeader:
        languageList=languageHeader.split(",")
        for item in languageList:
            l=item.split(";")[0][:2]
            if not l in langs:
                langs.append(l)

    return {"ACCEPTED_LANGUAGES": langs,
        "PATH": target.url}

def set_old(target):

    for old,new in (("serverDir","server_dir"),
        ("rootDir","root_dir"),
        ("outputEncoding","output_encoding")):
            setattr(target.handler.config,old,
                getattr(target.handler.config,new))

    for old,new in (("code","py_code"),
        ("extension","ext"),
        ("path","url"),
        ("subpath","args")):
        setattr(target,old,getattr(target,new))

