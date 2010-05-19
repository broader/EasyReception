"""Hook for static files management

The default implentation does nothing

Example of a function that restricts access to image files
to authenticated users :

def main(handler):
    ext = handler.target.ext
    role = handler.get_log_level()
    if ext in ['.png','.gif','.jpg'] and not role in ['admin','visit','edit']:
        raise handler.ns['SCRIPT_END'],"restricted access"
    return        
"""

def main(handler):
    return