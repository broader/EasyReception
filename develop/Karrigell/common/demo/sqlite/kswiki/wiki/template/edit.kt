<FORM action="$this.script_url/save" METHOD="POST">
<INPUT TYPE="hidden" NAME="pageName" VALUE="$data.pageName">
<SMALL> _[Admin] </SMALL>
<INPUT TYPE="checkbox" NAME="admin" $data.adminchecked >
<INPUT TYPE="submit" VALUE="_[save changes]">
<INPUT TYPE="button" VALUE="_[exit without saving]" onClick="history.back()">
<br>
<TEXTAREA COLS="120" ROWS="25" name="newText"  ONSELECT="markSelection(this);" ONCLICK="markSelection(this);" ONKEYDOWN="return gereTab(this);" ONKEYUP="markSelection(this)">
$data.text
</TEXTAREA>
</FORM>
@[edithelp.kt]
