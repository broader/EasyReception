# stores or updates user preferences 

db = Import("portalDb",REL=REL).db

db['users'].update(db['users'][Session().user],
    bgcolor=_bgcolor,fontfamily=_fontfamily)
db['users'].commit()

raise HTTP_REDIRECTION,"index.pih"
