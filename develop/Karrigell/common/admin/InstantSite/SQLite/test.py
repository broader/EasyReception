# -*- coding: iso-8859-1 -*-
def edit_structure(db_name,table):
    quoted = db_name
    db_name = unquote_plus(db_name)

    # hidden fields
    class h_db(INPUT):Type="hidden";name="db_name";value=quoted
    class h_table(INPUT):Type="hidden";name="table";value=table

    title = A("Home",href="index",target="_top")
    link = A(db_name,href="open_db?db=%s" %quoted,target="_parent")
    title += H3("Database %s - Table %s" %(link,table))

    db_fields = _get_fields(db_name,table)
    existing_fields = _table_info(db_name,table)
    uneditable_fields = [field for field in db_fields 
        if field['name'] in existing_fields]
    editable_fields = [field for field in db_fields 
        if not field['name'] in existing_fields]
        
    fields = TABLE()

    # other tables
    types = check_type.types.keys()
    for ext_table in Session().tables:
        if not ext_table == table and not ext_table=="sqlite_sequence":
            types.append('external:%s' %ext_table)

    if uneditable_fields:
        fields <= TR(colspan=6) <= TD(B("Current fields - can't be modified"))
        fields <= TR() <= TH("Field name")+TH("Type")+ \
            TH("Allow empty")+TH("Default value")+TD(" ")

        for field in uneditable_fields:
            fields <= TR(TD(field['name'])+
                       TD(field['type'])+
                       TD(field['allow_empty'])+
                       TD(field['default'])+
                       TD("&nbsp;")+
                       TD("&nbsp;")+
                       TD("&nbsp;"))
            
    if editable_fields:
        line = TR()
        line <= TD(colspan=3) <= B("Fields not yet saved in the database")
        line <= TD() <= SPAN(Class="save") <= \
            A(_("Save changes"),Class="save",
            href="save_changes?db_name=%s&table=%s" %(quoted,table))
        line <= TD("&nbsp;")*2

        fields <= line
        fields <= TR() <= TH("Field name")+TH("Type")+ \
            TH("Allow empty")+TH("Default value")

    for num,v in enumerate(editable_fields):
        f = v["name"]
        type_options = SELECT(name="typ") <= \
            Sum([OPTION(typ,value=typ,selected=typ==v["type"]) 
                for typ in types])
        line = TR()
        allow_empty = SELECT(name="allow_empty")
        allow_empty <= OPTION("Yes",value=1,selected=v["allow_empty"])+\
                    OPTION("No",value=0,selected=not v["allow_empty"])
        line <= (TD(INPUT(name="field",value=f))
                + TD(type_options)
                + TD(allow_empty)
                + TD(INPUT(name="default",value=v["default"].replace('"','&quot;')))
                + TD(INPUT(Type="submit",name="action",value="Update"))
                + TD(INPUT(Type="submit",name="action",value="Drop"))
                )
        form = FORM(action="edit_field",method="post")
        form <= (h_db + h_table
               + INPUT(Type="hidden",name="field_num",
                    value=num+len(uneditable_fields))
               + line) 
        fields <= form
    fields <= TR(colspan=6) <= TD(BR()+B("Add new field"))
    fields <= TR() <= TH("Field name")+TH("Type")+ \
        TH("Allow empty")+TH("Default value")+TD(" ")
    
    line = TR(
        TD(INPUT(name="field"))
        + TD(SELECT(Sum([OPTION(typ,value=typ,selected=typ=="string") 
                    for typ in types]),name="typ"))
        + TD(SELECT(OPTION("Yes",value=1)+OPTION("No",value=0),
                    name="allow_empty"))
        + TD(INPUT(name="default"))
        + TD(INPUT(Type="submit",value="Add"))
        )

    form = FORM(action="new_field",method="post") <= h_db+h_table+line

    fields <= form
    
    print HTML(header+BODY(title+fields))
