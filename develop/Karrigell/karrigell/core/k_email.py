# -*- Encoding: UTF-8 -*-
"""
This module is based on an excerpt of code found on the internet.
The original code was called mxmail and was published under a free licence.
The author said : TIUISICIIDC (Take it, use it, sell it, change it. I dont care.). 
The original code was largely modified to correct bugs, add functionnalities and make
it more useable.

----------------------------
Example for using SendMail :
----------------------------
myMsg = k_email.SendMail(u"Subject of this message", 'smtp.server.com')
myMsg.set_from (u"Karrigell WEB site", '')
myMsg.set_message('Hello message')
myMsg.set_reply_to(u"karrigell group", 'karrigell@googlegroups.com') # Not mandatory
myMsg.add_recipient(u'recipient 1', 'recipient1@server1.com')
myMsg.add_recipient(u'recipient 2', 'recipient2@server2.com')
myMsg.add_recipient(u'', 'recipient3@server3.com')
myMsg.add_recipient(u'recipient 4', 'recipient4@server4.com', cc=True) # Not mandatory
myMsg.add_attachment ("ASCII characters.pdf") # Not mandatory
myMsg.add_attachment (u"caractères UNICODE.pdf") # Not mandatory
myMsg.send()

-----------------------------------------------------
Example for using SendMail to send to a mailing list:
The list of recipients is hidden
Only one message is sent
-----------------------------------------------------
myMsg = k_email.SendMail(u"Subject of this message", 'smtp.server.com')
myMsg.set_from (u"Karrigell WEB site", '')
myMsg.set_message('Hello to list')
myMsg.set_reply_to(u"List group", 'list@server.com')
myMsg.add_recipient(u'list title', '', True, False)
myMsg.add_recipient(u'', 'recipient1@server1.com', False, True)
myMsg.add_recipient(u'', 'recipient2@server2.com', False, True)
myMsg.add_recipient(u'', 'recipient3@server3.com', False, True)
myMsg.send()

-----------------------------------------------------
Example for using SendMail to send to a mailing list:
One message per recipient is sent
-----------------------------------------------------
myMsg = k_email.SendMail(u"Subject of this message", 'smtp.server.com')
myMsg.set_from (u"Karrigell WEB site", '')
myMsg.set_message('Hello to list')
myMsg.set_reply_to(u"List group", 'list@server.com')
myMsg.add_recipient(u'recipient 1', 'recipient1@server1.com')
myMsg.send()
myMsg.clear_recipients()
myMsg.add_recipient(u'recipient2', 'recipient2@server2.com')
myMsg.send()
myMsg.clear_recipients()
myMsg.add_recipient(u'', 'recipient3@server3.com')
myMsg.send()
"""
import string, sys, types, os, tempfile, time
#import email
from email import Encoders
from email.MIMEAudio import MIMEAudio
from email.MIMEBase import MIMEBase
from email.MIMEImage import MIMEImage
from email.MIMEMultipart import MIMEMultipart
from email.MIMEText import MIMEText
from email.Message import Message
from email.Header import Header
import mimetypes
import smtplib

def _FILE(file_name):
    """Guess the content type based on the file's extension. Encoding
    will be ignored, altough we should check for simple things like
    gzip'd or compressed files."""
    base_name = str(Header(os.path.basename(file_name)))
    file_type, encoding = mimetypes.guess_type(file_name)
    if file_type is None or encoding is not None:
        # No guess could be made, or the file is encoded (compressed), so
        # use a generic bag-of-bits type.
        file_type = 'application.octet-stream'
    maintype, subtype = file_type.split('/', 1)
    if maintype == 'text':
        fp = open(file_name)
        # Note : we should handle calculating the charset
        msg = MIMEText(fp.read(), _subtype=subtype)
        fp.close()
    elif maintype == 'image':
        fp = open(file_name, 'rb')
        msg = MIMEImage(fp.read(), _subtype=subtype)
        fp.close()
    elif maintype == 'audio':
        fp = open(file_name, 'rb')
        msg = MIMEAudio(fp.read(), _subtype=subtype)
        fp.close()
    else:
        fp = open(file_name, 'rb')
        msg = MIMEBase(maintype, subtype)#, name=base_name)
        msg.set_payload(fp.read())
        fp.close()
        # Encode the payload using Base64
        Encoders.encode_base64(msg)
    # Set the filename parameter
    msg.add_header('Content-Disposition','attachment',filename=base_name)
    return msg


