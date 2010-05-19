from HTMLTags import *
from urllib import quote_plus,unquote_plus
import os

fonts = ["serif", "sans-serif", "cursive", "fantasy", "monospace",
    "Times", "TimesNR", "New Century Schoolbook","Helvetica", "Arial", 
    "Verdana","Courier","Mistral", "Author" ]
weights = ["normal","bold"]

try:
    open(REL('bookmarks'))
except IOError:
    out = open(REL('bookmarks'),'w')
    out.close()

def index(folder=None):
    print H2("Impression de la liste des morceaux")

    bookmarks = [line.strip() for line in open(REL('bookmarks'))]

    if bookmarks:
        print H4('Bookmarks')
        for bookmark in bookmarks:
            print A(unquote_plus(bookmark),href="index?folder=%s" %bookmark)
            print '('+A(_("Remove"),href="del_bookmark?folder=%s" %bookmark)+')'
            print BR()

    if folder is None:
        folder = CWD
    else:
        folder = unquote_plus(folder)
    table = TABLE()
    line = TR()
    line <= TD() <= A('..',href='index?folder=%s' %quote_plus(os.path.dirname(folder)))
    line <= TD('&nbsp;')*2
    table <= line
    for path in os.listdir(folder):
        if os.path.isdir(os.path.join(folder,path)):
            target = quote_plus(os.path.join(folder,path))
            line = TR()
            line <= TD() <= A(path,href='index?folder=%s' %target)
            line <= TD(A('List',href='roll?folder=%s' %target))
            line <= TD(A('Bookmark',href='save_bookmark?folder=%s' %target))
            table <= line
    print table

def roll(folder):
    print H2("Impression de la liste des morceaux")

    print _("Folder")
    print B(A(unquote_plus(folder),href="index?folder=%s" %folder))

    _dir = unquote_plus(folder)
    titles = []
    
    flist = TD()
    for _file in os.listdir(_dir):
        file_name = os.path.join(_dir,_file)
        flist <= BR()+A(_file,href=quote_plus(file_name))
        if os.path.isfile(file_name):
            titles.append(os.path.splitext(_file)[0])
    
    area = TD() 
    area <= B("Font")+'&nbsp;'+SELECT(name="font").from_list(fonts)+BR()
    area <= B("Artist")+'&nbsp;'+INPUT(name="artist",size="40")
    area <= BR()+B("Album")+'&nbsp;'+INPUT(name="album",size="40",
        value = os.path.basename(_dir))
    
    area <= BR()+B(_("Song list"))+BR()+TEXTAREA("\n".join(titles),rows=len(titles),cols="70",
        name="song_list")
    area <= BR()+INPUT(Type="submit",name="subm",value="Sleeve")
    area <= BR()+INPUT(Type="submit",name="subm",value="CD")
    
    print TABLE(TR(flist+FORM(area,action="display",method="post")))

def display(font,artist,album,song_list,subm):
    if subm == 'Sleeve':
        print _sleeve(font,artist,album,song_list)
    else:
        _cd(font,artist,album,song_list)

def _sleeve(font,artist,album,song_list):
    font = fonts[int(font)]
    head = HEAD(TITLE("Song list"))

    fstyle = STYLE('td {font-family:%s}' %font)

    front = TABLE(width="450px",height="450px",border="1",
        bordercolor="#000000",style="border-style:dotted",cellspacing="0")

    front <= TR() <= TD(H1(artist)+H2(album),align="center")

    back = TABLE(width="510px",height="455px",border="1",
        bordercolor="#000000",
        style="border-style:dotted none dotted dotted",
        cellspacing="0",cellpadding="0")

    row = TR()

    cell = TD(width="465px",
            style="border-style:dotted;",
            align="center")

    table3 = TABLE(cellpadding="5")
    table3 <= TR() <= TD(H1(artist),Class="front",align="center")
    table3 <= TR() <= TD(H2(album),Class="front",align="center")

    songs_cell = TD()
    for line in song_list.split('\n'):
        songs_cell <= line+BR()
    table3 <= TR(songs_cell)
    cell <= table3

    row <= cell
    back <= row

    return HTML(head+BODY(fstyle+front+P()+back+P()))

