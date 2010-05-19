<html>
<head>
<link rel="stylesheet" href="../manage.css">
<script type="text/javascript" src="/whizzywig/whizzywig.js"></script>
<script>
function show(elt_id,x,y)
{
    document.getElementById('info').innerHTML=elt_id+' '+x+' '+y
}

function change_widget(elt)
{
    widget = elt.options[elt.selectedIndex].text
    if (widget=="TEXTAREA" || widget=="WHIZZYWIG")
        { show_area(elt.id,10,10) }
    else if (widget=="INPUT")
        { show_input(elt.id,10)}
    else if (widget=="SELECT" || widget=="RADIO")
        { show_select(elt.id) }
}

function show_input(name,size)
{
    cell = document.getElementById('settings_'+name)
    ch = 'size = <input name="size_'+name+'" value=10 size='+size+'>'
    cell.innerHTML = ch
}

function show_area(name,cols,rows)
{
    cell = document.getElementById('settings_'+name)
    ch='cols <input name="cols_'+name+'" value='+cols+' size=4>'
    ch += ' rows <input name="rows_'+name+'" value='+rows+' size=4>'
    cell.innerHTML = ch
}

function show_select(name,ext_table,ext_fields)
{
    cell = document.getElementById('settings_'+name)
    ch = 'values from table '+select_table(name,ext_table)
    span_id = "field_list_"+name
    ch += '<br>Fields to present in entry form : '
    ch += '<input name="ext_fields_'+name+'" id="ext_fields_'+name
    ch += '" value="'+ext_fields+'" size=15>'
    ch += '<br>Available fields : <span id="'+span_id+'">'+default_fields+'</span>'
    cell.innerHTML = ch
}

function change_table(elt)
{
    cell = elt
    while (cell != undefined && cell.id.substr(0,9) != "settings_")
    { cell = cell.parentElement }
    field_id = cell.id.substring(9)
    selected_table = elt.options[elt.selectedIndex].text
    document.getElementById("field_list_"+field_id).innerHTML = fields[selected_table]
}

function select_table(field,selected_table)
{
    // build the SELECT tag to choose an external table for the field
    ch = '<select name="ext_table_'+field+'" onChange="change_table(this)">'
    for (table in fields)
    {
        ch += '<option value="'+table+'"'
        if (table==selected_table) { ch += ' selected' }
        ch += '>'+table
    }
    ch += '</select>'
    return ch
}

$init_script

</script>
</head>

<body onLoad="init_fields()">
<table width="50%">
<tr>
<td>_[Host] $host</td>
<td>_[Database] $db_name</td>
</table>

Table $table_name
$table_menu

$content

<script>
$tables
</script>
</body>

</html>