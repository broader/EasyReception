"""
A simple module for delivering one-shot CAPTCHA challenges and processing
user responses, suited for web site usage.
This module is partlly written by David McNab <david@rebirthing.co.nz>,
the captcha image creating functions is digested from 
http://code.activestate.com/recipes/440588/
"""
# ------------------------------------------------
# configuration items - set these here, or set them
# as module attributes when you import the module

# replace with your own gibberish
captchaSecretKey = "fR9^%tvHh2[+0_fxxhv$d(*rf!f$vns"

# timeout for the user to reply to the challenge
captchaTimeout = 3600

# ------------------------------------------------

import sys, os, StringIO, sha, base64, traceback
import random, time, tempfile
import Image, ImageFont, ImageDraw, ImageFilter

class Captcha(object):
## A Captcha class
	def __init__(self, stringSize=6, fontsize=25, font='VeraIt.ttf'):
		#self.reldir = relpath 	
		self.fontsize = fontsize
		self.font = font		
		self.stringSize = stringSize
		# create the captcha string
		self.answer = self.get_string(self.stringSize)
		self.imgdir = 'captcha_bg_images'
		# create Image instance
		self.im = self.get_image(self.answer)		
	
	def get_image(self, text):
		return self.gen_captcha(text)
		
	def get_string(self, size):
		# 'size' should be a int number
		return self._random_string(size)
			
	def _random_string (self, size) :
        	#Return a random string.
        	#The random string shall consist of small letters, big letters
        	# and digits.
        	letters = "abcdefghijklmnopqrstuvwxyz"
        	letters += "0123456789"

        	# The random starts out empty, then 40 random possible characters
        	# are appended.
        	random_string = ''
        	for i in range (size):
            		random_string += random.choice (letters)

        	# Return the random string.
        	return random_string
        
	        
        def get_bg_img(self):
		'''Return a random background image from the fixed directory.'''
		imgdir = self.imgdir
		# get the absolute path  
		path = getPath(imgdir)				
		fnames = os.listdir(path)	
		
		i = random.randint(0, len(fnames)-1)
		fname = os.path.join(path, fnames[i])		
		im = Image.open(fname)
		return im	

	def gen_captcha(self, text):
		"""Generate a captcha image"""		
		fnt = getPath(self.font)		
		fnt_sz = self.fontsize
		fgcolor = 0xffffff	
		# create a font object 
		font = ImageFont.truetype(fnt,fnt_sz)
		# determine dimensions of the text
		dim = font.getsize(text)
		# get a Image instance
		im = self.get_bg_img()
		# create a new image slightly larger that the text
		im = im.resize((dim[0]+3,dim[1] +3))	
		d = ImageDraw.Draw(im)
		# add the text to the image
		d.text((3,3), text, font=font, fill=fgcolor)
		# add a smooth filter to the image	
		im = im.filter(ImageFilter.SMOOTH_MORE)		
		# save the image to a file
		#im.save(file_name, format=fmt)
		return im
		

random.seed(time.time())
tmpdir = 'tmp'
RELDIR = 'register'

# a special function for get the absolute path
def getPath(curpath):
	# CONFIG is the builltin variable of Karrigell web server
	root = CONFIG.root_dir
	return os.path.join(root, RELDIR, curpath) 


def getChallenge():
	"""
    	Returns a string, which should be placed as a hidden field
    	on a web form. This string identifies a particular challenge,
    	and is needed later for:
        - retrieving the image file for viewing the challenge, via
          call to getImageData()
        - testing a response to the challenge, via call to testSolution()

    	The format of the string is::
        
        base64(id+":"+expirytime+":"+sha1(id, answer, expirytime, secret))
    
    	Where:
        - id is a pseudo-random id identifying this challenge instance, and
          used to locate the temporary file under which the image is stored
        - expirytime is unixtime in hex
        - answer is the plaintext string of the word on the challenge picture
        - secret is the secret signing key 'captchaSecretKey
        
        reldir - a relative path for Karrigell to identify the absolute file path
    	"""
    	# get a CAPTCHA object
    	g = Captcha()

    	# retrieve text solution
    	try:
    		answer = g.answer
    	except :
    		print sys.exc_info()    
    	# generate a unique id under which to save it
    	id = _generateId(answer)

    	# save the image to disk, so it can be delivered from the
    	# browser's next request
    	i = g.im    	
    	path = getPath(_getImagePath(id))
    	f = file(path, "wb")
    	i.save(f, "jpeg")
    	f.close()

    	# compute 'key'
    	key = _encodeKey(id, answer)
    	return key

def getImageFile(key):
	id, expiry, sig = _decodeKey(key)
	fname = _getImagePath(id)
	return fname 	

def testSolution(key, guess):
	"""
    	Tests if guess is a correct solution
   	"""
    	try:
        	id, expiry, sig = _decodeKey(key)
        	
        	# test for timeout        	
        	if time.time() > expiry:
        		# sorry, timed out, too late
            		_delImage(id)            		
            		return False

        	# test for past usage of this key        	
        	path = getPath(_getImagePath(id))
        	if not os.path.isfile(path):
        		# no such key, fail out
            		return False

        	# test for correct word
        	if _signChallenge(id, guess, expiry) != sig:
        		# sorry, wrong word
            		return False

        	# successful
        	_delImage(id) # image no longer needed
        	return True
    	except:
        	#traceback.print_exc()
        	return False

# ----------------------------------------------------
# lower level funcs

def _encodeKey(id, answer):
	"""
    	Encodes the challenge ID and the answer into a string which is safe
    	to give to a potentially hostile client

    	The key is base64-encoding of 'id:expirytime:answer'
    	"""
    	expiryTime = int(time.time() + captchaTimeout)
    	sig = _signChallenge(id, answer, expiryTime)
    	raw = "%s:%x:%s" % (id, expiryTime, sig)
    	key = base64.encodestring(raw).replace("\n", "")
    	return key

def _decodeKey(key):
    	"""
    	decodes a given key, returns id, expiry time and signature
    	"""
    	raw = base64.decodestring(key)
    	id, expiry, sig = raw.split(":", 2)
    	expiry = int(expiry, 16)
    	return id, expiry, sig

def _signChallenge(id, answer, expiry):
    	expiry = "%x" % expiry
    	return sha.new(id + answer + expiry + captchaSecretKey).hexdigest()[:16]

def _generateId(solution):
    	"""
    	returns a pseudo-random id under which picture
    	gets stored
    	"""
    	return sha.new(
        	"%s%s%s" % (
            	captchaSecretKey, solution, random.random())).hexdigest()[:10]

def _getImagePath(id):
	name = '.'.join((id, 'jpeg'))	
    	return os.path.join(tmpdir, name) 

def _delImage(id):
    	"""
    	deletes image from tmp dir, no longer wanted
    	"""
    	try:
        	imgPath = _getImagePath(id)
        	imgPath = getPath(imgPath)
        	if os.path.isfile(imgPath):
            		os.unlink(imgPath)
    	except:
        	traceback.print_exc()
        	pass
        