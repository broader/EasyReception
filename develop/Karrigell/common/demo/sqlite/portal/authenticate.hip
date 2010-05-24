# authentication script
SET_UNICODE_OUT('utf-8')

# convert _login to utf-8 (form page uses iso-8859-1)
_login = unicode(_login,'iso-8859-1').encode('utf-8')

def displayAuthentError(message):
    Include("header.hip")
    "<center><p><b>%s : %s</b>" %(_("Authentication error"),message)
    raise SCRIPT_END

so=Session()
table = Import("portalDb",REL=REL).table

users = table['users'](login=_login)
if not len(users):
    displayAuthentError(_("unknown user"))
else:
    user = users[0]

try:
    import hashlib
    pw_hash = hashlib.sha1(_password).hexdigest()
except ImportError:
    import sha # deprecated in Python 2.5
    pw_hash = sha.new(_password).hexdigest()
    
if pw_hash==user["password"]:
    so.user=user["__id__"]
    so.login=user["login"]
    raise HTTP_REDIRECTION,"index.pih"
else:
    displayAuthentError(_("incorrect password"))
