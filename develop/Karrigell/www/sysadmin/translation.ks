"""
Online translates some i18n strings in source files.
"""
from HTMLTags import *

APPATH = THIS.script_url[1:]
RELPATH = (lambda p : p.split('/')[0])(THIS.baseurl)

modules = {'pagefn': 'pagefn.py',}# 'JSON': 'demjson.py', 'formFn':'form.py'}
[locals().update({k : Import('/'.join(('',v)))}) for k,v in modules.items() ]

# config data object
INICONFIG = Import( '/'.join((RELPATH, 'config.py')), rootdir=CONFIG.root_dir)

#############################################################################
##  Page Functions
#############################################################################

def _strInConfig():
    """ Return the i18n strings in config.py file. """
    return INICONFIG.i18nStrings() 


FILENAMESCONTAINER,FILENAMES = 'translationFiles', {'config.py': _strInConfig,}
def page_fileList(**args):
    print H2(_('Files need translated')),HR(style='padding:0px;')
    div = DIV(**{'id':FILENAMESCONTAINER})
    for f in FILENAMES.keys():
	div <= A(f)

    print div 
    
    print pagefn.script(_fileListJs(), link=False)
    return

ARGNAME = 'fileName'
def _fileListJs():
    paras = [FILENAMESCONTAINER,SHOWPAGE, '/'.join((APPATH, 'page_translating')), ARGNAME] 
    paras = tuple(paras)
    js = \
    '''
    var container='%s', showContainer='%s', url='%s', argName='%s';

    $(container).getElements('a').each(function(item){
	item.addEvent('click', function(e){
	    new Event(e).stop();
	    $(showContainer).empty().load([url, [argName,item.get('text')].join('=')].join('?'));
	});
    }); 
    '''%paras
    return js

def _getLangs():
    """ Return the languages that used by client browser. """
    langs = []
    for lang in HEADERS.get("Accept-language","").split(","):
        lang1 = lang.split(";")[0][:2]
        if not lang1 in langs:
            langs.append(lang1)
    return langs

SHOWPAGE = 'translatingPage'
def page_translating(**args):
    """ The online translation page. """
    div = DIV(**{'id': SHOWPAGE})
    if args=={}:
	div <= H3(_("Please select a file in the left file list!"))
	print div
	return
  
    name = args.get(ARGNAME)
    strings = FILENAMES.get(name)()
    langs = _getLangs()
    
    import k_translation
    translation = k_translation.Translation(CONFIG)
    t_dict = translation.get_translations()
    trans = translation.translate_into
    lines = [TR(TH(_("In script"))+Sum([TH(lang) for lang in langs]))]

    for i,_string in enumerate(strings):
        _string1 = _string.replace('"','&quot;')
        line = TD(_string)+INPUT(Type="hidden",name="orig-%s" %i,value=_string1)
        for lang in langs:
            _trans = trans(t_dict,_string,lang)
            if _trans is None:
                _input = TEXTAREA(_string,name="%s-%s" %(lang,i),
                        cols=15,rows=len(_string1)/25,
                        style="font-style:italic;")
            else:
                _trans = _trans.replace('"','&quot;')
                _input = TEXTAREA(_trans,name="%s-%s" %(lang,i),
                        cols=15,rows=len(_string1)/25)
            line += TD(_input)
        lines += [TR(line)]
  
    formId = 'translatingForm'
    form = FORM(**{'id':formId, 'action': '/'.join((APPATH, 'page_update'))})
    form <= TABLE(Sum(lines)) + INPUT(Type="submit",value=_("Save translations"), name="saveTranslation")
    form <= pagefn.script(_translatingJs(formId), link=False)

    explain = H3(_("Translating strings in %s") %name)
    explain += I(_('Enter your translation and save changes.'))+P()
   
    div <= Sum(( explain,form))
    print div
    return

def _translatingJs(formId):
    paras = [formId, SHOWPAGE] 
    paras = tuple(paras)
    js = \
    '''
    var formId='%s', showContainer='%s';
    new Form.Request($(formId), $(showContainer));
    '''%paras
    return js

def page_update(**kw):
    """ Updates the translation strings in translations.dat file. """
    dico = {}
    for k,v in kw.iteritems():
        lang,num = k.split("-")
        if not dico.has_key(lang):
            dico[lang]={num:v}
        else:
            dico[lang][num] = v

    dico2 = {} # same structure as in translation file
    langs = [ lang for lang in dico if not lang == "orig" ]
    for num in dico["orig"]:
        for lang in langs:
            dico2[dico["orig"][num]]=dict([(lang,dico[lang][num]) for lang in langs])

    import threading
    slock = threading.Lock()

    import k_translation
    translation = k_translation.Translation(CONFIG)
    t_dict = translation.get_translations()
    # normalize strings with "
    for key in dico2:
        if key not in t_dict and key.replace('&quot;','"') in t_dict:
            dico2[key.replace('&quot;','"')] = dico2[key]
            del dico2[key]
    t_dict.update(dico2)
    slock.acquire()
    try:
        translation.save_translations(t_dict)
    finally:
        slock.release()
    print _("Translations saved!")
 
