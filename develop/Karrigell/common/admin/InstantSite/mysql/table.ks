import os
import string
import cgi
import re
import MySQLdb

import settings
from HTMLTags import *

Types = ['TINYINT','BIT','BOOL',
  'SMALLINT',
  'MEDIUMINT',
  'INT',
  'INTEGER',
  'BIGINT',
  'REAL',
  'DOUBLE',
  'FLOAT',
  'DECIMAL','DEC','FIXED',
  'NUMERIC',
  'DATE',
  'TIME',
  'TIMESTAMP',
  'DATETIME',
  'YEAR',
  'CHAR',
  'VARCHAR',
  'TINYBLOB',
  'BLOB',
  'MEDIUMBLOB',
  'LONGBLOB',
  'TINYTEXT',
  'TEXT',
  'MEDIUMTEXT',
  'LONGTEXT',
  'ENUM',
  'SET']
Types.sort()

# restrict access to administrator
Login(role=["admin"],valid_in='/')
user = COOKIE['login'].value

# unicode
SET_UNICODE_OUT('utf-8')

# utility functions
utils = Import('utils',CONFIG=CONFIG)

# file with MySQL connection info : host,user,password
mysql_settings_file = os.path.join(CONFIG.data_dir,'mysql_settings.py')

# possible widgets in entry forms
widget_list = ['INPUT','INPUT_DATE','SELECT','RADIO','TEXTAREA','WHIZZYWIG']

def _get_fields(db_name,table_name):
    infos = ('name','type','not_null','key','default','extra')
    fields = []
    cursor = utils._cursor()
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

def _table_menu(db_name,table_name,selected):
    args = "db_name=%s&table_name=%s" %(db_name,table_name)
    cells = []
    for label,href in [(_('Structure'),'table_structure'),
        (_('Views'),'customize_view'),
        (_('Edit forms'),'customize_entry_form')]:
        cell = TD(A(label,href=href+'?'+args,Class="table_menu"))
        if href==selected:
            cell.attrs['Class']='selected'
        else:
            cell.attrs['Class']='unselected'
        cells.append(cell)
    cells.append(TD('&nbsp;',Class='fill_menu'))
    res = A(_('Manage'),href='../manage.ks?db_name=%s&table_name=%s' 
        %(db_name,table_name),target='_blank')
    return res+BR()+TABLE(TR(Sum(cells)),cellpadding=5,width="100%")

def _actions(db_name,table_name,field,value):
    links = []
    for icon,title,href in [('b_edit',_('Edit'),'edit_record'),
        ('b_drop',_('Drop'),'delete_record')]:

        pic = IMG(src='../images/%s.png' %icon,border=0)
        links.append(A(pic,
            href='../table.ks/%s?db_name=%s&table_name=%s&field=%s&value=%s' 
                %(href,db_name,table_name,field,value),
            title=title))
    return TABLE(TR(Sum([TD(link,Class='tb_table') for link in links])))

