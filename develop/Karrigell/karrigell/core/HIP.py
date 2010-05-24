import cStringIO
import transform_script

class HTMLStream:
    """Instances of this class are used in Python scripts to produce HTML
    with this syntax :
    import k_utils
    H= HIP.HTMLStream()
    H + '<br>' - type(somevar)

    The last line above will send <br> and cgi.escape(type(somevar)) to the
    standard output"""

    def __add__(self,data):
        if isinstance(data, unicode):
            print data
        else:
            print str(data)
        return self
    
    def __sub__(self,data):
        if isinstance(data, unicode):
            d = data
        else:
            d = str(data)
        print cgi.escape(d)
        return self


class HIP:

    def __init__(self,filename,indent=""):
        # indent is used by Include() ???
        output = cStringIO.StringIO()
        self.cur_row = -1
        self.prev_tok = None
        transform_script.transform(open(filename),output,
            self.translate_func)
        self.output = cStringIO.StringIO()
        output.seek(0)
        for line in output.readlines():
            self.output.write(indent+line)
        
    def pythonCode(self):
        return self.output.getvalue()

    def translate_func(self,tokens,state):
        token_type,token_string,(srow,scol),(erow,ecol),line_str = tokens
        typ = transform_script.token.tok_name[token_type]
        res = token_string
        if typ == "STRING" and srow>self.cur_row:
            if not self.prev_tok == "NL":
                res = "print "+res
        self.cur_row = srow
        self.prev_tok = typ
        return res,state

if __name__=="__main__":
    hip = HIP("../../common/doc/en/tour/hip_test.hip")
    print hip.pythonCode()
    