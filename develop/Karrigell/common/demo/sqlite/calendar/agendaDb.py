import os
from PyDbLite import SQLite

db_path = os.path.join(CONFIG.data_dir,'agenda.sqlite')
conn = SQLite.Database(db_path)
db = SQLite.Table("agenda",conn)

db.create(('content','TEXT'),
    ('begin_time','BLOB'),
    ('end_time','BLOB'),
    mode="open")
db.is_datetime('begin_time')
db.is_datetime('end_time')