def table_structure(db_name,table_name,new=False):
    exec(open(mysql_settings_file).read())
    settings_file = os.path.join(CONFIG.data_dir,'mysql_admin',
        host,user,db_name,table_name,'settings.py')
    if not os.path.exists(settings_file) and not new:
        utils._create_settings_file(db_name,table_name)

    cursor = utils._cursor()
    cursor.execute('USE %s' %db_name)

    form = FORM(action="remove_fields",name="fields",method="post")
    form <= INPUT(Type="hidden",name="db_name",value=db_name)
    form <= INPUT(Type="hidden",name="table_name",id="table",value=table_name)
    _table = TABLE(Class="db_tables")
    _table <= TR(TH('&nbsp')+TH('Field')+TH('Type')+TH('Null')+TH('Key')+
        TH('Default')+TH('Extra'))

    content = ''
    if not new:
        cursor.execute('DESCRIBE %s' %table_name)
        columns = []
        for field_info in cursor.fetchall():
            columns.append(field_info)
            s = INPUT(Type="checkbox",name="field[]",
                value=field_info[0],onClick="sel_field()")
            _table <= TR(TD(s)+
                Sum([ TD(item or '&nbsp;',Class="db_table") 
                        for item in field_info ]))
        form <= _table
        form <= INPUT(Type="submit",
                value="Remove selected",id="sub",disabled=True)
        content = form

    if not new:
        form = FORM(action = "insert_field",name="add",method="post")
    else:
        form = FORM(action = "insert_field",
            name="add",method="post",target="_top")
    form <= INPUT(Type="hidden",name="new",value=new or 0)
    form <= INPUT(Type="hidden",name="db_name",value=db_name)
    form <= INPUT(Type="hidden",name="table_name",id="table",value=table_name)
    form <= H4('Insert new field')
    form <= P()
    field_def = DIV(Id="field_def")
    table = TABLE()
    
    table1 = TABLE(Class="db_tables")
    table1 <= TR(TD(B('Field name'))+
                 TD(INPUT(name="field",onKeyup="change_type()")))

    if not new:
        pos = OPTION('FIRST',value="FIRST")
        for i,item in enumerate(columns):
            pos += OPTION('AFTER %s' %item[0],value='AFTER %s' %item[0],
                 selected = i==(len(columns)-1)) 
        table1 <= TR(TD('Position')
            +TD(SELECT(pos,name="position",onChange="validate()")))

    row = TR()
    row <= TD('Type')
    row <= TD(SELECT(Sum([ OPTION(t,value=t,selected=t=='TEXT') for t in Types ]),
            name="Type",id="Type",onChange="change_type()"))
    table1 <= row
    table1 <= TR(TD('NULL')+TD(TEXT('NULL')+
             INPUT(name="null",Type="radio",
                   checked=True,onClick="ch_null(0)") +
             TEXT('NOT NULL')+
             INPUT(name="null",Type="radio",onClick="ch_null(1)")))
    table1 <= TR(TD('DEFAULT')+
        TD(INPUT(id="default",name="default",disabled=True,onKeyUp="validate()",
            onChange="change_type()"),Id='default_cell'))
    table1 <= TR(TD('KEY')+TD(TEXT('no')+
             INPUT(name="key",Type="radio",
                   checked=True,onClick="ch_key(0)") +
             TEXT('UNIQUE')+
             INPUT(name="key",Type="radio",onClick="ch_key(1)")+
             TEXT('PRIMARY KEY')+
             INPUT(name="key",Type="radio",onClick="ch_key(2)")
             ))
    for tag in table1.get_by_tag('TD'):
        tag.attrs['Class']='db_table'
    cell1 = TD(table1)
    cell2 = TD(DIV(id="f_opt",style="position:absolute"),valign="top")
    table <= TR(cell1+cell2)
    field_def <= table
    field_def <= P("SQL statement")
    field_def <= BR()+TEXTAREA(name="sql",cols="40",rows="4")
    field_def <= INPUT(id="subm",Type="submit", value="Ok")

    form <= field_def
    content += form

    table_menu = _table_menu(db_name,table_name,"table_structure")
    print KT('table_template.kt',**locals())

def _view_menu(db_name,table_name,selected_view=None):
    exec(open(mysql_settings_file).read())
    settings_dir = os.path.join(CONFIG.data_dir,'mysql_admin',
        host,user,db_name,table_name)
    settings_file = os.path.join(settings_dir,'settings.py')
    if not os.path.exists(settings_file):
        utils._create_settings_file(db_name,table_name)
    views = [ os.path.splitext(f)[0][5:] for f in os.listdir(settings_dir)
        if f.startswith('view_')]
    row = TR()
    link = 'customize_view?db_name=%s&table_name=%s' \
        %(db_name,table_name)
    if selected_view is None and views:
        selected_view = views[0]
    for view in views:
        cell = TD(A(view,href=link+'&view=%s' %view,Class="table_menu"),
            Class="unselected")
        if view == selected_view:
            cell.attrs['Class'] = 'selected'
        row <= cell
    form = FORM(action="create_view")
    form <= utils._hidden(db_name=db_name,table_name=table_name)
    form <= INPUT(name='view')+INPUT(Type="submit",value=_('Create'))
    row <= TD(form)
    return TABLE(row),selected_view

