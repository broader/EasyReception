# define allowed data types
# for each type, define a function to check that user entry has the right format
# and if so, convert to the value with the appropriate type

import re        
import datetime

def _date(s,elts):
    vals = [ int(x) for x in elts ]
    y = vals[date_fmt["y"]]
    m = vals[date_fmt["m"]]
    d = vals[date_fmt["d"]]
    try:
        return datetime.date(y,m,d)
    except:
        return s

class TypeError(Exception):
    pass

class Type:

    def __init__(self,conv_func,*patterns):
        self.patterns = patterns
        self.conv_func = conv_func

    def check(self,value):
        for pattern in self.patterns:
            if re.match(pattern,value):
                return self.conv_func(value)
        raise TypeError,self
        
types = {"integer":Type(int,"-?\d+$"),
    "float":(float,"-?\d*\.\d+$","-?\d+\.\d*$"),
    "date":(_date,"(\d+)[/-](\d+)[/-](\d+)$"),
    "string":(lambda x:x,".*")
    }

def check(value,typ):
    return types[typ].check(value)
    