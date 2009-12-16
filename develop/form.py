"""
This module is mainly used for render html form element.
"""

from HTMLTags import *

def yform(fields):
	""" Render YAML formats form components."""
	divs = [ getField(field) for field in fields ]
	return divs

def _getValidClass(field, required):
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
    
def getField(field):
	""" Render YAML formats form field."""
	prompt,required,oldvalue = [ field.pop(prop) for prop in ( "prompt", "required", "oldvalue" )]
	
	div = []
	label = TEXT()
	
	if required:
		# this field must be input by the user
		old = field.get('class')
		if old :
			newclass = ' '.join((old,'required'))
		else:
			newclass = "required"
			
		field['class'] = newclass
		label += SUP("*", title=_("This field is mandotroy."))
		 
		if prompt:
			label += TEXT(prompt)
	else:
		label = TEXT(prompt)
		 
	label = LABEL(label, **{"for": field.get("id"),"style":"font-size:1.2em"})
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
		if fieldType in ("input", "text", "password"):
			field["value"] = oldvalue
			input = INPUT( **field)
		elif fieldType == "textarea":
			input = TEXTAREA(oldvalue, **field)
		elif fieldType == "radio":
			options = field.pop("options")
			if not oldvalue:
				oldvalue = 0
			
			radioes = [BR(),]
			name = field.get("name")
			
			for option in options:				
				if str(option.get("value")) == str(oldvalue) :
					option["checked"] = ""
					
				option["name"] = name
				option["type"] = "radio"
				text = option.pop("label")
				input = INPUT(**option)
				text = TEXT("".join(( text, "&nbsp;&nbsp;")))
				radioes.append( Sum(( input, text)) )
				
			input = Sum(radioes)
		elif fieldType == "select":
			options = field.pop("options")
			if not oldvalue:
				oldvalue = 0
			select = []
			name = field.get("name")
			
			for option in options:
				if str(option.get("value")) == str(oldvalue):
					option["selected"] = ""
				text = option.pop("label")
				select.append(OPTION(text, **option))
			
			[ field.pop(prop) for prop in ("type", "class")]	
			input = SELECT(Sum(select),**field)
			
	div.append(input)
	
	if fieldType in ("text", "textarea", "input", "password"):
		ctype = "-".join(("type", "text"))
	elif fieldType in ( "radio", "multiselect" ):
		ctype = "-".join(("type", "check"))
	else:
		ctype = "-".join(("type", fieldType))
	
	return DIV(Sum(div), **{"class":ctype})