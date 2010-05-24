
"""
Module for application configuration.

example :

    import k_app_config
    
    app_config = k_app_config.AppConfig("mailing list")
    try :
        smtp_server = app_config.smtp_server
    except AttributeError :
        smtp_server = "my.smtp.server"
        app_config.smtp_server = smtp_server # set default value in configuration file

Application configuration data are saved in directory data_dir/app_config/xxxx 
where xxxx is the name given to  k_app_config.AppConfig()

"""

import os
import cPickle
import k_config
import threading


for host_name,config in k_config.config.iteritems() :
    path = os.path.join(config.data_dir,"app_config")
    if not os.path.exists(path):
        os.mkdir(path)

slock = threading.Lock()

class AppConfig (object):
    def __init__ (self, app_name):
        object.__init__(self)
        self.__dict__["file_name"] = os.path.join(config.data_dir,"app_config", "%s.dat" % app_name)
        try :
            self.__dict__["config"] = cPickle.load(open(self.file_name,"rb"))
        except (IOError, EOFError) :
            self.__dict__["config"] = {}
        self.__dict__["modified"] = False
    
    def __del__ (self):
        if self.__dict__["modified"] == True :
            slock.acquire()
            out = open(self.__dict__["file_name"], "wb")
            cPickle.dump(self.__dict__["config"], out, cPickle.HIGHEST_PROTOCOL)
            out.close()
            slock.release()

    def __setattr__ (self, name, value):
        try :
            self.__dict__["config"][name] = value
        except KeyError, msg :
            raise AttributeError, msg
        self.__dict__["modified"] = True
        
    def __getattr__ (self, name):
        try :
            return self.__dict__["config"][name]
        except KeyError, msg :
            raise AttributeError, msg
    
    def __delattr__ (self, name):
        try :
            del self.__dict__["config"][name]
        except KeyError, msg :
            raise AttributeError, msg
        self.__dict__["modified"] = True
        
    