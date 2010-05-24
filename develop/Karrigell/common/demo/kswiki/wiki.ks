# -*- coding: utf-8 -*-
ENCODING = 'utf-8'
SET_UNICODE_OUT(ENCODING)
MAXPAGELENGTH = 5000

import re
from HTMLTags import *
BuanBuan = Import("wiki/BuanBuan.py")

def _replace(matchObj):
    return "<b>"+matchObj.string[matchObj.start():matchObj.end()]+"</b>"

def _authTest():
    return (md5.new(AUTH_USER).digest()==userDigest \
        and md5.new(AUTH_PASSWORD).digest()==passwordDigest)

def _log(*arg):
    import sys
    sys.stderr.write('\n'.join(arg)+'\n')

def index():
    db = Import('wiki/wikiBase').db
    rows = [(r['lastmodif'], r['name']) for r in db()]
    rows.sort()
    rows.reverse()
    pagenames = UL()
    if len(rows) > 0:
        for lastmodif, name in rows[:5]:
            wikiname = BuanBuan.formatWikiname(name)
            dt = lastmodif.strftime("%Y-%m-%d %H:%M")
            pagenames <= LI(
                A(wikiname, Class="wikiname", href="show/%s" % name, title='Last modified: %s' % dt)
                )
        # Set start character for page lists - first character of first name in list
        startchar = rows[0][1][0].upper()
    else:
        pagenames = 'No pages'
        startchar = 'A'
    logout = ''
    if Role()=="admin":
        logout = A(_("Log out"), href="logout") 
    print KT('wiki/template/index.kt', data=locals(), this=THIS)

def show():
    import datetime
    db = Import("wiki/wikiBase").db
    pageName = THIS.args[0]
    page = db(name=pageName)[0]
    # increment number of visits
    page['nbvisits'] += 1

    b=BuanBuan.BuanDoc(pageName, page['content'])
    wikiNames=b.wikiNames

    # insert new pages in the base
    for w_name in wikiNames:
        if not db(name=w_name):
            insertTime = datetime.datetime.now()
            db.insert(w_name,'New page',page['admin'], 0, insertTime,1,insertTime)
    db.commit()
    lastmodif = page['lastmodif'].strftime("%d/%m/%y %H:%M")
    html = b.text
    title = '- %s' % BuanBuan.formatWikiname(pageName)
    heading = ''
    bodytmpl = 'show.kt'
    print KT('wiki/template/master.kt',data=locals(),page=page,this=THIS) 
    

def edit(action="", admin=False, pageName=None):
    db = Import("wiki/wikiBase").db
   
    pageName = pageName or THIS.args[0]
        
    if not BuanBuan.isLinkName(pageName):
        print "<b>"+pageName+"</b>&nbsp;"+_("is not a valid link name - ")
        print _("Must begin with a Capital and have at least another one inside")
        raise SCRIPT_END
        
    page = db(name=pageName)
    if page:
        text = page[0]['content']
        admin = page[0]['admin']
    else:
        text = 'New page'

    if admin and not Role()=="admin":
        Login(valid_in="/",redir_to="%s/edit/%s" % (THIS.script_url, pageName))
    if admin:
        adminchecked = 'CHECKED'
    else:
        adminchecked = ''
    title = '- %s %s' % (_('editing'), BuanBuan.formatWikiname(pageName))
    heading = '%s %s' % (_('Editing page'), pageName)
    jstmpl = 'editjs.kt'
    bodytmpl = 'edit.kt'
    res = KT('wiki/template/master.kt', data=locals(), this=THIS)
    print res

def save(pageName='', newText='', admin=0):
    import datetime

    db = Import("wiki/wikiBase").db

    if len(newText)>MAXPAGELENGTH:
        print "Text too long"
        raise SCRIPT_END

    if admin and not Role()=="admin":
        print "You must be logged in as admin to set this page to admin status"
        print "<br>Your role is",Role()
        raise SCRIPT_END
    
    # Convert new text to unicode, replacing any unsupported characters with xml references
    newText = unicode(newText,ENCODING,'xmlcharrefreplace')
    
    records = db(name=pageName)
    if records:
        # if existing record, update it
        record = records[0]
        updateTime = datetime.datetime.now()
        db.update(record, name=pageName, content=newText.rstrip(),
            admin=admin, version=record['version']+1, lastmodif=updateTime)
    else:
        # else create a new record
        insertTime = datetime.datetime.now()
        db.insert(pageName,newText.rstrip(), admin, 0, 
            insertTime, 1, insertTime)

    # commit changes
    db.commit()

    # show
    raise HTTP_REDIRECTION,"show/%s" % pageName

