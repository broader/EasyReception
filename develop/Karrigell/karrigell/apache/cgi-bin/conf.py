"""Configuration file for Apache / CGI mode
"""

import os

# these are the values with the distribution directory structure

server_dir = os.getcwd() # folder "cgi-bin"
karrigell_dir = os.path.dirname(os.path.dirname(server_dir)) # karrigell
root_dir = os.path.dirname(karrigell_dir)
data_dir = os.path.join(os.path.dirname(server_dir),"data")
# no use caching on CGI mode
cache_dir = None

# if you had to put the files in folder cgi-bin to another place
# you must replace these values
# root_dir is the full path of the Document Root
# server_dir is the directory where cgi-bin files stand
# data_dir is a folder with WRITE mode, if possible outside of the
#    Document Root for security reasons
# Example :
#root_dir = '/homez.151/karrigel/cgi-bin/www'
#server_dir = '/homez.151/karrigel/cgi-bin'
#karrigell_dir = os.path.join(root_dir,'karrigell')
#data_dir = os.path.join(karrigell_dir,'apache','data')
#cache_dir = None

# allow directory listing if url matches a directory ?
allow_directory_listing = [None]

# don't serve files with extension in this list
hide_extensions = [".pdl"]

# don't serve files with path matching regular expressions in this list
ignore = [".*/favicon.ico","/core.*","/package.*","/conf.*","/data.*"]

# logging file
logging_file = None #os.path.join(karrigell_dir,"logs","access.log")
logging_rotate = "hourly"

# Unicode management
# encode_output : a string = the encoding to use to send data back to the 
# client
output_encoding = None #"utf-8"

# language to translate marked strings to
language = None

# indicates if a complete trace should be printed in case of exception
debug = True

# dictionary of aliases
# if alias["foo"] = "/usr/some_folder" then url /foo/bar.py will
# be resolved to file /usr/some_folder/bar.py
alias = {
    'blogs/sqlite/.*?':os.path.join(root_dir,'demo','sqlite','blog'),
    'blogs/mysql/.*?':os.path.join(root_dir,'demo','mysql','blog')
    }

# use gzip to compress text files ?
gzip = True

# these modules will be available in all scripts namespace
global_modules = [] #[os.path.join(root_dir,"demo","tour","aaa.py")]

# capture request and response in a database ?
capture = False

# maximum number of sessions
max_sessions = 500
