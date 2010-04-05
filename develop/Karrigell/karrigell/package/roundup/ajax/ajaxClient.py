# $Id$

""" ajax request handler
"""
__docformat__ = 'restructuredtext'

import base64, binascii, cgi,codecs,os,copy
import random, re, rfc822, stat, time
import socket, errno
import sys

from roundup import roundupdb, date, hyperdb, password
from roundup.exceptions import *
from roundup.mailer import Mailer, MessageSendError

#import ajaxExceptions as exceptions
from ajaxActions import *
from ajaxExceptions import *
from FormParser import FormParser



def initialiseSecurity(security):
    '''Create some Permissions and Roles on the security object

    This function is directly invoked by security.Security.__init__()
    as a part of the Security object instantiation.
    '''
    p = security.addPermission(name="Web Access",
        description="User may access the web ajax interface")
    security.addPermissionToRole('Admin', p)    

    # doing Role stuff through the web - make sure Admin can
    # TODO: deprecate this and use a property-based control
    p = security.addPermission(name="Web Roles",
        description="User may manipulate user Roles through the web")
    security.addPermissionToRole('Admin', p)


class Client:
    '''Instantiate to handle one ajax request.

    See inner_main for request processing.

    Client attributes at instantiation:    
    - "form" is  a dictionary including all the request fields.     
    - "translator" is TranslationService instance

    During the processing of a request, the following attributes are used:

    - "error_message" holds a list of error messages
    - "ok_message" holds a list of OK messages    
    - "user" is the current user's name
    - "userid" is the current user's id    
    - "classname" is the current class context name
    - "nodeid" is the current context item id

    User Identification:
     If the user has no login name which should be set in the 'form' , 
     then they are anonymous and are logged in as that user. 
     This typically gives them all Permissions assigned to the
     Anonymous Role.
    '''

    # charset used for data storage and form templates
    # Note: must be in lower case for comparisons!
    # XXX take this from instance.config?
    STORAGE_CHARSET = 'utf-8'

    def __init__(self, instance, form=None):
        # re-seed the random number generator
        random.seed()
        self.start = time.time()        
        self.instance = instance
                
        #self.setTranslator(translator)
        self.mailer = Mailer(instance.config)        
        self.form = form
                
        # turn debugging on/off
        try:
            self.debug = int(form.get("ROUNDUP_DEBUG", 0))
        except :
            # someone gave us a non-int debug level, turn it off
            self.debug = 0
        
        # default character set
        #self.charset = self.STORAGE_CHARSET
              
        self.user = None
        self.userid = None
        self.nodeid = None
        self.classname = None
        self.db_open = 0
        
        
    def main(self):
        ''' Wrap the real main in a try/finally so we always close off the db.
        '''
        #New added variable to roundup's program,for set the return data structure.
        self.response = {} 
        self.response['success'] = 0 
        self.ok_message = []
        self.error_message = []      
        # This attribute is added to judge which type of error is happening.
        # Not in roundup
        self.error_type = None 
        try:
            res = self.inner_main()
            if res or self.ok_message:     
                self.response['data'] = res
                self.response['success'] = 1
                if self.ok_message:
                    self.response['ok'] = '\r\n'.join(self.ok_message)
            else:                
                err = ''
                if self.error_message:                    
                    for x in self.error_message :
                        err = err + str(x)                
                self.response['error'] = err                
            
        except :
            print 'ajaxClient,L123',sys.exc_info()            
        finally:
            if hasattr(self, 'db'):                
                self.closedb()            
            print 'ajaxClient,L127, response is ', self.response
            return self.response

    def inner_main(self):
        '''
        '''        
        try:                            
            print 'ajaxClient.Client.inner_main,L135, form is ', self.form
            self.determine_user()
            #print 'ajaxClient.Client.inner_main,L137'
            # figure out the object class this client action for.
            self.determine_context()         
            #print 'ajaxClient.Client.inner_main,L139'
            
            # possibly handle a form submit action (may change self.classname
            # and self.template, and may also append error/ok_messages)
            try:
                data = self.handle_action()  
                #print 'ajaxClient.Client.inner_main,L146', data
            except :
                err = sys.exc_info()
                print 'ajaxClient.inner_main,L149,error is ',err
                self.error_message.append(err)
                data = None
            return data                        

        except SeriousError, message:
            self.error_message.append(str(message))        
            
        except Unauthorised, message:
            self.error_message.append("You has no authority.")
        except NotFound, e:
            try:
                cl = self.db.getclass(self.classname)
                self.error_message.append("There is no query result for %s"%cl)
            except KeyError,e:
                # we can't map the URL to a class we know about
                # reraise the NotFound and let roundup_server
                # handle it
                self.error_message.append(str(e))
        except FormError, e:
            self.error_message.append('Form Error: ' + str(e))            
        except e:
            self.error_message.append(str(e))

    def determine_user(self):
        """Determine who the user is"""          
        #print 'ajaxClient.determine_user,L174,self.form is ', self.form
        self.opendb('admin')                
        #print 'ajaxClient.determine_user,L176,self.form is ', self.form
        
        # For ajax client, get user information from the form fields.
        # Add by ZG.
        user = self.form.get('user', None) or self.user
        
        # if no user name set by http authorization or session cookie
        # the user is anonymous        
        if not user:
            user = 'anonymous'        
        
        # sanity check on the user still being valid,
        # getting the userid at the same time
        try:
            self.userid = self.db.user.lookup(user)
        except (KeyError, TypeError):
            user = 'anonymous'

        # make sure the anonymous user is valid if we're using it
        if user == 'anonymous':
            self.make_user_anonymous()
            if not self.db.security.hasPermission('Web Access', self.userid):
                raise Unauthorised, "Anonymous users are not allowed to use the web interface"
        else:
            self.user = user
                
        # reopen the database as the correct user        
        self.opendb(self.user)

    def opendb(self, username):
        """Open the database and set the current user.

        Opens a database once. On subsequent calls only the user is set on
        the database object the instance.optimize is set. If we are in
        "Development Mode" (cf. roundup_server) then the database is always
        re-opened.
        """
        #print 'ajaxClient.opendb,L213'
        #print 'ajaxClient.opendb, L214, self.db_open is %s, '%self.db_open       
                
        # don't do anything if the db is open and the user has not changed
        if hasattr(self, 'db') and self.db_open == 1 and self.db.isCurrentUser(username):            
            return
        
        # open the database or only set the user
        if not hasattr(self, 'db'):
            try:
                self.db = self.instance.open(username)            
            except:
                print 'ajaxClient.opendb, L226', sys.exc_info()
        else:
            if self.instance.optimize:
                self.db.setCurrentUser(username)
            else:
                self.db.close()
                self.db = self.instance.open(username)
        
        # Added status signal,for reopening db needs.
        self.db_open = 1
        #print 'ajaxClient.opendb, L230'
        
    def closedb(self):        
        self.db.close()
        self.db_open = 0
    
    def determine_context(self):
        """Determine the object class of this client's action.
        """
        # default the optional variables
        self.classname = None
        self.nodeid = None                
        
        # the context format is :(class,nodeid)
        # example:('user',1)        
        if self.form.get('context') and isinstance(self.form['context'],type('')):
            self.classname = self.form['context']            
        elif self.form.get('context')  and isinstance(self.form['context'],type(())):
            self.classname = self.form['context'][0]                        
            self.nodeid = self.form['context'][1]       
        
        # make sure the classname is valid
        #print "ajaxClient.determine_context,L256, classname is ", self.classname
        if self.classname is not None:
            try:
                klass = self.db.getclass(self.classname)                
                if self.form.has_key('link2id') :                    
                    # 'v' format: (link class name,link property value, link property name)
                    v = self.form['link2id']
                    #get link class
                    lclass = self.db.getclass(v[0])
                    #get the item id of link class
                    lnodeid = lclass.lookup(v[1])                    
                    #get the node id of self.klass
                    lk_prop = v[2]                    
                    arg = {lk_prop: lnodeid}                   
                    #self.nodeid = klass.find(serial=lnodeid)[0]                    
                    self.nodeid = klass.find(**arg)[0]                                        
                    self.form['context'] = (self.classname,self.nodeid)
                elif self.form.has_key('keyvalue'):                    
                    self.nodeid = klass.lookup(self.form['keyvalue'])                    
                    self.form['context'] = (self.classname,self.nodeid)           
                
                #print "ajaxClient.determine_context,L277, self.form is ", self.classname
                
                if self.form.has_key('all_props') and self.nodeid :
                    all_props = self.form['all_props']
                    for key,value in all_props.items():                        
                        if key[0] == self.classname :
                            #change {('classname',None): ...} to {('classname',nodeid): ...}
                            new = {(self.classname,self.nodeid):copy.deepcopy(value)}
                            del all_props[key]
                            all_props.update(new)
                    #print 'ajaxClient.Client.determine_context,L287,all_props is %s'%self.form['all_props']                    

            except KeyError:
                raise NotFound, self.classname
        return
    
    # these are the actions that are available
    actions = (
        ('edit',        EditItemAction),
        ('editcsv',     EditCSVAction),
        ('new',         NewItemAction),
        ('register',    RegisterAction),        
        ('passrst',     PassResetAction),
        ('login',       LoginAction),
        ('logout',      LogoutAction),
        ('search',      SearchAction),
        ('retire',      RetireAction),
        ('export_csv',  ExportCSVAction),
        ('getitem',    GetItemAction),
        ('getitems',    GetItemsAction),
        ('getkey',      GetKeyAction),
        ('getkeys',    GetKeysAction),
        ('getlinks',   GetLinksAction),
        ('getpropvalue',  GetPropvalueAction),
        ('filterbylink',   FilterByLinkAction),
        ('getfile', GetFileAction),
        ('filterbyprop', FilterByPropValueAction),
        ('gibs', GetItemsByStringPropAction),
        ('getid', GetIdbyKeyAction),
        ('newitems', NewItemsAction),
        ('addnode', AddNodeAction),
        ('changeparent', ChangeParentNodeAction),
        ('gettree', GetTreeAction),
        ('calculate', CalculateAction),
        ('invalid',ValidToggleAction),
        ('transfer',TransferValueAction),
        ('virement',VirementAction),
        ('link', MultiLinkAction),
        ('getbysql', GetItemsBySqlAction),
        ('editstringprop', StringPropEditAction),
        ('getbylinkvalue', GetItemByLinkPropValueAction),
        ('linkcsv', LinkCSVAction),
        ('filtertext', FilterByTextAction),
        ('filterfunction', FilterByFunctionAction))
        
    def handle_action(self):
        ''' Determine whether there should be an Action called.

            The action is defined by the form variable :action which
            identifies the method on this object to call. The actions
            are defined in the "actions" sequence on this class.

            Actions may return a page (by default HTML) to return to the
            user, bypassing the usual template rendering.

            We explicitly catch Reject and ValueError exceptions and
            present their messages to the user.
        '''
        if self.form.has_key('action'):
            action = self.form['action'].lower()
            #print 'ajaxClient.handle_action,L337,action_class is %s'%action
        else:
            #return None
            return
        
        #Add to determine the action for client
        self.response['action'] = action
        
        try:            
            action_klass = self.get_action_class(action)           
            #print 'ajaxClient.handle_action,L346,action_class is %s'%action_klass            
            # call the mapped action
            #print 'ajaxClient.handle_action,L353,action class will be excuted'
            return action_klass(self).execute()
        #except (ValueError, Reject), err:
        #    self.error_message.append(str(err))
        except ValueError, err:
            self.error_message.append(str(err))
        except Reject, err:
            self.error_message.append(str(err))
            self.error_type = 1

    def get_action_class(self, action_name):                                   
        # First,try to find whether there is tracker defined action.
        if (hasattr(self.instance, 'ajax_actions') and
                self.instance.ajax_actions.has_key(action_name)):
            #print 'GUIClient.get_action_action,L602'
            # tracker-defined action
            action_klass = self.instance.cgi_actions[action_name]
        else:            
            # go with a default            
            for name, action_klass in self.actions:
                if name == action_name:
                    break
            else:
                raise ValueError, 'No such action "%s"'%action_name             
        return action_klass
   
    def set_user(self, name):
        ''' Set the Client's user to the new name and open database using this new
        user name. This is a new added method for ajax actions.
        '''
        if not name :
            self.make_user_anonymous()
        else:
            self.user = name
        #print 'ajaxClient.Client.set_user,L392, client user is ',self.user        
        self.opendb(name)
   
    def make_user_anonymous(self):
        ''' Make us anonymous

            This method used to handle non-existence of the 'anonymous'
            user, but that user is mandatory now.
        '''
        if not hasattr(self, 'db'):
            self.opendb('anonymous')
            
        self.user = 'anonymous'
        #self.userid = self.db.user.lookup('anonymous')        
            
    
    def parsePropsFromForm(self, create=0):         
        return FormParser(self).parse(create=create)

# vim: set et sts=4 sw=4 :
