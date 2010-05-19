# insert a news 

if len(_newsBody)>255:
    print _("Body must not exceed 255 characters")
    raise SCRIPT_END

import datetime
table = Import("portalDb",REL=REL).table

# form was submitted with iso-8859-1 encoding, transform it to utf-8 for SQLite
for key in ("newsTitle","newsBody"):
    REQUEST[key] = unicode(REQUEST[key],'iso-8859-1').encode('utf-8')

# update values
table['news'].update(table['news'][int(_id)],
    title=REQUEST['newsTitle'], body=REQUEST['newsBody'], 
    date=datetime.datetime.today())
table['news'].commit()
    
raise HTTP_REDIRECTION,"index.pih"
