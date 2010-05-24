import os

def open_db(config):
    import PyDbLite
    db_path = os.path.join(config.data_dir,"capture.pdl")
    return PyDbLite.Base(db_path).create("request",
        "resp_status","resp_headers","resp_body",mode="override")

def save(handler,db):
    request = handler.request_line + handler.header_text
    response_lines = handler.response.split("\r\n")
    status = response_lines.pop(0).rstrip()
    resp_headers = dict([(line.rstrip(),None) 
        for line in response_lines if line.rstrip()])
    handler.output.seek(0)
    body = handler.output.read()
    if db(request=request):
        db.update(db(request=request)[0],
            resp_status = status,
            resp_headers = resp_headers,
            resp_body = body)
    else:
        db.insert(request=request,
            resp_status = status,
            resp_headers = resp_headers,
            resp_body = body)
    db.commit()
    