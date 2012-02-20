#!/usr/bin/python
#
# Fix FamilySearch Download
# GEDitCOM II Python Script
# 24 AYG 2010, by John A. Nairn
#
# GEDCOM files downloaded from FamilySearch.org have some minor issues
# that make them less useful than they should be. This script goes through
# such downloads and fixes the following issues:
#
# 1. If you merge several downloads, you will get multiple submitter records
#    and those with the same name are merged.
# 2. Similarly, you will get multiple repository records
#    (often to Family History Library) and those are merged.
# 3. Similarly, you will get multiple source records to the same source
#    and those are merged.
# 4. Some files incorrectly use "Male" and "Female" for sex. This are changed
#    to the GEDCOM standard "M" and "F"
# 5. Some dates are poorly formatted (such as be surrended by "<" and">"). These
#    dates are fixed.
#
# If other problems are found, they can be added to this script

# Prepare to use Apple's Scripting Bridge for Python
from Foundation import *
from ScriptingBridge import *

################### Subroutines

# Verify acceptable version of GEDitCOM II is running and a document is open.
# Return 1 or 0 if script can run or not.
def CheckAvailable(gedit,sName,vNeed):
    vnum = gedit.versionNumber()
    if vnum<vNeed:
        vNeed = int(vNeed*100+.5)/100.
        errMsg = "The script '" + sName + "' requires GEDitCOM II, Version "\
        + str(vNeed) + " or newer.\nPlease upgrade and try again."
        print errMsg
        return 0

    if gedit.documents().count()<1:
        errMsg = "The script '" + sName + \
        "' requires requires a document to be open\n"\
        + "Please open a document and try again."
        print errMsg
        return 0

    return 1

################### Main Script

# fetch application object
gedit = SBApplication.applicationWithBundleIdentifier_("com.geditcom.GEDitCOMII")

# verify document is open and version is acceptable
if CheckAvailable(gedit,"Fix FamilySearch Download",1.499)==0 :
    quit()

# decide if should change "All" individuals or "Selected" individuals
# For some reason need to send command to document even though AppleScript
# can send to application
gedit.activate()
gdoc = gedit.documents()[0]
whichOnes=gdoc.userOptionTitle_buttons_message_("Which records should be fixed?",
    ["All","Cancel","Selected"],
    "Change 'All' individuals in the file or just the currently 'selected' individuals.")

# being undo
gdoc.beginUndo()
numChanged=0

# merge Submitters
n=len(gdoc.submitters())-1
if n>0:
    gdoc.displayByName_byType_sorting_(None,"SUBM","view")
    recn=gdoc.submitters()[n]
    n-=1
    while n>=0:
	    recnm1=gdoc.submitters()[n]
	    if recn.name()==recnm1.name():
	        recnm1.mergeWithRecord_(recn)
	        numChanged+=1
	    recn=recnm1
	    n-=1

# merge Repositories
n=len(gdoc.repositories())-1
if n>0:
    gdoc.displayByName_byType_sorting_(None,"REPO","view")
    recn=gdoc.repositories()[n]
    n-=1
    while n>=0:
	    recnm1=gdoc.repositories()[n]
	    if recn.name()==recnm1.name():
	        recnm1.mergeWithRecord_(recn)
	        numChanged+=1
	    recn=recnm1
	    n-=1

# merge Sources
n=len(gdoc.sources())-1
if n>0:
    gdoc.displayByName_byType_sorting_(None,"SOUR","view")
    recn=gdoc.sources()[n]
    n-=1
    while n>=0:
        recnm1=gdoc.sources()[n]
        if recn.name()==recnm1.name():
            if recn.sourceAuthors().get()==recnm1.sourceAuthors().get():
                if recn.sourceDetails().get()==recnm1.sourceDetails().get():
                    recnm1.mergeWithRecord_(recn)
                    numChanged+=1
        recn=recnm1
        n-=1

# Main name changing loop
gdoc.displayByName_byType_sorting_(None,"INDI","view")

# fetch all or selected individual records
if whichOnes=="Selected" :
    recs = gdoc.selectedRecords()
elif whichOnes=="All" :
    recs = gdoc.individuals()
else:
    quit()

# set up for progress
n=len(recs)
i=0
fractionStepSize = nextFraction = 0.01

# loop over individuals
for indi in recs:
    if indi.recordType()=="INDI":
        # fix sex
        currentSex=indi.evaluateExpression_("SEX")
        if len(currentSex)>1:
            indi.setSex_(currentSex)
            numChanged+=1
        
        # fix birth date
        currentBD=indi.birthDate()
        newBD=currentBD.strip(" <>")
        if newBD!=currentBD:
            indi.setBirthDate_(newBD)
            numChanged+=1

    # time for progress
    i+=1
    fractionDone = float(i) / float(n)
    if fractionDone > nextFraction:
        gdoc.notifyProgressFraction_message_(fractionDone,None)
        nextFraction = nextFraction + fractionStepSize
        
gdoc.endUndoAction_("Fix FamilySearch Download")

# output summary of the results
if numChanged==1:
    summary =  "One change was made"
elif numChanged==0:
    summary = "No changes were needed"
else:
    summary = str(numChanged)+" changes were made"
    
stitle="Checking for typical problems in GEDCOM files downloaded from FamilySearch.org"
gdoc.userOptionTitle_buttons_message_(stitle,["OK"],summary)

