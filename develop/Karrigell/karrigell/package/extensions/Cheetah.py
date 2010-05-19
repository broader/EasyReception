import urlparse

class action:
    def __init__(self, target):
        self.target = target
        
    def __call__(self,url,**namespace):
        # apply the Cheetah template engine to document at url filename
        # with provided namespace
        from Cheetah.Template import Template # or raise Exception
        abs_url = urlparse.urljoin(self.target.script_url,url)
        target = self.target.url_to_file(abs_url)
        templateDef = open(target.name).read()
        t = Template(templateDef, searchList=[namespace])
        return t
