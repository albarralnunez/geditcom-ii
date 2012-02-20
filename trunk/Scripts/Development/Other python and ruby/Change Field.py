#!/usr/bin/python
#
# Change Field script
# GEDitCOM II Python Script
# 2 MAY 2010, by John A. Nairn

# Prepare to use Apple's Scripting Bridge for Python
from Foundation import *
from ScriptingBridge import *

################### Subroutines

# Check that the current version of GEDitCOM II is new enough for this script
# Also check if a document is open
# Return 0 to abort script or 1 if OK to continue
def CheckAvailable():
    if gedit.versionNumber()<1.29 :
        print "This script requires GEDitCOM II, Version 1.3 or newer."
        return 0

    if gedit.documents().count()<1 :
        print "You have to open a document in GEDitCOM II to use this script"
        return 0

    return 1

################### Main Script

# fetch application object
gedit = SBApplication.applicationWithBundleIdentifier_("com.geditcom.GEDitCOMII")

# verify document is open and version is acceptable
if CheckAvailable()==0 :
    quit()

# current front document
gdoc = gedit.documents()[0]

# retrieve the current field being edited
details = gdoc.editingDetails()

# read current text being edited
if len(details)>2 :
    currentText = details[2].contents()
else :
    currentText = ""
print "Current text is",currentText

# decide on new text
newText = "Hello World"

# change the text
if len(details)>2 :
    gdoc.beginUndo()
    details[2].setContents_(newText)
    gdoc.endUndoAction_("Change Field")
else :
    selRange = (1,-1)
    gdoc.setSelectionRange_(selRange)
    gdoc.setSelectedText_(newText)
print "Field changed to",newText