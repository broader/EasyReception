import sys,os, random
from PyDbLite import Base

def createBase():
    """for path in ('chansons','recueils','dialectes',
        'genres','chansons_par_dialecte',
        'chansons_par_recueil'):
        try:
            os.remove(path+'.pdl')
        except OSError:
            pass"""

    txt_path = os.path.join(os.path.dirname(os.path.dirname(CWD)),
        "base.txt")
    chansons=open(txt_path).readlines()

    db_genres = Base(REL('genres.pdl')).create('nom',mode="override")
    db_chansons = Base(REL('chansons.pdl')).create('url','breton',
        'francais','prix','genre',mode="override")
    db_recueils = Base(REL('recueils.pdl')).create('nom',mode="override")
    db_dialectes = Base(REL('dialectes.pdl')).create('nom',mode="override")
    db_ch_par_dial = Base(REL('chansons_par_dialecte.pdl')).create(
        'chanson','dialecte',mode="override")
    db_ch_par_rec = Base(REL('chansons_par_recueil.pdl')).create(
        'chanson','recueil',mode="override")


    l_chansons=[]
    id_chanson = 0
    l_recueils=[]
    l_dialectes=[]
    l_genres=[]
    chansonsParRecueil=[]
    chansonsParGenre=[]
    chansonsParDialecte=[]

    for line in chansons:
        [url,breton,francais,recueils,genre,dialectes,enreg]=line.strip().split("#")
        if not genre in l_genres:
            l_genres.append(genre)
        id_genre = l_genres.index(genre)
        prix=random.randrange(200,400)
        l_chansons.append([url,breton,francais,prix,id_genre])

        recs=recueils.split(";")
        for rec in recs:
            if not rec in l_recueils:
                l_recueils.append(rec)
            id_recueil = l_recueils.index(rec)
            chansonsParRecueil.append([id_chanson,id_recueil])
        dials=dialectes.split(";")
        for dial in dials:
            if not dial in l_dialectes:
                l_dialectes.append(dial)
            id_dialecte = l_dialectes.index(dial)
            chansonsParDialecte.append([id_chanson, id_dialecte])

        id_chanson += 1

    for g in l_genres:
        db_genres.insert(nom=g)
    for d in l_dialectes:
        db_dialectes.insert(nom=d)
    for r in l_recueils:
        db_recueils.insert(nom=r)

    for ch in l_chansons:
        db_chansons.insert(**dict(zip(db_chansons.fields,ch)))
    for ch_d in chansonsParDialecte:
        db_ch_par_dial.insert(chanson = ch_d[0],
            dialecte = ch_d[1])
    for ch_r in chansonsParRecueil:
        db_ch_par_rec.insert(chanson = ch_r[0],
            recueil = ch_r[1])
    for db in (db_genres,db_dialectes,db_recueils,db_chansons,
        db_ch_par_dial,db_ch_par_rec):
            db.commit()

if not os.path.exists(REL('chansons.pdl')):
    createBase()
