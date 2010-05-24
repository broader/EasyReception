<form action="search"><b>_[Search]</b>
<input size="20" name="words" value="$data.words">
_[Case sensitive] <input type="checkbox" name="caseSensitive">
_[Full word] <input type="checkbox" name="fullWord">
<input type="submit" value="_[Search]">
</form>
[<a href="pagesbytitle?char=$data.firstchar">Pages by title</a>]
[<a href="pagesbytitlekeyword?char=$data.firstchar">Pages by title keyword</a>]
<hr>
$data.content
$data.msg
<p />
<a href="index">Back</a>
