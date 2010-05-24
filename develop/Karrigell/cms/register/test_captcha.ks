from HTMLTags import *
Captcha = Import('Captcha.py')

def index():	
	head = HEAD(TITLE('ezcaptcha demo'))	
	form = []	
	key = _getChallenge()	
	form.append(INPUT(**{'type':'hidden', 'name':'captchaKey', 'value': key}))	
	imgurl = '/'.join(('..',  _getImage(key)))	
	form.append(IMG(**{'src': imgurl, 'alt':'captchaImage'}))
	form.append(BR())	
	form.append(TEXT('Please type in the word you see in the image above:'))
	form.append(BR())
	form.append(INPUT(**{'type':'text', 'name':'captchaAnswer'}))
	form.append(INPUT(**{'type':'submit', 'value':'Submit'}))
	form = FORM(Sum(form), method='POST', action='valid')
	#print form
	body = H1('ezcaptcha demo') + form
	#print body
	html = HTML(head+body)
	print html	
	
def _getChallenge( ):
	return Captcha.getChallenge()
	
def _getImage(key):		
	return Captcha.getImageFile(key)

def valid(captchaKey=None, captchaAnswer=None):	
	if Captcha.testSolution(captchaKey, captchaAnswer):
		print 'Success'
	else:
		print 'Fail'
	