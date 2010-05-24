from HTMLTags import *

def index():
    print H2("Login test")
    print "Current role :",Role()
    print BR()+FORM(TEXT("Name")+
        INPUT(name="name")+
        INPUT(Type="submit",value="Ok"),
        action="test")
    
def test(**kw):
    Login() # no argument : log in as admin
    print H2("Login test")
    print "Your role is",Role()
    print BR(),"You entered",kw
    if Role():
        print BR()+A("Logout",href="logout")

def logout():
    Logout()
    