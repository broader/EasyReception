"""
The module for registration application. 
"""

from HTMLTags import *

# 'THIS.script_url' is a global variable in Karrigell system
#APPATH = THIS.script_url[1:]
#RELPATH = (lambda p : p.split('/')[0])(THIS.baseurl)
#model = Import( '/'.join((RELPATH, 'model.py')))

modules = {'pagefn' : 'pagefn.py',  'JSON' : 'demjson.py', 'form':'form.py'}
[locals().update({k : Import('/'.join(('',v)))}) for k,v in modules.items() ]
 

# ********************************************************************************************
# Page Variables
# ********************************************************************************************
# the javascript lib name for tabs widget
#REGJSLIB = 'morphtabs'
# the id of the 'DIV' component which holds the tabs widget in the page
#REGTABS = 'regtabs'

# The id for the 'Account' form
#ACCOUNTFORM = 'AccountForm'
# the id for the SPAN component in the account form page which holds buttons 
#ACCOUNTFORMBNS = 'accountBns'

# End*****************************************************************************************

# ********************************************************************************************
# The page functions begining 
# ********************************************************************************************

def index(**args):
    header = H2('Congradulations!', style='text-align:left;background:white;')
    print header, HR(style='color:white;border-color:white;margin:0px;padding:0px;')
    left = DIV('Test Left', **{'class':'c33l'})
    right = DIV('Test Left', **{'class':'c66r'})
    print DIV( Sum((left,right)), **{'class':'subcolumns'})