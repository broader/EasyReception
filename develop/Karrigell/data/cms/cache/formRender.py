['render_rows', 'render_ol', 'render_table_fields']
'''
This module is mainly used for render html form element.
'''
from HTMLTags import *

def render_rows(content, remember={}, required=[]):
	''' Render YAML foramtted form fileds.
	'''
	rows = []
	for row in content :
		name = row[1].get('name')
		div = []
		label = TEXT()
		if name in required:
			# this field should be input
			mandotory = True
			old = row[1].get('class')
			if old :
				newclass = old + ' required'
			else:
				newclass = 'required'
			row[1]['class'] = newclass

			label += SUP('*', title=_("This field is mandotroy."))
		if row[0]:
			label += TEXT(row[0])
		label = LABEL(label, **{'for': row[1].get('id'),'style':'font-size:0.9em'})
		div.append(label)

		# maybe this filed has old value
		oldvalue = remember.get(name) or ''

		itype = row[-1]
		if itype == 'select' :
			tag = []
			for i in row[2]:
				tag.append(OPTION(i[1], **i[0]))
			input = SELECT(Sum(tag), **row[1])
		elif itype == 'multiselect':
			if oldvalue:
				row[1]['value'] = oldvalue
			input = INPUT(**row[1] )
		elif itype in ('input', 'text'):
			row[1]['value'] = oldvalue
			input = INPUT( **row[1])
		elif itype == 'textarea' :
			input = TEXTAREA(oldvalue, **row[1])
		elif itype == 'captcha':
			image, ckey = [row[2].get(name) for name in ('image', 'ckey')]
			input = Sum((INPUT( **row[1]),image, ckey))

		div.append(input)
		if itype in ('text', 'textarea', 'input', 'multiselect'):
			ctype = '-'.join(('type', 'text'))
		else:
			ctype = '-'.join(('type', itype))
		rows.append(DIV(Sum(div), **{'class':ctype}))
	return rows


def render_ol(content=None, required=[], remember={}):
	if not content:
		return

	rows = []
	for i in content :
		input_type = i[-1]
		# set label
		if input_type in ('radio', 'select') :
			label = LABEL(i[0])
		elif i[1].get('name') in required:
			em = EM(IMG(**{'alt':'required','src':'css/images/required_star.gif'}))
			label = LABEL(Sum((TEXT(i[0]), em)), **{'for': i[1]['id']})
			# add 'required' to this tag's 'class' attribute
			old = i[1].get('class')
			if old:
				value = old +' required'
			else:
				value = 'required'
			i[1].update({'class': value})
		else:
			label = LABEL(i[0], **{'for': i[1]['id']})

		if input_type in ('input' , 'captcha') :
			# render 'INPUT' tag
			d = i[1]
			if d['name'] not in ('password', 'cpwd', 'captcha'):
				v = remember.get( d['name'])
				if v :
					d['value'] = v

			input = INPUT(**d)

			if i[2] != 'captcha' :
				rows.append(Sum((label, input)))
			else:
				# append captcha tag
				Captcha = Import('Captcha.py')
				key = Captcha.getChallenge()
				image = '/'.join(('register',Captcha.getImageFile(key)))
				image = SUB(IMG(**{'src':image, 'alt' : 'captchaImage', 'class': 'captcha'}))
				cinput = INPUT(**{'id':'ckey','value':key, 'type':'hidden'})
				rows.append(Sum((label, input, image, cinput)))
		elif input_type == 'textarea':
			# render 'TEXTAREA' tag
			d = i[1]
			#d['style'] = 'width:0em;'
			v = remember.get(d['name']) or ''
			textarea = TEXTAREA(v, **d)
			rows.append(Sum((label, textarea)))
		elif input_type == 'radio':
			# render 'radio' type INPUT
			attrname = i[1][0][1].get('name')
			oldvalue = remember.get(attrname)
			if oldvalue :
				oldvalue = int(oldvalue)
			else:
				oldvalue = 0

			radios = []
			for index,item in enumerate(i[1]):
				if index == oldvalue :
					# append the 'checked' attribute to this check button
					item[1]['checked'] = ''
				radios.append(Sum((INPUT(**item[1]), TEXT(item[0]+2*'&nbsp;'))))
			radios.insert(0, label)
			rows.append(Sum(radios))
		elif input_type == 'select':
			# render 'select' type
			attrname = i[1].get('name')
			oldvalue = remember.get(attrname)
			if oldvalue :
				oldvalue = int(oldvalue)
			else:
				oldvalue = 0

			options = []
			for index, op in enumerate(i[2]):
				if index == oldvalue :
					# append the 'selected' attribute to this option
					op[0]['selected'] = ''
				options.append(OPTION(op[1], **op[0]))
			select = SELECT(Sum(options), **i[1])
			rows.append(label+select)


	ol = OL(Sum([LI(row, **{'style':''}) for row in rows]))
	return ol


