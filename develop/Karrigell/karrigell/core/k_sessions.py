"""Session management module
"""
import os
import sys
import time
import cPickle
import random
import string
import threading
import k_config
#from collections import deque

slock = threading.Lock()

for host_name,config in k_config.config.iteritems() :
    path = os.path.join(config.data_dir,"sessions")
    if not os.path.exists(path):
        os.mkdir(path)

class LimitedDict(dict):
    """A dictionary which deletes the oldest elements if there are
       more than maxKeys keys"""
    
    def __init__(self,max_keys):
        dict.__init__(self)
        if  not isinstance(max_keys,int) :
            max_keys= 1000
        self.max_keys= max_keys
        self.keys = list()
        
    def __setitem__(self,key,value):
        dict.__setitem__(self,key,value)
        self.keys.append(key)
        if len(self.keys)>self.max_keys:
        		try:
        			first = self.keys.pop(0)
        			del self[first]
        		except:
        			print 'The session key %s is not existed ! now first session id in session pool is %s'%(first,self.keys[0])

class SessionObject(object):

    def __init__(self, expires = 15):
        """Create a session object. If it has not been reset in the last
        "expires" minutes it is removed from the database the next time
        it is opened"""
        self._expires = expires
        self._timestamp = time.time()

    def set_timestamp(self):
        self._timestamp = time.time()

    def close(self):
        self._expires = 0

# dictionary used if session management is in memory
# indexed by the host config object
memory_sessions = {}

def remove_old_sessions(config):
    if not config.persistent_sessions:
        if config in memory_sessions:
            #nbsessions = len(memory_sessions[config].keys())
            # add by ZG
            #print config
            #print memory_sessions[config]
            #print memory_sessions[config].keys
            nbsessions = len(memory_sessions[config].keys)
            # add end
            if nbsessions > config.max_sessions*1.2:
                    for session_id,s_obj in memory_sessions[config].iteritems():
                        if s_obj._timestamp + s_obj._expires < time.time():
                            del memory_sessions[config][sessions_id]
    else:
        # if number of sessions exceeds max_sessions by 20%, remove the
        # 20% oldest sessions
        nbsessions = len(os.listdir(os.path.join(config.data_dir,"sessions")))
        if nbsessions > config.max_sessions*1.2:
            sdict = {}
            for s_id in os.listdir(os.path.join(config.data_dir,"sessions")):
                path = os.path.join(config.data_dir,"sessions",s_id)
                s_obj = cPickle.load(open(path,"rb"))
                exp_time = s_obj._timestamp + s_obj._expires
                if exp_time < time.time():
                    # remove timed-out sessions
                    os.remove(path)
                    nbsessions -= 1
                else:
                    sdict[s_id] = exp_time
            if nbsessions > config.max_sessions*1.2:
                # remove 20% oldest sessions
                times = sdict.values()
                times.sort()
                remove_time = times[-config.max_sessions]
                removed = 0
                for s_id in sdict:
                    if sdict[s_id] < remove_time:
                        os.remove(os.path.join(config.data_dir,
                            "sessions",s_id))
                        removed += 1

def get_session_object(config,session_id,expires):
    if config.persistent_sessions:
        remove_old_sessions(config)
        path = os.path.join(config.data_dir,"sessions",session_id)
        try:
            session_obj = cPickle.load(open(path,"rb")) 
            
        except IOError:
            session_obj = SessionObject(expires)
            save_session_object(config,session_id,session_obj)
    else:
        if config in memory_sessions \
            and session_id in memory_sessions[config]:
            return memory_sessions[config][session_id]
        else:
            session_obj = SessionObject(expires)
            if not config in memory_sessions:
                memory_sessions[config] = LimitedDict(config.max_sessions)
            memory_sessions[config][session_id] = session_obj
    return session_obj

def make_session_object(config,expires):
    session_id = generate_random(16)
    session_obj = SessionObject(expires)
    save_session_object(config,session_id,session_obj)
    remove_old_sessions(config)
    return session_id,session_obj

def save_session_object(config,session_id,session_obj):
    if config.persistent_sessions:
        path = os.path.join(config.data_dir,"sessions",session_id)
        slock.acquire()
        out = open(path,"wb")
        cPickle.dump(session_obj,out,cPickle.HIGHEST_PROTOCOL)
        out.close()
        slock.release()
    else:
        if not config in memory_sessions:
            memory_sessions[config] = LimitedDict(config.max_sessions)
        memory_sessions[config][session_id] = session_obj
        
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

