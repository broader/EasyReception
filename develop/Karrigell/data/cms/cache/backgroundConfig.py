[]
######################### Web UI For User##################################################

## For menubar in application main page
nav = '#navigation.ks'
_getPath = lambda name : '/'.join((nav, name))
_menus = (\
		('profile?path=manage/userlist.hip', _("Register List")),\
		('profile?path=issue', _("Issue Tracker")),\
		('profile?path=agenda/agenda.ks/index', _("Agenda")),\
		('profile?path=broadcast/info.ks/page_manage', _("News")),\
	        ('profile?path=sysadmin', _("Advanced Config")),\
	        ('profile?path=user', _("Personal Info"))\
	        )
menus = [ (_getPath(path), text) for path, text in _menus ]

## The users list table's head titles
userlist_th_content = \
[ ({'width': '20%'},_("UserName"), 'username'),\
  ({'width': '25%'},_("First Name"), 'firstname'),\
  ({'width': '25%'},_("Last Name"), 'lastname'),\
  ({'width': '15%'},_("Country/Area"), 'country'),\
  ({'width': '15%'},_("Organization"), 'organization')\
]


## Issue Module
# Issue List Fields
## The head titles of the issues list table
issuelist_th_content = \
[ ({'width': '15%'},_("Creation"), 'creation'),\
  ({'width': '10%'},_("Id"), 'serial'),\
  ({'width': '25%'},_("Subject"), 'title'),\
  ({'width': '10%'},_("Keyword"), 'keyword'),\
  ({'width': '15%'},_("Status"), 'status')
]


form_buttons = [_("OK"), _("Cancel")]


## System Admin

# the classes that could be edited by web page
web_edited_classes = ['role', 'keyword','priority', 'status', 'user', 'webaction', 'service', 'reserve' ]

# the names of the applications' modules
apps = ['issue', 'manage', 'sysadmin', 'user' , 'service', 'reserve', 'agenda']



