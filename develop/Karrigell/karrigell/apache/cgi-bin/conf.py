"""Configuration file for Apache / CGI mode
"""

import os

# these are the values with the distribution directory structure
server_dir = os.path.dirname(os.path.abspath(__file__)) # folder "cgi-bin"
karrigell_dir = os.path.dirname(os.path.dirname(server_dir)) # karrigell
root_dir = os.path.dirname(karrigell_dir)
data_dir = os.path.join(karrigell_dir,"data")

# if you had to put the files in folder cgi-bin to another place
# you must replace these values
# root_dir is the full path of the Document Root
# server_dir is the directory where cgi-bin files stand
# data_dir is a folder with WRITE mode, if possible outside of the
#    Document Root for security reasons
# Example :
# root_dir = '/home.41/k/a/r/karrigel/www'
# server_dir = '/home.41/k/a/r/karrigel/cgi-bin'
# karrigell_dir = os.path.join(root_dir,'karrigell')
# data_dir = os.path.join(karrigell_dir,'apache','data')

# allow directory listing if url matches a directory ?
allow_directory_listing = True

# if redirection to a script, should the extension be shown ?
# default is True but some prefer no extension (cf REST principles)
show_script_extensions = True

# don't serve files with extension in this list
hide_extensions = [".pdl"]

# don't serve files with path matching regular expressions in this list
ignore = [".*/favicon.ico","/core.*","/package.*","/conf.*","/data.*"]

# logging file
logging_file = None #os.path.join(karrigell_dir,"logs","access.log")
logging_rotate = "hourly"

# Unicode management
# encode_input : boolean used to determine if server should try to transform 
# data received from the client into Unicode, using the Accept-charset header
#
# encode_output : a string = the encoding to use to send data back to the 
# client
#
# if encode_input is set, input encoding is successful, and encode_ouput is
# not set, then the output will be encoded with the same encoding as input
#
encode_input = False #True
output_encoding = None #"utf-8"

# language to translate marked strings to
language = None

# indicates if a complete trace should be printed in case of exception
debug = True

# dictionary of aliases
# if alias["foo"] = "/usr/some_folder" then url /foo/bar.py will
# be resolved to file /usr/some_folder/bar.py
alias = {}

# use gzip to compress text files ?
gzip = True

# these modules will be available in all scripts namespace
global_modules = [] #[os.path.join(root_dir,"demo","tour","aaa.py")]

# capture request and response in a database ?
capture = False

# maximum number of sessions
max_sessions = 500
