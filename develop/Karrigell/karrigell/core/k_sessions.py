"""Session management module
"""
import os
import sys
import time
import datetime
import cPickle
import random
import string


class SessionObject(object):

    def __init__(self, expires=15,session_id=None):
        """Create a session object. If it has not been reset in the last
        "expires" minutes it is removed from the database the next time
        it is opened"""
        self._expires = datetime.timedelta(0, expires*60, 0)
        self._timestamp = datetime.datetime.now()
        if session_id is None :
            self._id = generate_random(16)
        else:
            self._id = session_id
        self.session_id = self._id
        self.sessionId = self._id # compatibility with Karrigell 2.x
            
    def set_timestamp(self):
        self._timestamp = datetime.datetime.now()

    def close(self):
        self._expires = 0
        for name in dir(self):
            if not name in dir(SessionObject) +['_expires','_timestamp','_id']:
                delattr(self,name)

#***************************
# Memory sessions management
#***************************
def make_session_object_memory(config,expires):
    config.rlock.acquire()
    session_obj = SessionObject(expires)
    save_session_object_memory(config, session_obj)
    config.rlock.release()
    return session_obj

def get_session_object_memory(config,session_id,expires):
    config.rlock.acquire()
    try:
        session_obj = config.session_objects[session_id]
    except KeyError:
        session_obj = SessionObject(expires,session_id)
        save_session_object_memory(config, session_obj)
    config.rlock.release()
    return session_obj
        
def save_session_object_memory(config, session_obj):
    config.rlock.acquire()
    remove_old_sessions_memory(config)
    session_obj.set_timestamp() # Object is kind of new since is has just been used
    config.session_objects[session_obj._id] = session_obj
    config.rlock.release()

def remove_old_sessions_memory(config):
    config.rlock.acquire()
    nbsessions = len(config.session_objects)
    if nbsessions > config.max_sessions*1.2:
        sdict = {}
        # first, remove timed-out sessions
        now = datetime.datetime.now()
        for s_obj in config.session_objects.values():
            t_delta = now - s_obj._timestamp
            if t_delta > s_obj._expires :
                del config.session_objects[s_obj._id]
                nbsessions -= 1
            else:
                sdict[s_obj._id] = t_delta
        if nbsessions > config.max_sessions*1.2:
            # then remove 20% oldest sessions
            delta_times = sdict.values()
            delta_times.sort()
            remove_delta_time = delta_times[config.max_sessions]
            for s_id in sdict:
                if sdict[s_id] > remove_delta_time:
                    del config.session_objects[s_id]
    config.rlock.release()

#*******************************
# Persistent sessions management
#*******************************
def make_session_object_persistent(config,expires):
    config.rlock.acquire()
    session_obj = SessionObject(expires)
    save_session_object_persistent(config, session_obj)
    config.rlock.release()
    return session_obj

def get_session_object_persistent(config,session_id,expires):
    config.rlock.acquire()
    path = os.path.join(config.data_dir,"sessions",session_id)
    try:
        session_obj = cPickle.load(open(path,"rb"))
    except IOError:
        session_obj = SessionObject(expires,session_id)
        save_session_object_persistent(config,session_obj)
    config.rlock.release()
    return session_obj

def save_session_object_persistent(config, session_obj):
    config.rlock.acquire()
    remove_old_sessions_persistent(config)
    session_obj.set_timestamp() # Object is kind of new since is has just been used
    path = os.path.join(config.data_dir,"sessions",session_obj._id)
    try :
        s = cPickle.dumps(session_obj,cPickle.HIGHEST_PROTOCOL)
        out = open(path,"wb")
        out.write(s)
        out.close()
        config.rlock.release()
    except cPickle.PicklingError:
        config.rlock.release()
        msg = "Pickling error - "
        msg += "only built-in types can be saved in persistent sessions"
        raise ValueError,msg
       
def remove_old_sessions_persistent(config):
    # if number of sessions exceeds max_sessions by 20%, remove the
    # 20% oldest sessions
    config.rlock.acquire()
    listdir = os.listdir(os.path.join(config.data_dir,"sessions"))
    nbsessions = len(listdir)
    if nbsessions > config.max_sessions*1.2:
        sdict = {}
        now = datetime.datetime.now()
        for s_id in listdir:
            path = os.path.join(config.data_dir,"sessions",s_id)
            #t_delta = now - datetime.datetime.fromtimestamp(os.stat(path).st_atime)
            s_obj = cPickle.load(open(path,"rb"))
            t_delta = now - s_obj._timestamp
            if t_delta > s_obj._expires :
                # remove timed-out sessions
                os.remove(path)
                nbsessions -= 1
            else:
                sdict[s_obj._id] = t_delta
        if nbsessions > config.max_sessions*1.2:
            # then remove 20% oldest sessions
            delta_times = sdict.values()
            delta_times.sort()
            remove_delta_time = delta_times[config.max_sessions]
            for s_id in sdict:
                if sdict[s_id] > remove_delta_time:
                    os.remove(os.path.join(config.data_dir,
                        "sessions",s_id))
    config.rlock.release()
 
        
#******        
# utils
#******
def generate_random(length):
    """Return a random string of specified length
    Code by David Leung found on Active State site"""
    chars = string.ascii_letters + string.digits
    newpasswd = ""
    for i in range(length):
        newpasswd = newpasswd + random.choice(chars)
    return newpasswd

def trace(msg):
    # for debugging
    sessions = get_sessions()
    sys.stderr.write(msg+"\n")
    for _id,obj in sessions.iteritems():
        sys.stderr.write("%s: %s\n" %(_id,str(obj.__dict__)))

def init_config_session(config):
    # Create path where session files are stored
    path = os.path.join(config.data_dir,"sessions")
    if not os.path.exists(path):
        os.mkdir(path)
        
    #print config.server_type, config.__file__, config.host_name
    
    if config.server_type == "Multiprocess" and \
       config.persistent_sessions == False:
        print "\nUsing non persistent sessions", \
              "with multiprocess server is not safe"

    # Init config with session data
    config.session_objects = {}
    if config.persistent_sessions:
        #print host_name, "persistent"
        config.make_session_object = make_session_object_persistent
        config.get_session_object  = get_session_object_persistent
        config.remove_old_sessions = remove_old_sessions_persistent
        config.save_session_object = save_session_object_persistent
    else:
        #print host_name, "memory"
        config.make_session_object = make_session_object_memory
        config.get_session_object  = get_session_object_memory
        config.remove_old_sessions = remove_old_sessions_memory
        config.save_session_object = save_session_object_memory
        
        

