import os
from PyDbLite import MySQL

import k_databases
settings = k_databases.mysql_settings(CONFIG)

conn = MySQL.Connection(settings['host'],settings['user'],
    settings['password'])
try:
    _db = MySQL.Database("karrigell_demos",conn)
except:
    _db = conn.create("karrigell_demos")

db = {}
try:
    db['chansons'] = MySQL.Table('chansons',_db).open()
except IOError:
    createSongBase = Import('createSongBase')
    createSongBase.createBase(_db)
    db['chansons'] = MySQL.Table('chansons',_db).open()

for table in ['recueils','dialectes','genres',
    'chansons_par_recueil','chansons_par_dialecte']:
        db[table] = MySQL.Table(table,_db).open()
    