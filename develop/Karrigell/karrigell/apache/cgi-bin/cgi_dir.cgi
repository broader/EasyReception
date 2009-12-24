#!/usr/bin/python
import os
import cgi

print "Content-type: text/html\n\n"

print "<html><head><title>CGI directory</title></head><body>\n"

print "CGI directory is ",os.getcwd()

