"""
The module for registration application. 
"""

from HTMLTags import *

# 'THIS.script_url' is a global variable in Karrigell system
#APPATH = THIS.script_url[1:]
#RELPATH = (lambda p : p.split('/')[0])(THIS.baseurl)
#model = Import( '/'.join((RELPATH, 'model.py')))

#modules = {'pagefn' : 'pagefn.py',  'JSON' : 'demjson.py', 'form':'form.py'}
modules = {'pagefn' : 'pagefn.py', }
[locals().update({k : Import('/'.join(('',v)))}) for k,v in modules.items() ]
 

# ********************************************************************************************
# Page Variables
# ********************************************************************************************
# the javascript lib name for tabs widget
REGJSLIB = 'ertabs'

# the id of the 'DIV' component which holds the tabs widget in the page
REGTABS = 'ertabs'

# the name of the instance of the tabs class
TABSINSTANCE = 'tabsContainer'

# The id for the 'Account' form
#ACCOUNTFORM = 'AccountForm'
# the id for the SPAN component in the account form page which holds buttons 
#ACCOUNTFORMBNS = 'accountBns'

# End*****************************************************************************************

# ********************************************************************************************
# The page functions begining 
# ********************************************************************************************
def index():    
    # the tabs' titles    
    labels = ['Account', 'Base Info', 'End']
    links = [ '/'.join(( THIS.baseurl, name))\
              for name in ('accountForm.ks/index', 'baseInfoForm.ks/index', 'actionEnd.ks/index')]
    
    lis = [ LI(SPAN(A(label,ref=link), **{'class':'tab-label'})) \
            for label, link in zip(labels, links)]
       
    #ul = UL(Sum(lis), **{ 'id':'tabs-nav','class':'ertabs_title'} )
    ul = UL(Sum(lis), **{'class':'ertabs_title'} )
    
    # the content container for each tab label
    div = DIV( **{'class':'ertabs_content'} )
              
    print DIV( Sum((ul, div)), **{'id':REGTABS,'class':REGTABS})

    # import javascript lib
    # the files for tabs widget
    libname=REGJSLIB 
    paras = [ '/'.join(('js', 'lib', libname, ftype, '.'.join((libname, ftype)))) for ftype in ('css', 'js') ]  
    paras.append(REGTABS)
    # the css file for spinner
    paras.append('/'.join(('js','lib','spinner','spinner.css')))
    paras = tuple(paras)
    js = \
    """
    var cssUrl="%s", jsUrl="%s", tabsDiv="%s";
    var spinnerCss="%s";
    // import css file
    [cssUrl, spinnerCss].each(function(src){
       new Asset.css(src);
    });
    //var mtCss = new Asset.css(cssUrl);
    
    // initialize the tabs widget
    function tabsInit(){
       window.addEvent('domready',function(){
          var tabs = window[tabsDiv] = new ERTabs(tabsDiv);
          // diable others tabs
          tabs.disableTabs([1,2]);
       });
    };
    
    // import javascript file
    var mtJs = new Asset.javascript(jsUrl,{onload:tabsInit});

    """%paras
    print pagefn.script(js, link=False)
    return

    