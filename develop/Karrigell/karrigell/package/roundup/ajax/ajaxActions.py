#-----------------------------------------------------------------------------
# Name:        ajaxActions.py
# Purpose:     
#
# Author:      <your name>
#
# Created:     2008/01/20
# RCS-ID:      $Id: ajaxActions.py $
# Copyright:   (c) 2006
# Licence:     <your licence>
#-----------------------------------------------------------------------------
#$Id$

import re, cgi, StringIO, urllib, Cookie, time, random, csv, codecs,copy,sys,os

from roundup import hyperdb, token, date, password
from roundup.i18n import _
from roundup.mailgw import uidFromAddress
import roundup.exceptions as exceptions

from ajaxExceptions import *

__all__ = ['Action', 'RetireAction', 'SearchAction',
            'EditCSVAction', 'EditItemAction', 'PassResetAction',
             'RegisterAction', 'LoginAction', 'LogoutAction',
            'NewItemAction', 'ExportCSVAction','GetItemAction','GetItemsAction',
            'GetKeyAction','GetKeysAction','GetLinksAction','GetPropvalueAction',
            'FilterByLinkAction','GetFileAction','FilterByPropValueAction',
            'GetItemsByStringPropAction','GetIdbyKeyAction','NewItemsAction',
            'AddNodeAction','ChangeParentNodeAction','GetTreeAction',
            'CalculateAction','ValidToggleAction','TransferValueAction',
            'VirementAction', 'MultiLinkAction', 'GetItemsBySqlAction',
            'StringPropEditAction', 'GetItemByLinkPropValueAction', 'LinkCSVAction',
            'FilterByTextAction', 'serial2id', 'FilterByFunctionAction' ]

# used by a couple of routines
chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'

class Action:
    def __init__(self, client):
        self.client = client
        self.form = client.form
        self.db = client.db
        self.nodeid = client.nodeid
        self.classname = client.classname
        self.userid = client.userid
        self.user = client.user

    def handle(self):
        """Action handler procedure"""
        raise NotImplementedError

    def execute(self):
        """Execute the action specified by this object."""
        #print'ajaxAction.Action,L56'
        self.permission()        
        
        #print'ajaxAction.Action,L58'
        return self.handle()

    name = ''
    permissionType = None
    def permission(self):
        """Check whether the user has permission to execute this action.

        True by default. If the permissionType attribute is a string containing
        a simple permission, check whether the user has that permission.
        Subclasses must also define the name attribute if they define
        permissionType.

        Despite having this permission, users may still be unauthorised to
        perform parts of actions. It is up to the subclasses to detect this.
        """
        #print "ajaxAction.Action.permission(),L76,self.name is %s"%self.name
        if (self.permissionType and
                not self.hasPermission(self.permissionType)):
            info = {'action': self.name, 'classname': self.classname}
            print "ajaxAction.Action.permission(),L80,info is %s"%info
            raise exceptions.Unauthorised, 'You do not have permission to %(action)s the %(classname)s class.'%info

    _marker = []
    def hasPermission(self, permission, classname=_marker, itemid=None):
        """Check whether the user has 'permission' on the current class."""                
        if classname is self._marker:
            classname = self.client.classname        
        
        print 'ajaxAction.Action.hasPermission,L89, operator is %s, permission is %s, action name is %s'\
                    %(self.user, permission, self.name)
        
        x = self.db.security.hasPermission(permission, self.client.userid,\
            classname=classname, itemid=itemid)
        
        return x

    def gettext(self, msgid):
        """Return the localized translation of msgid"""
        return self.client.translator.gettext(msgid)

    _ = gettext



class RetireAction(Action):
    name = 'retire'
    permissionType = 'Edit'

    def handle(self):
        """Retire the context item."""
        # if we want to view the index template now, then unset the nodeid
        # context info (a special-case for retire actions on the index page)
        nodeid = self.nodeid
        #if self.template == 'index':
        #    self.client.nodeid = None

        # make sure we don't try to retire admin or anonymous
        if self.classname == 'user' and \
                self.db.user.get(nodeid, 'username') in ('admin', 'anonymous'):
            raise ValueError, self._(
                'You may not retire the admin or anonymous user')

        # do the retire
        self.db.getclass(self.classname).retire(nodeid)
        self.db.commit()

        self.client.ok_message.append(
            self._('%(classname)s %(itemid)s has been retired')%{
                'classname': self.classname.capitalize(), 'itemid': nodeid})
        return nodeid
    
    def hasPermission(self, permission, classname=Action._marker, itemid=None):
        if itemid is None:
            itemid = self.nodeid
        return Action.hasPermission(self, permission, classname, itemid)

class SearchAction(Action):
    name = 'search'
    permissionType = 'View'

    def handle(self):
        """Mangle some of the form variables.

        Set the form ":filter" variable based on the values of the filter
        variables - if they're set to anything other than "dontcare" then add
        them to :filter.

        Handle the ":queryname" variable and save off the query to the user's
        query list.

        Split any String query values on whitespace and comma.

        """
        self.fakeFilterVars()
        queryname = self.getQueryName()

        # editing existing query name?
        old_queryname = self.getFromForm('old-queryname')

        # handle saving the query params
        if queryname:
            # parse the environment and figure what the query _is_
            req = templating.HTMLRequest(self.client)

            url = self.getCurrentURL(req)

            key = self.db.query.getkey()
            if key:
                # edit the old way, only one query per name
                try:
                    qid = self.db.query.lookup(old_queryname)
                    if not self.hasPermission('Edit', 'query', itemid=qid):
                        raise exceptions.Unauthorised, self._(
                            "You do not have permission to edit queries")
                    self.db.query.set(qid, klass=self.classname, url=url)
                except KeyError:
                    # create a query
                    if not self.hasPermission('Create', 'query'):
                        raise exceptions.Unauthorised, self._(
                            "You do not have permission to store queries")
                    qid = self.db.query.create(name=queryname,
                        klass=self.classname, url=url)
            else:
                # edit the new way, query name not a key any more
                # see if we match an existing private query
                uid = self.db.getuid()
                qids = self.db.query.filter(None, {'name': old_queryname,
                        'private_for': uid})
                if not qids:
                    # ok, so there's not a private query for the current user
                    # - see if there's one created by them
                    qids = self.db.query.filter(None, {'name': old_queryname,
                        'creator': uid})

                if qids and old_queryname:
                    # edit query - make sure we get an exact match on the name
                    for qid in qids:
                        if old_queryname != self.db.query.get(qid, 'name'):
                            continue
                        if not self.hasPermission('Edit', 'query', itemid=qid):
                            raise exceptions.Unauthorised, self._(
                            "You do not have permission to edit queries")
                        self.db.query.set(qid, klass=self.classname,
                            url=url, name=queryname)
                else:
                    # create a query
                    if not self.hasPermission('Create', 'query'):
                        raise exceptions.Unauthorised, self._(
                            "You do not have permission to store queries")
                    qid = self.db.query.create(name=queryname,
                        klass=self.classname, url=url, private_for=uid)

            # and add it to the user's query multilink
            queries = self.db.user.get(self.userid, 'queries')
            if qid not in queries:
                queries.append(qid)
                self.db.user.set(self.userid, queries=queries)

            # commit the query change to the database
            self.db.commit()

    def fakeFilterVars(self):
        """Add a faked :filter form variable for each filtering prop."""
        cls = self.db.classes[self.classname]
        for key in self.form.keys():
            prop = cls.get_transitive_prop(key)
            if not prop:
                continue
            if isinstance(self.form[key], type([])):
                # search for at least one entry which is not empty
                for minifield in self.form[key]:
                    if minifield.value:
                        break
                else:
                    continue
            else:
                if not self.form[key].value:
                    continue
                if isinstance(prop, hyperdb.String):
                    v = self.form[key].value
                    l = token.token_split(v)
                    if len(l) > 1 or l[0] != v:
                        self.form.value.remove(self.form[key])
                        # replace the single value with the split list
                        for v in l:
                            self.form.value.append(cgi.MiniFieldStorage(key, v))

            self.form.value.append(cgi.MiniFieldStorage('@filter', key))

    def getCurrentURL(self, req):
        """Get current URL for storing as a query.

        Note: We are removing the first character from the current URL,
        because the leading '?' is not part of the query string.

        Implementation note:
        But maybe the template should be part of the stored query:
        template = self.getFromForm('template')
        if template:
            return req.indexargs_url('', {'@template' : template})[1:]
        """
        return req.indexargs_url('', {})[1:]

    def getFromForm(self, name):
        for key in ('@' + name, ':' + name):
            if self.form.has_key(key):
                return self.form[key].value.strip()
        return ''

    def getQueryName(self):
        return self.getFromForm('queryname')


class LinkCSVAction(Action):
    name = 'linkcsv'
    permissionType = ''

    def handle(self):
        """ CRUD(Create, Read, Update, Delete) the csv format file which is a link property of a class.
        """
        #print 'ajaxActions.LinkCSVAction,L301'
        cn,nodeId = self.client.form['context']
        linkprop = self.client.form['linkprop']
        actiontype = self.client.form['actiontype']
        filename = self.client.form['filename']
        content = self.client.form['content']
        # get class and link property's class
        klass = self.db.getclass(cn)
        linklass_name = klass.getprops()[linkprop].classname
        linklass = self.db.getclass(linklass_name)
        #rows = [[key, content.get(key)] for key in content.keys()]
        rows = [[key, value] for key,value in content.items()]
        if actiontype == 'create':
            # 'create' action must assign a file name
            if not filename:
                self.client.error_message.append('Please assigns a file name to write content.')
                return 
                
            newLinkPropId,fn = create_file(self.db,linklass, filename)
            #print 'ajaxActions.LinkCSVAction,L313, new file node id is %s, name is %s'%(newid, fn)
            klass.set(nodeId,**{linkprop: newLinkPropId})                
            try:
                write2csv(fn, rows)
            except:
                print 'ajaxActions.LinkCSVAction,L317', sys.exc_info()
                
            message = "New user id  %s, info link dossier id %s"%(nodeId, newLinkPropId)
        elif actiontype == 'edit':
            # find the link propterty's value
            linkId = klass.get(nodeId, linkprop)
            fn = get_filepath(self.db, linklass, linkId)            
            try:
                write2csv(fn, rows, 'wb')
            except:
                print 'ajaxActions.LinkCSVAction,edit,L329', sys.exc_info()
            
            # journal the action
            if klass.do_journal:
                self.db.addjournal(cn, nodeId, ''"set", {linkprop:content})
                
            message = 'Edit Successfully!'            
        
        self.db.commit()
        self.client.ok_message.append(message)
        return  message


