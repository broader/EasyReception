obl_length = new Array()
obl_length['CHAR']=new Array(1,255)
obl_length['VARCHAR']=new Array(1,255)
obl_length['DECIMAL']=new Array(1,64)
obl_length['NUMERIC']=obl_length['DECIMAL']

obl_decimals = new Array()
obl_decimals['DECIMAL'] = new Array(1,30)
obl_decimals['NUMERIC'] = obl_decimals['DECIMAL']

unsigned = new Array( 
  'INTEGER',
  'REAL'
  )

is_unsigned = new Array()
for (i=0;i<unsigned.length;i++)
{ is_unsigned[unsigned[i]]=1 }

keys = new Array('no','PRIMARY KEY')

key = ''
null_ = ''


function t_entry()
{
	ch = 'Create new table'
    ch += '<form action="view"><input name="table"><br>'
    ch += '<input type="hidden" name="new_table" value="1">'
    ch += '<input type="submit" value="Ok">'
    ch += '<input type="button" onclick="leave()" value="Cancel"></form>'
    document.getElementById("new_table").innerHTML = ch
}

function drop_table(t)
{
	flag = confirm('Do you want to drop table '+t+'? This will definitely erase all data')
	if (flag)
	{ location.href="drop_table?table="+t }
}

function sel_field()
{
	nb = document.forms["fields"].elements["field[]"].length
	if (nb != undefined)
	{ nbsel = false
	  for (i=0;i<nb;i++)
	  { if (document.forms["fields"].elements["field[]"][i].checked)
	    { nbsel = true }
	  }
	} else {
	  nbsel = document.forms["fields"].elements["field[]"].checked
	}
	if (nbsel)
	{ document.getElementById("sub").disabled=false }
	else
	{ document.getElementById("sub").disabled=true }
}

function leave()
{
    ch='<a href="javascript:t_entry()">New table</a>'
    document.getElementById("new_table").innerHTML = ch
}

function ch_null(n_num)
{
	if (n_num == 1)
	{ null_ = 'NOT NULL'
	  document.getElementById("default").disabled=false 
	}
	else
	{ null_ = ''
	  document.getElementById("default").disabled=true 
	}
}

function ch_key(k_num)
{
	key = keys[k_num]
}

function change_default_type()
{
	elt = document.getElementById('default_type')
	ix = elt.selectedIndex
	def_type = elt[ix].value
	flag = !(def_type=='STRING' || def_type=='NUMBER')
	document.getElementById('field_default').disabled = flag
}

function edit_field(ix)
{
document.getElementById("forder").value = ix

field_name = field[ix][1]
document.getElementById("f_action").innerHTML = "Editing field "+field_name
document.getElementById("field_name").value = field_name

f_type = field[ix][2]
t_sel = document.getElementById("field_type")

for (i=0;i<t_sel.options.length;i++)
   { 
   	 if (t_sel.options[i].value == f_type)
      { document.getElementById("field_type").options[i].selected = true
        document.getElementById("field_type").selectedIndex = i
      }
	 else
      { document.getElementById("field_type").options[i].selected = false }
   }

f_null = (field[ix][3]=='yes')
document.getElementById("fnull1").checked = f_null
document.getElementById("fnull2").checked = !f_null

def_type = field[ix][4]
if (def_type == 'None') { def_type = field[ix][5] }
def_typ_sel = document.getElementById('default_type')

for (i=0;i<def_typ_sel.length;i++)
 { if (def_typ_sel.options[i].value == def_type)
   { document.getElementById('default_type').options[i].selected = true }
   else
   { document.getElementById('default_type').options[i].selected = false }
 }

document.getElementById("field_default").value = field[ix][5]
if (field[ix][4] == 'None') 
 { document.getElementById("field_default").value = '' }

has_no_value = (field[ix][4] = 'None')
document.getElementById("field_default").disabled = has_no_value

f_key = (field[ix][6]=='yes')
document.getElementById("fkey1").checked = f_key
document.getElementById("fkey2").checked = !f_key

document.getElementById("subm1").value = "Edit field"
document.getElementById("subm2").disabled = false
document.getElementById("subm2").value = "Delete field"

}

function change_type()
{

	elt = document.getElementById("Type")
	selType = elt.options[elt.selectedIndex].value
	ch = '<table border="1">'
	if (obl_length[selType] != undefined)
	{
	  limits = obl_length[selType]
	  ch += '<tr><td>'
	  ch += 'Length ('+limits[0]+'-'+limits[1]+')</td>'
	  ch += '<td><input name="size"></td></tr>'
	}
	if (obl_decimals[selType] != undefined)
	{
	  limits = obl_decimals[selType]
	  ch += '<tr><td>'
	  ch += 'Decimals ('+limits[0]+'-'+limits[1]+')</td>'
	  ch += '<td><input name="decimals"></td></tr>'
	}

	ch += '</table>'

    document.getElementById("f_opt").innerHTML = ch
    
}

function valid_form(elt)
{
 if (document.getElementById('field_name').value == '')
 { alert('Missing field name') 
   return false
 }
}

