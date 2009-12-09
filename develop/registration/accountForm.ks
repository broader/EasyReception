"""
The pages for account form 
"""

from HTMLTags import *

# 'THIS.script_url' is a global variable in Karrigell system
APPATH = THIS.script_url[1:]
RELPATH = (lambda p : p.split('/')[0])(THIS.baseurl)

#model = Import( '/'.join((RELPATH, 'model.py')))
modules = {'pagefn' : 'pagefn.py',  'JSON' : 'demjson.py', 'formFn':'form.py'}
[locals().update({k : Import('/'.join(('',v)))}) for k,v in modules.items() ]
 
# import captcha module
Captcha = Import('./Captcha.py', relpath=THIS.baseurl, RELDIR=REL())

# ********************************************************************************************
# Page Variables
# ********************************************************************************************
# the session object for this page
SO = Session()
# config data object
CONFIG = Import( '/'.join((RELPATH, 'config.py')), rootdir=CONFIG.root_dir)
# form fields' names in CONFIG file
ACCOUNTFIELDS = 'userAccountInfo'
# The id for the 'Account' form
ACCOUNTFORM = 'AccountForm'
# the id for the SPAN component in the account form page which holds buttons 
ACCOUNTFORMBNS = 'accountBns'

# End*****************************************************************************************

