import os
import urllib

from HTMLTags import *

Login(role=["admin"],valid_in="/")

def index(folder = None):
    if folder is None:
        folder = CONFIG.root_dir
    folder = urllib.unquote_plus(folder)
    files = os.listdir(folder)
    for _dir in [ d for d in files 
        if os.path.isdir(os.path.join(folder,d)) ]:
        full_dir = urllib.quote_plus(os.path.join(folder,_dir))
        print A("+",href="index?folder=%s" %full_dir)
        print TEXT(_dir)+BR()
    for _file in [ f for f in files 
        if os.path.isfile(os.path.join(folder,f)) ]:
        full_file = urllib.quote_plus(os.path.join(folder,_file))
        print A(_file,href="edit?script=%s" 
            %urllib.quote_plus(full_file))
        print BR()

def edit(script):
    script = urllib.unquote_plus(script)
    header = HEAD(TITLE("Editing script %s" %script)+
        SCRIPT(language="javascript", Type="text/javascript",
            src="/editarea/edit_area/edit_area_full.js")+
        SCRIPT("""editAreaLoader.init({
        id : "textarea_1"       // textarea id
            ,toolbar: "search, go_to_line, |, undo, redo, |, select_font, |, syntax_selection, |, change_smooth_selection, highlight, reset_highlight, |, help"
            ,syntax_selection_allow: "css,html,js,php,python,vb,xml,c,cpp,sql,basic,pas,brainfuck"
            ,show_line_colors: false
            ,EA_load_callback: "editAreaLoaded"
            ,allow_toggle: true
            ,start_highlight: true
            

        })""",
        language="javascript", Type="text/javascript"))

    front = H3("Editing script %s" %script)
    front += INPUT(Type="submit",value=_("Save changes"))+BR()
    front += INPUT(Type="hidden",name="script",value=urllib.quote_plus(script))
    front += BR()
    content = TEXTAREA(open(script).read(),
        Id="textarea_1",name="content",cols="80",rows="40")

    print HTML(header+BODY(FORM(front+content,action="save_changes",method="post")))

def save_changes(script,content):
    script = urllib.unquote_plus(script)
    out = open(script,'wb')
    out.write(content)
    out.close()
    print "Changes saved"
            
