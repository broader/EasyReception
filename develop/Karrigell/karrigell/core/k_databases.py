import os

def get_engines():
    db_engines = {}

    # test if PyDbLite is installed
    try:
        import PyDbLite
        db_engines['PyDbLite'] = PyDbLite
    except ImportError:
        pass

    # test if sqlite is installed
    sqlite = None
    try:
        from sqlite3 import dbapi2 as sqlite
    except ImportError:
        try:
            from pysqlite2 import dbapi2 as sqlite
        except ImportError:
            pass
    if sqlite is not None:
        db_engines['SQLite'] = sqlite

    # test if MySQLdb is installed
    try:
        import MySQLdb
        db_engines['MySQL'] = MySQLdb
    except ImportError:
        pass
    
    return db_engines

def mysql_settings(config):
    mysql_settings_file = os.path.join(config.data_dir,'mysql_settings.py')
    settings = {}
    try:
        exec open(mysql_settings_file).read() in settings
        settings = dict([(key,value) for (key,value) in settings.iteritems()
            if not key.startswith('__') ])
        return settings
    except IOError:
        return None