# ********************************************************************************************
# The page functions begining 
# ********************************************************************************************
CAPTCHACLASS = 'captcha'
CAPTCHAKEY = 'ckey'
def index(**args):
	 """Render the form for account's information."""
	 # get fields names
	 username, usermail, pwd = CONFIG.getData(ACCOUNTFIELDS).get('fields')
	  
    # create a captcha tag 
    # 'THIS.baseurl' and 'REL()' are global variable and function in Karrigell system
    #Captcha = Import('./Captcha.py', relpath=THIS.baseurl, RELDIR=REL())        
	 key = Captcha.getChallenge()    
	 image = '/'.join((THIS.baseurl,Captcha.getImageFile(key)))        
	 image = IMG(**{'src':image, 'alt' : 'captchaImage', 'class': CAPTCHACLASS})
	 image = Sum((image, SPAN(_(' If the left image is unidentified, please click it and switch to anther image.'), style='font-size:1.1em;color:#a7a8a0;')))    
	 cinput = INPUT(**{'id':CAPTCHAKEY, 'value':key, 'type':'hidden'})
    
	 # the form fields
	 fields = \
      [ {'prompt':_('Login Name :'),'name':username,'type':'text','validate':['length[6,-1]','~accountCheck']},
        {'prompt':_("Email address :"), 'name':usermail, 'class':'email', 'type':'text','validate':['email',]},
        {'prompt':_("Confirm Email :"), 'name':'cemail','class':'email', 'type':'text','validate':['email','confirm[%s]'%usermail]},
        {'prompt':_("Password :"),'name':pwd, 'type':'password','validate':['length[6,-1]',]},
        {'prompt':_("Confirm Password :"), 'name':'cpwd', 'type':'password','validate':['confirm[password]',]},
        {'prompt':_("Captcha Image :"),'name':'captcha','type':'text', 'image':image, 'key':cinput, 'validate':['~cimgCheck',]}
      ]
    
	 rember = dict([ (name, getattr(SO, name, None))  for name in ('username', 'email')])
    # Add other properties for each field, these properties are 'id','required','oldvalue'
	 for field in fields :
       # Add 'id' property for each field
		 name = field.get('name')
		 field.update({'id':name})
       # Add required property to the needed fields, 
       # here means all the fields will be added the 'required' property.
		 field.update({'required':True})
       # add maybe old value
		 field.update({'oldvalue':rember.get(name)})
    
    # render the fields to the form
	 form = []
    # get the OL content from formRender.py module    
	 #yform = Import('../form.py').yform
	 yform = formFn.yform
	 left = DIV(Sum(yform(fields[:3])), **{'class':'c50l'})
	 right = DIV(Sum(yform(fields[3:])), **{'class':'c50r'})
	 divs = DIV(Sum((left, right)), **{'class':'subcolumns'})
            
    # add the <Legend> tag
	 legend = LEGEND(TEXT('Account Information'))    
	 form.append(FIELDSET(Sum((legend,divs))))
    
    # add buttons to this form   
	 bns =[_("Next"), _("Cancel")]    
	 sbn = BUTTON(bns[0], **{'class':'MooTrans', 'type':'submit'})    
	 cbn = BUTTON(bns[1],**{'class':'MooTrans', 'type':'button'})
	 span = DIV(Sum((sbn,cbn)), **{ 'id':ACCOUNTFORMBNS, 'style':'position:absolute;left:18em;'})    
	 form.append(span)
    
    # form action url
	 action = '/'.join((APPATH, '_'.join(('page', 'valid'))))              
              
	 form = FORM( Sum(form), 
                 **{
                   'action': action, 
                   'id': ACCOUNTFORM, 
                   'method':'get',                   
                   'class':'yform'
                 }
               )
	 print DIV(form, **{'class':'subcolumns'})
    
    # javascript functions for this page 
	 accountErr = _('This account has been used, please input other name.')    
	 cpatchaErr = _('Pleas input right info on the below image. If the image is difficult to identify, click it to change another image!')
	 paras = [ accountErr, CAPTCHACLASS,CAPTCHAKEY, cpatchaErr]
	 paras.extend([ '/'.join((APPATH, name))for name in ( 'page_captchaValid', 'page_switchImg', 'page_accountValid' )])
    
	 paras.extend([ ACCOUNTFORMBNS, ACCOUNTFORM, pagefn.REGISTERDLG, pagefn.TABSCLASS])
    # add some files' path for validation function
	 names = ('css/hack.css', 'lang.js.pih', 'formcheck.js', 'theme/red/formcheck.css')
	 paras.extend([ '/'.join(('js', 'lib', 'formcheck', name )) for name in names])
    
	 js = \
    """
    var accountErr='%s';
    var captchaClass='%s', captchaKey='%s', captchaErr='%s';
    var captchaValid='%s', captchaSwitch='%s';
    var accountValid='%s';
    var buttonsContainer='%s', formId='%s', digname='%s', tabsClass='%s';
    var hackCss='%s', fcI18nJs='%s', fcJs='%s', fcCss='%s';
    
    // Add validation function to the form
    // import css file for validation
    new Asset.css(hackCss);
    new Asset.css(fcCss);
    
    // import javascript file for validation
    new Asset.javascript(fcI18nJs);
    
    // Set a global variable 'formchk' which will be used as an instance of the validation Class-'FormCheck'.
    var formchk;
    
    // Load the form validation plugin script
    new Asset.javascript( fcJs, {
       onload:function(){
          formchk = new FormCheck(
             formId,
             {
                submitByAjax: true,
                onAjaxSuccess: function(response){
                   if(response != 1){alert('Account creating failed!');}
                   else{
                      tabSwitch();
                   };               
                },            

                display:{
                   errorsLocation : 1,
                   keepFocusOnError : 0, 
                   scrollToFirst : false
                }
              }
          );
       }
    });    
    
    // a Request.JSON class for send validation request to server side    
    var accountRequest = new Request.JSON({async:false});
    
    // check whether the input account has been used
    var accountValidTag = false;
    function accountCheck(el){
       el.errors.push(accountErr)
       // set some options for Request.JSON instance
       accountRequest.setOptions({
          url: accountValid,
          onSuccess: function(res){
             if(res.valid == 1){accountValidTag=true}
          }
       });
       alert(accountRequest.options.url);
       accountRequest.get({'name':el.getProperty('value')});
       if(accountValidTag){
          accountValidTag=false;   // reset global variable 'accountValid' to be 'false'
          return true
       }             
       return false;
    }
         
     
    // captcha image check
    var capthcaValidTag = false;   // a global variable to save the captcha check result
    // a Request.JSON class for send validation request to server side    
    var captchaRequest = new Request.JSON({async:false});
    // the really validation function for the captcha field
    function cimgCheck(el){
       el.removeEvents();
       el.errors.push(captchaErr);
       // Request captcha check from server side,
       // if it's a valid captcha,the 'cpatchaValidTag' variable
       // will be set to 'true' in the callback function of
       // 'captchaRequest' which is a Request.JSON instance.
       
       // set some options for Request.JSON instance first
       captchaRequest.setOptions({
          url: captchaValid,
          onSuccess: function(res){
          	 //alert('captcha image check result is ' + res.valid);
             if(res.valid == 1){capthcaValidTag=true}
          }
       });
       
       captchaRequest.get({ 
          'captcha':el.getProperty('value'),
          'ckey':$(captchaKey).getProperty('value')
       }); 
       
       if(capthcaValidTag){
          capthcaValidTag=false;   // reset global variable 'valid' to be 'false'
          return true
       }             
       return false;
    };
    
    // Successfully validation, start next step
    function tabSwitch(){       
       var tabs = window[$$('div.'+tabsClass)[0].getAttribute('id')];
       // diable action must be done first before switching to next tab
       tabs.disableTabs([tabs.currentTab()]);
       tabs.nextTab();
    };
         
    // The function which will close the popup dialog box.
    function closeBox(){
       // revove the displayed invalid info
       if($type(formchk) != false){
          formchk.removeErrors();
       };
       
       // Get the popup dialog object by its name 
       // which is defined in 'menu.ks._loginScript()'. 
       window[digname].close();
       delete window[digname];
    };
    
    function pageInit(event){       
       // Add click callback function to change captcha image       
       $$('.'+captchaClass)[0].addEvent('click', function(event){
          new Request.HTML().get(captchaSwitch);
       });
       
       // add mouseover effect to buttons
       new MooHover({container:buttonsContainer,duration:800});

       // Add click callback functions for buttons
       var bns = $(buttonsContainer).getElements('button');       
       
       $(bns[0]).addEvent('click',function(event){
         formchk.onSubmit(event);
       });

       // Add callback function to 'Cancel' button
       $(bns[1]).addEvent('click', closeBox);
    };

    window.addEvent('domready', pageInit);
    """%tuple(paras)
	 print pagefn.script(js, link=False)
	 return

