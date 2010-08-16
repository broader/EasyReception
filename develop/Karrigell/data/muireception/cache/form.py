['yform', 'getField', 'filterProps', 'render_table_fields']
"""
This module is mainly used for render html form element.
"""

from HTMLTags import *

modules = {'pagefn': 'pagefn.py'}
[locals().update({k : Import('/'.join(('',v)))}) for k,v in modules.items() ]


def yform(fields):
	""" Render YAML formats form components."""
	divs = [ getField(item) for item in fields ]
	return divs

def _getValidClass(field, required):
	""" Set the form fileld's style class. """
	validClassName = "validate"
	validClass = field.pop(validClassName)

	if required :
		validClass.append("required")

	if validClass :
		validClass = ["".join(("\'",item, "\'")) for item in validClass]
		validClass = "".join(( validClassName, "[", ",".join(validClass), "]"))
		# field type
		fieldType = field.get("type")
		if fieldType in ("text","input","password"):
			validClass = " ".join((validClass, "text-input"))

	else:
		validClass = None

	return validClass

def _radio(field, oldvalue):
	options = field.pop("options")
	if not oldvalue:
		oldvalue = 0

	tags = [BR(),]

	_labels, _values = [ [option.get(name) or '' for option in options] for name in ('label', 'value')]
	radioes = RADIO(_labels, _values,**{'name':field.get('name') or ''})

	# set checked value
	for label,tag in radioes:
		if str(tag.attrs['value']) == str(oldvalue) :
			radioes.check(content=label)
			break

	# construct html tags
	[ tags.append(Sum((tag, LABEL(label)))) for label,tag in radioes ]

	return Sum(tags)

def _selectField(field,oldvalue):
	options = field.pop("options")
	if not oldvalue:
		oldvalue = 0

	select = []
	for option in options:
		if str(option.get("value")) == str(oldvalue):
			option["selected"] = ""

		text = _( option.pop("label") )
		select.append(OPTION(text, **option))

	for item in ("type", "class"):
		if field.has_key(item):
			field.pop(item)

	return SELECT(Sum(select),**field)

def _textMultiCheckbox(field,oldvalue):
	containerId = field.pop('id')
	container = []

	# monitor box
	mElements = [\
		DIV(oldvalue, **{'class':'monitor-text'}),
		INPUT(**{'type':'hidden','name':field.get('name'),'value':oldvalue})
	]

	container.append( DIV(DIV(Sum(mElements)), **{'class':'monitor'}))

	# menus container
	chkboxes = []
	for option in field['options']:
		attrs = (option in oldvalue) and {'class':'selected'} or {}
		chkboxes.append(LI(SPAN(option),**attrs))

	container.append(UL(Sum(chkboxes)))
	container = DIV(Sum(container),**{'id':containerId})

	# js slice
	js = \
	"""
	var containerId='%s';
	MUI.textMultiCheckbox('',{
		'onload': function(){
			new TextMultiCheckbox(containerId);
		}
	});
	"""%(containerId)
	script = pagefn.script(js,link=False)
	return Sum((container,script))

def _mtMultiSelect(field, oldvalue):
	"""
	Parameters:
	field - a dictionary object which should include below keys.
	    'id' - the DIV element 'id'
	    'dataUrl' - the url to get the values for options of the multi select
	    'containerStyle' - the css style for the widget container
	    'fieldName' - the value for the 'name' property of the INPUT element which is hidden
	    'itemsPerPage' - the number of items that will be shown in each page
	oldvalue - the old selected values
	"""
	msContainerId, url, containerStyle = [ field.pop(name) for name in ('id', 'dataUrl', 'containerStyle')]

	if oldvalue:
		url = '&'.join((url, '='.join(('oldvalue', oldvalue))))

	js = \
	"""
	var multiSelectContainer='%s',
	    multiSelectUrl='%s',
	    field='%s',
   	    itemsNumber='%s';

	MUI.multiSelect('',{onload: function(){
		new MTMultiWidget({
			container: multiSelectContainer,
			dataUrl: multiSelectUrl,
			fieldName: field, items_per_page: itemsNumber
		});
	}});
	"""%(msContainerId, url, field.pop('fieldName'),field.pop('itemsPerPage'))
	script = pagefn.script(js, link=False)
	return Sum( [ DIV(**{'id':msContainerId, 'style': containerStyle}), script])

def _check(field, oldValue) :
	'''
	Return a group of checkboxes components.
	Parameters:
	  field - {'name':..., 'prompt':..., 'options':[{'label':..., 'value':...},...]}
	  oldValue - the old checked values
	'''

	options = field.pop("options")
	if not oldValue:
		oldValue = ''

	tags = []

	_labels, _values = [ [option.get(name) for option in options] for name in ('label', 'value')]
	chkBoxes = CHECKBOX(_labels, _values)
	prefix = field.get('name') or ''
	for index, (label, tag) in enumerate(chkBoxes):
		tag.attrs['name'] = '-'.join((prefix, str(index)))

	# set checked value
	checked = [ label for label,tag in chkBoxes if label in oldValue ]
	chkBoxes.check(content=checked)

	# construct html tags
	[ tags.append(DIV(Sum((tag, LABEL(label))), **{'class':'type-check'})) \
	  for label,tag in chkBoxes ]

	return Sum(tags)

