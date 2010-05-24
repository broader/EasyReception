from HTMLTags import *

def index():
    print H2("Test d'indentification")
    print "Rôle courant :",Role()
    print BR()+FORM(TEXT("Nom")+
        INPUT(name="name")+
        INPUT(Type="submit",value="Ok"),
        action="test")
    
def test(**kw):
    Login() # pas d'argument : connection comme admin
    print H2("Test d'identification")
    print "Votre rôle est",Role()
    print BR(),"Vous avez saisi",kw
    if Role():
        print BR()+A("Déconnection",href="logout")

def logout():
    Logout()
    