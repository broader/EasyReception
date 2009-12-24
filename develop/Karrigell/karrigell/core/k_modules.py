from k_config import modules

def run(handler,hook):
    if hook in modules:
        for module in modules[hook]:
            exec("import modules.%s as %s" %(module,module))
            eval("%s.main(handler)" %module)
                