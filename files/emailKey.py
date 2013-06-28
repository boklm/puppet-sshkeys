#! /usr/bin/python
#
# emailKey.py
# Script to send user keys
# https://github.com/shermdog/puppet-sshkeys
# v1.0
# 6.28.13

# Params:
#   filename (absolute path)
#   emailaddress

import sys
import socket
import smtplib
from email import encoders
from email.mime.base import MIMEBase
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart


# Script defaults - You need to set these!
sender = 'sender@host.com'
server = 'smtp.server.com'
port = 465
user = 'username'
password = 'password'


def printUsage ():
  print "Incorrect or invalid arguments."
  print "Usage: emailKey.py <filename> <emailaddress>"
  sys.exit(2) #Invalid sytax error code


# Start main program code
if len(sys.argv) != 3:
  printUsage()

fileName = sys.argv[1]
address = sys.argv[2]

# Create the enclosing (outer) message
outer = MIMEMultipart()
outer['Subject'] = 'SSH Access Key Updated'
outer['From'] = sender
outer['To'] = address

# Text inside of the email
body = MIMEText("""Your SSH access key has been updated and is included in this message.

This key will be installed in the next 30 minutes.  Your previous key will be removed.








"I am Vinz, Vinz Clortho, Keymaster of Gozer...Volguus Zildrohoar, Lord of the Seboullia. Are you the Gatekeeper?"
""")

outer.attach(body)

# Attach certificate
fp = open(fileName, 'rb')
# SES has some strict MIME types, this allows any extension
msg = MIMEBase('application', "pgp-encrypted")
msg.set_payload(fp.read())
fp.close()

# Encode the payload using Base64
encoders.encode_base64(msg)
msg.add_header('Content-Disposition', 'attachment', filename=fileName.rsplit('/',1)[1])
outer.attach(msg)

# Send email and cath errors
try:
    s = smtplib.SMTP_SSL(server, port, timeout=1)
    s.login(user,password)
    s.sendmail(sender, address, outer.as_string())
    s.quit()
    print "Successfully sent email."
    sys.exit() #Successful exit code 0
except Exception, e:    
    print "Unable to send email. Error: %s" % e
    sys.exit(1) #Exit with error

# It's over!
