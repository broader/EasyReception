import os
from PyDbLite import SQLite

db_path = os.path.join(CONFIG.data_dir,'business.sqlite')
conn = SQLite.sqlite.connect(db_path)

db = {}
try:
    db['chansons'] = SQLite.Base('chansons',conn).open()
except IOError:
    createSongBase = Import('createSongBase')
    createSongBase.createBase()
    db['chansons'] = SQLite.Base('chansons',conn).open()

for table in ['recueils','dialectes','genres',
    'chansons_par_recueil','chansons_par_dialecte']:
        db[table] = SQLite.Base(table,conn).open()
    