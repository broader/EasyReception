# removes a news from the database
# the news is identified by its id

table=Import("portalDb",REL=REL).table
del table['news'][int(_id)]
table['news'].commit()

raise HTTP_REDIRECTION,"index.pih"