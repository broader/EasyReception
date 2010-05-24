from HTMLTags import *
print H2("Attributes of built-in THIS")

lines = [TR(TD(key)+TD(getattr(THIS,key))) 
    for key in dir(THIS) if not key.startswith("__")]

print TABLE(Sum(lines),border="1")
    