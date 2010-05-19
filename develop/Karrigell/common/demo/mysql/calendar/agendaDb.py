import os
import k_databases
settings = k_databases.mysql_settings(CONFIG)

from PyDbLite import MySQL

conn = MySQL.Connection(settings['host'],settings['user'],
    settings['password'])
try:
    db = MySQL.Database("karrigell_demos",conn)
except:
    db = conn.create("karrigell_demos")

table = MySQL.Table("agenda",db)
table.create(('__id__','INTEGER PRIMARY KEY AUTO_INCREMENT'),
    ('content','TEXT'),
    ('begin_time','TIMESTAMP'),
    ('end_time','TIMESTAMP'),
    mode="open")