def getField(field):
	"""
	Render YAML formats form field.
	'field' format is :
	[
		{
		'id': ...,	# the id for this form fieldElement;
		'name': ...,	# field name;
		'prompt':..., 	# the text to decribe the filed which usually is at the left of the form field;
		'class':..., 	# the css class for prompt label
		'required':[True or False], 	# is this filed could not be empty?
		'oldvalue':..., # for edit action, old value is needed;
		'validate': [],	# form field validate function names, should be a list
		'type': one of ['text', 'input', 'textarea', 'radio', 'select', 'textMultiCheckbox', 'hidden']	# the form field type
		},
		......
	]
	"""

	prompt,required,oldvalue = [ field.pop(prop) for prop in ( 'prompt', 'required', 'oldvalue' )]

	# for i18n need
	prompt = _(prompt)

	div = []
	label = TEXT()

	if required:
		# this field must be input by the user
		old = field.get('class')
		if old :
			newClass = ' '.join((old,'required'))
		else:
			newClass = "required"

		field['class'] = newClass
		label += SUP("*")

		if prompt:
			label += TEXT(prompt)
	else:
		label = TEXT(prompt)


	label = LABEL(label, **{"for": field.get("id"),"style":"font-size:1.2em;text-align:left;width:100%;"})
	div.append(label)

	klass = _getValidClass(field,required)
	if klass :
		field["class"] = klass

	fieldType = field.get("type")
	key = field.get("key")
	if key :
		# It"s a "Captcha" input fields,
		# so add the captcha image and corresponding captcha key.
		field.pop("key")
		image = field.pop("image")
		input = Sum((INPUT(**field),image, key))
	else:
		# maybe this filed has old value
		oldvalue = oldvalue or ""
		if fieldType in ("input", "text", "password",'hidden'):
			field["value"] = oldvalue
			input = INPUT( **field)
		elif fieldType == "textarea":
			input = TEXTAREA(oldvalue, **field)
		elif fieldType == "radio":
			input = _radio(field,oldvalue)
		elif fieldType == "select":
			# normal html form 'select' component
			input = _selectField(field,oldvalue)
		elif fieldType == "textMultiCheckbox":
			# select multiful text
			input = _textMultiCheckbox(field,oldvalue)
		elif fieldType == 'mtMultiSelect':
			# select multiful values in multiful pages
			input = _mtMultiSelect(field, oldvalue)
		elif fieldType == 'check':
			# a group of checkboxes
			input = _check(field, oldvalue)

	div.append(input)

	if fieldType in ("text", "textarea", "input", "password"):
		ctype = "-".join(("type", "text"))
	elif fieldType in ( "radio", "multiselect"):
		ctype = "-".join(("type", "check"))
	else:
		ctype = "-".join(("type", fieldType))

	return DIV(Sum(div), **{"class":ctype})

def filterProps(fields,values):
	""" Filter the needed properties of fields for render_table_fields function."""
	postValues = []
	for field in fields :
		temp = {}
		[ temp.update({prop:field.get(prop)}) for prop in ('prompt','type')]

		if not temp['type'] :
			temp['type'] = 'text'

		propName = field.get('name')
		if temp['type'] in ('radio','select') :
			for option in field['options'] :
				if option['value'] == str(values.get(propName)):
					temp['value'] = option['label']
					break
		else:
			temp['value'] = values.get(propName)

		postValues.append(temp)

	return postValues

def render_table_fields( fields, cols=1, labelStyle={}, valueStyle={}):
	"""
	Render the table rows which is mainly used for showing fields.
	Parameters:
		fields - a list, the format is [{'prompt':...,'value':...,'type':...},...];
	  	cols - the columns divided by field number,
	  		   each column contains a label for showing field's name and
	  		   a label for showning field's value;
	  	labelStyle - A dictionary object that has two keyes('label' and 'td').
			 The values of these two keyes holds the styles of <td> and
			 <div> for showing field's label;
		valueStyle - A dictionary object that has two keyes('label' and 'td').
			 The values of these two keyes holds the styles of <td> and
			 <div> for showing field's values;
	"""
	fieldsNumber = cols

	cols = divmod(len(fields), cols)
	if cols[1]:
		cols = cols[0] +1
	else:
		cols = cols[0]

	trs = []
	for g in range(cols) :
		tr = []
		for i in range(fieldsNumber):
			try:
				field = fields.pop(0)
				name, value, fieldType = [ field.get(prop) for prop in ('prompt', 'value', 'type') ]
				if not fieldType:
					fieldType = 'text'

				attrdiv = DIV(name, style=labelStyle.get('label') or '')
				if fieldType !='textarea':
					valuelabel = LABEL(value,style=valueStyle.get('label') or '')
				else:
					valuelabel = TEXTAREA(value,style=valueStyle.get('textarea') or '', disabled='')
				td = TD(attrdiv, style=labelStyle.get('td') or '')+TD(valuelabel, style=valueStyle.get('td') or '')
			except:
				break
			tr.append(td)
		trs.append(TR(Sum(tr)))

	# return the HTMLTag
	return Sum(trs)

