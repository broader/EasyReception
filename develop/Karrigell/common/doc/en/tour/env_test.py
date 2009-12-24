from HTMLTags import *
print H2("Environment data")

lines = [TR(TD(key)+TD(ENVIRON[key])) 
    for key in ENVIRON]

print TABLE(Sum(lines),border="1")
    