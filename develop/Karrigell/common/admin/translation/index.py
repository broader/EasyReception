from HTMLTags import *

Login(role=["admin"],valid_in="/")

frameset = FRAMESET(cols="25%,*",borderwidth=0)
frameset <= FRAME(src="fileMenu.pih")
frameset <= FRAME(name="right")

print frameset