from HTMLTags import *

modules = {'pagefn' : 'pagefn.py',}
[locals().update({k : Import('/'.join(('',v)))}) for k,v in modules.items() ]

# The meaning of each item lists as below:
# first item is the value for 'Fieldset' tag;
# second item shows those 'Li' tags which needs add 'Required' mark.
# third item is a list consisted by :
# 1) first item is the same value for  'for' attribute of 'Label' such as 'id', 'name' attributes for 'Input';
# 2) second  item is the value of 'Label';
# 3) third item is the value of 'class' and 'type' attributes of 'Input'.

# append captcha tag 
Captcha = Import('Captcha.py')
key = Captcha.getChallenge()			
image = '/'.join(('register',Captcha.getImageFile(key)))
image = SUB(IMG(**{'src':image, 'alt' : 'captchaImage', 'class': 'captcha'}))
cinput = INPUT(**{'id':'ckey','value':key, 'type':'hidden'})

ol_content=[ [ _("Login Name :"), {'id':'username', 'name':'username','type':'text'},'input'],\		       
		       [_("Email address :"), {'id':'email', 'name':'email', 'class':'email', 'type':'text'},'input'],\
		       [_("Confirm Email :"), {'id':'cemail','name':'cemail','class':'email', 'type':'text'},'input'],\
		       [_("Password :"), {'id':'pwd', 'name':'password', 'type':'password', 'minlength': 6},'input'],\
		       [_("Confirm Password :"), {'id':'cpwd', 'name':'cpwd', 'type':'password'},'input'],\
		       [ _("Captcha Image :"),{'id':'captcha','name':'captcha','type':'text'},{'image':image,'ckey':cinput},'captcha']\
		     ]
required = [ i[1]['name'] for i in ol_content ]

form = []
# get the OL content from formRender.py module
so = Session()
#print so.gender
formRender = Import('../formRender.py')

rember = dict([ (name, getattr(so, name, None))  for name in ('username', 'email')])
#ol = formRender.render_ol(ol_content, required, so)
#ol = formRender.render_ol(ol_content, required, rember)
ol = formRender.render_rows(ol_content, rember, required)
ol = Sum(ol)

# add the <Legend> tag
#ld = LEGEND(SPAN(legend_tag))
#form.append(FIELDSET(ld+ol))
form.append(ol)

# add buttons to this form
# buttons style
style = ';'.join([':'.join((k,v)) for k,v in pagefn.BUTTON_CSS.items()])

bns =[_("Next"), _("Cancel")]
sbn = INPUT(**{'class':'submit', 'type':'submit', 'value':bns[0],'style':style})
cbn = INPUT(**{'class':'submit cancel', 'type':'button', 'value':bns[1],'style':style})
buttons = FIELDSET(Sum((sbn, cbn)), **{'class':'submit'})
form.append(buttons)
formAction = Import('../config.py').tabs[int(_step)][2]
formAction = '/'.join(('register', 'formActions.ks', formAction))
# render the html slice which is a form element
print FORM(Sum(form), **{'action': formAction, 'id':'step1' , 'method':'get','class':'yform'})

# below is the javascript code for this page
paras = [pagefn.AJAXLOADING, _('Loading...'),'register/step_1.js.pih?formId=step1']
paras = tuple(paras)
"""
<script type="text/javascript">
$(document).ready(function(){	
	// make the cursor focus on the first input field 	
	var ajaxloading = "%s", waitingInfo="%s",validAction = "%s";	
	$('.cancel').click(function(){		
		loader = '<div id="loader" style="margin-left: 30em;"><img src="url" alt="altInfo" /></div>';
		loader = loader.replace(/url/i, ajaxloading).replace(/altInfo/i,waitingInfo);		
		$('#main').html(loader).load( 'home.pih', function(){
				this.scrollLeft = 0;//scroll back to the left								
			});
		//last = this;// reset the global 'last' to enable 'login' clickable
		this.blur();
		return false;
	});
	
	// get script for form fields validation
	$.getScript(validAction);
});
</script>
"""%paras