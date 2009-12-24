import cStringIO
import shutil

# Python may not have gzip support
gzip_support = False
try:
    import gzip
    gzip_support = True
except ImportError:
    print "Warning - gzip is not supported"
    pass

def test_gzip(handler,config):
    """Test if content should be gzipped"""
    if not config.gzip:
        return False
    if not gzip_support:
        return False
    accept_encoding = handler.headers.get('accept-encoding','').split(',')
    accept_encoding = [ x.strip() for x in accept_encoding ]
    ctype = handler.resp_headers["Content-type"]
    # if gzip is supported by the user agent,
    # and if the option gzip in the configuration file is set, 
    # and content type is text/ or javascript, 
    # set Content-Encoding to 'gzip' and return True
    if 'gzip' in accept_encoding and \
        ctype and (ctype.startswith('text/') or 
        ctype=='application/x-javascript'):
        return True
    return False

buf_size = 2<<16

def do_gzip(fileobj):
    """gzip data and return a StringIO holding the gzipped data"""
    sio = cStringIO.StringIO()
    gzf = gzip.GzipFile(fileobj = sio, mode = "wb")
    while True:
        data = fileobj.read(buf_size)
        if not data:
            break
        gzf.write(data)
    gzf.close()
    return sio
