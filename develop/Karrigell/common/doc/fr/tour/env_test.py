from HTMLTags import *
print H2("Données d'environnement")

lines = [TR(TD(key)+TD(ENVIRON[key])) 
    for key in ENVIRON]

print TABLE(Sum(lines),border="1")
    