def create_view(db_name,table_name,view):
    try:
        utils._create_view_file(db_name,table_name,view)
    except Exception,msg:
        content = msg
        print KT('msg_template.kt',**locals())
        raise SCRIPT_END
    args = 'db_name=%s&table_name=%s&view=%s' %(db_name,table_name,view)
    raise HTTP_REDIRECTION,"customize_view?"+args

def customize_view(db_name,table_name,view=None):
    exec(open(mysql_settings_file).read())

    view_menu,view = _view_menu(db_name,table_name,view)
    args = "db_name=%s&table_name=%s&view=%s" %(db_name,table_name,view)

    settings_file = os.path.join(CONFIG.data_dir,'mysql_admin',
        host,user,db_name,table_name,'view_'+view+'.py')
    if not os.path.exists(settings_file):
        utils._create_settings_file(db_name,table_name)
    conf = settings.Settings(settings_file).load()
    field_names = [f['name'] for f in utils._get_fields(db_name,table_name)]

    # 3 style options : horizontal table, vertical table, no table
    styles = {'h_table':_('Horizontal table'),
        'v_table':_('Vertical table'),'no_table':_('No table')}

    def_style = H4('Style')
    def_style += _('Current style is %s' %styles[conf['style']])
    def_style += '&nbsp;'+A('Format...',href="format_view?%s&style=%s" 
        %(args,conf['style']))+BR()
    def_style += _('or select another style :')
    for _style in [s for s in styles if not s==conf['style']]:
        def_style += '&nbsp;'+A(styles[_style],
            href="format_view?%s&style=%s" %(args,_style))

    input_nbrecs = H4(_('Records per page'))
    input_nbrecs += INPUT(name='records_per_page',
        value=conf['records_per_page'])
    
    input_order_by = H4(_('Order records by...'))
    input_order_by += _('SQL syntax : <i>field1,field2 DESC</i> means : '
        'order the result by'
        ' field1 in ascending order, and for the records that have the'
        ' same value for field1, sort them by field2 in descending order')
    input_order_by += BR()+_('Fields in this table : %s' %(','.join(field_names)))
    input_order_by += BR()+INPUT(name='order_by',value=conf['order_by'])

    input_condition = H4(_('Filter records where...'))
    input_condition += _('SQL syntax : <i>field = $param</i> means : '
        'show the result where field equals the parameter <i>param</i>'
        '<br>Param is typically provided in the query string calling the view : '
        'for instance the record id of a blog entry is passed to the view '
        'showing all the comments to this entry : ?blog_id=23. In this '
        'case if the comments table has a field <i>parent</i> the condition '
        'to enter is : parent = $blog_id')
    input_condition += BR()+INPUT(name='condition',value=conf['condition'])
    
    form = FORM(action="update_nb_recs")
    form <= utils._hidden(db_name=db_name,table_name=table_name,view=view)
    form <= input_nbrecs
    form <= INPUT(Type="submit",value="Ok")
    form <= input_condition
    form <= INPUT(Type="submit",value="Ok")
    form <= input_order_by
    form <= INPUT(Type="submit",value="Ok")

    content = view_menu
    content += form
    content += def_style

    table_menu = _table_menu(db_name,table_name,"customize_view")
    print KT('customize_template.kt',**locals())

