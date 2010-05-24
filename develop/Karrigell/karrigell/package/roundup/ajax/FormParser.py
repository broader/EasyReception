import re, mimetypes,copy

from roundup import hyperdb, date, password

from ajaxExceptions import *

class FormParser:
        
    def __init__(self, client):        
        self.client = client
        self.db = client.db
        self.form = client.form
        self.classname = client.classname
        self.nodeid = client.nodeid
        self.ok_message = client.ok_message
        self.error_message = client.error_message
            

    def parse(self, create=0 ):
        """ Notes: 
            now,the new item which is instance of either 'file' or 'msg'
            could only be created one time.
        """        
        #print 'ajax.FormParser.FormParser.parse(),L24'
        # some very useful variables
        db = self.db
        form = self.form               

        # these indicate the default class / item
        default_cn = self.classname
        default_cl = self.db.classes[default_cn]
        default_nodeid = self.nodeid

        # we'll store info about the individual class/item edit in these        
        all_props = {}          # props to set per class/item
        # we should always return something, even empty, for the context
        
        #print 'ajax.FormParser.FormParser.parse(),L46,all_props is %s '%all_props            
        if form.has_key('all_props'):
            #all_props.update(form['all_props'])        
            all_props.update(copy.deepcopy(form['all_props']))        
        
        all_links = []          # as many as are required
        if form.has_key('all_links'):                  
            #all_links = form['all_links']
            all_links = copy.deepcopy(form['all_links'])
        
        #timezone = db.getUserTimezone()        
        # sentinels for the :note and :file props
        have_note = have_file = 0             
        
        #print 'ajax.FormParser.FormParser.parse(),L61,all_props is %s'%all_props
        for context in all_props.keys() :            
            cn = context[0]
            cl = self.db.classes[cn]
            nodeid = context[1]        
            props = all_props[context]
            #props = copy.copy(all_props[context])
            #print 'ajax.FormParser.FormParser.parse(),L59,context is %s,props is %s'%(context,props)
            #print 'ajax.FormParser.FormParser.parse(),L60,cn is %s,nodeid is %s'%(cn,nodeid)
            
            # skip implicit create if this isn't a create action
            if not create and nodeid is None:
                continue
            
            # now that we have the props field, we need a teensy little
            # extra bit of help for the old :note field...
            if cn == 'msg':
                if not props.has_key('author') or not props['author'] :
                    props['author'] = self.db.getuid()
                if not props.has_key('date') or not props['date'] :
                    props['date'] = date.Date()
                #all_links.append((default_cn, default_nodeid, 'messages',[('msg', '-1')]))
                have_note = 1    
            
            #print 'ajax.FormParser.FormParser.parse(),L76, props is %s'%props
            
            # for 'file' class, try to determine its type by its name, or set a 
            # default value.
            if cn == 'file':
                if not props.has_key('type'):
                        props['type'] = "application/octet-stream"
                elif not props['type']:
                    if props['name'] and mimetypes.guess_type(fn)[0]:
                        fn = props['name']
                        props['type'] = mimetypes.guess_type(fn)[0]
                    else:
                        props['type'] = "application/octet-stream"
                #all_links.append((default_cn, default_nodeid, 'files',[('file', '-1')]))
                #print 'ajax.FormParser.FormParser.parse(),L108,content length is ',len(props['content'])
                have_file = 1            
            
            # get all the properties defined by the class 
            propdef = cl.getprops()
            
            #for propname in props.keys() :
            for propname,value in props.items() :
                value = props[propname]
                
                # does the property exist?
                if not propdef.has_key(propname):
                    #if mlaction != 'set':
                    raise FormError, 'The property %s doesn\'t exist' % propname
                    # the form element is probably just something we don't care
                    # about - ignore it
                    self.error_message.append('The property %s doesn\'t exist' % propname)
                    continue
                
                # get the property's type
                proptype = propdef[propname]

                if isinstance(value,type([])) and not isinstance(proptype,hyperdb.Multilink) :
                    # multiple values are not OK except for the Multilink property
                    raise FormError, "You have submitted more than one value for the %s property" % propname
                    self.error_message.append('You have submitted more than one value for the %s property' % propname)        
                
                # handle by type now
                if isinstance(proptype, hyperdb.Password):
                    if not value:
                    # ignore empty password values
                        continue                    
                    try:
                        value = password.Password(value)
                    except hyperdb.HyperdbValueError, msg:
                        raise FormError, msg

                elif isinstance(proptype, hyperdb.Multilink):
                    # convert input to list of ids
                    try:
                        l = hyperdb.rawToHyperdb(self.db, cl, nodeid, propname, value)                        
                    except hyperdb.HyperdbValueError, msg:
                        raise FormError, msg                    
                    value = l
                    value.sort() 
                
                elif value == '' :
                    # other types should be None'd if there's no value
                    value = None
                
                else :                    
                    # handle all other types
                    try:
                        # The 'value' has to be transformatted to String to invoid
                        # Format errors in hyperdb.rawToHyperdb().                     
                        value = str(value)
                        # For 'content' property, there is no need to transformat it's value.
                        if propname != 'content' :                            
                            #finally, read the content RAW                        
                            value = hyperdb.rawToHyperdb(self.db, cl, nodeid, propname, value) 
                        
                            
                    except hyperdb.HyperdbValueError, msg:
                        raise FormError, msg
                
                
                # get the old value
                if nodeid and not nodeid.startswith('-'):
                    try:                    
                        existing = cl.get(nodeid, propname) 
                        #print 'ajax.FormParser,L172, existing value is ',existing
                    except KeyError:
                        # this might be a new property for which there is
                        # no existing value
                        if not propdef.has_key(propname):
                            raise "There is no property named %s"%propname
                    except IndexError, message:
                        raise FormError(str(message))

                    # make sure the existing multilink is sorted
                    if isinstance(proptype, hyperdb.Multilink):
                        existing.sort()                    

                    # "missing" existing values may not be None
                    if not existing:
                        if isinstance(proptype, hyperdb.String):
                            # some backends store "missing" Strings as empty strings
                            if existing == self.db.BACKEND_MISSING_STRING:
                                existing = None
                        elif isinstance(proptype, hyperdb.Number):
                            # some backends store "missing" Numbers as 0 :(
                            if existing == self.db.BACKEND_MISSING_NUMBER:
                                existing = None
                        elif isinstance(proptype, hyperdb.Boolean):
                            # likewise Booleans
                            if existing == self.db.BACKEND_MISSING_BOOLEAN:
                                existing = None
                    
                    if value == existing and not isinstance(proptype, hyperdb.Link) :
                        # if nothing change, remove it from the properties dictionary
                        del(props[propname])                        
                    else:
                        # change the property value to user input
                        props[propname] = value
                    #print 'ajax.FormParser,L203,props is %s'%props
                else:
                    # don't bother setting empty/unset values
                    if value is None:
                        continue
                    elif isinstance(proptype, hyperdb.Multilink) and value == []:
                        continue
                    elif isinstance(proptype, hyperdb.String) and value == '':
                        continue
                    props[propname] = value
            
        # check to see if we need to specially link a file to the note
        if have_note and have_file:
            all_links.append(('msg', '-1', 'files', [('file', '-1')]))

        #print 'ajax.FormParser.FormParser.parse(),L207,all_props is %s,all_links is %s'%(all_props,all_links)
        # When creating a FileClass node, it should have a non-empty content
        # property to be created. When editing a FileClass node, it should
        # either have a non-empty content property or no property at all. In
        # the latter case, nothing will change.
        for (cn, id), props in all_props.items():
            if (id == '-1') and not props:
                # new item (any class) with no content - ignore
                del all_props[(cn, id)]
            elif isinstance(self.db.classes[cn], hyperdb.FileClass):
                if id == '-1':
                    if not props.get('content', ''):
                        del all_props[(cn, id)]
                elif props.has_key('content') and not props['content']:
                    raise FormError, 'File is empty'
                #print 'ajax.FormParser.FormParser.parse(),L244,content length is ',len(props['content'])
        
        #print 'ajax.FormParser.FormParser.parse(),L224,all_props is %s,all_links is %s'%(all_props,all_links)        
        #print 100*'-'
        return all_props, all_links

    
# vim: set et sts=4 sw=4 :
