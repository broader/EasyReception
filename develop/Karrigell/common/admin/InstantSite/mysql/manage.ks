
def index(db_name,table_name,start=0,**kw):
    user = COOKIE['login'].value
    app_path = REL(user,'%s_%s.ks' %(db_name,table_name))
    tmpl = open(REL('script_template.ks')).read()
    tmpl = tmpl.replace('$db_name',db_name)
    tmpl = tmpl.replace('$table_name',table_name)
    out = open(app_path,'w')
    out.write(tmpl)
    out.close()
    raise HTTP_REDIRECTION,'../%s/%s_%s' %(user,db_name,table_name)
    