[]
# Displays the news ordered by deposit date

table = Import("portalDb.py",REL=REL).table

all_news= [ news for news in table["news"] ]
all_news.sort(lambda x,y : cmp(x["date"],y["date"]))

PRINT( '<table cellpadding="0" cellspacing="3" width="100%" bgcolor="#D0D0D0">')
PRINT( '<tr><td bgcolor="#808080">%s</td></tr>' %_("News"))
for news in all_news:
    timestring=news["date"].strftime("%d/%m/%y %H:%M")
    PRINT( '<tr><td bgcolor="#D0D0D0">')
    PRINT( '<b>%s</b>' %news["title"])
    PRINT( '<br>%s' %news["body"])
    PRINT( '<br><font size="-2">%s - %s</font>' %(news["login"],timestring))
    PRINT( '</td></tr>')

PRINT( '</table>')

