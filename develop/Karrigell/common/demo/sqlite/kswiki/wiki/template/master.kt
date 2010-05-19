<html>
<head>
<link rel="stylesheet" href="$this.baseurl/wiki/wiki.css">
<title>BuanBuan $data.title</title>
@[$data.jstmpl]
</head>
<body>
<center>
<table width="800px"><tr><td>
<table width="100%"><tr>
<td align="left" valign="top">
<a href="$this.script_url/index"><img src="$this.baseurl/wiki/home.gif" border="0" alt="Home"></a>
</td>
<td valign="top">
<h2>$data.heading</h2>
</td>
</tr></table>
@[$data.bodytmpl]
@[footer.kt]
</td></tr></table>
</body>
</html>
