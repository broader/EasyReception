from HTMLTags import *

def index():
    print H2("Test d'indentification")
    print "R�le courant :",Role()
    print BR()+FORM(TEXT("Nom")+
        INPUT(name="name")+
        INPUT(Type="submit",value="Ok"),
        action="test")
    
def test(**kw):
    Login() # pas d'argument : connection comme admin
    print H2("Test d'identification")
    print "Votre r�le est",Role()
    print BR(),"Vous avez saisi",kw
    if Role():
        print BR()+A("D�connection",href="logout")

def logout():
    Logout()
    