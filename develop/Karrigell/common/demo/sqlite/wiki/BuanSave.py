import time,datetime

db = Import("wikiBase").db

if len(_newText)>5000:
    print "Text too long"
    raise SCRIPT_END

new_admin = int(QUERY.has_key('admin'))
if new_admin:
    if not Role()=="admin":
        print "You must be logged in as admin to set this page to admin status"
        print "<br>Your role is",Role()
        raise SCRIPT_END
    
records = db(name=_pageName)
if records:
    # if existing record, update it
    record = records[0]
    updateTime = datetime.datetime.now()
    db.update(record,name=_pageName,content=_newText.rstrip(),
        admin = new_admin, version = record['version']+1, lastmodif = updateTime)
else:
    # else create a new record
    insertTime = datetime.datetime.now()
    db.insert(_pageName,_newText.rstrip(),new_admin, 0, 
        insertTime, 1, insertTime)

# commit changes
db.commit()

# show
raise HTTP_REDIRECTION,"BuanShow.pih?pageName=%s" %_pageName