class EditCSVAction(Action):
    name = 'edit'
    permissionType = 'Edit'

    def handle(self):
        """Performs an edit of all of a class' items in one go.

        The "rows" CGI var defines the CSV-formatted entries for the class. New
        nodes are identified by the ID 'X' (or any other non-existent ID) and
        removed lines are retired.

        """        
        #print 'ajaxAction.EditCSVAction,L334,form is ', self.form
        
        cl = self.db.classes[self.classname]
        idlessprops = cl.getprops(protected=0).keys()
        idlessprops.sort()
        # for 'user' Class, 'password' property is no need to edit
        if 'password' in idlessprops:
            idlessprops.remove('password')
        props = ['id'] + idlessprops

        # do the edit
        # changed by ZG
        rows = StringIO.StringIO(self.form['content'])
        # Change the csv delimiter character to ';'
        reader = csv.reader(rows, delimiter=';')
        found = {}
        line = 0
        for values in reader:
            line += 1
            # extract the nodeid
            nodeid, values = values[0], values[1:]
            #print 'EditCSVAction,L353, nodeid is %s, values are  %s'%(nodeid, values)
            
            found[nodeid] = 1

            # see if the node exists
            if nodeid in ('x', 'X') or not cl.hasnode(nodeid):
                exists = 0
            else:
                exists = 1
        
            #print 'EditCSVAction,L363, idle properties are %s, length is %s, values are %s, length is %s'\
            #            %(idlessprops, len(idlessprops), values, len(values))
            # confirm correct weight
            if len(idlessprops) != len(values):
                self.client.error_message.append(
                    'Not enough values on line %(line)s'%{'line':line})
                return

            # extract the new values
            d = {}
            values = [v or None for v in values]
            for name, value in zip(idlessprops, values):
                prop = cl.properties[name]
                if value:
                    value = value.strip()
                else:
                    value = ''
                # only add the property if it has a value
                #print 'EditCSVAction,L373, prop is %s, value is  %s'%(prop, value)
                if value:
                    # if it's a multilink, split it
                    if isinstance(prop, hyperdb.Multilink):
                        #value = value.split(':')
                        value = value.split(',')
                    elif isinstance(prop, hyperdb.Password):
                        value = password.Password(value)
                    elif isinstance(prop, hyperdb.Interval):
                        value = date.Interval(value)
                    elif isinstance(prop, hyperdb.Date):
                        value = date.Date(value)
                    elif isinstance(prop, hyperdb.Boolean):
                        value = value.lower() in ('yes', 'true', 'on', '1')
                    elif isinstance(prop, hyperdb.Number):
                        value = float(value)
                    d[name] = value
                elif exists:
                    # nuke the existing value
                    if isinstance(prop, hyperdb.Multilink):
                        d[name] = []
                    else:
                        d[name] = None
                        #d[name] = ''

            # perform the edit
            if exists:
                # edit existing
                #print 'EditCSVAction,L401, edit properties values are %s, nodeid is %s'%(d, nodeid)
                cl.set(nodeid, **d)                    
                """
                try:
                    print "EditCSVAction,L409, properties to be set are %s"%d.keys()
                    cl.set(nodeid, **d)                    
                except:
                    print 'EditCSVAction,L411,edit failed', sys.exc_info()
                """
            else:
                # new node
                try:
                    found[cl.create(**d)] = 1
                except:
                    print 'EditCSVAction,L431,create failed', sys.exc_info()

        # retire the removed entries
        for nodeid in cl.list():
            if not found.has_key(nodeid):
                cl.retire(nodeid)

        # all OK
        self.db.commit()
        self.client.ok_message.append('Items edited OK')
        

class EditCommon(Action):
    '''Utility methods for editing.'''

    def _editnodes(self, all_props, all_links):
        ''' Use the props in all_props to perform edit and creation, then
            use the link specs in all_links to do linking.
        '''
        print 'ajaxActions.Actions._editnode(),L445,all_props is %s'%str(all_props)
        
        # figure dependencies and re-work links
        deps = {}
        links = {}
        for cn, nodeid, propname, vlist in all_links:
            numeric_id = int (nodeid or 0)
            if not (numeric_id > 0 or all_props.has_key((cn, nodeid))):
                # link item to link to doesn't (and won't) exist
                continue

            for value in vlist:
                if not all_props.has_key(value):
                    # link item to link to doesn't (and won't) exist
                    continue
                deps.setdefault((cn, nodeid), []).append(value)
                links.setdefault(value, []).append((cn, nodeid, propname))
        
        #print 'ajaxActions.Actions._editnode(),L409,links is %s'%links
        #print 'ajaxActions.EditCommon._editnodes(),L449,deps is ',deps
        # figure chained dependencies ordering
        order = []
        done = {}
        # loop detection
        change = 0
        while len(all_props) != len(done):
            for needed in all_props.keys():
                if done.has_key(needed):
                    continue
                tlist = deps.get(needed, [])
                for target in tlist:
                    if not done.has_key(target):
                        break
                else:
                    done[needed] = 1
                    order.append(needed)
                    change = 1
            if not change:
                raise ValueError, 'linking must not loop!'
            
        #print 'ajaxActions.Actions._editnode(),L485, order is ',order
        #print 'ajaxActions.Actions._editnode(),L470,links is ',links
        # now, edit / create
        m = []
        for needed in order:                        
            props = all_props[needed]            
            cn, nodeid = needed            
            print 'ajaxActions.Actions._editnode(),L492, now class is %s ,nodeid is %s'%(cn,nodeid)  
            print 'ajaxActions.Actions._editnode(),L493, now class props values are ',props
            if props: 
                if nodeid is not None and int(nodeid) > 0:                    
                    # make changes to the node
                    #print 'ajaxActions.Actions._editnode(),L482,'
                    try:
                        props = self._changenode(cn, nodeid, props)
                    except:
                        print 'ajaxActions.Actions._editnode(),L485,',sys.exc_info()
                    # and some nice feedback for the user
                    if props:
                        info = ', '.join(props.keys())
                        m.append( '%(class)s %(id)s %(properties)s edited ok'%{'class':cn, 'id':nodeid, 'properties':info})
                    else:
                        m.append('%(class)s %(id)s - nothing changed'% {'class':cn, 'id':nodeid})
                    #print 'ajaxActions.Actions._editnode(),L488,message is ','\n'.join(m)
                else:
                    assert props
                    # make a new node
                    try:
                        #print 'ajaxActions.Actions._editnode(),L513,classname is %s,properties are %s'%(cn,props)
                        newid = self._createnode(cn, props)
                        print 'ajaxActions.Actions._editnode(),L520, new node id is ',newid
                    except:
                        print 'ajaxActions.Actions._editnode(),L517,error is ',sys.exc_info()
                        newid = None
                    
                    # Auto make a serrial number for this node.
                    # This class must have a String property named 'serial'.
                    if newid and self.form.get('autoSerial'):                        
                        #get date info, include year,month,day,hour,minute                        
                        t = date.Date('.').get_tuple()[:5]                        
                        s = [str(i).zfill(2) for i in t[1:]  ]
                        s.insert(0, str(t[0]))
                        s = ''.join(s)                        
                        #join date and id                         
                        serial = ''.join((cn[0].upper(), s, newid))
                        #print 'ajaxActions.EditCommon._editnodes,L506, serial is ',serial
                        klass = self.db.getclass(cn)
                        klass.set(newid, **{'serial': serial})
                        
                    print 'ajaxActions.Actions._editnode(),L539,classname is %s, newid is %s'%(cn,newid)
                    if self.form.has_key('needId') :
                        self.form['needId'].update({cn:newid})
                    if self.form.has_key('needCreation'):
                        cl = self.db.classes[cn]
                        self.form['needCreation'].update({cn: cl.get(newid,'creation')})
                                       
                    if nodeid is None:
                        self.nodeid = newid
                    nodeid = newid
                    # and some nice feedback for the user
                    m.append('%(class)s %(id)s created' % {'class':cn, 'id':newid})
            
            #print 'ajaxActions.EditCommon._editnodes(),L491,links is ',links            
            try:
                # fill in new ids in links
                if links.has_key(needed) and props:
                    for linkcn, linkid, linkprop in links[needed]:                        
                        props = all_props.get((linkcn, linkid))
                        if not props:
                            continue
                        #props = all_props[(linkcn, linkid)]
                        cl = self.db.classes[linkcn]                    
                        propdef = cl.getprops()[linkprop]
                        if not props.has_key(linkprop):
                            if linkid is None or linkid.startswith('-'):
                                # linking to a new item
                                if isinstance(propdef, hyperdb.Multilink):
                                    props[linkprop] = [newid]
                                else:
                                    props[linkprop] = newid
                            else:
                                # linking to an existing item
                                if isinstance(propdef, hyperdb.Multilink):
                                    existing = cl.get(linkid, linkprop)[:]
                                    existing.append(nodeid)
                                    props[linkprop] = existing
                                else:
                                    props[linkprop] = newid
            except:
                print 'ajaxActions.EditCommon._editnodes(),L574',sys.exc_info()
        
        info = '\r\n'.join(m)
        print'ajaxActions.Actions._editnode(),L582,return info is ',info
        return info

    def _changenode(self, cn, nodeid, props):
        """Change the node based on the contents of the form."""
        print 'ajaxActions.EditCommon._changenode,L582'
        # check for permission
        if not self.editItemPermission(props, classname=cn, itemid=nodeid):
            raise exceptions.Unauthorised, 'You do not have permission to edit %(class)s' % {'class': cn}        
        
        print 'ajaxActions.EditCommon._changenode,L587, cn is %s, nodeid is %s, props are %s'%(cn, nodeid, props)
        # make the changes
        cl = self.db.classes[cn]        
        return cl.set(nodeid, **props)        

    def _createnode(self, cn, props):
        """Create a node based on the contents of the form."""
        print 'ajaxActions.Actions._createnode(),L594'
        # check for permission
        if not self.newItemPermission(props, classname=cn):
            raise exceptions.Unauthorised, 'You do not have permission to create %(class)s' %{'class': cn}

        # create the node and return its id
        print 'ajaxActions.Actions._createnode(),L600',cn,props
        cl = self.db.classes[cn]
        try:
            newid = cl.create(**props)
            print 'ajaxActions.Actions._createnode(),L604, new node id is ',newid
        except:
            newid = None
            print sys.exc_info()
        return newid

    def isEditingSelf(self):
        """Check whether a user is editing his/her own details."""
        return (self.nodeid == self.userid
                and self.db.user.get(self.nodeid, 'username') != 'anonymous')

    _cn_marker = []
    def editItemPermission(self, props, classname=_cn_marker, itemid=None):
        """Determine whether the user has permission to edit this item.

        Base behaviour is to check the user can edit this class. If we're
        editing the "user" class, users are allowed to edit their own details.
        Unless it's the "roles" property, which requires the special Permission
        "Web Roles".
        """
        if self.classname == 'user':
            if props.has_key('roles') and not self.hasPermission('Web Roles'):
                raise exceptions.Unauthorised, self._(
                    "You do not have permission to edit user roles")
            if self.isEditingSelf():
                return 1
        if itemid is None:
            itemid = self.nodeid
        if classname is self._cn_marker:
            classname = self.classname
        if self.hasPermission('Edit', itemid=itemid, classname=classname):
            return 1
        return 0

    def newItemPermission(self, props, classname=None):
        """Determine whether the user has permission to create this item.

        Base behaviour is to check the user can edit this class. No additional
        property checks are made.
        """
        if not classname :
            classname = self.client.classname
        return self.hasPermission('Create', classname=classname)

