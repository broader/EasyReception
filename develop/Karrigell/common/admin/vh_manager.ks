import os
import k_utils

Login()
if not k_utils.is_default_host(REQUEST_HANDLER.host):
    raise HTTP_REDIRECTION,"index.ks"

import k_config
from HTMLTags import *

SET_UNICODE_OUT('utf-8')

header = HEAD(TITLE(_("Virtual hosts management"))+ \
    META(http_equiv="Content-Type",content="text/html; charset=utf-8")+ \
    LINK(rel="stylesheet",href="../admin.css"))

def index():
    print header
    print A(_("Home"),href="/")
    print H1(_("Virtual hosts management"))
    for host in k_config.config:
        if not k_utils.is_default_host(host):
            print host
            print A(_("Remove host"),href="remove?host=%s" %host)+BR()
    print BR()+A(_("Add new host"),href="new_host")

def remove(host):
    hosts_file = os.path.join(k_config.host_conf_dir,"hosts")
    lines = [line for line in open(hosts_file) 
        if not line.split()[0]==host]
    out = open(hosts_file,"w")
    out.writelines(lines)
    out.close()
    print lines
    
    k_config.init()
    print BR(),k_config.config.keys()
    #raise SCRIPT_END
    raise HTTP_REDIRECTION,"index"

def new_host():
    print header
    print H1(_("New virtual host"))
    lines = TR(TD(_("Host name"))+TD(INPUT(name="host_name")))
    lines += TR(TD(_("Set default aliases"))+
        TD(INPUT(Type="checkbox",name="use_alias",checked=True)))
    lines += TR(TD(_("Log requests"))+
        TD(INPUT(Type="checkbox",name="log",checked=False)))
    subm = INPUT(name="subm",Type="submit",value="Ok")
    subm += INPUT(name="subm",Type="submit",value=_("Cancel"))
    print FORM(TABLE(lines)+subm,action="create_host",method="POST")

def create_host(**kw):
    print header
    if kw["subm"] == _("Cancel"):
        raise HTTP_REDIRECTION,"index"
    # test if a host with this name already exists
    host_name = kw["host_name"]
    if not host_name:
        print "No host name entered"
        print BR()+A(_("Back"),href="new_host")
        raise SCRIPT_END
    if host_name in k_config.config:
        print "Host %s already defined" %host_name
        print BR()+A(_("Back"),href="new_host")
        raise SCRIPT_END    
    # create root directory for new host
    root_dir = os.path.join(k_config.server_dir,host_name)
    if not os.path.exists(root_dir):
        os.mkdir(root_dir)
    # create default home page
    out = open(os.path.join(root_dir,"index.pih"),"w")
    out.write("<h1>Default home page</h1>")
    out.close()
    # create data directory
    data_dir = os.path.join(k_config.server_dir,"data",host_name)
    if not os.path.exists(data_dir):
        os.mkdir(data_dir)
    # put conf file in data directory
    ns = {"host_name":host_name}
    if "use_alias" in kw:
        ns["alias"] = """{"admin":os.path.join(server_dir,"common","admin"),
            "doc":os.path.join(server_dir,"common","doc"),
            "demo":os.path.join(server_dir,"common","demo"),
            "editarea":os.path.join(server_dir,"common","editarea")
            }"""
    else:
        ns["alias"] = {}
    if "log" in kw:
        ns["logging_file"] = 'os.path.join(data_dir,"logs")'
    else:
        ns["logging_file"] = None
    conf = open("conf.tmpl").read() %ns # config template
    conf_path = os.path.join(data_dir,"conf.py")
    conf_file = open(conf_path,"w")
    conf_file.write(conf)
    conf_file.close()
    
    # update hosts file
    hosts_file = os.path.join(k_config.host_conf_dir,"hosts")
    out = open(hosts_file,"a")
    out.write("%s %s\n" %(host_name,conf_path))
    out.close()
    
    # update k_config
    k_config.init()
    
    print "New host %s added" %host_name
    href = "http://%s" %host_name
    if CONFIG.port != 80:
        href = "http://%s:%s" %(host_name,CONFIG.port)
    print BR()+A(_("Test it"),href=href)
    print BR()+A(_("Back"),href="index")
    
    
    