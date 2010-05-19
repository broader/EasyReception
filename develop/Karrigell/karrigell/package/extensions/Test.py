class action:
    def __init__(self, Target):
        self.Target = Target
        
    def __call__(self,url,namespace):
        import string
        if not hasattr(string,"Template"): # Python 2.4 or above
            raise SyntaxError,"Unable to handle this syntax for " + \
                "string substitution. Python version must be 2.4 or above"
        print "Test extension"
        print self
        print url
        print namespace
        return True