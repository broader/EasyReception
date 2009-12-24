import os
import urllib

from HTMLTags import *

header = HEAD(
    LINK(rel="stylesheet",href="../../admin.css")+
    META(http_equiv="Content-Type",content="text/html; charset=utf-8")
    )

def index(script):
    script = urllib.unquote_plus(script)
    name = os.path.basename(script)
    import k_pygettext
    strings = k_pygettext.get_strings(script)
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
            _trans = trans(t_dict,_string,lang).replace('"','&quot;')
            _input = INPUT(name="%s-%s" %(lang,i),value=_trans)
            line += TD(_input)
        lines += [TR(line)]
    print HTML(header +
        BODY(H3(_("Translating stings in %s") %name) +
             FORM(TABLE(Sum(lines))+INPUT(Type="submit",value="Ok"),
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

