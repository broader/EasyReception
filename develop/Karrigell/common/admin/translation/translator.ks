import os
import urllib

from HTMLTags import *
Login(role=["admin"],valid_in="/")
SET_UNICODE_OUT("utf-8")

header = HEAD(
    LINK(rel="stylesheet",href="../../admin.css")+
    META(http_equiv="Content-Type",content="text/html; charset=utf-8")
    )
    
def index(script):
    script = urllib.unquote_plus(script)
    name = os.path.basename(script)
    ext = os.path.splitext(script)[1]
    if ext in [".py",".pih",".hip",".ks"]:
        import k_pygettext
        strings = k_pygettext.get_strings(script)
    elif ext == ".kt":
        strings = KT.get_strings(script)
    list_langs = HEADERS.get("Accept-language","").split(",")
    langs = []
    for lang in list_langs:
        lang1 = lang.split(";")[0][:2]
        if not lang1 in langs:
            langs.append(lang1)

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
                        cols=25,rows=len(_string1)/25,
                        style="font-style:italic;")
            else:
                _trans = _trans.replace('"','&quot;')
                _input = TEXTAREA(_trans,name="%s-%s" %(lang,i),
                        cols=25,rows=len(_string1)/25)
            line += TD(_input)
        lines += [TR(line)]
    
    explain = H3(_("Translating strings in %s") %name)
    explain += I(_('Strings in italic have no translation yet. '))
    explain += _('Enter your translation and save changes')+P()
    print HTML(header + BODY(explain +
             FORM(TABLE(Sum(lines))+
                INPUT(Type="submit",value=_("Save translations")),
                action="update",method="post")))

def update(**kw):
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
    print _("Translations saved")