def format_view(db_name,table_name,view,style):
    exec(open(mysql_settings_file).read())
    view_menu,view = _view_menu(db_name,table_name,view)
    settings_file = os.path.join(CONFIG.data_dir,'mysql_admin',
        host,user,db_name,table_name,'view_'+view+'.py')
    conf = settings.Settings(settings_file).load()
    field_names = [f['name'] for f in utils._get_fields(db_name,table_name)]

    # buttons for the whizzywig textarea
    ww_buttons = 'all'

    field_list = ['$%s' %f for f in field_names]
    def_format = H4(_('Format'))

    script = 'btn._f="/whizzywig/WhizzywigToolbar.png";\n'
    script += 'buttonPath="/whizzywig/";\n'
    content = SCRIPT(script,Type='text/javascript')
    content += view_menu
    
    header = H2('Page header')
    header += TEXTAREA(conf.get('header',''),name="header",id="header")
    header += SCRIPT('makeWhizzyWig("header","%s")' %ww_buttons,
            Type='text/javascript')

    if style=="h_table":
        # zone for style = horizontal table
        if not conf['style'] == style:
            # if we are changing style, build default values
            # for horizontal tables
            table_headers = Sum([TH(f) for f in field_names])
            data_format = Sum([TD('$'+f) for f in field_names])
        else:
            table_headers = conf['table_headers']
            data_format = conf['data_format']
        def_format = H3(_('Horizontal table'))
        def_format += _('First line = table headers')
        def_format += BR()+_('Second line is a template with placeholders for values: ')
        def_format += ','.join(field_list)
        def_format += _(". Don't change their names !")
        table = TABLE(border=1)
        table <= TR(table_headers)
        table <= TR(data_format)
        area = TEXTAREA(table,
            Id="format",name="format",rows=10,cols=100)
        area += SCRIPT('makeWhizzyWig("format","%s")' %ww_buttons,
            Type='text/javascript')

        zone = header+def_format+area
        zone += INPUT(Type="hidden",name="style",value="h_table")
        zone += utils._hidden(db_name=db_name,table_name=table_name,view=view)
        zone += INPUT(Type="submit",value="Ok")
        content += FORM(zone,action="update_format",method="post")

    elif style=="v_table":
        # zone for style = no table
        if not conf['style'] == style:
            # if we are changing style, build default values 
            # for vertical tables
            table_headers = [TH(f) for f in field_names]
            data_format = [TD('$'+f) for f in field_names]
        else:
            table_headers = conf['table_headers']
            data_format = conf['data_format']
        def_format = H3(_('Vertical table'))
        def_format += _('First line = table headers')
        def_format += BR()+_('Second line is a template with placeholders for values: ')
        def_format += ','.join(field_list)
        def_format += _(". Don't change them !")
        table = TABLE(border=1)
        for header,data in zip(table_headers,data_format):
            table <= TR(header+data)
        area = TEXTAREA(table,
            Id="format",name="format",rows=10,cols=100)
        area += SCRIPT('makeWhizzyWig("format","%s")' %ww_buttons,
            Type='text/javascript')

        zone = header+def_format+area
        zone += INPUT(Type="hidden",name="style",value="v_table")
        zone += utils._hidden(db_name=db_name,table_name=table_name,view=view)
        zone += INPUT(Type="submit",value="Ok")
        content += FORM(zone,action="update_format",method="post")

    elif style=='no_table':
        # zone for free style
        if not conf['style'] == style:
            # if we are changing style, build default values 
            # for free style
            table_headers = ""
            data_format = '<br>'.join(['%s : $%s' %(f,f) for f in field_names])
        else:
            table_headers = conf['table_headers']
            data_format = conf['data_format']
        def_format = H3(_('Free style'))
        def_format += BR()+_('Use placeholders for values: ')
        def_format += ','.join(field_list)
        def_format += _(". Don't change their names !")
        area = TEXTAREA(data_format,
            Id="format",name="format",rows=10,cols=100)
        area += SCRIPT('makeWhizzyWig("format","%s")' %ww_buttons,
            Type='text/javascript')

        zone = header+def_format+area
        zone += INPUT(Type="hidden",name="style",value="no_table")
        zone += utils._hidden(db_name=db_name,table_name=table_name,view=view)
        zone += INPUT(Type="submit",value="Ok")
        content += FORM(zone,action="update_format",method="post")

    table_menu = _table_menu(db_name,table_name,"customize_view")

    print KT('customize_template.kt',**locals())

def update_nb_recs(**kw):
    exec(open(mysql_settings_file).read())
    db_name = kw["db_name"]
    table_name = kw["table_name"]
    view = kw["view"]
    del kw['table_name']
    del kw['db_name']
    del kw["view"]
    if 'records_per_page' in kw:
        kw['records_per_page']=int(kw['records_per_page'])
    settings_file = os.path.join(CONFIG.data_dir,'mysql_admin',
        host,user,db_name,table_name,'view_'+view+'.py')
    settings.Settings(settings_file).save(kw)
    raise HTTP_REDIRECTION,'customize_view?db_name=%s&table_name=%s&view=%s' \
        %(db_name,table_name,view)

