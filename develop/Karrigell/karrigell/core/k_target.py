"""URL resolution of a path

result = target(handler,url,post_data)

The url is split into its different elements by urlparse. The ones used
are the path and the query string

If form_data is provided it is used to create the attribute ns (namespace)
using cgi.parse_qs ; else, the query string is used

The path is made of elements (separated by /). If path is limited to a
single forward slash, the resulting path name is the document root
directory (defined in k_config), and method dirlist() of the result 
returns a listing of the directory content

If path has at least one element, resulting path is set to the root
directory, and the program evaluates if the first element matches the
name of a file or of a subdirectory :
1 - if it matches a file, match is successful ; result.name is the full
name of the file in the file system, result.args is the list of all
remaining elements
2 - if it matches a directory :
  . if there are other elements, evaluation continues with the next
    element
  . else, the program searches for a file with one of the names provided 
  in handler.index_names (typically index.html, index.py etc.) in this
  directory. If one is found, result has the same values as in (1) ; if 
  none is found, the result is the directory itself ; if more than one is 
  found, Duplicate is raised
3 - if it doesn't match a folder or a directory, and current element doesn't
have an extension (such as .txt, .html etc.), the program searches files with
the element name + one of the extensions provided in 
handler.managed_extensions. If one is found, the result is the same as in
(1) ; if none is found, NotFound is raised ; if more than one is found, 
Duplicate is raised

Methods is_file() and is_dir() indicate if the result is a file or a 
directory. If it's a directory, method dirlist() returns the directory content

For instance, supposing folder foo exists, file bar.txt exists in foo and
file baz doesn't exists in foo :

    /foo/bar.txt/arg1/arg2 ==> args = ["arg1","arg2"]
    /foo/baz/arg1 ==> NotFound exception

If baz.py exists and ".py" is in handler.managed_extensions :
    /foo/baz/arg1 ==> result.name = (root)/foo/baz.py
                     result.args = ["arg1"]

If handler.index_names = ["index.htm","index.html","index.py"] and there is
no file with these names in foo, 
    /foo/ ==> result.name = (root)/foo

If index.htm exists in foo, 
    /foo/ ==> result.name = (root)/foo/index.htm

I index.html and index.py exist in foo,
    /foo/ ==> Duplicate is raised
    /foo/index.htm ==> result.name = (root)/foo/index.htm
"""

import sys
import os
import cStringIO
import tokenize
import traceback
import imp

import urlparse
import urllib
import cgi

#import k_config
import transform_script
import python_code

class NotFound(Exception):
    pass

class Duplicate(Exception):
    pass

class Redir(Exception):
    pass

class NoFunction(Exception):
    pass

class RecursionError(Exception):
    pass

class ParseError(Exception):
    pass

class K_ImportError(Exception):
    pass

# class and function used by module transform_script to parse Python scripts
# changes print into print() and returns a list of module-level functions

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

def _log(*args):
    sys.stderr.write("\n".join([str(arg) for arg in args])+"\n")

