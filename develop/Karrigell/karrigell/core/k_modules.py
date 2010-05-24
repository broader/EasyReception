"""Modules management

Modules are used at specified "steps" in request processing. These steps
are defined in HTTP.py by "hooks" placed in the code, for instance
    self.hook("host_filter")
    self.hook("static_files")

For each hook, seek if the argument is one of the keys of the dictionary
modules in server_config.py

If so, for each script in modules[hook], import the script with this name
from directory package/modules, then execute its main() method, applied
to the instance of HTTP.HTTP
"""

from k_config import modules

def run(handler,hook):
    if hook in modules:
        for module in modules[hook]:
            try:
                exec("import modules.%s as %s" %(module,module))
            except: # silently ignore import errors
                pass
            eval("%s.main(handler)" %module)