def search(words, caseSensitive=False, fullWord=False ):
    # search engine
    import posixpath
    db = Import("wiki/wikiBase").db
    
    caseSensitive=QUERY.has_key("caseSensitive")
    fullWord=QUERY.has_key("fullWord")
    try:
        words = unicode(words, 'utf-8')
    except TypeError:
        pass
    words2 = "(%s)" %words
    if fullWord:
        words2=r"\W"+words2+r"\W"
    sentence="[\n\r.?!].*"+words2+".*[\n\r.?!]"
    #sentence=words
    if caseSensitive:
        sentencePattern=re.compile(sentence, re.UNICODE)
        wordPattern=re.compile(words2, re.UNICODE)
    else:
        sentencePattern=re.compile(sentence,re.IGNORECASE|re.UNICODE)
        wordPattern=re.compile(words2,re.IGNORECASE|re.UNICODE)
        
    occ=0           # number of occurences
    result = TEXT()     # formatted results
    # gets all pages in base
    for page in db:
        content = page['content']
        wikiname = BuanBuan.formatWikiname(page['name'])
        try:
            content = unicode(content, 'utf-8')
        except TypeError:
            pass
        content="\n"+wikiname+"\n"+content+"\n"
        flag=0  # true if at least one match
        deb=0
        while 1:
            searchObj=sentencePattern.search(content,deb)
            if searchObj is None:
                if flag:
                    result <= found
                break
            else:
                if not flag:
                    name = page['name']
                    wikiname = BuanBuan.formatWikiname(name)
                    result <= A(wikiname, Class="wikiname", href="show/%s" %name) + BR()
                    found = BLOCKQUOTE()
                    flag=1
                sentence=content[searchObj.start():searchObj.end()]
                sentence=sentence.lstrip()
                sentence=sentence[re.search("[^!]",sentence).start():]
                sentence=wordPattern.sub(_replace,sentence)
                # eliminates leading char "!"
                found <= TEXT(sentence)+BR()
                deb=searchObj.end()-len(words)+1
                occ+=1
                flag=1
                _log("Search - found %s" % occ)
    msg = ""
    if not occ:
        msg = "%s not found" %words
    title = ' - search results'
    heading = 'Searching for [%s]' %words
    bodytmpl = 'search.kt'
    firstchar = words[0].upper()
    try:
        content = unicode(result)
    except UnicodeEncodeError:
        content = '%s' % result
    print KT('wiki/template/master.kt', data=locals(), this=THIS)


def pagesbytitle(char='A'):
    import cgi
    char = char.upper()
    db = Import("wiki/wikiBase.py").db
    result = TEXT()
    index = dict([(c, False) for c in "ABCDEFGHIJKLMNOPQRSTUVWXYZ"])
    pagesExist = False
    names = [r['name'] for r in db()]
    names.sort()
    for name in names:
        page = db(name=name)[0]
        firstchar = page['name'][0].upper()
        index[firstchar] = True
        if firstchar == char:
            pagesExist = True
            name = page['name']
            wikiname = BuanBuan.formatWikiname(page['name'])
            result <= A(wikiname, Class="wikiname", href="show/%s" %name) + BR()
            # Get first paragraph
            content = page['content'].strip()
            lines = content.split('\n', 3)[:3]
            result <= BLOCKQUOTE(Sum([TEXT(cgi.escape(l)) + BR() for l in lines]))
    index = index.items()
    index.sort()
    indexhtml = TEXT()
    for c, flag in index:
        if c == char:
            indexhtml <= FONT(c + ' ', size='+1')
        elif flag:
            indexhtml <= A(c, href="pagesbytitle?char=%s" % c) + TEXT(' ')
        else:
            indexhtml <= TEXT(c + ' ')
    if not pagesExist:
        result = 'No page titles beginning with "%s"' % char
    title = _('Pages By Title')
    heading = _('Pages By Title')
    bodytmpl = 'pagelist.kt'
    altpagelist = A(_('Pages by title keyword'), href='pagesbytitlekeyword?char=%s' % char)
    try:
        content = unicode(result)
    except UnicodeEncodeError:
        content = '%s' % result
    print KT('wiki/template/master.kt', data=locals(), this=THIS)