class EditItemAction(EditCommon):
    def lastUserActivity(self):
        if self.form.has_key(':lastactivity'):
            d = date.Date(self.form[':lastactivity'].value)
        elif self.form.has_key('@lastactivity'):
            d = date.Date(self.form['@lastactivity'].value)
        else:
            return None
        d.second = int(d.second)
        return d

    def lastNodeActivity(self):
        cl = getattr(self.client.db, self.classname)
        activity = cl.get(self.nodeid, 'activity').local(0)
        activity.second = int(activity.second)
        return activity

    def detectCollision(self, user_activity, node_activity):
        '''Check for a collision and return the list of props we edited
        that conflict.'''
        if user_activity and user_activity < node_activity:
            props, links = self.client.parsePropsFromForm()
            key = (self.classname, self.nodeid)
            # we really only collide for direct prop edit conflicts
            return props[key].keys()
        else:
            return []

    def handleCollision(self, props):
        message = self._('Edit Error: someone else has edited this %s (%s). '
            'View <a target="new" href="%s%s">their changes</a> '
            'in a new window.')%(self.classname, ', '.join(props),
            self.classname, self.nodeid)
        self.client.error_message.append(message)
        return

    def handle(self):
        """Perform an edit of an item in the database.

        See parsePropsFromForm and _editnodes for special variables.

        """        
        user_activity = self.lastUserActivity()
        if user_activity:
            props = self.detectCollision(user_activity, self.lastNodeActivity())
            if props:
                self.handleCollision(props)
                return
        props, links = self.client.parsePropsFromForm()
        print 'ajaxActions.EditItemAction.handle,L697,props is %s, links is %s'%(props,links)

        # handle the props
        try:
            message = self._editnodes(props, links)            
        except (ValueError, KeyError, IndexError,
                exceptions.Reject), message:
            self.client.error_message.append('Edit Error: %s' % str(message))
            return

        # commit now that all the tricky stuff is done
        self.db.commit()
        self.client.ok_message.append(message)

class NewItemAction(EditCommon):
    
    def handle(self):
        ''' Add a new item to the database.

            This follows the same form as the EditItemAction, with the same
            special form values.
        '''
        # parse the props from the form
        try:
            try:
                props, links = self.client.parsePropsFromForm(create=1)
            except:
                print 'ajaxActions.NewItemAction(),L704,', sys.exc_info()
            print 'ajaxActions.NewItemAction(),L728,props is %s,links is %s'%(props,links)    
            
            #These properties is really set in the function EditCommon._editnodes().
            if self.form.get('needId') :
                self.form['needId'] = {}  
            if self.form.get('needCreation'):
                self.form['needCreation'] = {}     
               
        except (ValueError, KeyError), message:            
            self.client.error_message.append('Error: %s'% str(message))
            return

        # handle the props - edit or create
        try:
            # when it hits the None element, it'll set self.nodeid
            messages = self._editnodes(props, links)
        #except (ValueError, KeyError, IndexError, exceptions.Reject), message:
        except (ValueError, KeyError, IndexError, exceptions.Reject), message:
            # these errors might just be indicative of user dumbness
            print 'ajaxActions.NewItemAction(),L749,create node error is ',message
            self.client.error_message.append(_('Error: %s') % str(message))
            return

        # commit now that all the tricky stuff is done
        self.db.commit()        
        return messages
    

class PassResetAction(Action):
    def handle(self):
        """Handle password reset requests."""
        
        user = self.form.get('username')
        if not user:
            self.client.error_message.append(\
                "Invalid One Time Key!\n"
                "A Mozilla bug may cause this message to show up erroneously,\n"
                "please check your email!"
            )
            return
        else:
            try:
                uid = self.db.user.lookup(user)
            except KeyError:
                self.client.error_message.append("Unknown username")
                return
            
        # change the password
        newpw = password.generatePassword()
        print 'PassResetAction, new password is %s, user name is %s'%(newpw, user)
        
        try:
            # set the password
            self.db.user.set(uid, password=password.Password(newpw))            
            self.db.commit()
        except (ValueError, KeyError), message:
            self.client.error_message.append(str(message))
            return
        
        self.client.ok_message.append("Password reset successfully!")
        return newpw


class RegisterAction(EditCommon):
    name = 'register'
    permissionType = 'Create'

    def handle(self):
        """Attempt to create a new user based on the contents of the form.
        Return 1 on successful login.
        """        
        # parse the props from the form        
        props = self.client.form['all_props']
        links = []
        
        # registration isn't allowed to supply roles
        user_props = props[('user', None)]
        pwd = user_props.get('password')
        if pwd :
            user_props['password'] = password.Password(pwd)
        if user_props.has_key('roles'):
            raise exceptions.Unauthorised, "It is not permitted to supply roles at registration."

        # skip the confirmation step?
        if self.db.config['INSTANT_REGISTRATION']:            
            # handle the create now
            try:
                # when it hits the None element, it'll set self.nodeid
                messages = self._editnodes(props, links)
                #print 'ajaxAction.RegisterAction,L826, result is ',messages
            except (ValueError, KeyError, IndexError,
                    exceptions.Reject), message:
                # these errors might just be indicative of user dumbness
                print 'ajaxAction.RegisterAction,L831',sys.exc_info()
                self.client.error_message.append(_('Error: %s') % str(message))
                return

            # fix up the initial roles
            self.db.user.set(self.nodeid,
                roles=self.db.config['NEW_WEB_USER_ROLES'])

            # commit now that all the tricky stuff is done
            self.db.commit()

            # finish off by logging the user in
            self.userid = self.nodeid
            return self.userid

        # generate the one-time-key and store the props for later
        for propname, proptype in self.db.user.getprops().items():
            value = user_props.get(propname, None)
            if value is None:
                pass
            elif isinstance(proptype, hyperdb.Date):
                user_props[propname] = str(value)
            elif isinstance(proptype, hyperdb.Interval):
                user_props[propname] = str(value)
            elif isinstance(proptype, hyperdb.Password):
                user_props[propname] = str(value)
        otks = self.db.getOTKManager()
        otk = ''.join([random.choice(chars) for x in range(32)])
        while otks.exists(otk):
            otk = ''.join([random.choice(chars) for x in range(32)])
        otks.set(otk, **user_props)

        # send the email
        tracker_name = self.db.config.TRACKER_NAME
        tracker_email = self.db.config.TRACKER_EMAIL
        if self.db.config['EMAIL_REGISTRATION_CONFIRMATION']:
            subject = 'Complete your registration to %s -- key %s'%(tracker_name,
                                                                  otk)
            body = """To complete your registration of the user "%(name)s" with
%(tracker)s, please do one of the following:

- send a reply to %(tracker_email)s and maintain the subject line as is (the
reply's additional "Re:" is ok),

- or visit the following URL:

%(url)s?@action=confrego&otk=%(otk)s

""" % {'name': user_props['username'], 'tracker': tracker_name,
        'url': self.base, 'otk': otk, 'tracker_email': tracker_email}
        else:
            subject = 'Complete your registration to %s'%(tracker_name)
            body = """To complete your registration of the user "%(name)s" with
%(tracker)s, please visit the following URL:

%(url)s?@action=confrego&otk=%(otk)s

""" % {'name': user_props['username'], 'tracker': tracker_name,
        'url': self.base, 'otk': otk}
        if not self.client.standard_message([user_props['address']], subject,
                body, (tracker_name, tracker_email)):
            return

        # commit changes to the database
        self.db.commit()

        # redirect to the "you're almost there" page
        #raise exceptions.Redirect, '%suser?@template=rego_progress'%self.base

class LogoutAction(Action):
    def handle(self):
        """Make us really anonymous - nuke the cookie too."""
        # log us out
        self.client.make_user_anonymous()

        # reset client context to render tracker home page
        # instead of last viewed page (may be inaccessibe for anonymous)
        self.client.classname = None
        self.client.nodeid = None
        self.client.template = None

class LoginAction(Action):
    def handle(self):
        """Attempt to log a user in.

        Sets up a session for the user which contains the login credentials.

        """
        
        # we need the username at a minimum        
        if not self.form.has_key('username'):
            self.client.error_message.append('Username required')
            return

        # get the login info                
        self.client.user = self.form['username']
        if self.form.has_key('password'):            
            pwd = self.form['password']            
        else:
            pwd = ''
        
        #print 'ajaxAction.LoginAction,L972,user is %s, password is %s'%(self.client.user, pwd)
        pwd = password.Password(pwd)                
        auth = self.verifyLogin(self.client.user, pwd)
        #print 'ajaxAction.LoginAction,L975, the result of authorication is ',auth
        if auth[0] != 1 :
            self.client.make_user_anonymous()                    
        # now we're OK, re-open the database for real, using the user
        self.client.opendb(self.client.user)
        return auth

    def verifyLogin(self, username, password): 
        info = None
        # make sure the user exists
        try:                        
            userid = self.db.user.lookup(username)                        
        except KeyError:
            #raise exceptions.LoginError, self._('Invalid login')
            # 2 means user is invalid
            return (2, 'Invalid Username')
        
        # verify the password
        if not self.verifyPassword(userid, password):
            return (0, 'Invalid Password')
        
        # Determine whether the user has permission to log in.
        # Base behaviour is to check the user has "Web Access".
        if not self.hasPermission("Web Access"):            
            return (3, 'Not has Web Access permission')
        
        roles = self.db.user.get(userid,'roles')
        return (1, 'Login Successfully',roles)
        

    def verifyPassword(self, userid, password):
        '''Verify the password that the user has supplied'''
        # Note,here 'stored' is a instance of roundup.password.Password and has a internal defined method __cmp__.
        stored = self.db.user.get(userid, 'password')         
        #print 'ajaxAction.LoginAction.verifyPassword,L1007,password is %s, stored password is %s'%(password, stored)
        if password == stored:  
            # password is valid 
            return 1
        if not password and not stored:
            # there's no password 
            return 1
        # password is invalid
        return 0
        
    
class ValidToggleAction(Action):
    ''' This Action is used to set the 'valid' property of a class to a toggle 
        value such as True to Flase.
    '''
    name = ''
    permissionType = ''

    def handle(self):        
        ''' Check whether the Member's password is valid.'''                
        cl,nodeid = self.form['context']
        property = self.form['propname']
        tocheck = self.form['tocheck']   
        checktype = self.form['checktype'] 
        klass = self.db.getclass(cl)
        check = klass.get(nodeid,property)
        # check whether the 'tocheck' is the same as stored value in database
        valid = 0
        if check == tocheck:
            valid = 1
        else:
            check = self.db.user.get(self.client.userid, 'password')
            if check == tocheck:
                valid = 1 
        if valid:
            #klass.set(nodeid,**{'valid':0,})
            klass.set(nodeid,**{'valid':checktype,})
            info = ('invalid','valid')
            self.db.commit()
            self.client.ok_message.append( _("The item %s of class %s has been set to %s."\
                                            %(nodeid,cl,info[checktype])))
        else:
            self.client.error_message.append(_("Password Invalid!"))
        return valid
        
