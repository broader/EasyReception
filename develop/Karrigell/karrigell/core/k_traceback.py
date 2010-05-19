import sys
import cStringIO
import traceback
import urllib
import cgi

def trace(handler,exc_info,header,config):
    handler.output = cStringIO.StringIO()
    script = handler.target # may be included
    if not config.debug:
        handler._print("The request could not be completed")
        return
    tb = traceback.extract_tb(exc_info[2])
    [exc_type,exc_value]=exc_info[:2]
    handler.resp_headers["Content-type"] = "text/html"
    if exc_type in [SyntaxError,IndentationError]:
        try:
            errorMsg,(filename, line_num, offset, line) = exc_value
            if script.ext == ".pih":
                line_num = script.line_mapping[line_num-1]+1
            line = open(script.name).readlines()[line_num-1]
            line = cgi.escape(line)
        except:
            line_num = 'unknown'
            line = 'unknown'
            pass
    else:
        while len(tb)>1 and tb[-1][0] != "<string>":
            tb.pop()
        last_tb = tb[-1]
        filename, line_num, function_name, text = last_tb
        if filename == "<string>":
            try:
                if script.ext == ".pih":
                    line_num = script.line_mapping[line_num-1]+1
                line = open(script.name).readlines()[line_num-1]
                line = cgi.escape(line)
            except:
                line = "\n".join([str(x) for x in tb])
        else:
            line = "[in file %s\n]" %filename
            line += open(filename).readlines()[line_num-1]

    msg = cStringIO.StringIO()

    msg.write('<table style="background-color:#FFFFCC;'
        'border-style:solid;border-width:1;">'
        '<tr><td><pre>')
    msg.write('<b>%s</b><br>' %header)
    msg.write('Line %s    ' %line_num)
    msg.write('<div style="background-color:#D0D0D0">%s</div>' %line)
    msg.write(traceback.format_exception_only(exc_type,exc_value)[-1])
    msg.write("</pre></td></tr>")
    msg.write("</table><pre>")
    traceback.print_exc(file=msg)
    msg.write("</pre>")

    if handler.get_log_level()=="admin":
        eform = '<form action="/admin/editor/editScript.ks"'
        eform += ' target="_blank"><input type="hidden" name="script" '
        eform += 'value="%s">' %urllib.quote_plus(script.name)
        #eform += '<input type="hidden" name="editable" value="1">'
        eform += '<input type="submit" value="Debug"></form>'
        msg.write(eform)
    return msg.getvalue()