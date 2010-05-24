
function text(value)
{ return document.createTextNode(value)
}

function clear_attrs(elt)
{
  sub_elts = elt.childNodes
  removed = new Array()
  for (i=0;i<sub_elts.length;i++)
  { if (sub_elts[i].id != null)
  	{ if (sub_elts[i].id.substr(0,4)=='attr')
      { removed.push(sub_elts[i]) }
    }
  }
    
  for (i=0;i<removed.length;i++)
  { elt.removeChild(removed[i]) }
  
  if (removed.length>0)
  { alert(elt)
    return elt }
  else
  {
   sub_elts = elt.childNodes
   for (i=0;i<sub_elts.length;i++)
   { clear_attrs(sub_elts[i]) }
  }
}

function string_widget(elt)
{ 
  tb = document.getElementById("stringoptions")
  
  // remove rows with id starting with 'attr'
  rows = document.getElementsByTagName('TR')
  removed = new Array()
  for (i=0;i<rows.length;i++)
  { if (rows[i].id.substr(0,4) == 'attr')
    { removed.push(rows[i])}
  }

  for (i=0;i<removed.length;i++)
  { top_tb = removed[i].parentNode
    top_tb.removeChild(removed[i])
  }

  sel = document.getElementById("widget")
  typ = sel.options[sel.selectedIndex].value

  if (typ=='input')
  { c1 = document.createElement('TD')
    c1.appendChild(text('size'))
    c2 = document.createElement('TD')
    size = document.createElement('INPUT')
    size.setAttribute('name','size')
    c2.appendChild(size)

    panel = document.createElement('TR')
    panel.setAttribute('id','attr1')
    panel.appendChild(c1)
    panel.appendChild(c2)
    top_tb.appendChild(panel)
  }
  else  // textarea
  { c1 = document.createElement('TD')
    c1.appendChild(text('rows'))
    c2 = document.createElement('TD')
    rows = document.createElement('INPUT')
    rows.setAttribute('name','rows')
    c2.appendChild(rows)
    r1 = document.createElement('TR')
    r1.setAttribute('id','attr1')
    r1.appendChild(c1)
    r1.appendChild(c2)

    c1 = document.createElement('TD')
    c1.appendChild(text('cols'))
    c2 = document.createElement('TD')
    cols = document.createElement('INPUT')
    cols.setAttribute('name','cols')
    c2.appendChild(cols)
    r2 = document.createElement('TR')
    r2.setAttribute('id','attr2')
    r2.appendChild(c1)
    r2.appendChild(c2)
    
    top_tb.appendChild(r1)
    top_tb.appendChild(r2)

  }

}

function edit(elt)
{
alert(elt)
}

function preview(db_name)
{
window.parent.frames["preview"].location.href = "../form_preview.ks/preview?db_name=" + db_name
}