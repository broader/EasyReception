import datetime
import cPickle
from HTMLTags import *

import date_formats

def make_widget(f_name,f_code,f_type,format,ext_dbs,val='',rec_id=''):
    """Build the HTML widget (INPUT,TEXTAREA,SELECT) for the 
    specified field, with given value (val) and record id
    """
    widg_id = f_code
    #if isinstance(rec_id,int):
    #    widg_id = "%s_%s" %(f_code,rec_id)
    if f_type=="string":
        if format["widget"]=="input":
            line = INPUT(name=f_code,Id=widg_id,value=val,
                size = format.get("size",10))
        elif format["widget"]=="textarea":
            line = TEXTAREA(val,name=f_code,Id=widg_id,
                rows=format["rows"],
                cols=format["cols"])
    elif f_type in ["integer","float"]:
        line = INPUT(name=f_code,Id=widg_id,value=val)
    elif f_type=="date":
        d_sep = date_formats.date_seps[format["dsep"]]
        if format["popup"]:
            if d_sep == "None":
                d_sep = ""
            fmt = d_sep.join(date_formats.date_abr[format["dord"]])
        if isinstance(val,datetime.date):
            # format date with strftime pattern
            val = val.strftime(d_sep.join(
                date_formats.strf_patterns[format["dord"]]))
        cell = INPUT(name=f_code,Id=widg_id,value=val)
        if format["popup"]:
            cell += IMG(Id="%s_button" %widg_id,
                src="../calendar.gif",
                onClick="calendar(this,'%s')" %fmt)
        line = cell
    elif f_type.startswith("external"):
        vals = str(Sum([OPTION(v["value"],value=v["value"],selected=val==v["value"]) 
            for v in ext_dbs[f_code]()]))
        line = SELECT(vals,name=f_code,Id=widg_id)

    return line


def make_form(field_info,formats,ext_dbs,record={}):
    """Build the whole line to display and edit a record"""
    return [TH(k["name"])+TD(make_widget(k["name"],k["code"],k["type"],
                  formats[k["code"]],
                  ext_dbs,
                  record.get(k["code"],''),
                  record.get("__id__",'')))
                  for k in field_info]