class ExportCSVAction(Action):
    name = 'export'
    permissionType = 'View'

    def handle(self):
        ''' Export the specified search query as CSV. '''
        # figure the request
        request = templating.HTMLRequest(self.client)
        filterspec = request.filterspec
        sort = request.sort
        group = request.group
        columns = request.columns
        klass = self.db.getclass(request.classname)

        # full-text search
        if request.search_text:
            matches = self.db.indexer.search(
                re.findall(r'\b\w{2,25}\b', request.search_text), klass)
        else:
            matches = None

        h = self.client.additional_headers
        h['Content-Type'] = 'text/csv; charset=%s' % self.client.charset
        # some browsers will honor the filename here...
        h['Content-Disposition'] = 'inline; filename=query.csv'

        self.client.header()

        if self.client.env['REQUEST_METHOD'] == 'HEAD':
            # all done, return a dummy string
            return 'dummy'

        wfile = self.client.request.wfile
        if self.client.charset != self.client.STORAGE_CHARSET:
            wfile = codecs.EncodedFile(wfile,
                self.client.STORAGE_CHARSET, self.client.charset, 'replace')

        writer = csv.writer(wfile)
        writer.writerow(columns)

        # and search
        for itemid in klass.filter(matches, filterspec, sort, group):
            writer.writerow([str(klass.get(itemid, col)) for col in columns])

        return '\n'

class GetItemAction(Action):
    name = 'getitem'
    permissionType = 'View'
    
    def handle(self):
        ''' Export the values of the specified properties. 
          These properties belong to the specified item of a class.
           Retun a list inluding these values.
        '''       
        # get the class name        
        cl = self.client.classname        
        klass = self.db.getclass(cl)
        # get the nodeid
        id = self.client.nodeid
        # get the properties        
        props = self.client.form.get('propnames')
        #print 'GetItemAction,L1066, id is %s,props is %s'%(id,props)
        # Default,get all the properties of this class
        if not props :
            props = klass.getprops(protected=0).keys()
            props.append('id')
            props.append('creation')
            fetchAll = True
        else:
            fetchAll = False                   
        l2k = self.form.get('link2key')
        #print 'GetItemAction,L1149,link2key is ',l2k
        if l2k == None :
            l2k = True
        values = self.getitem(klass,id,props,link2key=l2k)
        
        if fetchAll :
            # when return all the properties'  values, we'll return a dictionary
            # whose format is {propname: value,...}
            result = {}            
            map(lambda key,value:  result.update({key:value}),props,values)
        else :
            result = values                
        
        #print 'GetItemAction,L1089, result is ',result
        return result
        
    def getitem(self,klass,id,props,link2key=False):
        ''' Return a list which contains the values of specified properties.
          Parameters:
              'klass' : the class instance
              'id' : the id  of the node
              'props' : the properties' name whose values will be get
              'link2key' : if True, the link id will be changed to the corresponding key value of the class          
        '''                        
        row = []            
        # get all the properties and their class
        pperties = klass.getprops()
        # get the Link and Multilink properties 
        if link2key :
            # here used a syntax: (lambda x,y:...)(x,y) 
            link = [(lambda name,prop: 
                    (isinstance(prop,hyperdb.Link)\
                     or isinstance(prop,hyperdb.Multilink))\
                     and name)(name,prop)\
                    for name,prop in pperties.items()]
            #print 'ajaxActions.GetItemAction,L1106,link is ',link
            #filter the False items.
            link = filter(None,link)
        else:
            link = None
        #print 'ajaxActions.GetItemAction,L1116, props is ',props
        for prop in props :            
            try :                
                propvalue = klass.get(id,prop)              
                #print 'ajaxActions.GetItemAction.getitem,L1120,prop is %s,value is %s'%(prop,propvalue)                   
                # if it's a Link property, change the value from id 
                # to link property key value.                                
                if link and (prop in link) and propvalue :                     
                    lkname = pperties[prop].classname                    
                    lklass = self.db.getclass(lkname)                         
                    # get key property of the Link klass
                    kprop = lklass.getkey()                                        
                    if not kprop:
                        # this link class has no key property,so do nothing.
                        pass
                    # get the value of the key property
                    elif isinstance(pperties[prop],hyperdb.Link) :                                                
                        propvalue = lklass.get(propvalue,kprop)                                                                        
                    else: #it's a Multilink property
                        text = []
                        def f(value,t=text):
                            t.append(lklass.get(int(value),kprop))
                        map(f,propvalue)
                        #print 'ajaxActions.GetItem.getitem(),L1095,property is Multilink,text is %s.'%text
                        propvalue = ','.join(text)                    
                
            except KeyError:
                # this might be a new property for which there is
                # no existing value
                if not klass.properties.has_key(propname):
                    raise                 
            except IndexError, message:
                print 'ajaxActions.GetItemAction,L1212', str(message)
                self.client.error_message.append(message)
                raise FormError(str(message))
            row.append(propvalue)
        #print 'ajaxActions.GetItemAction,L1152, row value is ',row
        return row
       

class GetItemsAction(GetItemAction):
    name = 'getitems'
    permissionType = 'View'
    
    def handle(self): 
        ''' Export the specified properties' values with specified ids in the Class, or return all the activated items.
          The input format is :[classname,[properties]]
          The output format is : [[value,...],...]
        '''
        # get the class name        
        cl = self.client.classname        
        klass = self.db.getclass(cl)
        # get all the items value,except for the retired node. 
        ids = self.form.get('ids')
        if not ids :
            if self.form.get('keyvalues'):
                ids = [klass.lookup(key) for key in self.form['keyvalues'].split(',') ]
            else:
                ids = klass.getnodeids(retired=0) 
        
        #ids.sort()                
        if ids == [] :
            #print _("Warning,there is no item of class '%s'.")%cl
            #raise exceptions.NotFound, _("Warning,there is no item of class '%s'.")%cl
            self.client.ok_message.append("Warning,there is no item of class '%s'."%cl)
            return []
        
        # get the specified properties        
        props = self.client.form.get('propnames')
        #print 'GetItemsAction,L1248, ids is %s,props is %s'%(ids,props)
        # Default,get all the properties of this class
        if not props :
            props = klass.getprops(protected=0).keys()
            #fetchall = True        
                           
        l2k = self.form.get('link2key')
        if l2k == None :
            l2k = True
        
        try:
            value = map(lambda id: self.getitem(klass,id,props,link2key=l2k),ids)        
        except:
            print sys.exc_info()
            value = []
        #print 'ajaxActions.GetItemsAction,L1262,return value is ',value
        return value
    

class GetIdbyKeyAction(Action):
    name = ''
    permissionType = ''
    
    def handle(self):
        ''' Return the item id by the value of the key property of a class.
        '''
        id = self.nodeid
        return id
        
    
class GetKeyAction(Action):
    name = ''
    permissionType = ''
    
    def handle(self):
        ''' Return the  name of the key property of a class.
        '''
        # get the class name        
        cl = self.client.classname   
        klass = self.db.getclass(cl)
             
        # Return the name of the key property of this klass       
        key = klass.getkey()
        return key
    
    
class GetKeysAction(Action):
    name = 'getkeys'
    permissionType = 'View'
    
    def handle(self) :
        ''' Get all the values of the key property
           Return a list of values of the key property  of a class.
        '''        
        # get the class name        
        cl = self.client.classname           
        #cl = self.client.form['context']   
        klass = self.db.getclass(cl)           
        return self.getkeys(klass)
    
    def getkeys(self,klass):
        ''' Get allvalues of the key property of a class.
        '''
        # get all the items value,except for the retired node.        
        ids = klass.getnodeids(retired=0) 
        
        if ids == [] :                        
            #raise exceptions.NotFound, _("Warning, class '%s' has no items.")%self.client.classname
            self.client.ok_message.append( _("Warning,there is no item of class '%s'.")%self.client.classname)
            #print 'GetKeysAction,L1185,class is ',klass
            return        
        # get the values of the key property of this class.        
        propname = klass.getkey()  
        values = [klass.get(id,propname) for id in ids]
        return values
    

class GetLinksAction(GetKeysAction):
    name=''
    permissionType = ''
    
    def handle(self):
        ''' Get the key values of the Link class.
        '''
        # get the class name        
        cl = self.client.classname   
        klass = self.db.getclass(cl)
        # get the class of link property
        lpropname = self.client.form['linkprop']
        lklassname = klass.getprops()[lpropname].classname
        lklass = self.db.getclass(lklassname)
        values = self.getkeys(lklass)
        return values


class GetPropvalueAction(Action):
    name = ''
    permissionType = ''
    
    def handle(self):
        ''' Get the property's value by the key value
        '''        
        # get the class name  
        cl = self.client.classname   
        klass = self.db.getclass(cl)             
        # get the property's value
        propname = self.client.form['propname']        
        value = klass.get(self.nodeid,propname)        
        return value
    
class FilterByLinkAction(GetItemAction):
    name = ''
    permissionType = ''
    
    def handle(self):
        ''' Get the items' values by the specified Link property value.
        '''                
        #print 'FilterByLinkAction,L1363,form values are ', self.client.form
        # get Link item id by its key property value
        value = self.client.form['linkvalue']
        #Link Class name
        lcn = self.client.form['linkclass']
        
        #print 'FilterByLinkAction,L1380, link class is %s, link value is %s'%(lcn, value)
        
        lci = self.db.getclass(lcn) # get the Link Class instance
        nid = lci.lookup(value)     # get node id by its 'key' property value
        
        # get class instance
        cn = self.client.classname
        cl = self.db.getclass(cn)
        
        #print 'FilterByLinkAction,L1390, class name is %s, link class id is %s'%(cn, nid)
        
        # get ids of the items of this class, these items has the link property's id
        propname  = self.client.form.get('linkprop')
        if propname :
                tofind = propname
        else:
                tofind = lcn
        arg = {tofind : nid}        
        ids = cl.find(**arg)                
        
        #print 'FilterByLinkAction,L1401, argument is %s, finded ids are %s'%(arg, ids)
        
        # get items'  values        
        props = self.client.form['propnames'] or cl.getprops().keys()
        
        #print 'FilterByLinkAction,L1408, props for class %s are %s'%(cn, props)  
             
        rows = [self.getitem(cl, nid,props,link2key=True) for nid in ids]
        
        #print 'FilterByLinkAction,L1407, result values are  %s'%rows
        
        return rows
        

class GetFileAction(Action):
    name = ''
    permissionType = ''
    
    def handle(self):
        '''  Return the content of  a node  of a constance of FileClass,
           just using FileClass.get() method.                      
        '''
        # get class instance
        #cn = 'file'
        cn = self.form['context']
        cl = self.db.getclass(cn)
        nodeid = self.form['id']        
        content = cl.get(nodeid,'content')
        if content[:5] == 'ERROR':
            self.client.error_message.append(_("File getting failed!"))
            content = None
##        print 'GetFileAction,L1432,file content is ',content
        return content    
        

