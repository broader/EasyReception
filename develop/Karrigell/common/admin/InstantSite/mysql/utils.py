import os
import MySQLdb
from HTMLTags import *
import settings

# file with MySQL connection info : host,user,password
mysql_settings_file = os.path.join(CONFIG.data_dir,'mysql_settings.py')

def _connection():
    exec(open(mysql_settings_file).read())
    return MySQLdb.connect(host=host,user=user,
        passwd=password)
    
def _cursor():
    exec(open(mysql_settings_file).read())
    connection = MySQLdb.connect(host=host,user=user,
        passwd=password)
    return connection.cursor()

def _get_tables(db_name):
    cursor = _cursor()
    cursor.execute('USE %s' %db_name)
    cursor.execute('SHOW TABLES')
    return [ table[0] for table in cursor.fetchall() ]

def _get_fields(db_name,table_name):
    infos = ('name','type','not_null','key','default','extra')
    fields = []
    cursor = _cursor()
    cursor.execute('USE %s' %db_name)
    try:
        cursor.execute('DESCRIBE %s' %table_name)
        for row in cursor.fetchall():
            column = dict(zip(infos,row))
            column['format'] = 'default'
            column['not_null'] = column['not_null']=='NO'
            if column['default'] is None:
                column['default'] = ''
            fields.append(column)
        return fields
    except:
        return []

def _hidden(**kw):
    return Sum([INPUT(Type="hidden",name=key,value=value)
        for (key,value) in kw.iteritems()])

def _create_settings_file(db_name,table_name):
    exec(open(mysql_settings_file).read())
    settings_file = os.path.join(CONFIG.data_dir,'mysql_admin',
        host,user,db_name,table_name,'settings.py')
    os.makedirs(os.path.dirname(settings_file))
    
    # save default view
    settings.Settings(settings_file).save({'views':['default'],
        'edit_forms':['default']})

    default_view_file = os.path.join(CONFIG.data_dir,'mysql_admin',
        host,user,db_name,table_name,'view_default.py')
    # default values
    fields = _get_fields(db_name,table_name)
    field_names = [f['name'] for f in fields]
    data = {'records_per_page':30,
        'order_by' : '',
        'condition':'',
        'style' : 'h_table',
        'table_headers' : str(Sum([TH(f) for f in field_names])),
        'data_format' : str(Sum([TD('$'+f) for f in field_names]))
    }
    settings.Settings(default_view_file).save(data)

    default_entry_file = os.path.join(CONFIG.data_dir,'mysql_admin',
        host,user,db_name,table_name,'entry_default.py')

    widgets = {}
    for field in fields:
        widgets[field['name']]={'type':'INPUT','size':10}
        if field['type'].lower()=='date':
            widgets[field['name']]={'type':'INPUT_DATE','size':10}
    data = {'widgets':widgets}
    settings.Settings(default_entry_file).save(data)

def _update_views_and_forms(db_name,table_name):
    # used if a field was created or removed
    exec(open(mysql_settings_file).read())
    settings_file = os.path.join(CONFIG.data_dir,'mysql_admin',
        host,user,db_name,table_name,'settings.py')
    if not os.path.exists(settings_file):
        _create_settings_file(db_name,table_name)
    conf = settings.Settings(settings_file).load()
        
    for entry in conf['edit_forms']:
        entry_file = os.path.join(CONFIG.data_dir,'mysql_admin',
            host,user,db_name,table_name,'entry_%s.py' %entry)
        entry_conf = settings.Settings(entry_file).load()
        widgets = entry_conf.get('widgets',{})
        fields = _get_fields(db_name,table_name)
        # new fields
        new_fields = [ f for f in fields if not f['name'] in widgets ]
        for field in new_fields:
            widgets[field['name']]={'type':'INPUT','size':10}
            if field['type'].lower()=='date':
                widgets[field['name']]={'type':'INPUT_DATE','size':10}
        # removed fields
        field_names = [ f['name'] for f in fields ]
        rem_fields = [ f for f in widgets if not f in field_names ]
        for field in rem_fields:
            del widgets[field]
        entry_conf['widgets'] = widgets
        settings.Settings(entry_file).save(entry_conf)        

