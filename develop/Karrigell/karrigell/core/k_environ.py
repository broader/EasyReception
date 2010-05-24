# set environment for scripts
# copied from CGIHTTPServer
import socket

def make_environ(handler,script):
    env = {}
    env['SERVER_SOFTWARE'] = handler.version_string()
    host = handler.server.host
    env['SERVER_NAME'] = socket.getfqdn(host)
    env['SERVER_PORT'] = str(handler.server.port)
    env['GATEWAY_INTERFACE'] = 'CGI/1.1'
    env['SERVER_PROTOCOL'] = handler.protocol
    env['REQUEST_METHOD'] = handler.method
    env['PATH_INFO'] = script.script_url
    env['PATH_TRANSLATED'] = script.name
    env['SCRIPT_NAME'] = script.script_url
    query = script.query
    if query:
        env['QUERY_STRING'] = query
    host = handler.headers.get('host',None)
    if host != handler.client_address[0]:
        env['REMOTE_HOST'] = host
    env['REMOTE_ADDR'] = handler.client_address[0]
    authorization = handler.headers.get("authorization",None)
    if authorization:
        authorization = authorization.split()
        if len(authorization) == 2:
            import base64, binascii
            env['AUTH_TYPE'] = authorization[0]
            if authorization[0].lower() == "basic":
                try:
                    authorization = base64.decodestring(authorization[1])
                except binascii.Error:
                    pass
                else:
                    authorization = authorization.split(':')
                    if len(authorization) == 2:
                        env['REMOTE_USER'] = authorization[0]
    # XXX REMOTE_IDENT
    env['CONTENT_TYPE'] = handler.headers.get('content_type','text.html')
    
    length = handler.headers.get('content-length',None)
    if length:
        env['CONTENT_LENGTH'] = length
    accept = []
    if handler.headers.get_all('accept'):
        for line in handler.headers.get_all('accept'):
            if line[:1] in "\t\n\r ":
                accept.append(line.strip())
            else:
                accept = accept + line[7:].split(',')
        env['HTTP_ACCEPT'] = ','.join(accept)
    else:
        env['HTTP_ACCEPT'] = ""
    ua = handler.headers.get('user-agent',None)
    if ua:
        env['HTTP_USER_AGENT'] = ua
    co = handler.headers.get_all('cookie')
    if co:
        env['HTTP_COOKIE'] = ', '.join(co)
    # XXX Other HTTP_* headers
    # Since we're setting the env in the parent, provide empty
    # values to override previously set values
    for k in ('QUERY_STRING', 'REMOTE_HOST', 'CONTENT_LENGTH',
              'HTTP_USER_AGENT', 'HTTP_COOKIE'):
        env.setdefault(k, "")

    return env
    