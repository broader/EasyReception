<html>
<head>
<link rel="stylesheet" href="../manage.css">
<script type="text/javascript" src="../dom-drag.js"></script>
<script type="text/javascript" src="/whizzywig/whizzywig.js"></script>
<script>
function show(elt_id,x,y)
{
    document.getElementById('info').innerHTML=elt_id+' '+x+' '+y
}

</script>
</head>

<body>
<table width="50%">
<tr>
<td>_[Host] $host</td>
<td>_[Database] $db_name</td>
</table>

Table $table_name
$table_menu

<form action="save_entry_form" method="post">
<INPUT type="submit" value = "Save">
<p>
<TEXTAREA id="area" cols="100" rows="40" name="entry_form">
$content
</TEXTAREA>
<script>
btn._f="/whizzywig/WhizzywigToolbar.png";
buttonPath = '/whizzywig/';
makeWhizzyWig("area","all")
</script>
<INPUT type="hidden" name="db_name" value="$db_name">
<INPUT type="hidden" name="table_name" value="$table_name">
</FORM>

</body>

</html>