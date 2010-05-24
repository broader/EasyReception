from HTMLTags import *
import datetime

head = TITLE(_("Breton songs scores"))
head += LINK(rel="stylesheet",Type="text/css",href="../business.css")

def _front():
    links = A(IMG('',src="/doc/images/karrigell.jpg", border="0", width="100px"),
            href="/")
    links += BR()+A(_("Home"),href="../")
    title = _("Breton songs scores")
    so = Session()
    if hasattr(so,"order") and so.order:
        links +=  BR()+A(_("See cart"),href="handle_cart")

    return DIV(links,Class="links")+DIV(DIV(title,Class="pagetitle"),Class="header")

# import createSongBase to create the song database
# if not created yet
Import("createSongBase",REL=REL,CWD=CWD)
SET_UNICODE_OUT('iso-8859-1')

def index():
    search = FORM(TEXT(_("Search"))+
        INPUT(name="words")+INPUT(Type="submit",value="Ok"),
        action = "song_list")

    browse = DT(_("Browse"))
    browse += DD(A(_("by collection"),href="browse?key=recueils"))
    browse += DD(A(_("by type"),href="browse?key=genres"))
    browse += DD(A(_("by dialect"),href="browse?key=dialectes"))
    browse += DD(A(_("whole list"),href="song_list"))

    browse = DL(browse)

    clear = SMALL(A(_("Clear session"),href="clear_session"))
    
    print HTML(HEAD(head)+BODY(_front()+DIV(search+browse+clear,Class="content")))

def browse(key):
    # choose a category of songs
    # key variable : recueils, genres or dialectes
    db = Import("songDb",REL=REL).db

    d={"recueils":_("by collection"),
        "genres":_("by type"),
        "dialectes":_("by dialect")}

    browse = P()+DT(_("Browse")+"&nbsp;"+d[key])

    dbase = db[key]
    elts=[ (r['__id__'],r['nom']) for r in dbase ]
    elts.sort(lambda x,y: cmp(x[1].lower(),y[1].lower()))
    for elt in elts:
        browse += DD(A(elt[1],href="song_list?key=%s&value=%s" %(key,elt[0])))

    print HTML(HEAD(head)+BODY(_front()+browse))

def song_list(**kw): #key="",value=""):
    db = Import("songDb",REL=REL).db
    import re
    if "key" in kw:
        key = kw["key"]
        value = int(kw["value"])
        rec = db[key][int(value)]
        title = rec['nom']
        rec_id = rec['__id__']
        if key=="genres":
            songs = [ r for r in db['chansons'] if r['genre'] == rec_id ]
        elif key in ['dialectes','recueils']:
            rec_id = db[key][int(value)]['__id__']
            songs = [ db['chansons'][r['chanson']]
                for r in db['chansons_par_%s' %key[:-1]] 
                if r[key[:-1]] == rec_id ]
        songs.sort(lambda x,y : cmp(x['breton'].lower(),y['breton'].lower()))

    elif "words" in kw:
        words = kw["words"]
        # find songs with _words in title
        title = 'Songs with "%s"' %words
        # pattern for case-insensitive search begins with (?i)
        songs=[ r for r in db['chansons'] if re.search('(?i)%s' %words,r['breton']) ]

    else:
        title = _("All the songs")
        songs=[ r for r in db['chansons'] ]
        songs.sort(lambda x,y:cmp(x['breton'].lower(),y['breton'].lower()))

    hdr = H2("%s (%s %s)" %(title,len(songs),_("songs")))
    
    lines = TR(TH(_("Song"))+TH(_("Price")))
    for s in songs:
        lines += TR(TD(A(s['breton'],href="details?song=%s" %s['__id__']))
            +TD(round(float(s['prix'])/100,2)))

    print HTML(HEAD(head)+BODY(_front()+hdr+TABLE(lines,border=1)))

def details(song):
    db = Import("songDb",REL=REL).db
    id_chanson = int(song)
    song=db['chansons'][id_chanson]

    # recueils et dialectes dans lesquels on trouve la chanson
    recueils = [ db['recueils'][r['recueil']]
        for r in db['chansons_par_recueil'] if r['chanson'] == id_chanson ]
    dialectes = [ db['dialectes'][r['dialecte']]
        for r in db['chansons_par_dialecte'] if r['chanson'] == id_chanson ]

    txt =H2(song['breton'])+H4(song['francais'])

    lines = TR(TD(_("Collection"))+
        TD(", ".join([r['nom'] for r in recueils])))
    lines += TR(TD(_("Type"))+
        TD(", ".join([d['nom'] for d in dialectes])))
    lines += TR(TD(_("Prize"))+
        TD(str(round(float(song['prix'])/100,2))+"&nbsp;&euro;"))
    
    txt += TABLE(lines,cellpadding=5,border=1)

    txt += FORM(INPUT(Type="hidden", name="action",value="add")+
        INPUT(type="hidden",name="song",value=id_chanson)+
        INPUT(Type="submit",value=_("Add to your cart")),
        action="handle_cart")

    print HTML(HEAD(head)+BODY(_front()+txt))

def handle_cart(action=None,song=None):

    txt = H2(_("Situation of your cart"))
    # if action=add, add the specified file
    # if action=remove, remove the specified file
    # in all cases, show the cart

    so=Session()
    db = Import("songDb",REL=REL).db
    if not hasattr(so,"order"):
        so.order=[]

    if song:
        song_id = int(song)
        song=db['chansons'][song_id]

        if action=="add":
            if not song_id in so.order:
                so.order.append(song_id)
                txt += I(song['breton'])+TEXT("&nbsp;"+_("added to your cart"))
            else:
                txt += I(song['breton'])
                txt += TEXT("&nbsp;"+_("was already in your cart"))
        elif action=="remove":
            if song_id in so.order:
                txt += I(song['breton'])
                txt += TEXT("&nbsp;"+_("removed from your cart"))
                so.order.remove(song_id)

    # show cart
    if not len(so.order):
        lines = TR(TD(_("Your cart is empty")))
    else:
        lines = TR(TH(_("Song"))+TH(_("Price"))+TH("&nbsp;"))
        total=0
        songs = [ db['chansons'][_id] for _id in so.order ]
        for song in songs:
            lines += TR(TD(song['breton'])+
                TD(round(float(song['prix'])/100,2))+
                TD(SMALL(A(_("Remove"),
                    href="handle_cart?action=remove&song=%s" %song["__id__"]))))

            total += song['prix']
        lines += TR(TH(_("Total"))+TH(round(float(total)/100,2))+TH("&nbsp;"))

    print HTML(HEAD(head)+BODY(_front()+txt+TABLE(lines,border=1,cellpadding=5)))

def clear_session():
    Session().close()
    raise HTTP_REDIRECTION,"index"
