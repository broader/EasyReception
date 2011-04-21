import htmllib, formatter, StringIO, urllib2,urllib, sys


class Paragraph:
    def __init__(self):
	self.text = ''
	self.bytes = 0
	self.density = 0.0

class LineWriter(formatter.AbstractWriter):
    def __init__(self, density=None):
	self.initDensity = density 

	self.last_index = 0
	self.lines = [Paragraph()]
	formatter.AbstractWriter.__init__(self)

    def send_flowing_data(self, data):
	# Work out the length of this text chunk.
	t = len(data)
	# We've parsed more text, so increment index.
	self.index += t
	# Calculate the number of bytes since last time.
	b = self.index - self.last_index
	self.last_index = self.index
	# Accumulate this information in current line.
	l = self.lines[-1]
	
	l.text += data
	l.bytes += b

    def send_paragraph(self, blankline):
	"""Create a new paragraph if necessary."""
	if self.lines[-1].text == '':
	    return

	self.lines[-1].text += '\n' * (blankline+1)
	self.lines[-1].bytes += 2 * (blankline+1)
	self.lines.append(Paragraph())
 
    def send_literal_data(self, data):
	self.send_flowing_data(data)

    def send_line_break(self):
	self.send_paragraph(0)
    
    def compute_density(self):
	"""Calculate the density for each line, and the average."""
	total = 0.0
	for l in self.lines:
	    if l.bytes == 0 :
		l.density = 0
	    else:
		l.density = len(l.text) / float(l.bytes)
	    total += l.density
	
	# Store for optional use by the neural network.
	self.average = total / float(len(self.lines))

    def output(self):
	"""Return a string with the useless lines filtered out."""
	self.compute_density()

	judge = self.initDensity or self.average
	if not self.initDensity:
	    print 'Average density is %s'%self.average

	output = StringIO.StringIO()
	for l in self.lines:
	    # Check density against threshold.
	    # Custom filter extensions go here.
	    #print 'Text: %s'%l.text, 'Bytest: %s'%l.bytes, 'Density: %s'%l.density
	    

	    if l.density > judge :
		output.write(l.text)

	return output.getvalue()


class TrackingParser(htmllib.HTMLParser):
    """Try to keep accurate pointer of parsing location."""

    def __init__(self, writer, *args):
	htmllib.HTMLParser.__init__(self, *args)
	self.writer = writer
       
    def parse_starttag(self, i):
	index = htmllib.HTMLParser.parse_starttag(self, i)
	self.writer.index = index
	return index

    def parse_endtag(self, i):
	self.writer.index = i
	return htmllib.HTMLParser.parse_endtag(self, i)

def extract_text(html, initDensity):
    # Derive from formatter.AbstractWriter to store paragraphs.
    writer = LineWriter(initDensity)
    # Default formatter sends commands to our writer.
    newFormatter = formatter.AbstractFormatter(writer)
    # Derive from htmllib.HTMLParser to track parsed bytes.
    parser = TrackingParser(writer, newFormatter)
    # Give the parser the raw HTML data.
    parser.feed(html)
    parser.close()
    # Filter the paragraphs stored and output them.
    return writer.output()


def fann_test(trainingText):
    """ The function to using fast artifitial neural network."""
    # using "fann" package in machine learning
    from pyfann import fann, libfann
    # This creates a new single-layer perceptron with 1 output and 3 inputs.
    obj = libfann.fann_create_standard_array(2, (3, 1))
    ann = fann.fann_class(obj)
    # Load the data we described above.
    patterns = fann.read_train_from_file('training.txt')
    ann.train_on_data(patterns, 1000, 1, 0.0)
    # Then test it with different data.
    for datin, datout in validation_data:
	result = ann.run(datin)
	print 'Got:', result, ' Expected:', datout


if __name__ == "__main__":
    #htmlFile = open("examples.html")
    #htmlFile = urllib2.urlopen("http://www.iotcc.org.cn/_d271324263.htm")
    req = urllib2.Request(
	"http://www.nbit.gov.cn/homepage/show_view.aspx",
	urllib.urlencode({'id':'5200','catid':'19#1'})
    )
    htmlFile = urllib2.urlopen(req)
    #htmlFile = urllib2.urlopen("http://www.nbit.gov.cn/homepage")
   
    content = htmlFile.read()

    argsNumber = len(sys.argv)

    if argsNumber == 1 :
	initDensity = None 
    elif argsNumber == 2:
	initDensity = float(sys.argv[1])
    else:
	sys.exit("Input arguments more than 1 error!")

    print extract_text(content, initDensity)
