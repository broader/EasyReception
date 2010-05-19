SET_UNICODE_OUT('utf-8')
table = Import("portalDb",REL=REL).table

# since form page uses iso-8859-1, we must convert login to utf-8
_login = unicode(_login,'iso-8859-1').encode('utf-8')

if not _password==_password2:
    Include("header.hip")
    print "<center><p>%s" %_("You must enter the same password twice")
    raise SCRIPT_END

so=Session()

if len([ user for user in table['users'] if user["login"]==_login]):
    Include("header.hip")
    print "<center><p>%s <b>%s</b>"  %(_(" Login"),_login)
    print _("is already used, please choose another one")
    raise SCRIPT_END

try:
    import hashlib
    pw_hash = hashlib.sha1(_password).hexdigest()
except ImportError:
    import sha # deprecated in Python 2.5
    pw_hash = sha.new(_password).hexdigest()
recno = table['users'].insert(_login,pw_hash,"#AAA866","times")
table['users'].commit()

so.user=recno
so.login=_login

raise HTTP_REDIRECTION,"index.pih"
    