def update_format(**kw):
    exec(open(mysql_settings_file).read())
    db_name = kw["db_name"]
    table_name = kw["table_name"]
    view = kw["view"]
    settings_file = os.path.join(CONFIG.data_dir,'mysql_admin',
        host,user,db_name,table_name,'view_'+view+'.py')
    del kw['table_name']
    del kw['db_name']
    del kw['view']
    format = kw['format']
    del kw['format']

    if kw['style']=='h_table':
        # headers line : first row between <tr> and </tr>
        # data format line : second row
        pos = 0
        for key in ['table_headers','data_format']:
            start = format.find('<tr>',pos)
            end = format.find('</tr>',pos)
            useful = format[start+4:end]
            kw[key] = useful
            pos = end+5

    elif kw['style']=='v_table':
        # each row between <tr> and </tr> has a header cell and a data cell
        pos = 0
        table_headers,data_format=[],[]
        while True:
            start = format.find('<tr>',pos)
            if start<0:
                break
            end = format.find('</tr>',pos)
            useful = format[start+4:end]
            sep = useful.find('<td>')
            table_headers.append(useful[:sep].strip())
            data_format.append(useful[sep:].strip())
            pos = end+5
        kw['table_headers'] = table_headers
        kw['data_format'] = data_format

    elif kw['style']=='no_table':
        kw['data_format'] = format
        kw['table_headers'] = ''

    settings.Settings(settings_file).save(kw)
    raise HTTP_REDIRECTION,'customize_view?db_name=%s&table_name=%s&view=%s' \
        %(db_name,table_name,view)

def remove_fields(db_name,table_name,field):
    conn = utils._connection()
    cursor = conn.cursor()
    cursor.execute('USE %s' %db_name)
    fields = utils._get_fields(db_name,table_name)
    if len(fields)==len(field):
        exec(open(mysql_settings_file).read())
        content = "You can't remove all fields. Drop table instead"
        table_menu = _table_menu(db_name,table_name,"table_structure")
        print KT('table_template.kt',**locals())
        raise SCRIPT_END
    for f in field:
        cursor.execute('ALTER TABLE %s DROP %s' %(table_name,f))
    conn.commit()
    conn.close()
    utils._update_views_and_forms(db_name,table_name)
    raise HTTP_REDIRECTION,"table_structure?db_name=%s&table_name=%s" \
        %(db_name,table_name)

def insert_field(**kw):
    sql = kw["sql"]
    conn = utils._connection()
    cursor = conn.cursor()
    cursor.execute('USE %s' %kw['db_name'])
    cursor.execute(sql)
    conn.commit()
    conn.close()
    utils._update_views_and_forms(kw['db_name'],kw['table_name'])
    if int(kw['new']):
        raise HTTP_REDIRECTION,"../index.ks/index?db_name=%s&table_name=%s" \
            %(kw['db_name'],kw['table_name'])
    else:
        raise HTTP_REDIRECTION,"table_structure?db_name=%s&table_name=%s" \
            %(kw['db_name'],kw['table_name'])

def customize_entry_form(db_name,table_name):
    exec(open(mysql_settings_file).read())
    settings_file = os.path.join(CONFIG.data_dir,'mysql_admin',
        host,user,db_name,table_name,'settings.py')
    if not os.path.exists(settings_file):
        utils._create_settings_file(db_name,table_name)
    args = 'db_name=%s&table_name=%s' %(db_name,table_name)
    content = A('customize view',href='customize_entry_view?'+args)
    content += BR()+A('customize widgets',href='customize_widgets?'+args)
    table_menu = _table_menu(db_name,table_name,"customize_entry_form")
    print KT('entry_template.kt',**locals())    

def customize_entry_view(db_name,table_name):
    exec(open(mysql_settings_file).read())
    content = utils._make_entry(db_name,table_name)
    content = cgi.escape(str(content))

    table_menu = _table_menu(db_name,table_name,"customize_entry_form")
    print KT('customize_entry_template.kt',**locals())

