<html>
<head>
<link rel="stylesheet" href="$this.baseurl/wiki/wiki.css">
<title>BuanBuan _[Welcome to BuanBuan]</title>
</head>
<body>
<center>
<table width="800px"><tr><td>
<table width="80%">
<tr>
<td valign="top">
<a href="/">_[Home]</a>
</td>
<td align="center">
<h2>_[Welcome to BuanBuan]</h2>
</td>
</tr>
</table>
_[BuanBuan is a simple Wiki server].
<p>This version of BuanBuan is a demonstration of ks scripts, smart URLs, KT templates and the HTMLTags module.
<p>_[Recent pages] :
$data.pagenames
[<a href="pagesbytitle?char=$data.startchar">Pages by title</a>] [<a href="pagesbytitlekeyword?char=$data.startchar">Pages by title keyword</a>]
<p><h3>_[Add new page]</h3>
<form action="$this.script_url/edit" METHOD="POST">
<input type="hidden" name="action" value="add">
_[Page name]&nbsp;<input size="20" name="pageName">
&nbsp;<small>Admin</small>
<input type="checkbox" name="admin">&nbsp;
<input type="submit" value="Add">
</form>
<p><h3>_[Search]</h3>
<form action="search">
<input size="20" name="words">
_[Case sensitive] <input type="checkbox" name="caseSensitive">
_[Full word] <input type="checkbox" name="fullWord">
<br><input type="submit" value="_[Search]">
</form>
<p>

<font size="-1">
<a href="admin">_[Administrator]</a>
<br>$data.logout
</font>
@[footer.kt]
</body>