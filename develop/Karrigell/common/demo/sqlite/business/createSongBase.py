import sys,os, random
from PyDbLite import SQLite

db_path = os.path.join(CONFIG.data_dir,'business.sqlite')
conn = SQLite.sqlite.connect(db_path)

def createBase():

    txt_path = os.path.join(os.path.dirname(os.path.dirname(CWD)),
        "base.txt")
    chansons=open(txt_path).readlines()

    db_genres = SQLite.Base('genres',conn)
    db_genres.create(('nom','TEXT'),mode="override")

    db_chansons = SQLite.Base('chansons',conn)
    db_chansons.create(('url','TEXT'),
        ('breton','TEXT'),
        ('francais','TEXT'),
        ('prix','INTEGER'),
        ('genre','INTEGER'),
        mode="override")

    db_recueils = SQLite.Base('recueils',conn)
    db_recueils.create(('nom','TEXT'),mode="override")

    db_dialectes = SQLite.Base('dialectes',conn)
    db_dialectes.create(('nom','TEXT'),mode="override")

    db_ch_par_dial = SQLite.Base('chansons_par_dialecte',conn)
    db_ch_par_dial.create(('chanson','INTEGER'),
        ('dialecte','INTEGER'),
        mode="override")
    
    db_ch_par_rec = SQLite.Base('chansons_par_recueil',conn)
    db_ch_par_rec.create(('chanson','INTEGER'),
        ('recueil','INTEGER'),
        mode="override")

    l_chansons=[]
    id_chanson = 1
    l_recueils=[]
    l_dialectes=[]
    l_genres=[]
    chansonsParRecueil=[]
    chansonsParGenre=[]
    chansonsParDialecte=[]

    for line in chansons:
        [url,breton,francais,recueils,genre,dialectes,enreg]=line.strip().split("#")
        breton = unicode(breton,'iso-8859-1')
        francais = unicode(francais,'iso-8859-1')
        genre = unicode(genre,'iso-8859-1')
        if not genre in l_genres:
            l_genres.append(genre)
        id_genre = l_genres.index(genre)+1
        prix=random.randrange(200,400)
        l_chansons.append([url,breton,francais,prix,id_genre])

        recs=recueils.split(";")
        for rec in recs:
            rec = unicode(rec,'iso-8859-1')
            if not rec in l_recueils:
                l_recueils.append(rec)
            id_recueil = l_recueils.index(rec)+1
            chansonsParRecueil.append([id_chanson,id_recueil])
        dials=dialectes.split(";")
        for dial in dials:
            if not dial in l_dialectes:
                l_dialectes.append(dial)
            id_dialecte = l_dialectes.index(dial)+1
            chansonsParDialecte.append([id_chanson, id_dialecte])

        id_chanson += 1

    for g in l_genres:
        db_genres.insert(nom=g)
    for d in l_dialectes:
        db_dialectes.insert(nom=d)
    for r in l_recueils:
        db_recueils.insert(nom=r)

    for ch in l_chansons:
        try:
            db_chansons.insert(**dict(zip(db_chansons.fields,ch)))
        except:
            import sys
            sys.stderr.write("error for %s %s\n" %(db_chansons.fields,ch))
    for ch_d in chansonsParDialecte:
        db_ch_par_dial.insert(chanson = ch_d[0],
            dialecte = ch_d[1])
    for ch_r in chansonsParRecueil:
        db_ch_par_rec.insert(chanson = ch_r[0],
            recueil = ch_r[1])
    for db in (db_genres,db_dialectes,db_recueils,db_chansons,
        db_ch_par_dial,db_ch_par_rec):
            db.commit()

# if one of the tables doesn't exist, create the base
try:
    SQLite.Base('chansons',conn).open()
except IOError:
    createBase()
