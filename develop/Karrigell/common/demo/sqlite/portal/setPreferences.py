# stores or updates user preferences 

table = Import("portalDb",REL=REL).table

table['users'].update(table['users'][Session().user],
    bgcolor=_bgcolor,fontfamily=_fontfamily)
table['users'].commit()

raise HTTP_REDIRECTION,"index.pih"
