# -*- coding: iso-8859-1 -*-

import os
import pprint

class Settings:

    def __init__(self,file_name=None):
        self.file_name = file_name
    
    def load(self):
        """Load settings from file"""
        settings = {}
        if not self.file_name is None:
            src = open(self.file_name).read()
            settings = eval(src)
        return settings
    
    def save(self,data):
        """Save dictionary data"""
        # old settings
        try:
            settings = self.load()
        except IOError:
            settings = {}
        # update with new values
        settings.update(data)
        if self.file_name is not None:
            out = open(self.file_name,'w')
            pprint.pprint(settings,out)
            out.close()
        else:
            print data

if __name__=='__main__':
    settings = Settings('dummy')
    settings.save({'name':u"lj'ljé",
        'value':55})
    namespace = settings.load()
    globals().update(namespace)
    print name,value
    settings.save({'age':10})
    print settings.load()
    
    conf = Settings(r'c:\Karrigell-dev\20100204\data\www\blogs\blog_settings.py').load()
    for k in conf:
        print k,conf[k],isinstance(conf[k],unicode)