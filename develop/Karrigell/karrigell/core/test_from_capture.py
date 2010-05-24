import os
import socket

import PyDbLite

db = PyDbLite.Base("../data/capture.pdl").open()
for r in db:
    sock = socket.socket(socket.AF_INET,socket.SOCK_STREAM)
    sock.connect(("localhost",80))
    sock.send(r["request"])
    result = ""
    while True:
        buff = sock.recv(1024)
        if not buff:
            break
        result += buff
    print r["request"].split("\n")[0].rstrip()
    print len(result),"recu"
    pos = result.find("\r\n\r\n")
    if pos>-1:
        resp_lines = result[:pos].split("\r\n")
        resp_status = resp_lines.pop(0).rstrip()
        resp_headers = dict([(line.rstrip(),None) 
            for line in resp_lines if line.rstrip()])
        res = result[pos+4:]
        assert resp_status == r["resp_status"]
        assert resp_headers == r["resp_headers"]
        assert res == r["resp_body"]
    sock.close()
    