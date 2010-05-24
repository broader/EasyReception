import cStringIO
import transform_script
import python_code

class State:

    def __init__(self):
        self.functions = []
        self.next_is_func = False # if True, next token is a function name
        self.in_print = False # True if token is inside a print statement

def translate_func(tokens,state):
    if state is None:
        state = State()
    token_type,token_string,(srow,scol),(erow,ecol),line_str = tokens
    typ = transform_script.token.tok_name[token_type]
    res = token_string
    print typ,token_string,state.in_print
    if typ == "NAME":
        if state.next_is_func:
            if not token_string.startswith("_"):
                state.functions.append(token_string)
            state.next_is_func = False
        elif token_string=="print":
            state.in_print = True
            res = "PRINT("
        elif token_string == "def" and scol==0:
            state.next_is_func = True
    elif state.in_print and ((typ == "OP" and token_string == ";") or \
        (typ in ["NEWLINE","ENDMARKER","COMMENT"])):
            res = ")"+token_string
            state.in_print = False
    
    return res,state

name = "../webapps/demo/tour/hello.hip"

src,line_mapping = python_code.get_py_code(name)
src = cStringIO.StringIO(src)

src = open("../webapps/demo/tour/hello.hip")

py_code = cStringIO.StringIO()


# transform Python script and get function names
result = transform_script.transform(src,py_code,debug=True) #,translate_func)
#functions = result.functions
print py_code.getvalue()
