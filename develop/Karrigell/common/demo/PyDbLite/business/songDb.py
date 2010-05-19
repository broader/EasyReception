from PyDbLite import Base
db = {}
try:
    db['chansons'] = Base(REL('chansons.pdl')).open()
except IOError:
    createSongBase = Import('createSongBase')
    createSongBase.createBase()
    db['chansons'] = Base(REL('chansons.pdl')).open()

db['recueils'] = Base(REL('recueils.pdl')).open()
db['dialectes'] = Base(REL('dialectes.pdl')).open()
db['genres'] = Base(REL('genres.pdl')).open()
db['chansons_par_recueil'] = Base(REL('chansons_par_recueil.pdl')).open()
db['chansons_par_dialecte'] = Base(REL('chansons_par_dialecte.pdl')).open()
    