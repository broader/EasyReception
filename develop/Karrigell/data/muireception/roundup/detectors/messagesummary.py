#$Id: messagesummary.py,v 1.2 2007-04-03 06:47:21 a1s Exp $

from roundup.mailgw import parseContent

def summarygenerator(db, cl, nodeid, newvalues):
    ''' If the message doesn't have a summary, make one for it.
    '''
    if newvalues.has_key('summary') or not newvalues.has_key('content'):
        return

    summary, content = parseContent(newvalues['content'], config=db.config)
    newvalues['summary'] = summary


def init(db):
    # fire before changes are made
    db.msg.audit('create', summarygenerator)

# vim: set filetype=python ts=4 sw=4 et si
#SHA: 51433442433794dd7d80d65557aa21d59403d95a
