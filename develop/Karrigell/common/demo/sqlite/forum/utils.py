import datetime

def _make_dict(fields,row):
    res = {}
    for field,item in zip(fields,row):
        if field in ['date','lastDate']:
            y = int(item[:4])
            m = int(item[5:7])
            d = int(item[8:10])
            H = int(item[11:13])
            M = int(item[14:16])
            S = int(item[17:19])
            res[field] = datetime.datetime(y,m,d,H,M,S)
        else:
            res[field] = item
            if isinstance(item,unicode):
                res[field] = item.encode('utf-8')
    return res
