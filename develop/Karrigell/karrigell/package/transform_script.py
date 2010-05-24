import sys
import tokenize
import token
import string

def transform(_in,out=sys.stdout,func=None,debug=False):
    """Copy script in file object _in into out, applying function func()
    to each token, and returns a state object
    func is a function with 2 arguments :
    - the tuple returned by generate_token
    - an arbitrary object (the state object) to store intermediate data
    func must return a tuple with 2 elements :
    - the string to write on the output object "out"
    - the new value of the state object
    If debug is set, a trace of each token is printed
    If func is not set, out is the same as _in
    """
    read_func = _in.readline
    state = None

    if not func:
        func = lambda x,y:(x[1],None)

    # values of previous token
    crow,ccol = 0,0 # current row and column
    cur_string = "\n"
    cur_typ = None
    cur_line = ""

    for tokens in tokenize.generate_tokens(read_func):

        token_type,token_string,(srow,scol),(erow,ecol),line_str = tokens
        typ = token.tok_name[token_type]
        if debug:
            print typ,token_string

        if srow>crow:
            # new line
            if debug:
                print "new line"
            indent = ""
            i = 0
            while i<len(line_str) and line_str[i] in string.whitespace:
                indent += line_str[i]
                i += 1
            if not cur_string.endswith("\n") and not typ=="ENDMARKER":
                out.write(cur_line[ccol:]) # end of previous line
                if debug:
                    print "write %s" %cur_line[ccol:]
            out.write(indent)
        else:
            out.write(line_str[ccol:scol]) # whitespace between words
        if not typ in ["INDENT","DEDENT","NL"]:
            state = process(out,func,tokens,state)
        if typ == "NL" and not cur_typ in["NEWLINE","COMMENT_","NL"]:
            state = process(out,func,tokens,state)
        crow,ccol = erow,ecol
        cur_string = token_string
        cur_typ = typ
        # avoid line breaks after a comment that doesn't start on col 0
        if cur_typ=="COMMENT" and token_string.endswith("\n"):
            cur_typ = "COMMENT_"
        cur_line = line_str

    return state

def process(out,func,tokens,state):
    res_str,new_state = func(tokens,state)
    out.write(res_str)
    return new_state

if __name__=="__main__":
    import cStringIO
    import os
    
    def testall():
        folder = r"c:\Python25\Lib"
        for fname in [ f for f in os.listdir(folder) if f.endswith(".py") ]:
            print fname,
            obj = cStringIO.StringIO(open(os.path.join(folder,fname)).read())

            out = cStringIO.StringIO()
            transform(obj,out)
            if not out.getvalue().strip()==obj.getvalue().strip():
                res = open("copypy.py","w")
                res.write(out.getvalue())
                res.close()
                inlines = obj.getvalue().strip().split('\n')
                outlines = out.getvalue().strip().split('\n')
                nb = 0
                for inline,outline in zip(inlines,outlines):
                    if not inline==outline:
                        nb += 1
                print nb,"erreurs"
                break
            else:
                print

    def testone():
        obj = cStringIO.StringIO(open("copytest.py").read())
        out = cStringIO.StringIO()

        def trans_print(tokens,state):
            # tranform "print something" into "print(something)"
            token_type,token_string,(srow,scol),(erow,ecol),line_str = tokens
            typ = token.tok_name[token_type]
            if typ == "NAME" and token_string=="print":
                return token_string+"(",True
            elif typ == "NEWLINE" and state is True:
                return ")"+token_string,False
            elif typ == "OP" and token_string == ";":
                return ")"+token_string,False
            else:
                return token_string,state

        transform(obj,out,func=trans_print,debug=True)
        res = open("copypy.py","w")
        res.write(out.getvalue())
        res.close()

        inlines = obj.getvalue().strip().split('\n')
        outlines = out.getvalue().strip().split('\n')
        nb = 0
        for inline,outline in zip(inlines,outlines):
            if not inline==outline:
                nb += 1
        print nb,"erreurs"

    testall()
    