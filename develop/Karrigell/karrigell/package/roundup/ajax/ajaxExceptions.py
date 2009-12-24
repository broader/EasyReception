#$Id$
'''Exceptions for use in Roundup's web interface.
'''

__docformat__ = 'restructuredtext'

#import cgi

class ClientNoResult(Exception):
    #return "It's Client.inner_main()'s end, there's no result."
    pass

class HTTPException(Exception):
    pass

class LoginError(Exception):
    pass

class Unauthorised(Exception):
    pass

class Redirect(HTTPException):
    pass

class NotFound(Exception):
    pass

class NotModified(Exception):
    pass

class FormError(ValueError):
    """An 'expected' exception occurred during form parsing.

    That is, something we know can go wrong, and don't want to alarm the user
    with.

    We trap this at the user interface level and feed back a nice error to the
    user.

    """
    pass

class SendFile(Exception):
    """Send a file from the database."""

class SendStaticFile(Exception):
    """Send a static file from the instance html directory."""

class SeriousError(Exception):
    """Raised when we can't reasonably display an error message on a
    templated page.

    The exception value will be displayed in the error page, HTML
    escaped.
    """
    def __str__(self):
        return 'Roundup issue tracker: An error has occurred'


# vim: set filetype=python sts=4 sw=4 et si :
