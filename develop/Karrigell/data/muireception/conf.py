"""Default configuration file
"""

import os

# karrigell_dir is in the namespace where this script is run in k_config.py
root_dir = os.path.join(server_dir,"muireception")
data_dir = os.path.join(server_dir, "data","muireception")
cgi_dir = os.path.join(root_dir,"cgi-bin")

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
alias = {"admin":os.path.join(server_dir,"common","admin"),
    "doc":os.path.join(server_dir,"common","doc"),
    "demo":os.path.join(server_dir,"common","demo"),
    "editarea":os.path.join(server_dir,"common","editarea")
    }

# use gzip to compress text files ?
gzip = True

# these modules will be available in all scripts namespace
global_modules = [] #[os.path.join(root_dir,"demo","tour","aaa.py")]

# capture request and response in a database ?
capture = False

# maximum number of sessions
max_sessions = 500