class FilterByTextAction(Action):
    name = ''
    permissionType = ''
    
    def handle(self):
        ''' 
        Get the item's values by the specified text, 
        search the specified text value in 'Sring' properties and a specified linked files' content,
        matched items will selected and returned.                       
        Returned value is a list, whose sequence is as the argument properties' list sequence.           
        '''        
        cl = self.form['context']
        klass = self.db.getclass(cl)
        props = self.form.get('propnames')
        search = self.form.get('search') or ''
        link2contentProps =self.form.get('link2contentProps') or []
            
        # 'require' is a dictionary which holds the required Sring properties and their values;
        # format is {propname: value,......}
        require = self.form.get('require')        
        
        #print 'ajaxActions.FilterByTextAction,L1433,klass is %s, props are %s, search is %s, require is %s'\
        #            %(klass, props, search,require)
        
        # get  the required nodes' ids of this class
        if require:
            ids = klass.stringFind(**require)
        else:
            ids = klass.list()
        self.form['total'] = len(ids)
        
        print 'FilterByTextAction,L1442, propnames are %s, search value is %s, item ids are %s'%(props, search, ids)
        
        rows = []
        for id in ids:
            row = searchString(klass, id, props, search, link2contentProps)
            if row:
                rows.append(row)                               
        
        print 'FilterByTextAction,L1448, searched result values are ', rows
        
        return rows
 
 
class FilterByFunctionAction(GetItemAction):   
    name = ''
    permissionType = ''
    
    def handle(self):
        ''' Get the item's values by the specified filter function and properties which value will be
           the arguments of the filter function.
           Warning : This Action could be only used on server side.
           Parameters:
               'context' - the class name 
               'propnames' - the properties whose values should be returned
               'filterFn' - a function to filter the item of the class 
               'filterArgs' - the properties' names that should be passed to 'filterFn' as arguments.
                              Note, 'filterArgs' colud be different with 'propnames'.
           returned value is a list, whose sequence is as the argument properties' list sequence.           
        '''        
        cl = self.form['context']
        klass = self.db.getclass(cl)
        props = self.form.get('propnames')
        filterFn = self.form.get('filterFn')
        filterArgs = self.form.get('filterArgs')
        #print "FilterByFunctionAction, L1467, props are %s, filterArgs are %s"%(props, filterArgs)
        result = filter( None, \
                    [ self.judge(klass, nodeid, props, filterFn, filterArgs) for nodeid in klass.list() ]\
                 )
        return result
    
    def judge(self, klass, nodeid, props, filterFn, filterArgs):
        # confirm the properties to inlud filter arguments
        allProps = tuple(set(props).union(set(filterArgs)))
        
        values = self.getitem(klass, nodeid, allProps)
        values = dict(zip(allProps, values))
        args = tuple([values.get(prop) for prop in filterArgs ])
        row = None
        if filterFn(*args):
            row = [values.get(prop) for prop in props ]
        #print "FilterByFunctionAction.judge, L1481"
        return row        
        
        
class FilterByPropValueAction(GetItemAction):
    name = ''
    permissionType = ''
    
    def handle(self):
        ''' Get the items' values by the specified properties' vlaues.'''   
        cl = self.form['context']
        klass = self.db.getclass(cl)
        # Get items' ids that 'filter' value, 
        # whose format is :{'propname': value,...}        
        ids = klass.filter(None,self.form.get('filter'))        
        if ids == [] :            
            raise exceptions.NotFound, _("Warning,there is no item of class '%s'.")%cl
            return
        
        # get the specified properties        
        props = self.form.get('propnames')        
        # Default,get all the properties of this class
        if not props :
            props = klass.getprops(protected=0).keys()
            props.append('id')
            fetchAll = True
        else:
            fetchAll = False           
        
        list = []
        ids.sort() 
        #a transient function for 'map' function calling.
        def f(id) :
            row = self.getitem(klass,id,props,link2key=True) 
            if fetchAll :
                # when return all the properties'  values, we'll return a dictionary whose format is {propname: value,...}
                p2v = {}            
                map(lambda key,value:  p2v.update({key:value}),props,row)
                row = p2v                
            #print 'ajaxActions.FilterByPropValue,L1396, row value is ',row
            return row
                
        return map(f,ids)
    
    
class GetItemsByStringPropAction(GetItemAction):
    name = ''
    permissionType = ''
    
    def handle(self):
        '''  Get items by specified string value of the class's String properties.
            This Action will return the same result as FilterByPropValueAction, 
            but it uses directle sql query not hyperdb.Proptree.That will result
            in a better perfermance.
        '''                 
        cl = self.form['context']
        klass = self.db.getclass(cl)
        #property string, a dictionary holding the values of multiful 'String' properties
        ps = self.form['filter']        
        
        #print "GetItemsByStringPropAction,L1565,the properties and values are ",ps
          
        ids = klass.stringFind(**ps)        
        props = self.form.get('propnames')
        
        #print "GetItemsByStringPropAction,L1571,props are %s, classname is %s, filtered nodes ids are %s"%(props, cl, ids)
        
        if not ids:
            self.client.ok_message.append("Nothig find.")
            return None
        elif props:  
            link2key = self.form.get('link2key')
            #print 'GetItemsByStringPropAction,L1578,link2key is ',link2key
            if self.form.get('needId') == False:
                #values = [self.getitem(klass,id,props) for id in ids]     
                values = [self.getitem(klass,id,props, link2key) for id in ids]     
                #values = [self.getitem(*args) for id in ids]    
                
            else:
                #values = [[id]+self.getitem(klass,id,props) for id in ids]
                values = [[id]+self.getitem(klass,id,props, link2key) for id in ids]
            
            #print "GetItemsByStringPropAction,L1581,filtered values are ", values
            return values
        else:            
            return ids  
    

class NewItemsAction(Action):
    '''Creates more items of a class.'''
    name = ''
    permissionType = ''

    def handle(self):    
        cl = self.form['context']
        klass = self.db.getclass(cl)
        props = self.form.get('propnames')
        # Default,get all the properties of this class
        if not props :
            props = klass.getprops(protected=0).keys()
            props.sort()
            
        values = self.form.get('propvalues')
        ids = self.create_items(klass, props, values)
        # all OK
        self.db.commit()        
        self.client.ok_message.append('Items whose ids are %s have been created successfully!'%','.join(ids))
        return ids
    
    def create_items(self,klass,props,values):
        #a transient function for 'map' function calling.
        def f(rowvalue):
            d={}
            map(lambda p,v: d.update({p:v}),props,rowvalue)                           
            return klass.create(**d)                                 
        ids = tuple(map(f,values))  
        #print 'NewItems.create_items,L1532,created ids are ',ids          
        return ids
            

class AddNodeAction(NewItemsAction,GetItemAction):
    '''Add a node item to a tree class which implement Nested Set Model.'''
    name = ''
    permissionType = ''

    def handle(self):    
        ''' Judge whether the parent node has been in the tree, if True, then 
            it's a 'insert' action, or False, then it's a new tree action.
            The action of creating a new tree:              
            new 'tree' name should be parent node 'id' root node should be 
            (1,parent's id,4,parent's id),the responding property is 
            ('left','node','right','tree') as same as below.
            second node should be (2,node's id,3,parent's id)
            The action of inserting a branch to a tree:
            First, get the parent node and all the nodes whose 'left' is more 
            than the parent node's 'right'.
            Second, insert a node to the parent node.
            Third, add 2 to the 'right' of the parent node.
            Fourth, the 'left' and 'right of the nodes whose 'left' is more than
            the parent node's 'right' will be added 2.
            In the end, save all these nodes to database.
        '''
        cl = self.form['context']
        klass = self.db.getclass(cl)
        nodeinfo = self.form['nodeinfo']
        pnode = nodeinfo[0]
        node = nodeinfo[1]
        
        props = self.form.get('propnames')
        # Default,get all the properties of this class
        if not props :
            props = klass.getprops(protected=0).keys()
            props.append('id')
            props.sort()
        #now props should be ['id','left','node','right','tree']        
        
        #get the id of parent node
        pid = klass.filter(None,{'node': pnode})      
        #print 'AddNodeAction,L1575,pid is %s, pid type is %s'%(pid,type(pid))  
        if pid:     
            #now pid is a list which has only one item,so we just get the '0' item. 
            pid = pid[0]                              
            #First need the 'treename' and 'right' which will be used to insert node.
            #root = klass.get(pid,'tree')
            treename = klass.get(pid,'tree')
            #get parent node's 'right'
            prid = klass.get(pid,'right')                          
            #find all the nodes in this tree by the tree name
            #propspec = {'tree': root}
            propspec = {'tree': treename}
            ids = klass.find(**propspec)            
            ids.sort()        
            #props is changed from ['id','left','node','right','tree'] to be ['id','left','node','right']
            props.pop()
            #get the values of the nodes in this tree
            nodes = map(lambda id: self.getitem(klass,id,props),ids)   
                             
            #insert the new node to the tree
            # call roudup.gui.tree.insert() function            
            branch = [[1,node,2],]
            #print 'AddNodeAction,L1597,branch is %s,nodes is %s'%(branch,nodes)            
            newids = self.add_branch(klass,treename,nodes,prid,branch)
            self.client.ok_message.append(_("New Item whose id is %s have been created successfully!"%newids))
            #print 'InsertNodeAction,L1524, new node has been created,its id is ',newid                        
        else:            
            #props is changed from ['id','left','node','right','tree'] to be
            # ['left','node','right','tree']
            props.pop(0)            
            ids = self.add_tree(klass,pnode,node)
            self.client.ok_message.append(_("New Items whose id are %s have been created successfully!"%','.join(ids)))       
        # all OK
        self.db.commit()
        
    #def add_branch(self,klass,treename,nodes,prid,branch,props):
    def add_branch(self,klass,treename,nodes,prid,branch,new=True):
        ''' 'klass' : the table's name in database
           'treename' : the name of this tree
           'nodes' : the tree nodes
           'prid' : the right value of parent node
           'branch' : the branch to be inserted, which format is [['left','node','right'],...],
           when 'new' is Fasle,'branch' format is [['id','left','node','right'],...]           
        '''        
        props = ['id','left','node','right']
        changenodes,newnodes = tree.insert(nodes,prid,branch,new=new)
        print 'AddNodeAction,L1552,class is %s,treename is %s,\n nodes is %s,\n prid is %s,branch is %s'\
                        %(klass,treename,nodes,prid,branch)
        print 'AddNodeAction,L1553,changenodes is %s,newnodes is %s'%(changenodes,newnodes)        
        
        #a transient function to set the changed nodes' value to database.
        def f(row,p):            
            #popup the 'id' and its value
            id = row.pop(0)      
            #print 'AddNodeAction,L1561,value is %s,properties are %s'%(row,p)
            #construct the property and value dictionary         
            d={}
            map(lambda prop,v: d.update({prop:v}),p,row) 
            #print 'AddNodeAction,L1565,the value of changed nodes is %s,id is %s'%(d,id)                    
            klass.set(id,**d)                                      
            print 'AddNodeAction,L1568,the value of changed nodes is %s,id is %s'%(d,id)
            return     
        # Now,'changenodes' format is ['id','left','node','right'], 
        # popup 'node' property
        [i.pop(-2) for i in changenodes]           
        map(f,changenodes,len(changenodes)*[('left','right'),])
        
        if new :
            # 'newids' stored the new created ids        
            newids = []        
            # create the new node          
            # a transient function to create new item in 'klass'
            def create_new(values):                
                d = {}
                map(lambda p,v: d.update({p:v}),['left','node','right','tree'],values)
                print 'AddNodeAction,L1581,the nodes to be created are ',d
                newids.append(klass.create(**d))     
            # Here, newnodes format is ['left','node','right']
            # append treename to each item of newnodes.
            [i.append(treename) for i in newnodes]
            map(create_new,newnodes)                      
            res = newids
        else:            
            print 'AddNodeAction,L1590,properties are ',props
            # 'props' format is ['id','left','node','right'].
            # First,popup 'node'
            map(props.remove,('id','node'))                        
            # Second,append 'tree' to properties
            props.append("tree")                          
            print 'AddNodeAction,L1596,properties are ',props            
            # 'branch' format is ['id','left','node','right'].            
            # popup 'node' value of each item in branch
            [i.pop(-2) for i in branch]                        
            # append treename to each item in branch
            [i.append(treename) for i in branch]   
            print 'AddNodeAction,L1602,branch is  ',branch
            try:
                map(f,branch,len(branch)*(props,))
            except :
                print "Unexpected error:", sys.exc_info()
                raise
            res = None
        return res
    
    #def add_tree(self,klass,pnode,node,props):
    def add_tree(self,klass,pnode,node):
        ''' 'klass' : the table's name in database
          'pnode' :  the 'node' value of parent node         
          'node'  :   the 'node' value of node          
          'props' format is ['lef','node','right','tree']
        '''
        props = ['left','node','right','tree']
        #ctreate new tree and nodes,first the root node
        nodes = [['1',pnode,'4',pnode],
                        ['2',node,'3',pnode]
                       ]
        print 'AddNodeAction.add_tree,L1604,nodes is %s,props is %s'%(nodes,props)
        ids = self.create_items(klass,props,nodes)     
        return ids           