def customize_widgets(db_name,table_name):
    exec(open(mysql_settings_file).read())
    settings_file = os.path.join(CONFIG.data_dir,'mysql_admin',
        host,user,db_name,table_name,'entry_default.py')
    conf = settings.Settings(settings_file).load()
    widgets = conf['widgets']

    fields = _get_fields(db_name,table_name)
    init_script = 'function init_fields() {\n'
    table = TABLE(border=1)
    for field in fields:
        if field['extra'].lower()=='auto_increment':
            continue
        if field['type'].lower() in ['datetime','timestamp'] \
            and field['default'].lower()=='current_timestamp':
                continue
        name = field['name']
        widget = widgets.setdefault(name,{'type':'INPUT','size':10})
        select = SELECT(name='widget_'+field['name'],Id=field['name'],
            onChange='change_widget(this)')
        select.from_list(widget_list)
        select.select(content=widget['type'])
        # script to enter settings
        if widget['type'] in ['INPUT','INPUT_DATE']:
            init_script += 'show_input("%s",%s)\n' %(name,widget['size'])
        elif widget['type'] in ['TEXTAREA','WHIZZYWIG']:
            init_script += 'show_area("%s",%s,%s)\n' \
                %(name,widget['cols'],widget['rows'])
        elif widget['type'] in ['SELECT','RADIO']:
            init_script += 'show_select("%s","%s","%s")\n' \
                %(name,widget['table'],widget['fields'])
        table <= TR(TD(field['name'])+TD(select)+
            TD('&nbsp;',Id='settings_'+field['name']))    
    init_script += '}\n'
    form = FORM(table,action="update_widgets",method="post")
    form <= utils._hidden(db_name=db_name,table_name=table_name)
    form <= INPUT(Type="submit",value=_("Update"))
    
    content = H4(_('Customize widgets')) + form
    
    # get list of other tables in the database
    table_list = utils._get_tables(db_name)
    table_list.remove(table_name)
    fields = dict([(table,_get_fields(db_name,table)) for table in table_list])
    tables_with_recid = []
    for table,field_list in fields.iteritems():
        has_recid = False
        for field in field_list:
            if field['extra'].lower() == 'auto_increment':
                tables_with_recid.append(table)
                break
    select = SELECT(onChange='change_table(this)',name='[field]')
    select.from_list(tables_with_recid,use_content=True)
    tables = "select_table_pattern = '%s'\n" %(str(select).replace('\n',''))
    tables += 'fields = new Array()\n'

    for i,table in enumerate(tables_with_recid):
        fields = _get_fields(db_name,table)
        tables += 'fields["%s"]="' %table
        tables += ' '.join(['$%s' %field['name'] for field in fields])
        tables += '"\n'
        if i==0:
            tables += 'default_fields = fields["%s"]\n' %table

    table_menu = _table_menu(db_name,table_name,"customize_entry_form")
    print KT('customize_widgets.kt',**locals())

def update_widgets(**kw):
    widget = {}
    for key in kw:
        if key.startswith('widget_'):
            field = key[7:]
            widget[field] = {'type':widget_list[int(kw[key])]}
    for field in widget:
        if widget[field]['type'] in ['INPUT','INPUT_DATE']:
            widget[field]['size']=kw['size_%s' %field]
        elif widget[field]['type'] in ['TEXTAREA','WHIZZYWIG']:
            widget[field]['rows']=kw['rows_%s' %field]
            widget[field]['cols']=kw['cols_%s' %field]
        elif widget[field]['type'] in ['SELECT','RADIO']:
            widget[field]['table']=kw['ext_table_%s' %field]
            widget[field]['fields']=kw['ext_fields_%s' %field]

    exec(open(mysql_settings_file).read())
    settings_file = os.path.join(CONFIG.data_dir,'mysql_admin',
        host,user,_db_name,_table_name,'entry_default.py')
    settings.Settings(settings_file).save({'widgets':widget})
    url = 'customize_entry_form?db_name=%s&table_name=%s' \
        %(_db_name,_table_name)
    raise HTTP_REDIRECTION,url

def save_entry_form(**kw):
    exec(open(mysql_settings_file).read())
    settings_file = os.path.join(CONFIG.data_dir,'mysql_admin',
        host,user,_db_name,_table_name,'entry_default.py')
    settings.Settings(settings_file).save({'entry_form':kw['entry_form']})
    url = 'customize_entry_form?db_name=%s&table_name=%s' \
        %(_db_name,_table_name)
    raise HTTP_REDIRECTION,url
