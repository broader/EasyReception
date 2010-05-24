import os
import string
import cgi
import re
import MySQLdb

import settings
from HTMLTags import *

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

def _get_fields(db_name,table_name):
    infos = ('name','type','not_null','key','default','extra')
    fields = []
    cursor = _cursor()
    cursor.execute('USE %s' %db_name)
    cursor.execute('DESCRIBE %s' %table_name)
    for row in cursor.fetchall():
        column = dict(zip(infos,row))
        column['format'] = 'default'
        column['not_null'] = column['not_null']=='NO'
        if column['default'] is None:
            column['default'] = ''
        fields.append(column)
    return fields

def _actions(db_name,table_name,edit_form,field,value):
    links = []
    pic = IMG(src='../images/b_edit.png',border=0)
    links.append(A(pic,
        href='edit?form=%s&field=%s&value=%s' %(edit_form,field,value),
        title=_('Edit')))
    pic = IMG(src='../images/b_drop.png',border=0)
    links.append(A(pic,
        href='delete?field=%s&value=%s' %(field,value),
        title=_('Drop')))
    return TABLE(TR(Sum([TD(link,Class='tb_table') for link in links])))

def browse_table(db_name,table_name,view,start,role,**kw):
    start = int(start)
    exec(open(mysql_settings_file).read())
    old = locals().keys()
    settings_file = os.path.join(CONFIG.data_dir,'mysql_admin',
        host,user,db_name,table_name,'view_'+view+'.py')
    conf = settings.Settings(settings_file).load()
    
    edit_form = kw.get('edit_form','default')
    actions = role in ['admin','edit']

    fields = _get_fields(db_name,table_name)
    field_names = [f['name'] for f in fields]

    cursor = _cursor()
    # PRIMARY KEY ?
    id_field = False
    for field in fields:
        if field['key'].upper()=='PRI':
            id_field = field['name']

    if not conf['order_by']:
        query = 'SELECT * FROM %s.%s' %(db_name,table_name)
    else:
        query = 'SELECT * FROM %s.%s ORDER BY %s' \
            %(db_name,table_name,conf['order_by'])
    if conf['condition']:
        template = string.Template(conf['condition'])
        query += ' WHERE %s' %template.safe_substitute(kw)

    query += ' LIMIT %s,%s' %(start,conf['records_per_page'])
    try:
        cursor.execute(query)
    except:
        content = "error with request %s" %query
        return content
    _records = cursor.fetchall()

    # build list of dictionaries
    records = []
    for record in _records:
        dico = dict(zip(field_names,record))
        # replace None by &nbsp;
        for f,v in dico.iteritems():
            if v is None:
                dico[f] = '&nbsp;'
        records.append(dico)

    # links to browse the table
    navig = TR()
    navig <= TD(BUTTON('<',onClick="location.href='show?view=%s&start=%s'"
            %(view,max(0,start-conf['records_per_page'])),
            disabled=start-conf['records_per_page']<0))
    cursor.execute('SELECT COUNT(*) FROM %s.%s' %(db_name,table_name))
    nb_recs = cursor.fetchone()[0]
    navig <= TD(BUTTON('>',onClick="location.href='show?view=%s&start=%s'" 
            %(view,start+conf['records_per_page']),
            disabled=start+conf['records_per_page']>nb_recs))

    if conf['style']=='h_table':
        # one line per record
        table = TABLE(Class="db_table")
        table_headers = conf['table_headers']
        if id_field and actions:
            table_headers = str(TH(_('Actions')))+conf['table_headers']
        table <= TR(table_headers)
        for record in records:
            recid = record[id_field]
            row = string.Template(conf['data_format']).safe_substitute(record)
            
            if id_field and actions:
                actions = _actions(db_name,table_name,edit_form,id_field,recid)
                row = str(TD(actions))+row
            table <= TR(row)
    elif conf['style']=='v_table':
        # one line per field
        table = TABLE(Class="db_table")
        if id_field and actions:
            row = TD(_('Actions'))
            for record in records:
                recid = record[id_field]
                row += TD(_actions(db_name,table_name,edit_form,id_field,recid))
            table <= TR(row)
        templates = [string.Template(df) for df in conf['data_format']]
        for header,template in zip(conf['table_headers'],templates):
            row = header
            row += ''.join([template.safe_substitute(record)
                for record in records])
            table <= TR(row)

    elif conf['style']=='no_table':
        # no table, apply template to records
        template = string.Template(conf['data_format'])
        table = ''
        for record in records:
            zone = DIV(Class='record')
            if id_field and actions:
                actions = _('Actions')
                recid = record[id_field]
                actions += _actions(db_name,table_name,edit_form,id_field,recid)
                zone <= actions
            zone <= template.safe_substitute(record)
            table += zone

    content = conf.get("header","")
    content += TABLE(navig)
    content += table
    content += HR()
    return content

def enter_record(db_name,table_name):
    exec(open(mysql_settings_file).read())
    settings_file = os.path.join(CONFIG.data_dir,'mysql_admin',
        host,user,db_name,table_name,'settings.py')

    table = utils._make_entry(db_name,table_name)
    
    form = FORM(action='insert_record',method="post")
    # modify names for db_name and table_name to avoid conflicts with
    # field names
    form <= INPUT(Type="hidden",name="db_name[",value=db_name)
    form <= INPUT(Type="hidden",name="table_name[",value=table_name)
    form <= table
    form <= INPUT(Type="submit",value=_('Save'))
    
    content = form
    table_menu = _table_menu(db_name,table_name,"enter_record")
    print KT('entry_template.kt',**locals())