def _create_view_file(db_name,table_name,view):
    exec(open(mysql_settings_file).read())
    settings_file = os.path.join(CONFIG.data_dir,'mysql_admin',
        host,user,db_name,table_name,'settings.py')
    # save default view
    conf = settings.Settings(settings_file).load()
    if view in conf['views']:
        raise Exception,'View %s already defined' %view
    else:
        conf['views'].append(view)
        settings.Settings(settings_file).save(conf)

    view_file = os.path.join(CONFIG.data_dir,'mysql_admin',
        host,user,db_name,table_name,'view_%s.py' %view)

    # default values
    fields = _get_fields(db_name,table_name)
    field_names = [f['name'] for f in fields]
    data = {'records_per_page':30,
        'order_by' : '',
        'condition':'',
        'style' : 'h_table',
        'table_headers' : str(Sum([TH(f) for f in field_names])),
        'data_format' : str(Sum([TD('$'+f) for f in field_names]))
    }
    widgets = {}
    for field in fields:
        widgets[field['name']]={'type':'INPUT','size':10}
        if field['type'].lower()=='date':
            widgets[field['name']]={'type':'INPUT_DATE','size':10}
    data['widgets'] = widgets
    settings.Settings(view_file).save(data)

def _make_entry(db_name,table_name,record=None):
    exec(open(mysql_settings_file).read())
    settings_file = os.path.join(CONFIG.data_dir,'mysql_admin',
        host,user,db_name,table_name,'entry_default.py')
    conf = settings.Settings(settings_file).load()
    try:
        return conf['entry_form']
    except KeyError:
        return _make_default_entry(db_name,table_name,record)

def _make_default_entry(db_name,table_name,record=None):
    exec(open(mysql_settings_file).read())
    entry_file = os.path.join(CONFIG.data_dir,'mysql_admin',
        host,user,db_name,table_name,'entry_default.py')
    conf = settings.Settings(entry_file).load()
    widgets = conf['widgets']

    fields = _get_fields(db_name,table_name)
    field_names = [f['name'] for f in fields]
    table = TABLE(Class="db_tables")
    for i,field in enumerate(fields):
        name = field['name']
        if field['extra'].lower()=='auto_increment':
            continue
        if field['type'].lower() in ['datetime','timestamp'] \
            and field['default'].lower()=='current_timestamp':
                continue
        cells = TH(name)
        widget = widgets.setdefault(name,{'type':'INPUT','size':10})

        if widget['type'] in ['INPUT','INPUT_DATE']:
            entry = INPUT(name=name,Id=name,size=widget['size'],value='$%s' %name)
        elif widget['type'] in ['TEXTAREA','WHIZZYWIG']:
            entry = TEXTAREA('$%s' %name,name=name,Id=name,
                rows=widget['rows'],cols=widget['cols'])
        elif widget['type'] in ['SELECT','RADIO']:
            ext_table = widget['table']
            ext_fields_pattern = widget['fields']
            template = string.Template(ext_fields_pattern)
            cursor = _cursor()
            # get auto increment field
            ext_fields = _get_fields(db_name,ext_table)
            ext_field_names = [f['name'] for f in ext_fields]
            ext_id = [f for f in ext_fields 
                if f['extra'].lower()=='auto_increment'][0]['name']
            # select records from external table
            cursor.execute('SELECT * FROM %s.%s' %(db_name,ext_table))
            options = []
            for rec in cursor.fetchall():
                rec_dict = dict(zip(ext_field_names,rec))
                opt_value = rec_dict[ext_id]
                opt_text = template.safe_substitute(rec_dict)
                options.append((opt_text,opt_value))
            if widget['type']=='SELECT':
                entry = SELECT(name=name,Id=name)
                for opt_text,opt_value in options:
                    entry <= OPTION(opt_text,value=opt_value)
            elif widget['type']=='RADIO':
                lines = []
                for opt_text,opt_value in options:
                    line = INPUT(Type='radio',name=name,value=opt_value)
                    line += '&nbsp;'+opt_text+BR()
                    lines.append(str(line))
                entry = '<br>'.join(lines)
        cells += TD(entry,Class="db_table")

        table <= TR(cells)
    return table
