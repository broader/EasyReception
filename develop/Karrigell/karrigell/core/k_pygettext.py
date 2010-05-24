import transform_script
import token
import cStringIO
import os

class detector:

    def __init__(self):
        self.strings = []
        self.found = False

def get_trans(tokens,state):
    if state is None:
        state = detector()
    token_type,token_string,(srow,scol),(erow,ecol),line_str = tokens
    typ = token.tok_name[token_type]
    if not state.found and typ == "NAME" and token_string == "_":
        state.found = True
    elif state.found is True and typ == "OP" and token_string == "(":
        state.found = "ready"
    elif state.found == "ready":
        if typ == "STRING":
            _string = eval(token_string)
            if not _string in state.strings:
                state.strings.append(_string)
        state.found = False
    return "",state

def get_strings(file_name):
    import python_code
    src = cStringIO.StringIO(python_code.get_py_code(file_name)[0])
    src.seek(0)
    res = transform_script.transform(src,
        out = cStringIO.StringIO(), func=get_trans)
    return res.strings

if __name__ == "__main__":
    print get_strings("../webapps/index.pih")