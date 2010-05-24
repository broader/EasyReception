"""Logging management
logging_rotate management by Gustavo Galvan
"""
import os
import sys
import datetime

def log(config,*data): 
    if config.logging_file or \
        (hasattr(config,"silent") and not config.silent): 
        msg = str(" ".join([str(x) for x in data]))+"\n" 
    if hasattr(config,"silent") and not config.silent: 
        sys.stderr.write(msg) 
    # logging 
    if config.logging_file: 
        if hasattr(config,"logging_rotate") and config.logging_rotate: 
            now = datetime.datetime.now()
            log_filename = config.logging_file + "_"
            if config.logging_rotate == "monthly": 
                log_filename += now.strftime('%Y%m') + ".log" 
            elif config.logging_rotate == "daily": 
                log_filename += now.strftime('%Y%m%d') + ".log" 
            elif config.logging_rotate == "hourly": 
                log_filename += now.strftime('%Y%m%d%H') + ".log" 
            else: # if unknown value is provided
                log_filename += now.strftime('%Y%m%d') + ".log"
        else: 
            log_filename = config.logging_file 
        if not os.path.exists(log_filename): 
            log_file = open(log_filename,"w") 
        else: 
            log_file = open(log_filename,"a+") 
        log_file.write(msg) 
        log_file.close() 