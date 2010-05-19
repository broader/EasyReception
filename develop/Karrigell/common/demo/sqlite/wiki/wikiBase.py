"""Create or open the page database
"""
import os
from PyDbLite import SQLite

db_path = os.path.join(CONFIG.data_dir,"wiki.sqlite")
conn = SQLite.Database(db_path)
db = SQLite.Table("wiki",conn)

db.create(('name','TEXT'),
    ('content','TEXT'),
    ('admin','INTEGER'),
    ('nbvisits','INTEGER'),
    ('created','BLOB'),
    ('version','INTEGER'),
    ('lastmodif','BLOB'),
    mode="open")

db.is_datetime('created')
db.is_datetime('lastmodif')
