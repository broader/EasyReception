import os
import PyDbLite

db = PyDbLite.Base(os.path.join(CONFIG.data_dir,'agenda.pdl'))
db.create('content','begin_time','end_time',mode="open")
