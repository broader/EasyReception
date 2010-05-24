"""Create or open the page database

Save this file as wikiBase.py to use a PyDBLite database
"""
import os
from PyDbLite import Base

db = Base(os.path.join(CONFIG.data_dir,'pages.pdl'))
db.create('name','content','admin','nbvisits','created',
    'version','lastmodif',mode="open")
db.create_index('name')