def _cd(font,artist,album,song_list):
    head = HEAD()
    head <= TITLE("Song list")
    head <= SCRIPT(src='../cdcover.js')
    head <= LINK(rel='stylesheet',href='../cdcover.css')
    print head
    
    font = fonts[int(font)]
    
    # cd itself (round)

    # draw cd border
    import math
    r2 = 225*225
    for i in range(450):
        dx = int(round(math.sqrt(r2-(225-i)**2),0))
        pos = "top:%s;left:%s;width:%s;height:1;" %(10+i,10+225-dx,2*dx)
        style = "position:absolute;border-width:0 1 0 1;border-style:solid;"
        style += "border-color:#D0D0D0;font-size:1;"
        style += pos
        print DIV(style=style)

    default_style = "position:absolute;text-align:center;"
    default_style += "font-size:%spx;font-weight:%s;"
    
    top,left = 50,100
    width = 2*(235-left)
    pos = 'top:%s;left:%s;width:%spx;' %(top,left,width)
    print DIV(artist,Id="artist",onClick="config(this,'artist')",
        style=default_style %(24,'bold')+"font-family:%s;%s" %(font,pos))
    top,left = 100,60
    width = 2*(235-left)
    pos = 'top:%s;left:%s;width:%spx;' %(top,left,width)
    print DIV(album,Id="album",onClick="config(this,'album')",
        style=default_style %(20,'bold')+"font-family:%s;%s" %(font,pos))

    # center
    r2 = 82*82
    for i in range(164):
        dx = int(round(math.sqrt(r2-(82-i)**2),0))
        top = 10+225-82
        pos = "top:%s;left:%s;width:%s;height:1;" %(top+i,10+225-dx,2*dx)
        style = "position:absolute;border-width:0 1 0 1;border-style:solid;"
        style += "border-color:#D0D0D0;font-size:1;"
        style += pos
        print DIV(style=style)
    
    top,left = 340,100
    width = 2*(235-left)
    pos = 'top:%s;left:%s;width:%spx;' %(top,left,width)
    print DIV(song_list.replace(' ','&nbsp;'),Id="song_list",
        onClick="config(this,'song_list')",
        style=default_style %(14,'normal')+"font-family:%s;%s" %(font,pos))
    
    # settings
    settings = DIV(Id="menu",
        style="position:absolute;visibility:hidden;")

    row1 = TR() 
    row1 <= TD(B("Settings"),align="center")
    row1 <= TD(align="right") <= BUTTON('x',onClick="javascript:close_menu()")
    row1 = TABLE(row1,width="100%")
    
    options = TABLE(width="100%")
    select_font = SELECT(Id="f_fam",onChange="change_family(this)",width="10")
    select_font.from_list(fonts)
    options <= TR(TH("Font")+TD(select_font))

    select_weight = SELECT(Id="f_weight",onChange="change_weight(this)")
    select_weight.from_list(weights)
    options <= TR(TH("Weight")+TD(select_weight))

    select_size = SELECT(Id="f_size",onChange="change_size(this)")
    select_size.from_list(range(8,40))
    options <= TR(TH("Size")+TD(select_size))

    settings <= TABLE(TR(TD(row1)) + TR(TD(options)),width="100%")

    """select_width = SELECT(onChange="change_width(this,'song_list')")
    select_width.from_list(range(200,350))
    settings <= B('Width')+select_width"""
    
    print settings

def save_bookmark(folder):
    try:
        out = open(REL('bookmarks'),'a')
    except IOError:
        out = open(REL('bookmarks'),'w')
    out.write(folder+'\n')
    raise HTTP_REDIRECTION,"index?folder=%s" %folder

def del_bookmark(folder):
    bookmarks = [line.strip() for line in open(REL('bookmarks'))
        if line.strip() != folder]
    out = open(REL('bookmarks'),'w')
    for bookmark in bookmarks:
        out.write(bookmark+'\n')
    out.close()
    raise HTTP_REDIRECTION,"index?folder=%s" %folder    