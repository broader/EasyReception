['index', 'create', 'create1']
import os

from HTMLTags import *
import PyDbLite

db = PyDbLite.Base(os.path.join(CWD,"data","quizz.pdl")).create("name",
    "id_cat","id_quizz","text",mode="open")
db_cat = PyDbLite.Base(os.path.join(CWD,"data","categories.pdl")).open()


def index():
    PRINT( H2("Quizz"))
    PRINT( A("Try existing quizzes",href="play"))
    PRINT( BR(A("Create new quizz",href="create")))

def create():
    PRINT( H2("Create new quizz"))
    lines = [TR(TD("Quizz name")+TD(INPUT(name="name",size=30)))]
    cats = db_cat()
    lines += [TR(TD("Quizz type")+
        TD(SELECT(Sum([OPTION(r["name"],value=r["__id__"]) for r in db_cat()]),
            width=30)))]
    lines += [TR(TD("Presentation text")+TD(TEXTAREA(name="content",
        rows="10",cols="50")))]
    lines += [TR(TD(INPUT(Type="submit",value="Create"),colspan=2))]
    PRINT( FORM(TABLE(Sum(lines)),action="create1",method="post"))

def create1(**kw):
    if not "name" in kw or not kw["name"]:
        PRINT( "You must provide a name for this quizz")
        raise SCRIPT_END


