import urllib
from HTMLTags import *
import os

def index(dir):
    #print TEXT("Placeholder for a script intended to manage the current directory") + BR()
    dir = urllib.unquote_plus(dir)
    files = os.listdir(dir)
    print TEXT("Current directory : %s" % dir) + BR()*2
    edit_functs = ['edit', 'delete', 'rename']
    edit_functs = Sum(TD(A(ed, href='#')) for ed in edit_functs)
    table = TABLE( Sum ( [ TR(TD(_file) + edit_functs)  for _file in files] ), border=1 )
    print table
    print BR()*2 + A('[Create a new file]', href = '#' ) 
    print TEXT("&nbsp;") + A('[Upload a file]', href = '#' ) 
    

 