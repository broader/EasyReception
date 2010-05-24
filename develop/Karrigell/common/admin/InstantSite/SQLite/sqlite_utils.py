from datetime import date,datetime
import re

try:
    from sqlite3 import dbapi2 as sqlite
except ImportError:
    from pysqlite2 import dbapi2 as sqlite
except ImportError:
    print "SQLite is not installed"
    raise SCRIPT_END

# CURRENT_TIME format is HH:MM:SS
# CURRENT_DATE : YYYY-MM-DD
# CURRENT_TIMESTAMP : YYYY-MM-DD HH:MM:SS
c_time_fmt = re.compile('(\d\d):(\d\d):(\d\d)')
c_date_fmt = re.compile('(\d\d\d\d)-(\d\d)-(\d\d)')
c_tmsp_fmt = re.compile('(\d\d\d\d)-(\d\d)-(\d\d) (\d\d):(\d\d):(\d\d)')

def guess_default_fmt(value):
    mo = c_time_fmt.match(value)
    if mo:
        h,m,s = [int(x) for x in mo.groups()]
        if (0<=h<=23) and (0<=m<=59) and (0<=s<=59):
            return 'CURRENT_TIME'
    mo = c_date_fmt.match(value)
    if mo:
        y,m,d = [int(x) for x in mo.groups()]
        try:
            date(y,m,d)
            return 'CURRENT_DATE'
        except:
            pass
    mo = c_tmsp_fmt.match(value)
    if mo:
        y,mth,d,h,mn,s = [int(x) for x in mo.groups()]
        try:
            datetime(y,mth,d,h,mn,s)
            return 'CURRENT_TIMESTAMP'
        except:
            pass

def get_info(file_name):
    """Return information about the tables in the database located
    in file_name
    Returns a dictionary indexed by table names
    For each table, the value is a list of tuples, one for each field,
    with :
    0 - field rank (0 to number of fields)
    1 - field name
    2 - field type
    3 - a flag ('yes' or 'no') if the field can be NULL
    4 - the default value as a 2-element tuple (def_type,def_value)
       . if no default is specified the tuple is (None,None)
       . if default is a STRING : ('STRING',value) - same for int and float
       . if default is a built-in time value : (None,'CURRENT_DATE') etc.
    5 - a flag if the field is a key
    """
    connection = sqlite.connect(file_name)
    cursor = connection.cursor()
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
    tables = {}
    for table in cursor.fetchall():
        tname = table[0]
        if tname == 'sqlite_sequence':
            continue
        tables[tname] = []
        cursor.execute('PRAGMA table_info (%s)' %tname)
        for field_info in cursor.fetchall():
            field_info = list(field_info)
            info = {'name':field_info[1],'type':field_info[2]}
            # can be null ?
            if field_info[3] == 0:
                info['allow_empty'] = True
            else:
                info['allow_empty'] = False
            # default value
            if field_info[4] is None:
                info['default'] = ''
            else:
                def_value = field_info[4]
                if isinstance(def_value,int):
                    def_type = 'INTEGER'
                elif isinstance(def_value,float):
                    def_type = 'REAL'
                elif isinstance(def_value,unicode):
                    # if default value is CURRENT_DATE etc. SQLite doesn't
                    # give the information, def_value is the value of the
                    # variable as a string. We have to guess...
                    # CURRENT_TIME format is HH:MM:SS
                    # CURRENT_DATE : YYYY-MM-DD
                    # CURRENT_TIMESTAMP : YYYY-MM-DD HH:MM:SS
                    default_fmt = guess_default_fmt(def_value)
                    if default_fmt is not None:
                        def_type = None
                        def_value = default_fmt
                    else:
                        def_type = 'STRING'
                info['default'] = def_value

            tables[tname].append(info)
    return tables

if __name__ == "__main__":
    import os
    print get_info(os.path.join(os.getcwd(),'quentel','test1.sqlite'))