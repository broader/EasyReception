"""URL resolution of a path

result = target(handler,url)

The url is split into its different elements by urlparse. The ones used
are the path and the query string

The path is made of elements (separated by /). If path is limited to a
single forward slash, the resulting path name is the document root
directory (defined in config scripts), and method dirlist() of the result
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
  in Target.index_names (typically index.html, index.py etc.) in this
  directory. If one is found, result has the same values as in (1) ; if
  none is found, the result is the directory itself ; if more than one is
  found, Duplicate exception is raised
3 - if it doesn't match a folder or a directory, and current element doesn't
have an extension (such as .txt, .html etc.), the program searches files with
the element name + one of the extensions provided in
Target.managed_extensions. If one is found, the result is the same as in
(1) ; if none is found, NotFound is raised ; if more than one is found,
Duplicate is raised

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

If index.html and index.py exist in foo,
    /foo/ ==> Duplicate is raised
    /foo/index.htm ==> result.name = (root)/foo/index.htm
"""

import sys
import os
import cStringIO
import tokenize
import traceback
import imp
import cPickle
import threading

import urlparse
import urllib
import cgi

import transform_script
import python_code

import re

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
        self.cwd_i = os.path.dirname(url)

        # parse url into its elements
        elements = urlparse.urlparse(url)
        scheme,netloc,path,params,query,fragment = elements
        path = urllib.unquote_plus(path)
        self.path_without_qs = urlparse.urlunparse((scheme,netloc,path,params,
            "",""))
        self.query = query

        # get name and args or raise exception
        self.args = self.subpath = []
        if not path:
            raise NotFound,'Bad path %s' %path

        self.name = handler.config.root_dir
        
        path_elts = path.split('/')
        if not path_elts or not path_elts[0]=='':
            raise NotFound,'Bad path %s' %path

        # remove leading ''
        used_path_elts = [path_elts.pop(0)]

        # alias ?
        for alias in handler.config.alias:
            mo = re.match('^/(%s)' %alias,path)
            if mo:
                self.name = handler.config.alias[alias]
                for i in range(len(mo.groups()[0].split('/'))):
                    used_path_elts.append(path_elts.pop(0))
                break
                        
        while True:
            if not path_elts:
                # all path elements consumed and name exists
                if os.path.isdir(self.name):
                    if not self.has_index():
                        return
                    self.name = os.path.join(self.name,self.ix_name)
                    if self.ext == '.ks':
                        redir = '/'.join(used_path_elts)
                        if not redir.endswith('/'):
                            redir += '/'
                        redir += 'index/'
                        new_elts = scheme,netloc,redir,params,query,fragment
                        raise Redir,urlparse.urlunparse(new_elts)
                    elif not path.endswith('/'):
                        new_elts = scheme,netloc,path+'/',params,query,fragment
                        raise Redir,urlparse.urlunparse(new_elts)
                self.ext = os.path.splitext(self.name)[1]
                self.baseurl = "/".join(used_path_elts[:-1])
                self.script_url = "/".join(used_path_elts)
                self.basename = os.path.basename(self.name)
                return

            elt = path_elts.pop(0)
            used_path_elts.append(elt)
            
            if self.search(self.name,elt):
                if os.path.isfile(self.name):
                    if self.ext == '.ks' and not path_elts:
                        # ks scripts urls must end with at least '/'
                        new_elts = scheme,netloc,path+'/',params,query,fragment
                        raise Redir,urlparse.urlunparse(new_elts)
                        
                    self.args = path_elts
                    self.baseurl = "/".join(used_path_elts[:-1])
                    self.script_url = "/".join(used_path_elts)
                    self.basename = os.path.basename(self.name)
                    return
            else:
                raise NotFound,url

    def has_index(self):
        self.ext = None
        found = []
        for index_name in self.index_names:
            name = os.path.join(self.name,index_name)
            if os.path.exists(name):
                found.append(name)
        if not found:
            return False
        elif len(found) > 1:
            raise Duplicate,"More than one index file in folder %s : %s" \
                %(os.path.dirname(self.name),found)
        else:
            self.ix_name = found[0]
            self.ext = os.path.splitext(self.ix_name)[1]
            return True

    def search(self,dir_name,name):
        if os.path.exists(os.path.join(dir_name,name)):
            self.name = os.path.join(dir_name,name)
            self.ext = os.path.splitext(name)[1]
            return True
        else:
            found = []
            for _ext in self.handler.managed_extensions:
                fname = os.path.join(dir_name,name+_ext)
                if os.path.exists(fname):
                    found.append(fname)
            if not found:
                return False
            elif len(found) > 1:
                raise Duplicate,"Files %s match url %s" %(found,
                    os.path.join(dir_name,name))
            else:
                self.name = os.path.join(self.name,found[0])
                self.ext = os.path.splitext(found[0])[1]
                return True

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

    def parse_script(self):
        """Parse a Python script : find the functions defined
        at module level, transform print to PRINT()"""

        # get Python code from source file
        cached = False
        if self.handler.config.cache_dir is not None:
            elts = self.baseurl.split('/')
            cache_dir_name = os.path.join(self.handler.config.cache_dir, 
                *elts)
            cache_file_name = os.path.join(cache_dir_name, 
                os.path.basename(self.name))
            if os.path.exists(cache_dir_name):
                if os.path.exists(cache_file_name):
                    source_mod_time = os.path.getmtime(self.name)
                    cache_mod_time = os.path.getmtime(cache_file_name)
                    if cache_mod_time > source_mod_time:
                        try:
                            cached = True
                            cache_file_obj = open(cache_file_name, "r")
                            src = cache_file_obj.read()
                            funcs,self.py_code = src.split("\n",1)
                            self.functions = eval(funcs)
                            cache_file_obj.close()
                        except:
                            cached = False
                            pass
            else:
                try:
                    os.makedirs(cache_dir_name)
                except: # eg if write mode not set for the folder
                    import traceback
                    traceback.print_exc(file=sys.stderr)

        if not cached:
            src,self.line_mapping = python_code.get_py_code(self.name, 
                self.handler.config.output_encoding)
            src = cStringIO.StringIO(src)
            py_code = cStringIO.StringIO()

            # transform Python script and get function names
            result = transform_script.transform(src,py_code,translate_func)
            self.functions = result.functions
            self.py_code = py_code.getvalue()+"\n"
            # cache: write
            try:
                cache_file_obj = open(cache_file_name, "w")
                cache_file_obj.write(str(self.functions)+"\n")
                cache_file_obj.write(self.py_code)
                cache_file_obj.close()
            except:
                pass

    def data_namespace(self):
        # build namespace from post data or query string
        data = cgi.parse_qs(self.query,1)
        if self.handler.method == "POST":
            post_data = self.handler.get_post_data()
            data.update(post_data)

        norm_data = {}
        for key in data:
            if not isinstance(data[key],list): # file
                norm_data[key] = data[key]
            elif key.endswith('[]'):
                norm_data[key[:-2]] = data[key]
            else:
                norm_data[key] = data[key][0]

        ns = {"QUERY":norm_data}

        for key,val in ns["QUERY"].iteritems():
            ns["_"+key] = ns["QUERY"][key]

        ns["REQUEST"] = ns["QUERY"]
        # values that can be updated in scripts
        for key in "RESPONSE","SET_COOKIE":
            ns[key] = self.handler.ns[key]
        return ns

    def function_namespace(self):
        """Create namespace for script-specific functions"""
        # if extension is .py, .hip or .ks, import HTMLTags names
        namespace = {}

        namespace.update({"Include":self.include,
            "Import":self._import,
            "Login":self.login,
            "Logout":self.logout,
            "_":self.translation,
            "SET_UNICODE_OUT":self._set_unicode_out,
            })

        # customize built-in functions open() and file()
        # to allow relative paths to script folder
        self.cwd = os.path.dirname(self.name)
        namespace.update({"open":self._open,
            "file":self._open,
            "CWD":self.cwd,
            "REL":self._rel,
            "REL_I":self.rel_i})
            
        # Add extensions to the namespace
        for name, module in self.handler.config.ext_modules.items():
            namespace[name] = module.action(self)

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
            function = self.args.pop(0) or 'index'
            if function in self.functions:
                # if function exists, it is in the local namespace
                # after the execfile() above
                func = namespace[function]
                # run this function with form fields
                form_fields = namespace["REQUEST"]
                result = func(**form_fields)
                if result is not None:
                    self.handler._print(result)
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

    def url_to_file(self,other_url):
        return Target(self.handler,other_url)

    def include(self,url,**args):
        """Include the file or script matching specified url"""
        abs_url = urlparse.urljoin(self.script_url,url)
        try:
            other_target = self.url_to_file(abs_url)
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
            module = self.url_to_file(abs_url)
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
                  "_":self.translation,
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

    def _set_unicode_out(self,encoding):
        self.handler.output_encoding = encoding
        threading.currentThread().output_encoding = encoding

    def translation(self,src):
        import k_translation
        trans = k_translation.Translation(self.handler.config)
        # return the translation, utf-8 encoded
        tr = trans.translation(src,self.handler.headers)
        if tr is None:
            return src # encoding is unknown, don't try to change it !
        encoding = self.handler.output_encoding
        if encoding is None:
            return tr    
        else:
            # change encoding
            return unicode(tr,'utf-8').encode(encoding)

    def login(self,script="/admin/login.ks/login",role=[],
        valid_in=None,redir_to="",add_user=False):
        """If user is not logged, redirect to the login script"""
        if self.is_logged():
            if not role:
                return self.handler.COOKIE["login"].value# user logged, all roles accepted
            if self.handler.COOKIE["role"].value in role:
                return self.handler.COOKIE["login"].value# user logged with one of the specified roles
        # user not logged or not with the good role
        # validity defaults to the script directory
        valid_in = valid_in or self.baseurl
        # redirection defaults to the calling url (including parameters)
        redir_to = urllib.quote_plus(redir_to) or urllib.quote_plus(self.url)
        args = "%s?valid_in=%s&redir_to=%s&role=%s" \
                %(script,valid_in,redir_to,",".join(role))
        if add_user:
            args += "&add_user=%s" %add_user
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
