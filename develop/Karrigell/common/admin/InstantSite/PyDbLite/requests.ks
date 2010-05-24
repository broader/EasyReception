import cPickle
from urllib import quote_plus,unquote_plus

from HTMLTags import *

Login(role=["admin","edit"],add_user=True)

user = COOKIE['login'].value

def requests(db_name):
    db_name = unquote_plus(db_name)
    print HEAD(LINK(rel="stylesheet",href="../default.css"))
    # open requests file
    infos = cPickle.load(open(REL(user,db_name)+"_infos.dat"))
    if not "requests" in infos:
        infos["requests"]={}
        cPickle.dump(infos,open(REL(user,db_name)
            +"_infos.dat","wb"))
        
    requests = infos.get("requests",{})
    lines = [BR(A(request,href="edit_request?db_name=%s&request=%s"
        %(quote_plus(db_name),request))) for request in requests ]
    lines.append(BR(FORM(
        INPUT(Type="hidden",name="db_name",value=quote_plus(db_name))+
        INPUT(name="request")+
        INPUT(Type="submit",name="new",value="New request"),
        action="edit_request")))
    print BODY(Sum(lines))
        
def edit_request(**kw):
    print HEAD(LINK(rel="stylesheet",href="../default.css"))
    request = kw["request"]
    db_name = unquote_plus(kw["db_name"])

    if "new" in kw:
        print H2("New request")
    else:
        print H2("Request %s" %request)

    infos = cPickle.load(open(REL(user,db_name)+"_infos.dat"))
    fields = infos["fields"]
    requests = infos["requests"]
    
    conditions = requests.get(request,[])
    conds = H3("Conditions")
    if conditions:
        l_conds = []
        for i,cond in enumerate(conditions):
            code,op,value = cond
            field = [f["name"] for f in fields if f["code"]==code][0]
            l_conds.append(TR(TD("%s %s %s" %(field,op,value))+
                TD(FORM(
                    INPUT(Type="hidden",name="db_name",value=quote_plus(db_name))+
                    INPUT(Type="hidden",name="request",value=request)+
                    INPUT(Type="hidden",name="num",value=i)+
                    INPUT(Type="submit",value="Delete"),
                    action="delete_condition"))))
        conds += TABLE(Sum(l_conds))

    fields = infos["fields"]
    lines = INPUT(Type="hidden",name="db_name",value=quote_plus(db_name))
    lines += INPUT(Type="hidden",name="request",value=request)
    lines += SELECT(Sum([OPTION(field["name"],
        value=field["code"]) for field in fields]),
        name="code")
    lines += SELECT(OPTION("=",value="=")+OPTION(">",value=">")+OPTION("<",value="<"),
        name="op")
    lines += INPUT(name="value") + INPUT(Type="submit",value="Ok")
    print BODY(conds+P()+FORM(lines,action="add_condition"))

def add_condition(**kw):
    db_name = unquote_plus(kw["db_name"])
    request = kw["request"]
    
    infos = cPickle.load(open(REL(user,db_name)+"_infos.dat"))
    fields = infos["fields"]
    requests = infos["requests"]
    conditions = requests.get(request,[])
    conditions.append((kw["code"],kw["op"],kw["value"]))
    requests[request] = conditions
    infos["requests"] = requests
    cPickle.dump(infos,open(REL(user,kw["db_name"])
        +"_infos.dat","wb"))
    raise HTTP_REDIRECTION,"edit_request?db_name=%s&request=%s" \
        %(kw["db_name"],request)

def delete_condition(db_name,request,num):
    db_name = unquote_plus(db_name)
    infos = cPickle.load(open(REL(user,db_name)+"_infos.dat"))
    requests = infos["requests"]
    conditions = requests.get(request,[])
    del conditions[int(num)]
    requests[request] = conditions
    infos["requests"] = requests
    cPickle.dump(infos,open(REL(user,db_name)+"_infos.dat","wb"))
    raise HTTP_REDIRECTION,"edit_request?db_name=%s&request=%s" \
        %(quote_plus(db_name),request)

