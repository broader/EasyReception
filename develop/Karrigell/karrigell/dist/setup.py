import os
import sys
import tempfile
import zipfile

# customize these lines for your application
app_name = "MyKarrigellApplication"
version = "1.0"
author = "Pierre Quentel",
author_email = "pierre.quentel@gmail.com"
# choose the built-in server
server = "Karrigell.py"

from distutils.core import setup
import py2exe

# ugly hacks to make "import Karrigell" work
this_dir = os.path.dirname(__file__)
server_dir = os.path.dirname(os.path.dirname(os.path.dirname(__file__)))
sys.path.append(server_dir)
os.chdir(server_dir)
sys.argv[0] = os.path.join(server_dir,"Karrigell.py")
sys.argv.append(server_dir)

# aaah !
import Karrigell
conf = Karrigell.k_config.config[None]
cache_dir = conf.cache_dir

del sys.argv[-1]
sys.argv.append('-q')
sys.argv.append('py2exe')

temp_dir = tempfile.mkdtemp()
excluded = [".pyc",".pdl",".bat",".sqlite"]
data_files = []

def is_valid(filename):
    base,ext = os.path.splitext(filename)
    if ext.lower() in excluded:
        return False
    if ext == '.dat' and base != "translations":
        return False
    return True

for dirpath,dirnames,filenames in os.walk(os.getcwd()):

    if dirpath == cache_dir:
        continue
    if dirpath.endswith('.svn'):
        del dirnames[:]
        continue
    _dirpath = dirpath[len(os.getcwd())+1:]
    filenames = [ os.path.join(dirpath,f)[len(os.getcwd())+1:]
        for f in filenames 
        if is_valid(f) ]
    data_files.append((_dirpath,filenames))

setup(
    name = app_name,
    version = version,
    author = author,
    author_email = author_email,
    license = "BSD",
    options = {'py2exe':
            {'bundle_files':1,
             'includes':['mimetypes','Cookie','cgi','shutil','gzip',
                'sqlite3','csv','ConfigParser'],
             'packages':['email'],
             'dist_dir':temp_dir}
        },
    data_files = data_files,
    console = [{"script":server}
        ]
    )

path = os.path.join(temp_dir)

exe = zipfile.ZipFile("%s-%s.zip" %(app_name,version),"w",
    zipfile.ZIP_DEFLATED)
for dirpath,dirnames,filenames in os.walk(path):
    if dirpath == path:
        filenames = [ f for f in filenames
            if not f=="setup.py"
            and not (os.path.splitext(f)[1]==".py" and f.startswith("Karrigell"))]
    for f in filenames:
        f_path = os.path.join(dirpath,f)
        exe.write(f_path,os.path.join(app_name,f_path[len(path)+1:]))
exe.close()

# cleanup server dir
build_dir = os.path.join(server_dir,'build')
if os.path.exists(build_dir):
    import shutil
    shutil.rmtree(build_dir)