def render_table_fields(names, values, cols):
	''' Render the table rows which is mainly used for showing
	  fields.
	  Parameters:
	  	names -the list contains fields' names
	  	values -the list contains fields' values
	  	cols - the columns divided by field number,
	  		   each column contains a label for showing field's name and
	  		   a label for showning field's value.
	'''
	names = list(names)
	values = list(values)

	fieldsNumber = cols
	cols = divmod(len(names), cols)
	if cols[1]:
		cols = cols[0] +1
	else:
		cols = cols[0]

	trs = []
	for g in range(cols) :
		tr = []
		for i in range(fieldsNumber):
			try:
				name = names.pop(0)
				value = values.pop(0)
				attrdiv = DIV(name, style='text-align:right;font-weight:bold;')
				valuelabel = LABEL(value,style='align:right')
				td = TD(attrdiv)+TD(valuelabel)
			except:
				break
			tr.append(td)
		trs.append(TR(Sum(tr)))

	# return the HTMLTag
	return Sum(trs)


'''
# The below scripts is only for test, so is be commented.
# the test form content
Content = [     [ _("Login Name :"), {'id':'username', 'name':'username','type':'text'}, 'input'],\
		       [_("Email address :"), {'id':'email', 'name':'email', 'class':'email', 'type':'text'}, 'input'],\
		       [_("Confirm Email :"), {'id':'cemail','name':'cemail','class':'email', 'type':'text'}, 'input'],\
		       [_("Password :"), {'id':'pwd', 'name':'password', 'type':'password', 'minlength': 6}, 'input'],\
		       [_("Confirm Password :"), {'id':'cpwd', 'name':'cpwd', 'type':'password'}, 'input'],\
		       [_("Captcha Image :"), {'id':'captcha','name':'captcha','type':'text'}, 'captcha'] \
		 ]

from HTMLTags import *
form = []
# the fieldset tag
ld = LEGEND(SPAN('Test'))
#print ld
ol = render_ol(Content, ('username', 'password', 'email'))
#print ol
form.append(FIELDSET(ld+ ol))
bns =[_("Next"), _("Cancel")]
sbn = INPUT(**{'class':'submit', 'type':'submit', 'value':bns[0]})
cbn = INPUT(**{'class':'submit cancel', 'type':'button', 'value':bns[1]})
buttons = FIELDSET(Sum((sbn, cbn)), **{'class':'submit'})
form.append(buttons)
formAction = Import('../config.py').tabs[1][2]
formAction = '/'.join(('register', 'formActions.ks', formAction))
#print form
print str(FORM(Sum(form), **{'action': formAction, 'id':'step1' , 'method':'get'}))

# print table
table = []
# append the caption
table.append( CAPTION(_("Login Info"), style='text-align: left; font-size: 1.6em;font-weight:bold;'))
names = [item[0] for item in Content ]
values = [item[1]['name'] for item in Content ]
trs = render_table_fields(names, values, 2)
table.append( trs)
print str(TABLE(Sum(table)))
'''


