import os, random
import Image
import ImageFont
import ImageDraw
import ImageFilter

def get_bg_img( ):
	'''Return a random background image from the fixed directory.'''
	subdir = 'images'	
	path = os.path.join(os.curdir, subdir)
	fnames = os.listdir(path)
	i = random.randint(0, len(fnames)-1)
	fname = os.path.join(path, fnames[i])
	im = Image.open(fname)
	return im	

def gen_captcha(text, fnt, fnt_sz, file_name, fmt='PNG'):
	'''Generate a captcha image'''
	fgcolor = 0xffffff	
	# create a font object 
	font = ImageFont.truetype(fnt,fnt_sz)
	# determine dimensions of the text
	dim = font.getsize(text)
	
	# get a Image instance
	im = get_bg_img()
	# create a new image slightly larger that the text
	im = im.resize((dim[0]+5,dim[1]+5))	
	d = ImageDraw.Draw(im)
		
	# add the text to the image
	d.text((3,3), text, font=font, fill=fgcolor)
	# add a smooth filter to the image	
	im = im.filter(ImageFilter.SMOOTH_MORE)
	
	# save the image to a file
	im.save(file_name, format=fmt)

if __name__ == '__main__':
	'''Example: This grabs a random word from the dictionary 'words' (one
	word per line) and generates a jpeg image named 'test.jpg' using
	the truetype font 'porkys.ttf' with a font size of 25.
	'''
	words = open('words').readlines()	
	word = words[random.randint(0,len(words)-1)]	
	#gen_captcha(word.strip(), 'porkys.ttf', 25, "test.png")
	gen_captcha(word.strip(), 'VeraIt.ttf', 25, "test.png")