class Target:

    script_extensions = ".py",".ks",".pih",".hip"
    index_names = ("index.html","index.htm","index.py","index.ks","index.pih",
        "index.hip")

    def __init__(self,handler,url):

        self.handler = handler
        self.url = url
        self.current = self
        self.data_encoding = None
        self.cwd_i = os.path.dirname(url)

        # parse url into its elements
        self.elements = urlparse.urlparse(url)
        scheme,netloc,path,params,query,fragment = self.elements
        self.path_without_qs = urlparse.urlunparse((scheme,netloc,path,params,
            "",""))
        self.query = query

        # get name and args or raise exception
        self.name = self.handler.config.root_dir
        self.args = self.subpath = []
        if not path:
            return
        path_elts = path.split('/')

        used_path_elts = []
        while True:
            if not path_elts:
                break
            elt = path_elts.pop(0)
            # if this is the first element, check if it's an alias
            if elt and (not used_path_elts or not used_path_elts[0]):
                if elt in self.handler.config.alias:
                    name = self.handler.config.alias[elt]
                else:
                    name = os.path.join(self.name,elt)
            else:
                name = os.path.join(self.name,elt)
            
            used_path_elts.append(elt)
            if not os.path.exists(name):
                ext = os.path.splitext(elt)[1]
                if ext:
                    if os.path.exists(name):
                        self.name = name
                    else:
                        raise NotFound,url
                else:
                    found = 0
                    for _ext in handler.managed_extensions:
                        name = os.path.join(self.name,elt+_ext)
                        if os.path.exists(name):
                            found_name = name
                            found_ext = _ext
                            found += 1
                    if not found:
                        if self.is_dir():
                            raise NotFound,url
                        else:
                            self.args = self.subpath = [elt]+path_elts
                            used_path_elts.pop()
                            break # stop search here
                    elif found > 1:
                        raise Duplicate,"%s files match url %s" %(found,
                            os.path.join(self.name,elt))
                    else:
                        self.name = found_name
                        self.ext = found_ext
            else:
                self.name = name
        self.used_path_elts = used_path_elts
        if self.is_dir():
            found = []
            dir_name = self.name
            for index_name in self.index_names:
                name = os.path.join(dir_name,index_name)
                if os.path.exists(name):
                    self.name = name
                    self.ext = os.path.splitext(self.name)[1]
                    if not self.handler.config.show_script_extensions \
                        and self.ext in self.handler.managed_extensions:
                        # hide extension of managed file
                        self.name = os.path.splitext(self.name)[0]
                        index_name = os.path.splitext(index_name)[0]
                    found.append(name)
                    ix_name = index_name
            if len(found) > 1:
                raise Duplicate,"More than one index file in folder %s : %s" \
                    %(os.path.dirname(self.name),found)
            elif len(found) == 1:
                new_path = "/".join(self.used_path_elts)
                while new_path.startswith('//'):
                    new_path = new_path[1:]
                if new_path.endswith('/'):
                    new_path += ix_name
                else:
                    new_path += "/%s" %ix_name
                new_elements = list(self.elements)
                new_elements[2] = new_path
                new_url = urlparse.urlunparse(new_elements)
                raise Redir,new_url
        else:
            self.ext = os.path.splitext(self.name)[1]
            self.baseurl = "/".join(self.used_path_elts[:-1])
            self.script_url = "/".join(self.used_path_elts)
            self.basename = os.path.basename(self.name)
            
    def is_dir(self):
        return os.path.isdir(self.name)

    def is_file(self):
        return os.path.isfile(self.name)

    def is_cgi(self):
        """indicate if target is a cgi script"""
        if not self.ext in [".py",".cgi"]:
            return False
        if not self.handler.config.cgi_dir:
            return False
        cgi_elts = self.handler.config.cgi_dir.split(os.sep)
        return self.name.split(os.sep)[:len(cgi_elts)] == cgi_elts

    def is_script(self):
        """determine if target is a script to execute or a file to read"""
        return self.ext in self.script_extensions
        
    def dirlist(self):
        import k_utils
        return k_utils.dirlist(self.name,self.url)

    def parse_script(self):
        """Parse a Python script : find the functions defined
        at module level, transform print to PRINT()"""

        # get Python code from source file
        src,self.line_mapping = python_code.get_py_code(self.name,
            self.handler.config.output_encoding)
        src = cStringIO.StringIO(src)
        py_code = cStringIO.StringIO()

        # transform Python script and get function names
        result = transform_script.transform(src,py_code,translate_func)
        self.functions = result.functions
        self.py_code = py_code.getvalue()+"\n"
                
        # in case a .ks script has an index() function and this function is 
        # not explicit in the path, rebuild the complete url and raise an
        # exception to trigger redirection
        if "index" in self.functions and not self.args \
            and self.ext.lower()==".ks":
            new_path = "/".join(self.used_path_elts) + "/index"
            new_elements = list(self.elements)
            new_elements[2] = new_path
            new_url = urlparse.urlunparse(new_elements)
            raise Redir,new_url

    def data_namespace(self):
        # build namespace from post data or query string
        if self.handler.method == "POST":
            data = self.handler.get_post_data()
        else:
            data = cgi.parse_qs(self.query,1)

        norm_data = {}
        for key in data:
            if not isinstance(data[key],list): # file
                norm_data[key] = data[key]
            elif key.endswith('[]'):
                norm_data[key[:-2]] = data[key]
            else:
                norm_data[key] = data[key][0]

        ns = {"QUERY":norm_data}

        # tranform to unicode if charsets is set
        if self.handler.charsets:
            # if user agent sent an accept-charset tag, use it
            for charset in self.handler.charsets:
                res = {}
                flag = True
                try:
                    for key in ns["QUERY"]:
                        res[key] = unicode(ns["QUERY"][key],charset)
                except:
                    flag = False
                    continue
                self.data_encoding = charset
                ns["QUERY"] = res
                break

        for key,val in ns["QUERY"].iteritems():
            ns["_"+key] = ns["QUERY"][key]

        ns["REQUEST"] = ns["QUERY"]
        # values that can be updated in scripts
        for key in "RESPONSE","SET_COOKIE":
            ns[key] = self.handler.ns[key]
        return ns

    def function_namespace(self):
        """Create namespace for script-specific functions"""
        namespace = {"Include":self.include,
            "Login":self.login,
            "Logout":self.logout }
        
        # customize built-in functions open() and file()
        # to allow relative paths to script folder
        self.cwd = os.path.dirname(self.name)
        namespace.update({"open":self._open, 
            "file":self._open,
            "Import":self._import,
            "CWD":self.cwd,
            "REL":self._rel,
            "REL_I":self.rel_i})

        return namespace
    
    def run(self,namespace={},included=False):
        """Run the script in specified namespace"""
        
        if not included:
            namespace.update(self.data_namespace())
            namespace.update(self.function_namespace())
            namespace["THIS"] = self
            import compat2_3
            compat2_3.set_old(self)
            namespace.update(compat2_3.add_ns(self))
        self.namespace = namespace

        # add name of global modules to namespace
        for module,obj in self.handler.config.global_modules.iteritems():
            namespace[module] = obj[0]

        # execute Python code in namespace
        exec (self.py_code,namespace)
            
        if self.args and self.ext.lower() == ".ks":
            function = self.args.pop(0)
            if function in self.functions:
                # if function exists, it is in the local namespace
                # after the execfile() above
                func = namespace[function]
                # run this function with form fields
                form_fields = namespace["REQUEST"]
                func(**form_fields)
            else:
                raise NoFunction,function
        self.ns = namespace

    def rel(self,*url):
        return '../' * len(self.args) + '/'.join(url)

    def _rel(self,*path):
        """Convert a relative path to the absolute path based on current
        script folder"""
        return os.path.join(self.cwd,*path)
                        
    def rel_i(self,*path):
        """Convert a relative path to the absolute path based on current
        included script folder"""
        return os.path.join(self.cwd_i,*path).replace('\\', '/')
                
    def _open(self,filename,mode="r",bufsize=-1):
        """Replacement for the built-in function open() or file()
        If the filename is a relative path, replace it with the
        absolute path using the script folder"""
        import __builtin__
        path = filename
        if not os.path.isabs(filename):
            path = os.path.join(self.cwd,filename)
        return __builtin__.open(path,mode,bufsize)

    def include(self,url,**args):
        """Include the file or script matching specified url"""
        abs_url = urlparse.urljoin(self.script_url,url)
        try:
            other_target = Target(self.handler,abs_url)
        except NotFound,msg:
            raise IOError,msg
        except Duplicate,msg:
            raise IOError,msg
        other_target.parent = self
        # detect recursion errors
        tg = other_target
        while True:
            if hasattr(tg,"parent"):
                if tg.parent.name == other_target.name:
                    raise RecursionError,url+" includes itself"
                tg = tg.parent
            else:
                break
        if other_target.is_script():
            # execute included script in namespace
            other_target.parse_script()
            namespace = self.namespace
            namespace.update(args)
            rel_i = namespace["REL_I"]
            namespace["REL_I"] = other_target.rel_i
            self.handler.target = other_target
            other_target.run(namespace,included = True)
            self.handler.target = self
            namespace["REL_I"] = rel_i
        else:
            # print content of included static document
            self.handler.output.write(open(other_target.name).read())

    def _import(self,url,**kw):
        """Replaces import for user-defined modules, searching them by url"""
        abs_url = urlparse.urljoin(self.script_url,url)
        try:
            module = Target(self.handler,abs_url)
        except NotFound,msg:
            raise ImportError,msg
        except Duplicate,msg:
            raise ImportError,msg
        module.parent = self
        if module.ext.lower() == ".py":
            module.parse_script()
            # imported modules must be able to print, so we have to run
            # them in a namespace with some functions
            ns = {"PRINT":self.handler._print,
                  "CONFIG":self.handler.config,
                  "_":self.handler.translation,
                  "Import":self._import}
            ns.update(kw)
            ns["__file__"] = module.name
            try:
                module.run(ns,included=True)
            except:
                tb = cStringIO.StringIO()
                traceback.print_exc(file=tb)
                raise K_ImportError,(module,url,sys.exc_info())
            for key in module.ns:
                setattr(module,key,module.ns[key])
            return module
        else:
            raise ImportError,"%s doesn't match a Python module" %url

    def login(self,script="/admin/login.ks/login",role=[],
        valid_in=None,redir_to="",add_user=False):
        """If user is not logged, redirect to the login script"""
        if self.is_logged():
            if not role:
                return # user logged, all roles accepted
            if self.handler.COOKIE["role"].value in role:
                return # user logged with one of the specified roles
        # user not logged or not with the good role
        # validity defaults to the script directory
        valid_in = valid_in or self.baseurl
        # redirection defaults to the calling url (including parameters)
        redir_to = urllib.quote_plus(redir_to) or urllib.quote_plus(self.url)
        args = "%s?valid_in=%s&redir_to=%s&role=%s&add_user=%s" \
                %(script,valid_in,redir_to,",".join(role),int(add_user))
        raise Redir,args

    def logout(self,script="/admin/login.ks/logout",valid_in=None,
        redir_to=None):
        valid_in = valid_in or self.baseurl
        redir_to = redir_to or self.script_url
        args = "%s?valid_in=%s&redir_to=%s" %(script,valid_in,redir_to)
        raise Redir,args

    def is_logged(self):
        """check if user is authenticated"""
        import k_users_db
        return k_users_db.is_logged(self.handler)
