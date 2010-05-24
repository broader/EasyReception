"""
<style type="text/css" media="screen">
@import "register/css/screen.css";
</style>
<!--[if lte IE 7]>
<style type="text/css" media="all">
@import "register/css/required-fields-star1-ie.css";
</style>
<![endif]-->
"""
# The meaning of each item lists as below:
# first item is the value for 'Fieldset' tag;
# second item shows those 'Li' tags which needs add 'Required' mark.
# third item is a list consisted by :
# 1) first item is the same value for  'for' attribute of 'Label' as for  'id', 'name' attributes of 'Input';
# 2) second  item is the value of 'Label';
# 3) third item is the value of 'class' and 'type' attributes of 'Input'.
fContent = [ [ 'Contact Details', [0, 1],
		       ['name', 'Name :', 'text'],\
		       ['email', 'Email address :', 'text'],\
		       ['phone', 'Telephone :', 'text'] ],\
		     [ 'Login Details', [0,],\
		       ['password', 'Password :', 'password'],\
		       ['confirmPassword', 'ConfirmPassword :', 'password'], ],\
		     [ 'Delivery Address', [1,2],\
		       ['address1', 'Address1 :', 'text'],\
		       ['address2', 'Address2 :', 'text'],\
		       ['suburb', 'Suburb/Town :', 'text'],\
		       ['postcode', 'Postcode :', 'text'],\
		       ['contry', 'Contry :', 'text'], ],\
		     [ 'Payment Details', [1],\
		       ['cardNumber', 'Credit card number :', 'text'],\
		       ['cardName', 'Credit card name :', 'text'], ] ]

from HTMLTags import *
form = []
for i,fs in enumerate(fContent) :
	rows = []
	for li in range(len(fs)-2):
		d = {'id': fs[li+2][0], 'name' : fs[li+2][0], 'class' : fs[li+2][2], 'type' : fs[li+2][0]}		
		if fs[1] and li in fs[1]:
			em = EM(IMG(**{'alt':'required','src':'register/css/images/required_star.gif'}))
			label = LABEL(Sum((TEXT(fs[li+2][1]), em)), **{'for': fs[li+2][0]})
			d.update({'class': d['class']+' required'})
		else:
			label = LABEL(fs[li+2][1], **{'for': fs[li+2][0]})
		
		input = INPUT(**d)
		rows.append(Sum((label, input)))
		
	ol = OL(Sum([LI(row) for row in rows]))
	ld = LEGEND(SPAN(fs[0]))
	form.append(FIELDSET(ld+ol))

bns =[_("Next"), _("Cancel")]
sbn = INPUT(**{'class':'submit', 'type':'submit', 'value':bns[0]})
cbn = INPUT(**{'class':'submit closeDOMWindow', 'type':'button', 'value':bns[1]})
buttons = FIELDSET(Sum((sbn, cbn)), **{'class':'submit'})
form.append(buttons)
#form.insert(0, buttons)
print FORM(Sum(form), **{'action':'register/register.ks/register', 'id':'step1' , 'method':'post'})
print DIV(id='target')

"""
<script type="text/javascript">
$(document).ready(function(){
	// fixes a bug of firefox which results the cursor not blured in input fields.
	//$('#DOMWindow').css({'position':'fixed','_positon':'absolute', 'text-align':'left'});
	// make the cursor focus on the first input field 	
	//$('#name').focus();
	//$('.closeDOMWindow').closeDOMWindow({eventType:'click'}); 
	//$.getScript('register/init.js.pih?formId=step1');
});
</script>
"""