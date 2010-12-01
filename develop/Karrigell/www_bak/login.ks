# login and logout for home page

def logout():
    Logout(valid_in='/',redir_to='/')

def login():    
    Login(role=["admin","edit","visit"],valid_in='/',
        redir_to='/')