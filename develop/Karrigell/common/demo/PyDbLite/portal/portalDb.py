import os
from PyDbLite import Base

portal_dir = os.path.join(CONFIG.data_dir,"portal")
if not os.path.exists(portal_dir):
    os.mkdir(portal_dir)

db = { 'users':Base(os.path.join(portal_dir,'users.pdl')), 
    'news':Base(os.path.join(portal_dir,'news.pdl')) }
db['users'].create('login','password','bgcolor','fontfamily',
    mode="open")
db['news'].create('login','title','body','date',mode="open")