def page_valid(**args):
	 """
    Valid the account informations of user.
    """
	 import sys
	 reload(sys)
	 sys.setdefaultencoding('utf8')
	 for k,v in args.items():
	 	setattr( SO, k, v)
	 #print JSON.encode({'type':1, 'session': args})
	 print '1'
	 return
    
def page_switchImg(**args):
    """ A function to switch a captcha image and corresponding captcha key.
    All these action implemented by javascript slice which will be returned to 
    clientside and be excuted on clientside.
    """
    key = Captcha.getChallenge()    
    image = '/'.join((THIS.baseurl,Captcha.getImageFile(key)))
    paras = [CAPTCHAKEY, key, CAPTCHACLASS, image]
    paras = tuple(paras) 
    script = \
    """
    var keyId='%s',keyValue='%s', imgClass='%s',imgUrl='%s';    
    // replace the captcha key
    $(keyId).setProperty('value',keyValue);
    // replace the image source 
    $$('.'+imgClass)[0].setProperty('src',imgUrl);
    """%paras
    print pagefn.script(script,link=False)
    # replace the validation rule for captcha	
    #url = 'register/formActions.ks/validCaptcha?key=%s' %key
    #print '$("#captcha").rules("add", {remote: "%s"});' %url 
    return

def page_captchaValid(**args):
    """ Validate the user inputing captcha."""
    key,captcha = [ args.get(name) or '' for name in ('ckey', 'captcha') ]
    res = {'valid':0}
    if Captcha.testSolution(key, captcha):
       res['valid'] = 1
    print JSON.encode(res)
    
def page_accountValid(**args):
    """ Check whether the input account name has been used."""
    name = args.get('account') or ''
    res = {'valid':1}
    print JSON.encode(res) 