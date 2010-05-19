from HTMLTags import *
print H2("Entêtes de requête")

lines = [TR(TD(k)+TD(HEADERS[k])) for k in HEADERS.keys()]
print TABLE(Sum(lines),border="1")
