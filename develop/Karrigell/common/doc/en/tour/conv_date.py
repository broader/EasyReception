import datetime
def conv(d,m,y):
    date = datetime.date(y,m,d)
    day = date.strftime("%A")
    return "%s was a %s" %(date,day)