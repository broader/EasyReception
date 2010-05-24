"""
Edit form to edit records
Information is stored in a dictionary indexed by database field codes
For each field in the database, the information is the widget type
and attributes (size for INPUT, rows, cols for TEXTAREA)
For date fields, also stores the date format (DDMMYYYY etc.) and a
flag to indicate if a popup calendar should be displayed
"""
import cPickle
from HTMLTags import *

date_fmts = Import("applications/date_formats")

def index():
    print 'bonjour'

