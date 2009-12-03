"""
This module is mainly used for render html form element.
"""
from HTMLTags import *

def yform(fields):
    """ Render YAML formats form components."""
    divs = [ getField(field) for field in fields ]
    return divs

def _getValidClass(field, required):
    validClassName = 'validate'
    validClass = field.pop(validClassName)
           
    if required :
       validClass.append('required')
    
    if validClass :
       validClass = [''.join(('\'',item, '\'')) for item in validClass]
       validClass = ''.join(( validClassName, '[', ','.join(validClass), ']'))
       
       # field type
       fieldType = field.get('type')
       if fieldType in ('text','input','password'):
          validClass = ' '.join((validClass, 'text-input'))
    else:
       validClass = None 
    
    return validClass
    
def getField(field):
    """ Render YAML formats form field."""    
    prompt,required,oldvalue = [ field.pop(prop) for prop in ( 'prompt', 'required', 'oldvalue' )]
    div = []
    label = TEXT()
    if required:
       # this field should be input
       old = field.get('class')
       if old :
          newclass = old + ' required'
       else:
          newclass = 'required'
       field['class'] = newclass
       label += SUP('*', title=_("This field is mandotroy."))
    if prompt:
       label += TEXT(prompt)
    label = LABEL(label, **{'for': field.get('id'),'style':'font-size:1.2em'})
    div.append(label)
    
    klass = _getValidClass(field,required)
    if klass :
       field['class'] = klass    
    
    fieldType = field.get('type')
    key = field.get('key')
    if key :
	    # It's a 'Captcha' input fields, 
	    # so add the captcha image and corresponding captcha key.
       field.pop('key')
       image = field.pop('image')
       #input = Sum((INPUT(**field),image, key))
       input = Sum((INPUT(**field),image, key))
    else:
       # maybe this filed has old value
       oldvalue = oldvalue or ''
       if fieldType in ('input', 'text', 'password'):
	       field['value'] = oldvalue
	       #klass = _getValidClass(field,required)
	       #if klass :
	       #   field['class'] = klass
	       input = INPUT( **field)
       elif fieldType == 'textarea' :
	       #klass = _getValidClass(field,required)
	       #if klass :
	       #   field['class'] = klass
	       input = TEXTAREA(oldvalue, **field)			 

    div.append(input)
    if fieldType in ('text', 'textarea', 'input', 'multiselect','password'):
       ctype = '-'.join(('type', 'text'))
    else:
       ctype = '-'.join(('type', fieldType))
       
    return DIV(Sum(div), **{'class':ctype})