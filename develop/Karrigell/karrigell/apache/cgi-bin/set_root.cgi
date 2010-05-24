#!/usr/bin/python

import cgi
import cgitb; cgitb.enable()
import sys

print "Content-type: text/html\n\n"

print "<html><head><title>Test cgi python </title></head><body>\n"


form = cgi.FieldStorage()
root = form["root"].value

print "Root directory : %s<br>" %root

import os
if not os.path.exists(root) or not os.path.isdir(root):
    print 'This directory doesn\'t exist. '
    print 'Choose</a> another one'
    sys.exit()
karrigell_dir = os.path.join(root,"karrigell")
if not os.path.exists(karrigell_dir):
    print "Directory karrigell doesn't exist in this folder. "
    print '<a href="config.cgi">Choose</a> another one'
    sys.exit()
out = open("root","w")
out.write(root)
out.close()
print "Root dir set. "
print '<br><a href="/">Home page'