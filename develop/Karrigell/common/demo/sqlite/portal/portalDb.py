import os
from PyDbLite import SQLite

db_path = os.path.join(CONFIG.data_dir,'portal.sqlite')
db = SQLite.Database(db_path)

table = { 'users':SQLite.Table("users",db), 
    'news':SQLite.Table("news",db)
    }
table['users'].create(('login','TEXT'),
    ('password','TEXT'),
    ('bgcolor','TEXT'),
    ('fontfamily','TEXT'),
    mode="open")
table['news'].create(
    ('login','TEXT'),
    ('title','TEXT'),
    ('body','TEXT'),
    ('date','BLOB'),
    mode="open")
table['news'].is_datetime('date')
