from k_rss import RSS
import datetime

rss = RSS(title="Karrigell", 
          description="Flexible Python web framework, with a clear and intuitive syntax.", 
          link="http://www.karrigell.com",
          webMaster="quentel.pierre@wanadoo.fr (Pierre Quentel)", 
          language="en",
          generator="Karrigell RSS generator",
          image={"url":"http://karrigell.sourceforge.net/images/karrigell_skeudenn.png",
                 "title":"Karrigell",
                 "link":"http://www.karrigell.com"}
          )

rss.AddItem (title='Last item', 
             description='My most recent item.',
             pubDate = datetime.datetime.now())

rss.AddItem (title='First item', 
             description='My first item.',
             pubDate = datetime.datetime(year=2009, month=3, day=16, hour=22, minute=34, second=17))

print rss.Render()

#rss.RenderInFile(REL('rss.xml'))
#raise HTTP_REDIRECTION, "rss.xml"