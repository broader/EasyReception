Login(role=["admin"],valid_in='/')

import cgi
import urllib
from HTMLTags import *

host = ENVIRON["REMOTE_HOST"]
conf_file = CONFIG.__file__
SET_UNICODE_OUT("iso-8859-1")

def index():

    header = HEAD(TITLE("Editing configuration script")+
        LINK(rel="stylesheet",href="/karrigell.css")+
        SCRIPT(language="javascript", Type="text/javascript",
            src="/editarea/edit_area/edit_area_full.js")+
        SCRIPT("""editAreaLoader.init({
        id : "conf"       // textarea id
        ,syntax: "python"          // syntax to be uses for highlighting
        ,start_highlight: true      // to display with highlight mode on start-up
        ,allow_toggle: false
        })""",
        language="javascript", Type="text/javascript"))

    front = A(_("Home"),href="/")+BR()
    front += H3("Current config file is %s" %conf_file)
    front += INPUT(Type="submit",name="subm",value=_("Save changes"))
    front += INPUT(Type="submit",name="subm",value=_("Cancel"))+BR()
    front += BR()
    content = TEXTAREA(cgi.escape(open(conf_file).read()),
        Id="conf",name="content",cols="100",rows="40")

    print HTML(header+BODY(FORM(front+content,action="save_changes",method="post")))

def save_changes(content,subm):
    if subm==_("Cancel"):
        raise HTTP_REDIRECTION,"/"
    # normalize line ends
    content = "\n".join(content.split("\r\n"))
    # test if new source has no syntax error
    import parser
    try:
        parser.suite(content)
        out = open(conf_file,"wb")
        out.write(content)
        out.close()
        print _("Changes in configuration file %s saved") %conf_file
        print BR(_("Apply them immediately ? "))
        print A(_("Yes"),href="apply")
        print "&nbsp;"
        print B(A(_("No"),href="/admin"))
    except:
        print _("Error in new configuration script")
        import traceback
        import cStringIO
        msg = cStringIO.StringIO()
        msg.write("<P><pre>")
        traceback.print_exc(file=msg)
        msg.write("</pre>")
        print msg.getvalue()
        print P(A(_("Back"),href="index"))

def apply():
    import k_config
    k_config.set_host_conf(host,CONFIG.__file__)
    print _("New configuration applied")
    print BR()+A(_("Home"),href="/")
