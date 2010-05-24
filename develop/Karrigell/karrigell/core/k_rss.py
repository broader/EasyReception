"""
    
    Simple RSS 2.0 stream generator.
    
Example of use :

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
    
"""
try :
    import xml.etree.ElementTree as ET
except ImportError :
    import elementtree.ElementTree as ET

import datetime
import time
 
CHANNEL_ATTRIBUTES = ("title",          # mandatory
                      "link",           # mandatory
                      "description",    # mandatory
                      "language",
                      "copyright",
                      "managingEditor",
                      "webMaster",
                      "pubDate",
                      "lastBuildDate",
                      "category",
                      "generator",
                      "docs",
                      "cloud",
                      "ttl",
                      "image",
                      "rating",
                      #"textInput",
                      "skipHours",
                      "skipDays")

IMAGE_ATTRIBUTES = ("url",      # mandatory
                    "title",    # mandatory
                    "link",     # mandatory
                    'width',
                    'height',
                    'description'
                    )

ITEM_ATTRIBUTES = ('title',
                   'link',
                   'description',
                   'author',
                   'category',
                   'comments',
                   'enclosure',
                   'guid',
                   'pubDate',
                   'source'
                   )

_DAYS = ("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun")
_MONTHS = ("Jan", "Feb", "Mar", "Apr", "May", "Jun",
           "Jul", "Aug", "Sep", "Oct", "Nov", "Dec")


class RSS(object):
    def __init__(self, **kw):
        self.root = ET.Element("rss", {"version": "2.0"})
        self.channel = ET.SubElement(self.root, "channel")
        if "title" not in kw :
            raise AttributeError, "missing title parameter in RSS"
        if "description" not in kw :
            raise AttributeError, "missing description parameter in RSS"
        if "link" not in kw :
            raise AttributeError, "missing link parameter in RSS"
        for k,v in kw.iteritems() :
            if k in CHANNEL_ATTRIBUTES :
                if k == "image" :
                    self._Image(self.channel, **v)
                else :
                    if isinstance(v, datetime.datetime) :
                        ET.SubElement(self.channel, k).text = self._Date(v)
                    else :
                        ET.SubElement(self.channel, k).text = v
            else :
                raise AttributeError, "%s is an invalid element of RSS channel tag" % k
        
    def AddItem (self, **kw):
        item = ET.SubElement (self.channel, 'item')
        if "title" not in kw and "description" not in kw :
            raise AttributeError, "either title or description parameter must be specified in AddItem" 
        for k,v in kw.iteritems() :
            if k in ITEM_ATTRIBUTES :
                if k == "image" :
                    self._Image(item, **v)
                else :
                    if isinstance(v, datetime.datetime) :
                        ET.SubElement(item, k).text = self._Date(v)
                    else :
                        ET.SubElement(item, k).text = v
            else :
                raise AttributeError, "%s is an invalid element of RSS item tag" % k
        
    def Render (self, encoding="iso-8859-1"):
        return ET.tostring(self.root, encoding)
        
    def RenderInFile (self, filename, encoding="iso-8859-1"):
        rss = ET.ElementTree(self.root)
        rss.write(filename, encoding)
        
        
    def _Image (self, parent, **kw):
        image = ET.SubElement(parent, "image")
        if "url" not in kw :
            raise AttributeError, "missing url parameter in Image"
        if "title" not in kw :
            raise AttributeError, "missing title parameter in Image"
        if "link" not in kw :
            raise AttributeError, "missing link parameter in Image"
        for k,v in kw.iteritems() :
            if k in IMAGE_ATTRIBUTES :
                ET.SubElement(image, k).text = v
            else :
                raise AttributeError, "%s is an invalid element of RSS image tag" % k
        return image
    
    def _Date(self, date_time):
        """Convert a datetime into an RFC 822 formatted date.
            If date_time is naive (no timezone defined), set computer local time zone for it.
        """
        if (date_time.tzinfo is None) or (date_time.tzinfo.utcoffset() is  None) :
            # date_time is naive -> Add local time zone
            date_time = date_time.replace(tzinfo=LocalTimeZone())

        utc_offset_s = (date_time.utcoffset().days * 24 * 3600) + date_time.utcoffset().seconds
        if utc_offset_s >= 0 :
            utc_offset_sign = '+'
        else :
            utc_offset_sign = '-'
            utc_offset_s = -utc_offset_s
        utc_offset_h, utc_offset_s = divmod(utc_offset_s, 3600)
        utc_offset_m, utc_offset_s = divmod(utc_offset_s, 60)
        
        return "%s, %02d %s %04d %02d:%02d:%02d %c%02d%02d" % (
                _DAYS[date_time.weekday()],
                date_time.day,
                _MONTHS[date_time.month-1],
                date_time.year, date_time.hour, date_time.minute, date_time.second,
                utc_offset_sign, utc_offset_h, utc_offset_m)
    

class LocalTimeZone(datetime.tzinfo):
    def __init__(self):
        self.std_offset = datetime.timedelta(seconds = -time.timezone)
        if time.daylight:
            self.dst_offset = datetime.timedelta(seconds = -time.altzone)
        else:
            self.dst_offset = self.std_offset
        self.dst_diff = self.dst_offset - self.std_offset


    def utcoffset(self, dt):
        if self._isdst(dt):
            return self.dst_offset
        else:
            return self.std_offset

    def dst(self, dt):
        if self._isdst(dt):
            return self.dst_diff
        else:
            return datetime.timedelta(0)

    def tzname(self, dt):
        return time.tzname[self._isdst(dt)]

    def _isdst(self, dt):
        tt = (dt.year, dt.month, dt.day,
              dt.hour, dt.minute, dt.second,
              dt.weekday(), 0, -1)
        stamp = time.mktime(tt)
        tt = time.localtime(stamp)
        return tt.tm_isdst > 0