def pagesbytitlekeyword(char='A'):
    import cgi
    char = char.upper()
    db = Import("wiki/wikiBase.py").db
    index = dict([(c, False) for c in "ABCDEFGHIJKLMNOPQRSTUVWXYZ"])
    keywords = {}
    pagesExist = False
    for page in db():
        name = page['name']
        wikiwords = BuanBuan.getWikiwords(name)
        for word in wikiwords:
            firstchar = word[0].upper()
            index[firstchar] = True
            if firstchar == char:
                pagesExist = True
                if not keywords.has_key(word):
                    keywords[word] = [name]
                else:
                    keywords[word].append(name)
    keys = keywords.keys()
    keys.sort()
    result = TEXT()
    for key in keys:
        result <= H3(key)
        keyresult = BLOCKQUOTE()
        names = keywords[key]
        names.sort()
        for name in names:
            page = db(name=name)[0]
            wikiname = BuanBuan.formatWikiname(name)
            keyresult <= A(wikiname, Class="wikiname", href="show/%s" %name) + BR()
            # Get first paragraph
            content = page['content'].strip()
            lines = content.split('\n', 3)[:3]
            keyresult <= BLOCKQUOTE(Sum([TEXT(cgi.escape(l)) + BR() for l in lines]))
        result <= keyresult
    index = index.items()
    index.sort()
    indexhtml = TEXT()
    for c, flag in index:
        if c == char:
            indexhtml <= FONT(c + ' ', size='+1')
        elif flag:
            indexhtml <= A(c, href="pagesbytitlekeyword?char=%s" % c) + TEXT(' ')
        else:
            indexhtml <= TEXT(c + ' ')
    if not pagesExist:
        result = 'No title keywords beginning with "%s"' % char
    title = _('Pages By Title Keyword')
    heading = _('Pages By Title Keyword')
    altpagelist = A(_('Pages by title'), href='pagesbytitle?char=%s' % char)
    bodytmpl = 'pagelist.kt'
    try:
        content = unicode(result)
    except UnicodeEncodeError:
        content = '%s' % result
    print KT('wiki/template/master.kt', data=locals(), this=THIS)


def authenticate():
    import md5
    digest=open("/common/admin/admin.ini","rb").read()
    userDigest=digest[:16]
    passwordDigest=digest[16:]
    Authentication(_authTest,realm=_("Administration"),errorMessage=_("Authentication error"))
    
def remove(subm=None,remove=[]):
    """ Removes the pages whose names are the keys of QUERY """
    # check authentication
    Login(role=["admin"])
    if subm == _("Cancel") or not "remove" in REQUEST:
        raise HTTP_REDIRECTION,"index"
    # get records to remove using their recno
    db = Import("wiki/wikiBase").db
    pagelist = ''
    for r in remove:
        pagelist += '<li>%s</li>' % db[int(r)]['name']
    if len(remove) == 1:
        msg = "1 page deleted<p>\n"
    else:
        msg = "%s pages deleted<p>\n" %len(remove)
    
    # Display the results
    title = ' - removing pages'
    bodytmpl = 'remove.kt'
    print KT('wiki/template/master.kt', data=locals(), this=THIS)

    # actually remove the records
    for r in remove:
        del db[int(r)]
    db.commit()

def admin():
    db = Import("wiki/wikiBase.py").db
    Login(role=["admin"],valid_in="/")
    records = [ (r['__id__'],r['name']) for r in db ]
    if not records:
        print "No page to remove"
        print '<p><a href="index">Back</a>'
        raise SCRIPT_END
    pagelist = ''
    for (_id,name) in records:
        pagelist += '<tr><td><input type="checkbox" name="remove[]" value="%s"">' %_id
        pagelist += '&nbsp;</td><td>%s</td></tr>' %name
    title = '- admin'
    heading = _('Administration')
    bodytmpl = 'admin.kt'
    print KT('wiki/template/master.kt', data=locals(), this=THIS)
    
def logout():
    Logout(valid_in="/",redir_to=THIS.baseurl+"/wiki.ks")
            