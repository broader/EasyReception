""" Removes the pages whose names are the keys of QUERY """

# check authentication
print "cookie",COOKIE

Login(role=["admin"])

if _subm == _("Cancel") or not "remove" in REQUEST:
    raise HTTP_REDIRECTION,"index.pih"
        
# get records to remove using their recno
db = Import("wikiBase").db

recs_to_remove = []
for r in _remove:
    recs_to_remove.append(db[int(r)])

if len(_remove) == 1:
    print "Deleting 1 page<p>\n"
else:
    print "Deleting %s pages<p>\n" %len(_remove)

# actually remove the records
for r in _remove:
    del db[int(r)]

db.commit()

print '<a href="index.pih">Back</a>'