class ChangeParentNodeAction(AddNodeAction):
    '''Change the parent of  a node and resorder the tree which implement Nested
       Set Model.
    '''
    name = ''
    permissionType = ''

    def handle(self):    
        '''
        '''       
        cl = self.form['context']
        klass = self.db.getclass(cl)
        nodeinfo = self.form['nodeinfo']
        # new parent node 'id'
        pnode = nodeinfo[0]
        # id of the node whose parent will be changed to 'pnode'
        cnode = nodeinfo[1]        
        # get the name of the class which holds the 'serial' property
        scn = self.form.get('serial_class')
        if scn:
            sklass = self.db.getclass(scn)
        
        props = self.form.get('propnames')
        # Default,get all the properties of this class
        if not props :
            props = klass.getprops(protected=0).keys()
            props.append('id')
            props.sort()
        #now props should be ['id','left','node','right','tree']     
        
        ids = klass.getnodeids(retired=0) 
        ids.sort()
        #print 'ChangeParentNodeAction,L1660,tree ids is ',ids
        forest = map(lambda id: self.getitem(klass,id,props),ids)
        tree_ids = [i[2] for i in forest]          
        
        # 'pv' -> parent node's properties'  value, 
        # 'v'->the propertites' value of the node to  be inserted
        pv,v = (None,None)
        # 'nit' means node id in tree ids,'pit' means new parent node id in tree ids. 
        nit,pit = ('0','0')
        if pnode in tree_ids:
            # new parent node has been in a tree
            pit = '1'
            # get the tree that new parent node located
            id = klass.filter(None,{'node': pnode})[0]                  
            pv = self.getitem(klass,id,['left','right','tree'])            
            
        if cnode in tree_ids :
            # the node to be moved has been a node of a tree
            nit = '1'
            # get the branch from the old tree
            id = klass.filter(None,{'node': cnode})[0]                                         
            v = self.getitem(klass,id,['left','right','tree'])
            v = [int(v[0]),int(v[1]),v[2]]            
            if pv and pv[-1] == v[-1]:
                # The node and its new parent are in the same tree,they will be
                # proceeded later.
                pass
            else:
                # Proceed the nodes in the old tree.
                # Reset the 'left' or 'right' value of the nodes in the old 
                # tree,these nodes include the ancestors of the node to bemoved
                # and the nodes whose 'left' value is less than the node to be 
                # moved.
                oldtree_name = v[-1]
                oldtree_ids = klass.filter(None,{'tree': oldtree_name})
                oldtree = map(lambda id: self.getitem(klass,id,\
                                        ['id','left','node','right']),oldtree_ids)
                oldtree.sort(key=lambda i: int(i[1]))           
                
                #--------------Get the branch to be moved-----------------------
                # get the branch to be deleted from this tree                   
                branch = filter(lambda i:int(i[1]) >=int(v[0])\
                                         and int(i[-1]) <= int(v[1]),\
                                oldtree)                       
                base = int(v[0])-1
                
                # Now set the 'left' and 'right' to calculate from base
                [map(lambda i: n.__setitem__(i,int(n[i])-base),(1,3)) \
                for n in branch]
                # Change the value of 'node' in branch from id to [name,serial],
                #  so the format of branch has been changed from from 
                #  ['id','left','node','right'] 
                #  ---> ['id','left',['name','serial','valid'],'right']
                props = ('name','serial','valid')
                map(lambda i: i.__setitem__(2,self.getitem(sklass,i[2],props)),\
                    branch)
                #---------------------------------------------------------------
                                
                # Get all the nodes whose 'left' or 'right' is more than the 
                # 'right' value of the node and subtract (rigth-left+1) from them.
                # 'toChange' means the nodes who needs reset their 'left' or 
                # 'right' ids.
                # 'toDel' means the nodes that should be retired from this table.
                if len(oldtree) == 2 and int(v[0]) != 1:
                    # It's a two nodes tree,when the single child will be removed,
                    # this tree should be deleted.
                    toChange = []
                    toDel = oldtree[0]                    
                else:
##                    toChange = filter(lambda i: int(i[1]) > int(v[1]) \
##                                                or int(i[-1]) > int(v[1]),\
##                                      oldtree)
                    toChange = filter(lambda i: int(i[-1]) > int(v[1]),\
                                      oldtree)

                    # Node is a root node in the old tree,so nothing need to be 
                    # deleted.
                    toDel = None
                    
                if toChange:                    
                    # Popup the 'node' property
                    [n.pop(-2) for n in toChange]
                    base = int(v[1])-int(v[0])+1                    
                    for n in toChange:
                        index = filter(lambda i: int(n[i]) > v[1],(1,-1))                        
                        map(lambda i: n.__setitem__(i,str(int(n[i])-base)),index)
                    
                    # set the values of these nodes to database  
                    try:
                        map(lambda n: klass.set(n[0],**{'left':n[1],'right':n[-1]}),toChange)
                    except:
                        print sys.exc_info()                    
                elif toDel:
                    id = toDel[0]
                    klass.retire(id)                
  
        # Here 'type' is a tag to show the type of tree's action.
        # '00'-> neither parent id nor node id in tree ids.
        # '10'-> parent id in tree ids, node id not in tree ids.
        # '01'-> parent id not in tree ids, node id in tree ids.
        # '11'-> both parent id and node id in tree ids.
        type = pit+nit        
        # holds the data which will be return
        data = {}
        ok_msg = None
        if type == '00':            
            if pnode:
                newids = self.add_tree(klass,pnode,cnode)                                                       
                ok_msg = _("New items of 'mtree' whose id are %s have been created successfully!"%','.join(newids))
            else:                
                ok_msg = _("Nothing needs change!")
                
        elif type == '01':            
            if pnode:                                
                # Now branch format is 
                # [['id','left',('name','serial),'right'],...]
                # add 1 to both left and right of each item in branch
                [map(lambda i: n.__setitem__(i,str(int(n[i])+1)),(1,3))\
                 for n in branch]                   
                                          
                # set the changed 'left' ,'right' and 'tree'  value of each node
                # in branch to database                
                map(lambda n : \
                    klass.set(n[0],**{'left': n[1],'right': n[-1],'tree': pnode}),\
                    branch)         
        
                # popup the 'id' value of each item in branch
                [n.pop(0) for n in branch]
                # create the first node of the new tree, the 'node' property value of this root is 'pnode' .
                props = ['left','node','right','tree']
                nodes = [['1',pnode,str((len(branch)+1)*2),pnode],]                
                newids = self.create_items(klass,props,nodes)                                      
                ok_msg = _("New items of 'mtree' whose id are %s have been created successfully!"%','.join(newids))                                 
            else:
                if len(branch) == 1:
                    # Just deletes this node from 'mtree'
                    id = branch[0][0]
                    klass.retire(id) 
                    # popup the 'id' value of each item in branch
                    [n.pop(0) for n in branch]
                    ok_msg = _("The item whose id is %s has been retired."%id)                   
                else:
                    # Just append this branch to the root,that means this branch
                    # has been changed to be a tree.
                    # set the changed 'left' ,'right' and 'tree'  value of each 
                    # node in branch to database
                    for n in branch:
                        d = {'left': str(n[1]),\
                             'right': str(n[-1]),\
                             'tree': str(cnode)}
                        klass.set(n[0],**d)
                    ids = [n.pop(0) for n in branch]                                        
                    ok_msg = _("A new tree named %s has been created successfully! That tree has nodes with ids %s "%(cnode,','.join(ids)))
            data['branch'] = branch    
        elif type == '10':                                    
            treename = pv[-1]
            #get parent node's 'right'            
            prid = pv[-2]
            # get tree
            nodes = filter(lambda i : i[-1] == treename,forest)
            # popup the last value-'tree' from each item of the tree.            
            [i.pop(-1) for i in nodes]
            # Now the item format has been set to ['id','left','node','right']            
            # set the branch            
            branch = [[1,cnode,2],]                                                                    
            newids = self.add_branch(klass,treename,nodes,prid,\
                                     copy.deepcopy(branch))            
            ok_msg = _("New items of 'mtree' whose id are %s have been created successfully!"%','.join(newids))
            # change the value of 'node' in branch from id to [name,serial]
            map(lambda i: i.__setitem__(1,self.getitem(sklass,i[1],['name','serial'])),branch)
            data['branch'] = branch        
        else:
            # type is '11'
            # 'v' and 'pv' format is ['left','right','tree']
            # set the 'left' and 'right' value to be int type
            [map(lambda i:  n.__setitem__(i,int(n[i])),(0,1))  for n in (v,pv)]                                   
            if v[-1] == pv[-1]:
                # The node and new parent are in the same tree.
                # get the tree
                treename = v[-1]
                nodes = filter(lambda i : i[-1] == treename,forest)
                nodes.sort(key=lambda i: int(i[1]))                
                # popup the last value-'tree' from each item of the tree.            
                [i.pop(-1) for i in nodes]
                # Now the item format has been set to ['id','left','node','right']     
                # set the 'left' and 'right' value to be int type
                [map(lambda i:  n.__setitem__(i,int(n[i])),(1,-1))  for n in nodes]                
                groupstore = [[],[],[],[],[],[]]                 
                def group(s):
                    # 'v' and 'pv' format is ['left','right','tree']
                    if s[1] <= min(v[0],pv[0]) and s[-1] >= max(v[1],pv[1]):
                        # This node is the ancestor of both the old and the new
                        # parent, we have to select this node and do nothing to 
                        # it to invoid that it'll be select by other conditions.
                        pass
                    elif s[1] >= v[0] and s[-1] <= v[1]:
                        # select all the nodes of the branch to be moved
                        groupstore[3].append(s)                        
                    elif s[1] < v[0] and s[-1]  > v[1]:
                        # select all the old ancestors of the node
                        groupstore[1].append(s)                        
                    elif s[1] <= pv[0] and s[-1] >=pv[1]:
                        # select all the ancestors of the new parent node 
                        groupstore[0].append(s)                        
                    elif s[1] > pv[0] and s[-1] < pv[1]:
                        # select all the nodes including by the new parent
                        groupstore[4].append(s)                        
                    elif s[1] > min(v[1],pv[1])  and s[-1] < max(v[0],pv[0]):
                        # select all the nodes between the node and the new parent
                        groupstore[2].append(s)                        
                    else:
                        groupstore[5].append(s)
                # filter the node in 'nodes' to the corresponding group
                map(group,nodes)                        
                try:
                    # fiter the elder children of old node
                    t = []
                    # the first right item of group[0] is the old parent node
                    if groupstore[0] and groupstore[5]:                        
                        oldparent = groupstore[0][-1]
                        for node in groupstore[5]:
                            if node[1]>oldparent[1] and node[-1]<oldparent[-1]:
                                t.append(node)
                    if t:
                        groupstore[5] = t
                    else:
                        groupstore[5] = []       
                except:
                    print 'ChangeParentNodeAction,L1908,',sys.exc_info()
                
                #----get the branch to be moved---------------------------------
                # Get the branch to be returned to client first for 'groupstore'\
                # will be changed in the next steps.
                #branch = copy.deepcopy(groupstore[3])
                # this 'base' is used to set the branch 'left id' starting from '1'
                base = v[0] - 1
                # Now set the 'left' and 'right' to calculate from base.
                [map(lambda i: n.__setitem__(i,n[i]-base),(1,3)) for n in groupstore[3]]
                
                # now branch format is ['id','left','node','right'],
                # 'id' is not need
                branch = copy.deepcopy(groupstore[3])
                map(lambda n: n.pop(0),branch)                
                
                # Change the value of 'node' in branch from id to [name,serial],
                #  so the format of branch has been changed from 
                #  ['left','node','right']--->['left',['name','serial'],'right']                
                map(lambda i: i.__setitem__(1,self.getitem(sklass,i[1],\
                                            ['name','serial','valid'])),branch)
                
                # 'branch' will be returned to gtk.TreeWidget to render the \
                # treeview widget again.
                #---------------------------------------------------------------
                
                # change the format from ['id','left','node','right'] to \
                # ['id','left','right']                
                [map(lambda n: n.pop(-2),group) for group in groupstore]
                
                # Here 'base' means the base number of the nodes of the moved 
                # branch.
                base = v[1]-v[0]+1                
                map(lambda i: i.__setitem__(2,i[2]+base),groupstore[0])                
                map(lambda i: i.__setitem__(2,i[2]-base),groupstore[1])
                
                if groupstore[0]:
                    if v[0] < pv[0]:
                        # the node left value is no more than parent node left 
                        # value,so move the branch backward.
                        for i in (0,2,4):
                            [map(lambda i: n.__setitem__(i,n[i]-base),(1,2)) \
                                 for n in groupstore[i]]
                        
                    else:
                        # the node 'left' value is than parent node 'left' value,\
                        # so move the branch forward.
                        for i in (1,2,5):
                            [map(lambda i: n.__setitem__(i,n[i]+base),(1,2)) \
                                 for n in groupstore[i]]
                    [map(lambda i: n.__setitem__(i,n[i]-base-1+groupstore[0][-1][2]),(1,2))\
                        for n in groupstore[3]] 
                else: 
                    #print 'ChangParentNodeAction,1971,groupstore is ',groupstore                   
                    [map(lambda i: n.__setitem__(i,n[i]-base-1+pv[1]),(1,2))\
                        for n in groupstore[3]] 
                    
                    for node in groupstore[4]:                           
                        if node[-1]>v[1]:
                             map(lambda i: node.__setitem__(i,node[i]-base),(1,2))                    
                    
                    for node in groupstore[5]:
                        if node[-1]>v[1]:
                             map(lambda i: node.__setitem__(i,node[i]-base),(1,2))
                    #print 'ChangParentNodeAction,1982,groupstore is ',groupstore
                
                # set 'left' and 'right' value of the nodes in the branch to be 
                # moved                                                                        
                
                # now join all the group to a list
                toSet = []
                map(lambda l: toSet.extend(l),groupstore)
                [map(lambda i: n.__setitem__(i,str(n[i])),(1,2)) for n in toSet]
                
                #a transient function to set the nodes' value to database.
                def f(values):            
                    props = ('left','right')
                    id = values.pop(0)                    
                    #construct the property and value dictionary         
                    d={}
                    map(lambda p,v: d.update({p:v}),props,values)                    
                    #only set the node's 'left' or 'right' value and return the ids.               
                    try:
                        klass.set(id,**d)                                             
                    except:
                        print "Unexpected error:", sys.exc_info()
                        raise
                    return     
                map(f,toSet)                
                
            else:
                # The node and new parent are in different trees,
                # so we need to move the branch from the old tree to the new tree.
                # Because we have got this branch from the old tree, 
                # and the old tree has already been set,
                # now we just need to insert this branch to the new parent node.
                treename = pv[-1]
                #get parent node's 'right'                
                prid = pv[-2]
                # get tree
                nodes = filter(lambda i : i[-1] == treename,forest)
                # popup the last value-'tree' from each item of the tree.            
                [i.pop(-1) for i in nodes]
                # Now the item format has been set to ['id','left','node','right']                            
                # set the branch                                                                                
                newids = self.add_branch(klass,treename,nodes,prid,\
                                            copy.deepcopy(branch),new=False)
                
                #print "ChangeParentNodeAction,L1774, new created nodes' ids is ",newids
                if newids:
                    ok_msg = _("New items of 'mtree' whose id are %s have been created successfully!"%','.join(newids))
                else:
                    ok_msg = _("Some items of 'mtree' have been moved from one tree to another tree!")
                map(lambda i: i.pop(0),branch)
                
            data['branch'] = branch                                
        if ok_msg:
            self.client.ok_message.append(ok_msg)
        data['type'] = type
        # all OK
        self.db.commit()        
        # retrun what to client?a branch of tree?
        return data        
    

class GetTreeAction(GetItemAction):
    name = ''
    permissionType = ''
    
    def handle(self):
        '''  Get all the tree data from two tables in the database.
        '''                 
        cn = self.form['context']
        klass = self.db.getclass(cn)
        #The props should be ['id','name',parent],here parent means a property name point to the parent.
        props = self.form.get('propnames')
        #print 'GetTreeAction,L1615,classname is %s,class is %s,properties is %s'%(cl,klass,props)
        # Default,get all the properties of this class
        if not props :
            props = klass.getprops(protected=0).keys()
            props.append('id')
            props.sort()
        #get the klass' properties data
         # get all the items value,except for the retired node.        
        ids = klass.getnodeids(retired=0)         
        #sort ids so the items will be shown in ascend order by the  created date.
        ids.sort(key=lambda i: int(i))        
        #print 'ajaxActions,L1050,ids is %s,ids type is %s '%(ids,type(ids))        
        if not ids :            
            self.client.ok_message.append( _("Warning,there is no item of class '%s'."%cn))
            return
        
        data = map(lambda id: self.getitem(klass,id,props),ids)        
        #get tree path data
        tcn = self.form.get('tree')
        tklass = self.db.getclass(tcn)
        tprops = ['left','node','right','tree']        
        ids = tklass.getnodeids(retired=0) 
        ids.sort(key=lambda i: int(i))   
        #print 'GetTreeAction,L1640,ids is ',ids
        if ids == [] :
            treedata = None            
        else :
            treedata = map(lambda id: self.getitem(tklass,id,tprops),ids)
        self.client.ok_message.append( _("the data in class %s and tree class %s\
                                            has been got."%(cn,tcn)))
        return (data,treedata)
        

class CalculateAction(Action):
    name = ''
    permissionType = ''
    
    def handle(self):
        '''  This action is used to calculate some properties' values of a class.
        '''                 
        cn,id = self.form['context']
        klass = self.db.getclass(cn)      
        
        # 'p2v' format: [['property name','action type','property value'],...]
        p2v = self.form.get('propvalue')
        d = self.calculate(klass,id,p2v)
        self.client.ok_message.append( _("The item %s of class %s has been set."%(id,cn)))
        return (cn,id,d)
    
    def calculate(self,klass,id,p2v):
        d = {}
        for prop,action,value in p2v:          
            print 'CalculateAction.calculate,L2143,prop is %s,action is %s,value is %s'%(prop,action,value)             
            old = klass.get(id,prop)
            if not old :
                old = 0            
            if action == '+':
                new = int(old + float(value))
            else:
                new = int(old - float(value))
            d.update({prop : new})
        #print 'CalculateAction,L2026,new dict is ',d
        klass.set(id,**d)
        self.db.commit()
        return d
    
            
class TransferValueAction(Action):
    ''' This Action is used to transfer the value of a item of a class to another
        item of this class.
    '''
    
    name = ''
    permissionType = ''

    def handle(self):        
        ''' Check whether the Member's password is valid.'''                        
        cl,nodeid = self.form['context']        
        pwd = self.form['password']   
        type = self.form['type'] 
        prop2value = self.form['prop2value']
        klass = self.db.getclass(cl)
        property = self.form['checkprop']
        store = klass.get(nodeid,property)
        # check whether the 'tocheck' is the same as stored value in database
        valid = 0
        if pwd == store:
            valid = 1
        else:
            store = self.db.user.get(self.client.userid, 'password')
            if pwd == store:
                valid = 1 
        
        if valid:
            if type == 'new':                
                try:
                    klass.set(nodeid,**prop2value)                 
                except:
                    print sys.exc_info()                                    
                self.db.commit()
                self.client.ok_message.append(_("The value of item %s of \
                                                class %s has been changed."\
                                                %(nodeid,cl)))
        else:
            self.client.error_message.append(_("Old Password Invalid!"))
        return valid
        
        
class VirementAction(GetItemAction):
    name = ''
    permissionType = ''
    
    def handle(self):
        '''  A virement action used to transfer amount from one to another.
        '''                 
        cn = self.form['context']
        klass = self.db.getclass(cn)      
        
        # 'p2v' format: [['id','property name','action type',
        #               'property value'],...]
        p2v = self.form.get('propvalue')
        #print 'CalculateAction,L2018,p2v is ',p2v
        d = []
        for key,prop,action,value in p2v:            
            id = klass.lookup(key)
            old = klass.get(id,prop)
            if not old :
                old = 0            
            if action == '+':
                new = old + value
            else:
                new = old - value                      
            #print 'CalculateAction,L2026,new dict is ',d
            klass.set(id,**{prop:new})
            d.append({prop : new})
        self.db.commit()        
        return d
     

