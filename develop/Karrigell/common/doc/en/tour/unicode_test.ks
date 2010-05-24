from HTMLTags import *

def index():

    SET_UNICODE_OUT("utf-8")
    print FORM(INPUT(name="foo")+INPUT(Type="submit",value="Ok"),
        action="bar")

def bar(foo):
    foo = unicode(foo,"utf-8").encode("iso-8859-1")
    SET_UNICODE_OUT("iso-8859-1")
    print foo
