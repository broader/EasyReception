var year = new Array()
var month = new Array()
var cur_day = new Array()
var week_start = 1 // week begins on Monday

var days_per_month = new Array(31,28,31,30,31,30,31,31,30,31,30,31)
var day_names = new Array("Su","Mo","Tu","We","Th","Fr","Sa")
var month_names = new Array("Jan","Feb","Mar","Apr","May",
	"Jun","Jul","Aug","Sep","Oct","Nov","Dec")
var date_format = "MM/DD/YYYY"
var today_name = "Today" // local name for "today"

function read_car(i)
{ return date_format.charAt(i).toUpperCase() }

function date_to_string(cal_id,day_num)
{
 ch = ""
 i = 0
 while (i<date_format.length)
 {
  if (read_car(i)=="Y" || read_car(i)=="A")
  { nb = 1; i++;
    while (i<date_format.length && (read_car(i)=="Y" || read_car(i)=="A"))
    { nb ++; i++ }
    if (nb>2) { ch += year[cal_id].toString() }
    else { ch += year[cal_id].toString().substr(2) }
  }
  else if (read_car(i)=="M")
  { i++;
    while (i<date_format.length && read_car(i)=="M")
    { i++ }
    m = (month[cal_id]+1).toString()
    if (m.length==1) { m = "0"+m }
    ch += m
  }
  else if (read_car(i)=="D" || read_car(i)=="J")
  { i++;
    while (i<date_format.length && (read_car(i)=="D" || read_car(i)=="J"))
    { i++ }
    if (day_num<10) { day_num = "0"+day_num }
    ch += day_num
  }
  else
  { ch += date_format.charAt(i); i++ }
 }
 return ch
}

function string_to_date(cal_id)
{
	 // extract day,month,num from string found in field cal_id
	 // the string is supposed to be formatted like in date_format
	 dstr = document.getElementById(cal_id).value
	 if (dstr == undefined) {setCurrentDate(cal_id); return }
	 if (dstr.length==0) { setCurrentDate(cal_id); return }
	 if (dstr.length != date_format.length)
	 { alert("Invalid date "+dstr+" - format should be "+date_format)
	   setCurrentDate(cal_id)
	   return }
	 i = 0
	 while (i<date_format.length)
	 {
	  if (read_car(i)=="Y" || read_car(i)=="A")
	  { ystr = dstr.charAt(i); i++; nb= 1;
		while (i<date_format.length && (read_car(i)=="Y" || read_car(i)=="A"))
		{ ystr += dstr.charAt(i); nb++; i++ }
		if (nb==2) {ystr = "20"+ystr}
	  }
	  else if (read_car(i)=="M")
	  { mstr = dstr.charAt(i); i++;
		while (i<date_format.length && (read_car(i)=="M"))
		{ mstr += dstr.charAt(i); i++ }
	  }
	  else if (read_car(i)=="D" || read_car(i)=="J")
	  { daystr = dstr.charAt(i); i++;
		while (i<date_format.length && (read_car(i)=="D" || read_car(i)=="J"))
		{ daystr += dstr.charAt(i); i++ }
	  }
	  else { i++ }
	 }
	 _year = parseInt(ystr)
	 if (mstr.charAt(0)=="0") {mstr=mstr.substr(1)}
	 _month = parseInt(mstr)-1
	 if (isNaN(_month) || (_month<0 || _month>11))
	 { setCurrentDate(cal_id); return }
	 if (daystr.charAt(0)=="0") {daystr=daystr.substr(1)}
	 _cur_day = parseInt(daystr)
	 if (isNaN(_cur_day)) {setCurrentDate(cal_id); return }
	 year[cal_id] = _year
	 month[cal_id] = _month
	 cur_day[cal_id] = _cur_day
}

function setCurrentDate(cal_id)
{
	 today = new Date()
	 year[cal_id] = today.getFullYear()
	 month[cal_id] = today.getMonth()
	 cur_day[cal_id] = today.getDate()
}

function calendar(elt,dfmt)
{
	 // open calendar relative to element elt
	 // dfmt (optional) : date format
	 if (dfmt != undefined) {date_format = dfmt}
	 field_id = elt.id.substr(0,elt.id.length-7)
	 field = document.getElementById(field_id)
	 // get value in field - should be a date formatted like date_format
	 string_to_date(field_id)
	 //alert(year[field_id]+' '+month[field_id]+' '+cur_day[field_id])
	 cal = document.getElementById(field_id+"_calendar")
	 if (cal == undefined)
	  { make_new_calendar(elt) }
	 // else { makeMonth(field_id) }
	 else {	document.body.removeChild(cal) }
}

function make_new_calendar(elt)
{
	 field_id = elt.id.substr(0,elt.id.length-7)
	 pos = get_pos(elt)
	 cal = document.createElement("div")
	 cal.id = field_id+"_calendar"
	 with (cal.style)
	 {
	  position = "absolute"
	  left = pos[0]
	  top = pos[1]+30
	 }
	 document.body.appendChild(cal)
	 makeMonth(field_id)
}

