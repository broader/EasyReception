import sys
import os

class Config:

    pass

# ugly hacks to make "import k_sessions" work
karrigell_dir = os.path.dirname(os.path.dirname(__file__))
sys.path.append(os.path.join(karrigell_dir,"core"))

import k_sessions
session_dir = os.path.join(os.getcwd(),"sessions")
if not os.path.exists(session_dir):
    os.mkdir(session_dir)
#for _file in os.listdir(session_dir):
#    os.remove(os.path.join(session_dir,_file))

config = Config()
config.data_dir = os.getcwd()
config.max_sessions = 10

config.persistent_sessions = True
for i in range(20):
    k_sessions.make_session_object(config,60)

config.persistent_sessions = False
for i in range(20):
    k_sessions.make_session_object(config,60)
