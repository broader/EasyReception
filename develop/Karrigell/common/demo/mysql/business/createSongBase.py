import sys,os, random
from PyDbLite import MySQL

import k_databases
settings = k_databases.mysql_settings(CONFIG)

conn = MySQL.Connection(settings['host'],settings['user'],
    settings['password'])
try:
    db = MySQL.Database("karrigell_demos",conn)
except:
    db = conn.create("karrigell_demos")

def createBase(db):

    txt_path = os.path.join(os.path.dirname(os.path.dirname(CWD)),
        "base.txt")
    chansons=open(txt_path).readlines()

    db_genres = MySQL.Table('genres',db)
    db_genres.create(('nom','TEXT'),mode="override")

    db_chansons = MySQL.Table('chansons',db)
    db_chansons.create(('__id__','INTEGER PRIMARY KEY AUTO_INCREMENT'),
        ('url','TEXT'),
        ('breton','TEXT'),
        ('francais','TEXT'),
        ('prix','INTEGER'),
        ('genre','INTEGER'),
        mode="override")

    db_recueils = MySQL.Table('recueils',db)
    db_recueils.create(('__id__','INTEGER PRIMARY KEY AUTO_INCREMENT'),
        ('nom','TEXT'),mode="override")

    db_dialectes = MySQL.Table('dialectes',db)
    db_dialectes.create(('__id__','INTEGER PRIMARY KEY AUTO_INCREMENT'),
        ('nom','TEXT'),mode="override")

    db_ch_par_dial = MySQL.Table('chansons_par_dialecte',db)
    db_ch_par_dial.create(('__id__','INTEGER PRIMARY KEY AUTO_INCREMENT'),
        ('chanson','INTEGER'),
        ('dialecte','INTEGER'),
        mode="override")
    
    db_ch_par_rec = MySQL.Table('chansons_par_recueil',db)
    db_ch_par_rec.create(('__id__','INTEGER PRIMARY KEY AUTO_INCREMENT'),
        ('chanson','INTEGER'),
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
    MySQL.Table('chansons',db).open()
except IOError:
    createBase(db)