function makeMonth(cal_id)
{
	 ch = '<table class="calendar" cellpadding=0 cellspacing=0>'

	 // first line
	 ch += '<tr><td><table class="cal_top" cellpadding=0 cellspacing=0 width="100%">'
	 ch += '<tr>'
	 // link for previous year
	 ch += '<td class="nav" align="right">'
	 ch += '<button class="nav_year" onClick="previousYear(\''
	 ch += cal_id+'\')"><</button></td>'
	 // current year
	 ch += '<td class="year" align="center"><input class="year"'
	 ch += ' onChange="selectYear(\''+cal_id+'\',this)"'
	 ch += ' value="'+year[cal_id]+'"></td>'
	 // link for next year
	 ch += '<td class="nav" align="left">'
	 ch += '<button class="nav_year" onClick="nextYear(\''
	 ch += cal_id+'\')">></button></td>'
	 // link for today
	 ch += '<td class="nav" align="center">'
	 ch += '<button class="today" onClick="setCurrentDate(\''
	 ch += cal_id+'\');makeMonth(\''+cal_id+'\');">'
	 ch += today_name + '</button></td>'	 
	 // link to close the calendar
	 ch += '<td class="nav" align="right">'
	 ch += '<button class="close" onClick="closeCalendar(\''
	 ch += cal_id+'\')">x</button></td>'
	 // end of first line
	 ch += '</tr></table></td></tr>'

	 // line for months
	 ch += '<tr><td>'
	 ch += '<table class="month" cellpadding = 2 cellspacing=0 width="100%">'
	 ch += '<tr>'
	 for (i=0;i<12;i++)
	 { if (i==month[cal_id])
	   { ch += '<td width="10" class="selected_month">'
	     ch += month_names[i].charAt(0)+'</td>' }
	   else
	   { ch += '<td width="8" class="month" onClick="selectMonth(\''+cal_id+'\','+i+')">'
	     ch += month_names[i].charAt(0)+'</td>' }
     }	   
	 ch += '</tr></table></td></tr>'
	 // end of line for months

	 // table for current month
	 ch += '<tr><td><table class="month" cellpadding = 2 cellspacing=0 width="100%">'

	 // line for day names
	 ch += '<tr>'
	 for (cell=0;cell<7;cell++)
	 { rank=(cell+week_start+7) % 7;
	   ch += '<td width="14%" class="day_name">'+day_names[rank]+'</td>'
	 }
	 ch += '</tr>'
	 nb_days = days_per_month[month[cal_id]]
	 // february of leap years
	 if ((year[cal_id] %4 == 0) && (month[cal_id]==1)) {nb_days+=1}

	 // first day of the month
	 d = 1
	 first_day = new Date(year[cal_id],month[cal_id],1)
	 r1 = first_day.getDay() // rank of first day
	 started = false

	 // lines for weeks
	 while (d<=nb_days)
	 {
	   // begin week
	   ch += '<tr>'
	   for (cell=0;cell<7;cell++)
	   { if (!started && (cell+week_start%7<r1))
		   { ch += '<td width="14%" class="day">&nbsp;</td>'}
		 else
		   { started = true
			 if (d<=nb_days)
			 { if (d==cur_day[cal_id]) {day_class="selected_day"}
			   else {day_class="day"}
			   ch += '<td width="14%" class="'+day_class+'" '
			   // mouse over
			   ch += 'onMouseOver="enterDay(this)" '
			   // mouse out
			   ch += 'onMouseOut="quitDay(this)" '
			   // select day
			   ch += 'onClick="selectDay(\''+cal_id+'\','+d+')">'
			   ch += +d+'</td>'
			  }
			 else
			 { ch += '<td width="14%" class="day">&nbsp;</td>'}
			 d += 1
		   }
	   }
	   ch += '</tr>'  // end week
	 }
	 ch += '</table></tr></td>' 
	 // end of month table

	 ch += '</table>' // end of calendar table
	 
	 cal = document.getElementById(cal_id+'_calendar')
	 cal.innerHTML = ch
}

function enterDay(elt)
{ elt.style.backgroundColor = "#FFEC53"; }

function quitDay(elt)
{ elt.style.backgroundColor = "#FFCC33"; }

function selectDay(cal_id,day_num)
{
	// user clicks on a date in calendar
    document.getElementById(cal_id).value = date_to_string(cal_id,day_num)
	closeCalendar(cal_id)
}

function selectMonth(cal_id,month_num)
{
 month[cal_id] = month_num
 makeMonth(cal_id)
}

function selectYear(cal_id,elt)
{
 year[cal_id] = elt.value
 makeMonth(cal_id)
}

function previousYear(cal_id)
{ year[cal_id] -= 1; makeMonth(cal_id) }

function nextYear(cal_id)
{ year[cal_id] += 1; makeMonth(cal_id) }

function closeCalendar(cal_id)
{
	cal = document.getElementById(cal_id+"_calendar")
	document.body.removeChild(cal)
}

function get_pos(elt)
{
	// get absolute position of element elt
	x = 0; y = 0
	while (elt != undefined)
	{ x += elt.offsetLeft
	  y += elt.offsetTop
	  elt = elt.offsetParent
	}
	res = new Array(x,y)
	return res
}