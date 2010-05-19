import time,datetime
table = Import("agendaDb",REL=REL).table

y,m,d = Session().year,Session().month,Session().day

if _subm == "Add":
    if _content:
        begin_time = datetime.datetime(y,m,d,int(_begin_hour),int(_begin_minute))
        end_time = datetime.datetime(y,m,d,int(_end_hour),int(_end_minute))
        table.insert(_content,begin_time,end_time)
        table.commit()
elif _subm == "Delete":
    del table[int(_rec_id)]
    table.commit()
elif _subm == "Update":
    if _content:
        record = table[int(_rec_id)]
        bt = datetime.datetime(y,m,d,int(_begin_hour),int(_begin_minute))
        et = datetime.datetime(y,m,d,int(_end_hour),int(_end_minute))
        table.update(record,content=_content,begin_time=bt,end_time=et)
        table.commit()

raise HTTP_REDIRECTION,"index.pih"
