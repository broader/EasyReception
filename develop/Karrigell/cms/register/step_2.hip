from HTMLTags import *
config = Import('../config.py')

modules = {'pagefn' : 'pagefn.py',}
[locals().update({k : Import('/'.join(('',v)))}) for k,v in modules.items() ]


legend_tag = _("Base Info")

# get the OL content from formRender.py module
content = config.base_fields_form
required = []
formRender = Import('../formRender.py')
ol = formRender.render_ol(content, required)

# add the <Legend> tag
ld = LEGEND(SPAN(legend_tag))

form = []
form.append(FIELDSET(ld+ol))

# add buttons to this form
# buttons style
style = ';'.join([':'.join((k,v)) for k,v in pagefn.BUTTON_CSS.items()])

bns =[_("Back"), _("Next"),  _("Cancel")]
backbn = INPUT(**{'class':'submit back', 'type':'button', 'value':bns[0],'style':style})
nextbn = INPUT(**{'class':'submit', 'type':'submit', 'value':bns[1],'style':style})
cancelbn = INPUT(**{'class':'submit cancel', 'type':'button', 'value':bns[2],'style':style})
buttons = FIELDSET(Sum((backbn, nextbn, cancelbn)), **{'class':'submit'})
form.append(buttons)
formAction = Import('../config.py').tabs[int(_step)][2]
formAction = '/'.join(('register', 'formActions.ks', formAction))
# render the html slice which is a form element
print FORM(Sum(form), **{'action': formAction, 'id':'step2' , 'method':'post', 'class':'yform'})

# below is the javascript code for this page

"""
<script type="text/javascript">
$(document).ready(function(){	
	// make the cursor focus on the first input field 	
	$('#name').focus();
	
	loader = '<div id="loader" style="margin-left: 30em;"><img src="images/ajax_loading.gif" alt="loading..." /></div>';
	// call back function for 'Cancel' button
	$('.cancel').click(function(){	
		$('#main').html(loader).load( 'home.pih', function(){
				this.scrollLeft = 0;//scroll back to the left								
			});
		last = this;// reset the global 'last' to enable 'login' clickable
		this.blur();
		return false;
	});
	
	// call back function for 'Back' button
	$('.back').click(function(){			
		var t =$('#tabs');	
		// Note that the '1' and '2' tabs must be disabled after '0' tab has been selected. 
		t.tabs('enable', 0).tabs('select', 0).tabs('disable',2).tabs('disable',1);		
		return true;
	});
	
	
	// get script for form fields validation
	$.getScript('register/step_2.js.pih?formId=step2');
});
</script>
"""