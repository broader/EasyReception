import datetime

date_abr = ("DD","MM","YYYY"),("MM","DD","YYYY"),\
    ("YYYY","DD","MM"),("YYYY","MM","DD")
# separators
date_seps = ["","/","-"]
# patterns for strftime formatting
strf_patterns = [("%d","%m","%Y"),("%m","%d","%Y"),
    ("%Y","%d","%m"),("%Y","%M","%d")]
    
def str_to_date(date_string,pattern,sep=''):
    # check if date_string is a valid date for pattern
    # pattern is a 3-element tuple like 'DD','MM','YYYY'
    # sep is a separator
    if not len(pattern) == 3:
        raise ValueError,"Incorrect pattern %s, must be a 3-element tuple" \
            %str(pattern)
    if not sep in date_seps:
        raise ValueError,"Incorrect separator %s, must be in %s" \
            %(sep,str(date_seps))
    ranks = dict([(p[0].upper(),i) for i,p in enumerate(pattern)])
    if sep:
        pt = sep.join(['(.+)']*3)
        import re
        mo = re.match(pt,date_string)
        if mo:
            d = int(mo.groups()[ranks['D']])
            m = int(mo.groups()[ranks['M']])
            y = int(mo.groups()[ranks['Y']])
    else:
        pt = "".join(pattern)
        if not len(date_string)==len(pt):
            raise ValueError,"Date string should have %s characters" %len(pt)
        d = int(date_string[pt.find('D'):pt.rfind('D')+1])
        m = int(date_string[pt.find('M'):pt.rfind('M')+1])
        y = int(date_string[pt.find('Y'):pt.rfind('Y')+1])
        
    return datetime.date(y,m,d) # will raise value error if not correct
    
if __name__ == "__main__":
    print str_to_date("02/03/1999",('D','M','Y'),'/')
    print str_to_date("02052009",('DD','MM','YYYY'),'')
    
    