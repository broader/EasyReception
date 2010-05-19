<!-- Script to handle the tab key inside the textarea : instead of putting focus on the next widget, -->
<!-- inserts a tab at the cursor position -->
<!-- Written by Droby10 http://www.experts-exchange.com/Web/Web_Languages/JavaScript/memberProfile.jsp?mbr=Droby10 --><script language=javascript>
<!--

function gereTab( txtObj)
{
   if (event.keyCode==9)
   {
    insertText(txtObj,'\t');
    return false;
   }
}

function markSelection ( txtObj ) {
 if ( txtObj.createTextRange ) {
   txtObj.caretPos = document.selection.createRange().duplicate();
   isSelected = true;
 }
}

function insertText ( txtObj, text ) {
 if ( isSelected ) {
   if (txtObj.createTextRange && txtObj.caretPos) {
     var caretPos = txtObj.caretPos;
     caretPos.text = ( text+caretPos.text );
     markSelection ( txtObj );
     if ( txtObj.caretPos.text=='' ) {
       isSelected=false;
    txtObj.focus();
     }
   }
 } else {
   // placeholder for loss of focus handler
 }
}

//-->
</script>