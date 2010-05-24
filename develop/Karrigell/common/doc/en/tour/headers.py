from HTMLTags import *
print H2("Request headers")

lines = [TR(TD(k)+TD(HEADERS[k])) for k in HEADERS.keys()]
print TABLE(Sum(lines),border="1")
