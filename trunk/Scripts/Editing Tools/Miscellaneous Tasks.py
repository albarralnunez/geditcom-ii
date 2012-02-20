#!/usr/bin/python
#
# Miscellaneous Tasks (Python Script for GEDitCOM II)

# Load GEDitCOM II Module
from GEDitCOMII import *

################### Subroutines

# Remove RIN tag for all records
# This assumes records have only one RIN (which is the GEDCOM standard).
# Merged records, however, may end up with more than one RIN tag. To remove
# all, keep running this task until it reports not RIN tags were found.
def RemoveRIN() :
    recs = gdoc.gedcomRecords()
    numRecs = len(recs)
    numDel = 0
    fractionStepSize=nextFraction=0.01
    gdoc.beginUndo()
    for i in range(numRecs) :
        rin = recs[i].structures().objectWithName_("RIN")
        if rin.exists() is True:
            rin.delete()
            numDel += 1
        
        # time for progress
        fractionDone = float(i+1)/float(numRecs)
        if fractionDone > nextFraction:
            ProgressMessage(fractionDone)
            nextFraction += fractionStepSize
    gdoc.endUndoAction_("Delete RIN Tags")
            
    # output summary of the results
    ProgressMessage(1.)
    if numDel==0:
        msg = "No Record Identication Number (RIN) were found in this file."
    else:
        if numDel==1:
            msg = "One Record Identication Number (RIN) tag was deleted."
        else:
            msg = str(numDel)+" Record Identication Number (RIN) tags were deleted."
    Alert("RIN Deletion Done",msg)

################### Main Script

# Preamble
gedit = CheckVersionAndDocument("Miscellaneous Tasks",1.6,2)
if not(gedit) : quit()
gdoc = FrontDocument()

# Pick from currently available editing tasks
choices = ["Delete Record ID Numbers (RIN Tags)"]
prompt = "Select the editing task you would like to perform"
otitle = "Miscellaneous Editing Tasks"
option = gdoc.userChoiceListItems_prompt_buttons_multiple_title_(choices,prompt,["OK","Cancel"],False,otitle)
if option[0] == "Cancel":
    quit()

taskID = option[2][0]

# delete RIN
if taskID == 1 :
    RemoveRIN()

else :
    Alert("Unknown Task?","The task '"+option[1][0]+"' is not yet supported in this script.")


