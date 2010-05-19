var target_zone = null

function change_family(elt)
{
ff = elt.options[elt.selectedIndex].innerHTML
document.getElementById(target_zone).style.fontFamily = ff
}

function change_weight(elt)
{
fw = elt.options[elt.selectedIndex].innerHTML
document.getElementById(target_zone).style.fontWeight = fw
}

function change_size(elt)
{
fs = elt.options[elt.selectedIndex].innerHTML
document.getElementById(target_zone).style.fontSize = fs+'px'
}

function change_width(elt)
{
w = elt.options[elt.selectedIndex].innerHTML
document.getElementById(target_zone).style.width = w
document.getElementById(target_zone).style.left = 235-(parseInt(w)/2)
}

function getpos(elt)
{
    x = 0
    y = 0
    while (elt != undefined)
    {
        x += elt.offsetLeft
        y += elt.offsetTop
        elt = elt.parentElement
    }
    return new Array(x,y)
}

function set_option(elt_id,value)
{
    for (i=0;i<document.getElementById(elt_id).options.length;i++)
    { if (document.getElementById(elt_id).options[i].innerHTML == value)
      { document.getElementById(elt_id).options[i].selected = true }
      else
      { document.getElementById(elt_id).options[i].selected = false }
    }
}

function config(elt,zone)
{
    pos = getpos(elt)
    x=pos[0]
    y=pos[1]

    // get font family, weight and size and select option in select lists
    set_option("f_fam",elt.style.fontFamily)
    set_option("f_weight",elt.style.fontWeight)

    font_size = elt.style.fontSize // ends with "px"
    font_size = font_size.substring(0,font_size.length-2)
    set_option("f_size",font_size)

	elt_width = elt.style.width
	elt_width = parseInt(elt_width.substring(0,elt_width.length-2))

    with (document.getElementById("menu").style)
    { width = 100
      height = 100
      top = y
      left = x+elt_width
      visibility = "visible"
	  backgroundColor = "#FFFFD0"
	  borderStyle = "ridge"
	  borderWidth = 2
	  borderColor = "#8080FF"
	  fontFamily = "sans-serif"
	}
 	target_zone = zone   
}

function close_menu()
{
	document.getElementById("menu").style.visibility="hidden"
}