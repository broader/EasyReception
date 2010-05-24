def expire_format(dtime):
    """Convert datetime.datetime instance to cookie expires format"""
    import email.Utils
    import time
    import datetime
    return email.Utils(time.mktime(dtime.timetuple()))

def is_default_host(host):
    """Test if host is the default host"""
    import socket
    hostname = socket.gethostname()
    def_names = [None,'localhost','127.0.0.1',hostname.lower()]
    for name in socket.gethostbyname_ex(hostname):
        if name:
            if type(name) is type([]):
                def_names.append(name[0])
            else:
                def_names.append(name)
    if host is not None:
        host = host.split(':')[0]
    return host in def_names

def dirlist(dir_path,url):
    import os
    import urlparse
    from urllib import pathname2url,url2pathname
    if not url.endswith("/"):
        url += "/"
    names = os.listdir(dir_path)
    dirs = [ name for name in names
        if os.path.isdir(os.path.join(dir_path,name)) ]
    files = [ name for name in names 
        if os.path.isfile(os.path.join(dir_path,name)) ]
    
    dirs.sort(lambda x,y:cmp(x.lower(),y.lower()))
    files.sort(lambda x,y:cmp(x.lower(),y.lower()))
    
    head = """<head>
    <title>Directory listing</title>
    <link rel="stylesheet" href="/karrigell.css">
    </head>"""
    body = "<H1>Contents of %s</H1>" %url
    body += '<span class="cadre">-</span>'
    body += '<A href="../">parent directory</A>'
    for d in dirs:
        #body += '<BR>+<A href="%s">%s</A>\n' %(urlparse.urljoin(url,pathname2url(d)),d)
        body += '<BR><SPAN class="cadre">+</span>'
        body += '<A href="%s/">%s</A>\n' \
            %(urlparse.urljoin(url,pathname2url(d)),d) 

    for f in files:
        body += '<BR>&nbsp;<A href="%s">%s</A>\n' \
            %(urlparse.urljoin(url,pathname2url(f)),f)

    
    return '<html>%s <body>%s</body></html>' %(head,body)