def insert_record(**kw):
    exec(open(mysql_settings_file).read())
    conn = utils._connection()
    cursor = conn.cursor()
    db_name = kw['db_name[']
    table_name = kw['table_name[']
    del kw['db_name[']
    del kw['table_name[']
    sql = 'INSERT INTO %s.%s SET ' %(db_name,table_name)
    sql += ','.join(['%s=%%s' %key for key in kw.keys()])
    cursor.execute(sql,kw.values())
    conn.commit()
    conn.close()
    
    raise HTTP_REDIRECTION,'browse_table?db_name=%s&table_name=%s' \
        %(db_name,table_name)

def update_record(db_name,table_name,**kw):
    exec(open(mysql_settings_file).read())
    conn = _connection()
    cursor = conn.cursor()

    fields = _get_fields(db_name,table_name)
    for field in fields:
        if field['key'].upper()=='PRI':
            id_field = field['name']
            break
    if id_field in kw:
        id_value = int(kw[id_field])
        del kw[id_field]
        sql = 'UPDATE %s.%s SET ' %(db_name,table_name)
        sql += ','.join(['%s=%%s' %key for key in kw.keys()])
        sql += 'WHERE %s=%%s' %id_field
        cursor.execute(sql,kw.values()+[id_value])
    else: # new record, no record id passed
        sql = 'INSERT INTO %s.%s SET ' %(db_name,table_name)
        sql += ','.join(['%s=%%s' %key for key in kw.keys()])
        cursor.execute(sql,kw.values())
    
    conn.commit()
    conn.close()

def _make_widgets(db_name,table_name,form,record=None):
    exec(open(mysql_settings_file).read())
    settings_file = os.path.join(CONFIG.data_dir,'mysql_admin',
        host,user,db_name,table_name,'entry_'+form+'.py')
    conf = settings.Settings(settings_file).load()

    fields = _get_fields(db_name,table_name)
    field_names = [f['name'] for f in fields]
    data = dict([(f,'') for f in field_names])
    if record is not None:
        data = dict(zip(field_names,record))
        for k in data:
            if data[k] is None:
                data[k] = ''
        
    table = TABLE(Class="db_tables")
    widget_list = []
    for i,field in enumerate(fields):
        name = field['name']
        if field['extra'].lower()=='auto_increment':
            continue
        if field['type'].lower() in ['datetime','timestamp'] \
            and field['default'].lower()=='current_timestamp':
                continue
        widget = conf['widgets'][name]
        if widget['type'] == 'INPUT':
            entry = INPUT(name=name,Id=name,size=widget['size'],
                value = data[name])
        elif widget['type'] == 'INPUT_DATE':
            entry = INPUT(name=name,Id=name,size=widget['size'],
                value = data[name])
            entry += IMG(src='../images/calendar.gif',
                onClick="calendar(this,'YYYY-MM-DD')",
                Id=name+'_button')
        elif widget['type'] in ['TEXTAREA','WHIZZYWIG']:
            entry = TEXTAREA(data[name],
                name=name,Id=name,
                rows=widget['rows'],cols=widget['cols'],
                )
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
                    entry <= OPTION(opt_text,value=opt_value,
                        selected=opt_value==data[name])
            elif widget['type']=='RADIO':
                lines = []
                for opt_text,opt_value in options:
                    line = INPUT(Type='radio',name=name,value=opt_value,
                        checked=opt_value==data[name])
                    line += '&nbsp;'+opt_text+BR()
                    lines.append(str(line))
                entry = '<br>'.join(lines)
        widget_list.append((name,entry))
    return widget_list

def _make_default_entry(db_name,table_name,form,record=None):
    table = TABLE(Class="db_tables")
    for name,entry in _make_widgets(db_name,table_name,form,record):
        cells = TH(name)
        cells += TD(entry,Class="db_table")
        table <= TR(cells)
    return table

def _make_entry(db_name,table_name,form,record=None):
    exec(open(mysql_settings_file).read())
    settings_file = os.path.join(CONFIG.data_dir,'mysql_admin',
        host,user,db_name,table_name,'entry_'+form+'.py')
    conf = settings.Settings(settings_file).load()
    try:
        return conf['entry_form']
    except KeyError:
        return _make_default_entry(db_name,table_name,form,record)

def edit_record(db_name,table_name,form,field,value):
    exec(open(mysql_settings_file).read())
    cursor = _cursor()
    record = None
    if field is not None:
        sql = 'SELECT * FROM %s.%s WHERE %s=%%s' %(db_name,table_name,field)
        cursor.execute(sql,(value,))
        record = cursor.fetchone()
    
    fields = _get_fields(db_name,table_name)
    field_names = [f['name'] for f in fields]
    table = _make_entry(db_name,table_name,form,record)
    if record:
        rec_dict = dict(zip(field_names,record))
    else:
        rec_dict = dict([(f,'') for f in field_names])
    template = string.Template(str(table))
    table = template.safe_substitute(rec_dict)
    
    form = FORM(action='update_record',method="post")
    if field is not None:
        form <= INPUT(Type="hidden",name=field,value=value)
    form <= table
    form <= INPUT(Type="submit",value=_('Save'))
    
    content = form
    return content

def delete_record(db_name,table_name,field,value):
    exec(open(mysql_settings_file).read())
    conn = _connection()
    cursor = conn.cursor()
    sql = 'DELETE FROM %s.%s WHERE %s=%%s' %(db_name,table_name,field)
    cursor.execute(sql,(value,))
    conn.commit()
    conn.close()
