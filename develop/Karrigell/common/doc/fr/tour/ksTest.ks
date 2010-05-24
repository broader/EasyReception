so = Session()
if not hasattr(so, 'x'):
    so.x = 0

def index():
    print "x = %s" %so.x
    print '<br><a href="increment">Incrémenter</a>'
    print '<br><a href="decrement">Décrémenter</a>'
    print '<br><a href="reset">Remise à zéro</a>'
    
def increment():
    so.x += 1
    raise HTTP_REDIRECTION,"index"

def decrement():
    so.x -= 1
    raise HTTP_REDIRECTION,"index"

def reset():
    so.x = 0
    raise HTTP_REDIRECTION,"index"