class MultiLinkAction(Action):
    name = ''
    permissionType = ''
    
    def handle(self):
        '''  A action used to append new link id to the Multilink property of a calss.
        '''                 
        #print 'MultiLinkAction,L2305,self.form is ',self.form
        cn,id = self.form['context']
        klass = self.db.getclass(cn)            
        # 'p2v' format: [['property name','action type','property value'],...]
        p2v = self.form.get('propvalue')        
        d = self.linkaction(klass,id,p2v)        
        self.client.ok_message.append( _("The item %s of class %s has been set."%(id,cn)))
        return (cn,id,d)
    
    def linkaction(self,klass,id,p2v):
        d = {}        
        for prop,action,value in p2v:                                   
            #print 'MultiLinkAction.linkaction,L2337,changed link ids are ',value
            old = klass.get(id,prop)            
            if not old :
                old = []
            if action == '+':
                old.extend(value)
            else:
                for i in value:
                    if i in old :
                        old.remove(i)
            d.update({prop : old})        
        klass.set(id,**d)
        self.db.commit()
        return d
        
class GetItemsBySqlAction(Action,  GetItemAction):
    name = ''
    permissionType = ''
    
    def handle(self):
        '''  A action used to find the items by sql 'Select' clause.
        '''                 
        #print 'GetItemsBySqlAction,L2349,self.form is ',self.form
        cn = self.form['context']
        klass = self.db.getclass(cn)           
        conditions = self.form['conditions']
        if not conditions:
            return None
        
        props = self.form.get('propnames')
        sql_type = self.form['sql_type']
        sql = ''
        if sql_type == 'LIKE':            
            c = []
            for cond in conditions:                            
                if len(cond) == 3:
                    # format like (property name, property value, 'AND' or 'OR')
                    searchTxt = ''.join(('\'%', cond[1], '%\''))
                    c.append(' %s '%cond[2] + ''.join(('_'+cond[0],' LIKE ', searchTxt)))                    
                else:
                    # format like (property name, property value), 
                    # this format is offten used in the first item of "condition" list
                    c.append(''.join(('_'+cond[0],' LIKE ','\'%', cond[1],'%\'')))
                    
                #print 'GetItemsBySqlAction,L2318,sql clause is %s'%c
            sql = ' ' .join((sql, ' '.join(c)))
            #print 'GetItemsBySqlAction,L2397,sql clause is %s'%sql
        elif sql_type in ('AND', 'OR'):
            c = []
            for k,v in conditions.items():                            
                if type(v) == type([]):
                    # one property corresponding to multiful values
                    map(lambda i: c.append(''.join(('_'+k,'=','\'',i,'\''))),v)
                else:
                    # one property corresponding to one value
                    c.append(''.join(('_'+k,'=','\'',v,'\'')))
            #print 'GetItemsBySqlAction,L2403,sql_type is %s, clause is %s'%(sql_type,c)            
            prep = ''.join((' ', sql_type, ' '))
            sql = ' ' .join((sql, prep.join(c)))
                
        prefix = ' '.join(('SELECT','id','FROM', '_'+cn, 'WHERE'))        
        sql = ' '.join((prefix,sql))
        #print 'GetItemsBySqlAction,L2334,Final sql clause is ',sql
        try:
            ids = klass.filter_sql(sql)
        except:
            ids = None
            print sys.exc_info()        
        if ids:
            ids = [i[0] for i in ids]
        else:
            self.client.ok_message.append(_("There is no query result."))            
        res = ids
        if props:
            res = [self.getitem(klass,id,props,link2key=True) for id in ids]
        #return ids
        return res


class StringPropEditAction(Action):
    name = ''
    permissionType = ''
    
    def handle(self):
        '''  A action used to add/replace/delete some value in a property whose type is String class .
            Now assumes that the separated symbol is comma ( ',') .
        '''                 
##        print 'StringPropEditAction,L2427,self.form is ',self.form
        cn = self.form['context']
        klass = self.db.getclass(cn)
        stringSep = ','
        for item in self.form.get('data'):
            key, action,prop,value = item[:4]
##            print 'StringPropEditAction,L2432,key is %s,action is %s,prop is %s,value is %s'%item[:4]
            id = klass.lookup(key)     
            oldValue =klass.get(id,prop)
##            print 'StringPropEditAction,L2435,node id is %s, old value is %s'%(id,oldValue)
            if action == 'add':
                # append new value to the old value                
                if oldValue:
                    newValue = stringSep.join((oldValue, value))
                else:
                    newValue = value
##                print 'StringPropEditAction,L2436,add action, new value is ',newValue
            elif action == 'delete':                
                # delete the value from the old value
                oldValue = oldValue.split(stringSep)                
                oldValue.remove(value)
                newValue = stringSep.join(oldValue)
            elif action == 'replace':                
##                print 'StringPropEditAction,L2445',
                # replace some partial  value in the old value
                oldValue = oldValue.split(stringSep)
                for i, v in enumerate(oldValue):
                    if value.split('-')[:-1] == v.split('-')[:-1]:
                        oldValue[i] = value
                        break
                newValue = stringSep.join(oldValue)

            klass.set(id,**{prop : newValue,})
        self.db.commit()
        self.client.ok_message.append(_("Edit String Property Action Successfully!"))
    
class GetItemByLinkPropValueAction(Action, GetItemAction):
    name = ''
    permissionType = ''
    
    def handle(self):
        '''  A action used to add/replace/delete some value in a property whose type is String class .
        '''                 
        #print 'GetItemByLinkPropValueAction,L2490,self.form is ',self.form
        cn = self.form['context']
        klass = self.db.getclass(cn)
        # get link id that has the filter property value
        link = self.form['linkprop']
        p2v = self.form['filter']        
        props = klass.getprops(protected=0)        
        lklassname = props[link].classname
        lklass = self.db.getclass(lklassname)        
        target_id = lklass.stringFind(**p2v)        
        res = None
        if target_id:
            target_id = target_id[0]        
            #print 'GetItemByLinkPropValueAction,L2501, target_id is ',target_id         
            # search the corresponding id of klass
            ids = klass.getnodeids(retired=0)                     
            for id in ids:            
                linkvalue = klass.get(id, link)
                #print 'GetItemByLinkPropValueAction,L2509,link property value is %s,type is %s'%(linkvalue,type(linkvalue))            
                if linkvalue == target_id:
                    props = props.keys()                
                    props.append('id')
                    props.append('creation')                                
                    values = self.getitem(klass,id,props,link2key=True)
                    res = {}
                    [res.update({prop : propvalue}) for prop, propvalue in zip(props,values)]
                    break        
        self.client.ok_message.append(_("Search Action Successfully!"))
        #print 'GetItemByLinkPropValueAction,L2517, action result is ',res
        return res


def get_filepath(db,fileclass, id):
    #filepath = fileclass.exportFilename(db.dir,id)
    subdir_filename = db.subdirFilename(fileclass.classname, id)
    #print ajaxActions.create_file, L2414, subdir_filename is ',subdir_filename
    filepath = os.path.join(db.dir, 'files', fileclass.classname, subdir_filename)
    return filepath

def create_file(db,fileclass,filename):
    ''' Create a empty data file whose format is csv.
    '''        
    props = {'name': filename,'content': '','type': 'text/csv'}
    try:
        id = fileclass.create(**props)
        db.commit()
    except:
        print 'ajaxActions.create_file(),L2518',sys.exc_info()
        id = None
    
    filepath = get_filepath(db, fileclass, id)
    
    return (id,filepath)
        
def write2csv(filename,content, mode='ab'):
    ''' Append the data to the csv file.
        filename - the csv file's name
        content - a list or tuple contains lists or tuples to write to csv file.
        mode - 'a' means append the content to the file, 'b' means binarary, 'w' mease overwrite the file
    '''
    f = open(filename, mode)
    writer = csv.writer(f) 
    writer.writerows(content)
    f.close()  

def searchString(klass, nodeid, props, search='', link2contentProps=[]):
    ''' Get properties values of a class, if the property is linked to a FileClass,
       return file content.
    '''
    print 'ajaxActions.searchString, L2541, class is %s, nodeid is %s, props are %s, search is %s'\
          %(klass,nodeid, props, search)
    row = []          
    properties = klass.getprops()  
    for prop in props:
        instance = properties[prop] 
        classtype = instance.__class__.__name__
        #print 'ajaxAction,L2555, class type is ', instance.__class__.__name__
        if classtype in ('Link', 'Multilink'):
            cn = instance.classname
            lklass = klass.db.getclass(cn)            
            # get the linked node id of this item
            linkid = klass.get(nodeid, prop)
            print 'ajaxAction,L2490, link class name is %s, link class is %s, link ids are %s '%(cn, lklass, linkid)
            if not linkid:
                # no linked file, set the content to null
                content = '' or linkid
            elif not prop in link2contentProps:
                if type(linkid) in (type(()), type([])):
                    content = ','.join(linkid)
                else:
                    content = linkid
            elif lklass.properties.has_key('content'):
                # for FileClass, append the 'content' of the file
                if type(linkid) in ( type([]), type(())):
                    content = [lklass.get(i, 'content') for i in linkid ]
                    content = '\n'.join(content)
                elif type(linkid) == type(''):                    
                    content = lklass.get(linkid, 'content')
                else:
                    content = ''
            else:
                keyprop = lklass.getkey()
                if type(linkid) != type([]):
                    ids = linkid.split(',')
                else:
                    ids = linkid
                content = [lklass.get(id, keyprop) for id in ids ]
                content = ','.join(content)                                   
            row.append(content)
            print 'ajaxAction,L2506, searched row value is ', row            
        elif classtype == 'String' :
            row.append(klass.get(nodeid,prop))
            print 'ajaxAction,L2509, searched row value is ', row
        else:
            try:
                row.append(str(klass.get(nodeid,prop)))
            except:
                row.append('')
    print 'ajaxAction,L2515, searched row value is ', row
    
    # search the text in the item of this row
    # join all the item in this row to a string for judging handyly
    row = [i or '' for i in row]
    target = ''.join(row)
    print 'ajaxAction,L2521, searched value is %s, target is %s'%(target, search)
    if not target:
        row = []
    elif search not in target:
        row = []    
    return row

def serial2id(serial):
    ''' Parse the serial and filter the real node id.
    The 1~13 bits of the serial is constructed as below:
        1- the first letter of the class name, this letter is upper.
        2~5 - the creation year of the item
        6~7 - the creation moth of the item
        8~9 - the creation day of the item
        10~11 - the creation hour of the item
        12~13 - the creation minute of the item
    The 14~end bits is the real node id of this item.
    '''
    id = serial[13:]
    return id
    
# vim: set filetype=python sts=4 sw=4 et si :
