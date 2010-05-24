from HTMLTags import *

print FRAMESET(
        FRAME(name="preview",src="form_preview.ks/preview?db_name=%s" %_db_name) +
       FRAME(name="edit"),
    cols="75%,*")