class SendMail:
    """Class to send an e-mail very easily
    """
    def __init__(self, subject='', smtp_server=''):
        self.clear_header_data()
        self.set_subject(subject)
        self.set_message('')
        self.clear_recipients()
        self.clear_attachments()
        self.set_smtp_server(smtp_server)
        self.smtp_from_address = None
        self.clear_smtp_user_and_password()

    def __str__(self):
        return self.message
    
    def clear_header_data(self):
        self.header_data = {}
        self.header_data['From'] = None
        self.from_address = None

    def set_from (self, name, address):
        """Set from. """
        if name :
            self.header_data['From'] = "%s <%s>" % (name, address)
            self.from_address = address
        else :
            self.header_data['From'] = "%s" % (address)

    def set_sender (self, name, address):
        """Set sender. """
        if name :
            self.header_data['Sender'] = "%s <%s>" % (name, address)
        else :
            self.header_data['Sender'] = "%s" % (address)

    def set_reply_to (self, name, address):
        """Set reply to. """
        if name :
            self.header_data['Reply-To'] = "%s <%s>" % (name, address)
        else :
            self.header_data['Reply-To'] = "%s" % (address)

    def set_subject(self, text):
        """Set the subject of the message. """
        self.header_data['Subject'] = text
        
    def set_message(self, text):
        """Set text of current message """
        self.message = text

    def message_prepend(self, text):
        """Add text in front of current message """
        self.message = text + self.message

    def message_append(self, text):
        """Add text at the end of current message """
        self.message = self.message + text

    def message_prepend_file(self, fileName):
        """Add the content of a file in front of current message. """
        f = open(fileName)
        self.message_prepend(f.read())
        f.close()

    def message_append_file(self, fileName):
        """Add the content of a file in front of current message. """
        f = open(fileName)
        self.message_append(f.read())
        f.close()

    def clear_recipients(self):
        """Clear the list of recipients. """
        self.header_data["To"] = []
        self.header_data["Cc"] = []
        self.smtp_recipients = []
        
    def add_recipient(self, name, address, add_to_header=True, add_to_smtp=True, cc=False):
        """Add a recipient to the list of recipients.
        name : name of recipient
        address : e-mail address of recipient
        add_to_header : the name and e-mail address are added to the message header
        add_to_smtp : the e-mail address is added to the recipient list sent to smtp server 
                      (the actual recipient list)
        """
        if add_to_header :
            if cc :
                k = "Cc"
            else :
                k = "To"

            if name :
                self.header_data[k].append("%s <%s>" % (name, address))
            else :
                self.header_data[k].append("%s" % (address))

        if add_to_smtp :
            self.smtp_recipients.append(address)
            

    def clear_attachments(self):
        self.attachments = []

    def add_attachment(self, fileName):
        """Add an attached file to the message.
        The attached file is automaticaly converted to the correct mime type if possible """
        self.attachments.append(fileName)

    def set_smtp_server(self, server):
        """Set the SMTP server address. """
        self.smtp_server = server
        
    def set_smtp_from_address(self, address):
        """Set the SMTP from address. """
        self.smtp_from_address = address
        
    def clear_smtp_user_and_password(self):
        """Clears SMTP user name and password."""
        self.smtp_user_name = ""
        self.smtp_password = ""
    
    def set_smtp_username_and_password(self, user_name, password):
        """Set the SMTP user name and paswword for login() """
        self.smtp_user_name = user_name
        self.smtp_password = password
        
    def send(self):
        """Sends message 
        Returns a dict containing refused recipients. 
        """
        message = MIMEMultipart()

        # List of strings -> string
        if self.header_data['To'] :
            self.header_data['To'] = ", ".join(self.header_data['To'])
        
        if self.header_data['Cc'] :
            self.header_data['Cc'] = ", ".join(self.header_data['Cc'])
        
        #Header
        for k,v in self.header_data.iteritems():
            message[k] = Header(v)

        # Body
        if type(self.message) == str:
            msg = MIMEText(self.message)
        elif type(self.message) == unicode:
            msg = MIMEText(self.message.encode('utf-8'), 'plain', 'utf-8')
        #Encoders.encode_7or8bit(msg)
        message.attach(msg)
        
        # Attached files
        for attach_file in self.attachments:
            # encodes the attached files
            if type(attach_file) == types.TupleType and len(attach_file) == 2:
                filePath,fileName = attach_file
            else:
                fileName = attach_file
                filePath = attach_file
#            else:
#                raise "Attachments Error: must be pathname string or path,filename tuple"
            message.attach(_FILE(attach_file))

        # SMTP
        from_address = self.smtp_from_address or self.from_address
        s = smtplib.SMTP(self.smtp_server)
        if self.smtp_user_name or self.smtp_password :
            s.login(self.smtp_user_name, self.smtp_password)
        refused_addresses = s.sendmail(from_address, self.smtp_recipients, message.as_string())
        s.quit()
        return refused_addresses

if __name__ == "__main__":
    subject = raw_input("Subject: ")
    send_to = "pierre.quentel@gmail.com"
    message = raw_input("Message: ")
    
    myMsg = SendMail(subject, 'smtp.wanadoo.fr')
    myMsg.set_from (u"Karrigell WEB site", '')
    myMsg.set_message(message)
    myMsg.add_recipient(u'recipient 1', send_to)
    myMsg.send()
