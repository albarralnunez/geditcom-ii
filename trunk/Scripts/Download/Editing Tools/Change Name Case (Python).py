#!/usr/bin/python
#
# Name Case script
# GEDitCOM II Python Script
# 29 APR 2010, by John A. Nairn
#
# This script changes names of all or selected individuals to be
# all UPPERCASE, to be Uppercase SURNAMES, or to be Title Case Names.
#	
# The Uppercaase SURNAMES options does not change non-surname parts of the name.
# To change names in all upper case to upper case surnames only, first change
# to Title Case Names and then do a second pass for Uppercase SURNAMES.
from GEDitCOMII import *
from Foundation import *

# fetch application object
gedit = CheckVersionAndDocument("Change Name Case",1.6,2)
if not(gedit) : quit()
gdoc = FrontDocument()

# decide if should change "All" individuals or "Selected" individuals
# For some reason need to send command to document even though AppleScript
# can send to application
whichOnes=GetOption("Which names should be changed?",\
"Change 'All' individuals in the file or just the currently 'selected' individuals.",\
("All","Cancel","Selected"))

# fetch all or selected individual records
if whichOnes=="Selected" :
    selrecs = gdoc.selectedRecords()
    # filter to individual records
    pred = NSPredicate.predicateWithFormat_("recordType LIKE \"INDI\"")
    recs = selrecs.filteredArrayUsingPredicate_(pred)
elif whichOnes=="All" :
    recs = gdoc.individuals()
else :
    quit()

# decide the new name case as "upper", "uppersurname", or "title"
nameCase=GetOption("How should the name case be changed?",\
"Make names all uppercase, just the surname uppercase, or use title case.",\
("UPPERCASE","Uppercase SURNAMES","Title Case"))

print "Changing name case of",whichOnes,"individuals to",nameCase
if nameCase=="UPPERCASE" :
    nameCase="upper"
elif nameCase=="Uppercase SURNAMES" :
    nameCase="uppersurname"
else :
    nameCase="title"

# Main name changing loop
gdoc.beginUndo()
numChanged=len(recs)
oldName=gdoc.bulkReaderSelector_target_argument_(["evaluate"],recs,["NAME"])
for i in range(numChanged):
    recs[i].setName_(gdoc.formatNameValue_case_(oldName[0][i],nameCase))
gdoc.endUndoAction_("Change Name Case")

# output summary of the results
if numChanged==1:
    print "One name was changed"
else:
    print numChanged,"names were changed"

