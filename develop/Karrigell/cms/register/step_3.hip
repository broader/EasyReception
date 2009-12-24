"""
<link type="text/css" href="../css/prettyinpink.css" rel="stylesheet" />
"""

from HTMLTags import *

config = Import('../config.py')
# all the login and base information fields have been stored in session object
so = Session()

##------------------Render login info table ---------------------------------------- 
table = []
# append the caption
table.append( CAPTION(_("Login Info"), style='text-align: left; font-size: 1.6em;font-weight:bold;'))
names = list(config.login_fields_names)
values = [getattr(so, name, None) for name in list(config.login_fields)]
formRender = Import('../formRender.py')
cols = 2
trs = formRender.render_table_fields(names, values, cols)
# now constructs the Table
table.append(trs)
table = TABLE(Sum(table))
#-------------------Login info table end ---------------------------------------

#-------------------Render base info table -------------------------------------
btable = []
# append the caption
btable.append( CAPTION(_("Base Info"), style='text-align: left; font-size: 1.6em;font-weight:bold;'))
names = list(config.base_fields_names)
values = [getattr(so, name, None) for name in list(config.base_fields)]
formRender = Import('../formRender.py')
cols = 2
trs = formRender.render_table_fields(names, values, cols)
# now constructs the Table
btable.append(trs)
btable = TABLE(Sum(btable))
#-------------------Base info table end ---------------------------------------

div = []
head = H4(_("Congradulations! You have registered successfully!<BR>\
		     If you have any question, please contact with us. <BR>\
		     You're welcom always!"))

d = 'height:2.4em;color: black;font-weight:bold;'
      		     
button = BUTTON(_("Click here to end registration!"),**{'style':d, 'type':'button', 'class': 'login'})		     
[div.append(i) for i in (head, HR(), BR(), table, BR(), btable, HR(), button) ] 

print DIV(Sum(div), **{'class': 'table4fields'})

"""
<script type="text/javascript">
$('.login').click(function(){
"""
#print '$.getScript("../login.hip?ltype=1&name=%s&pwd=%s");'%(so.username, so.password)
print '$.getScript("../menu.ks/page_postValid?user=%s");'%so.username

"""
});
</script>
"""