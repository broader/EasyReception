import os
from HTMLTags import *
import urllib
import cgi

Login(role=["admin"])

def index(script,editable=False):
    script = urllib.unquote_plus(script)
    ext = os.path.splitext(script)[1]
    if ext == ".py":
        syntax = "python"
    elif ext in [".html",".htm"]:
        syntax = "html"
    elif ext in [".css",".js"]:
        syntax = ext[1:]
    elif ext == ".ks":  syntax = "python"
    elif ext == ".pih": syntax = "html"
    elif ext == ".hip": syntax = "python"
    else:
        syntax = ""
        
    header = HEAD(TITLE("Editing script %s" %script)+
        SCRIPT(language="javascript", Type="text/javascript",
            src="/editarea/edit_area/edit_area_full.js")+
        SCRIPT("""editAreaLoader.init({
        id : "textarea_1"       // textarea id
        ,syntax: "%s"          // syntax to be uses for highlighting

            ,toolbar: "search, go_to_line, |, undo, redo, |, select_font, |, syntax_selection, |, change_smooth_selection, highlight, reset_highlight, |, help"
            ,syntax_selection_allow: "css,html,js,php,python,vb,xml,c,cpp,sql,basic,pas,brainfuck"
            ,show_line_colors: false
            ,EA_load_callback: "editAreaLoaded"
            ,allow_toggle: true 
            ,start_highlight: true
            
        
        })""" %syntax,
        language="javascript", Type="text/javascript"))

    front = H3("Editing script %s" %script)+SMALL("Powered by ")
    front += A(SMALL("editarea"),href="http://sourceforge.net/projects/editarea",
        target="_blank")+P()
    if editable:
        front += INPUT(Type="submit",value=_("Save changes"))+BR()
        front += INPUT(Type="hidden",name="script",value=urllib.quote_plus(script))
        front += BR()
    content = TEXTAREA(cgi.escape(open(script).read()),
        Id="textarea_1",name="content",cols="80",rows="40")

    if editable:
        print HTML(header+BODY(FORM(front+content,action="save_changes",method="post")))
    else:
        print HTML(header+BODY(content))

def save_changes(script,content):
    script = urllib.unquote_plus(script)
    out = open(script,'wb')
    out.write(content)
    out.close()
    print "Changes saved"
        