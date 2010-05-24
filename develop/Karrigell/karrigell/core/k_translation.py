import os
import cPickle
import k_config
    
class Translation:

    def __init__(self,config):
        self.config = config
        self.t_path = os.path.join(config.data_dir,"translations.dat")
        if not os.path.exists(self.t_path):
            out = open(self.t_path,"wb")
            cPickle.dump({},out,cPickle.HIGHEST_PROTOCOL)
            out.close()

    def translation(self,src,headers):
        # translate source src into the language specified in the
        # accept-language header
        # if no translation is defined, or no language specified in headers,
        # return None
        if not self.config.language:
            if not "accept-language" in headers:
                return None
            else:
                t_dict = self.get_translations()
                if not src in t_dict:
                    return None
                else:
                    langs = headers["Accept-language"].split(",")
                    for lang in langs:
                        language = lang.split(";")[0]
                        language = language.split('-')[0]
                        if language in t_dict[src]:
                            return t_dict[src][language]
                    return None
        else:
            return self.translate_into(src,k_config.language)

    def get_translations(self):
        return cPickle.load(open(self.t_path,'rb'))

    def save_translations(self,dico):
        # first try to pickle to a string
        try:
            data = cPickle.dumps(dico,cPickle.HIGHEST_PROTOCOL)
        except:
            raise Exception,"Couldn't save translations"

        # update file in a thread-safe way
        import threading
        tlock = threading.Lock()
        tlock.acquire()
        out = open(self.t_path,"wb")
        out.write(data)
        out.close()
        tlock.release()

    def translate_into(self,t_dict,src,language):
        if not src in t_dict or not language in t_dict[src]:
            return None
        else:
            return t_dict[src][language]

    def update_translations(self,dico):
        # update translation file from a dictionary
        t_dict = self.get_translations()
