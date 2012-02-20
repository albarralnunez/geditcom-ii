#!/usr/bin/python
#
# Move Memos to Notes (Python Script for GEDitCOM II)
# Written by John A. Nairn
# 16 Oct 2010
#
# GEDitCOM II's memos are a nice feature to help in your genealogy research,
# but they use a custom tag. If you send to another person as a GEDCOM file
# and they are not using GEDitCOM II, that software will be likely to ignore
# the memos is is fairly likely to delete them. This script can solve
# that problem as follows:
#
# Before export a GEDCOM file for someone without GEDitCOM II, run this script
# and it will move all memos to notes for that record. Some GEDCOM record's do
# not allow notes and their memos will be moved to the header record.
#
# The change can be done all all currently selected records or on all records
# in the file. The later is more common when you are about to export a GEDCOM
# file from all records.
#
# You can optionally retain the memos in the file (the normally don't hurt) or
# delete them. The delete option is probably only needed if the target
# application fails to import a file containing memos (they use custom
# tag _MEMO).

# Load Apple's Scripting Bridge for Python
from GEDitCOMII import *

################### Subroutines

# Move memos in one record
def MoveMemos(theRec) :
    global memoNote,recsMoved,notMoved
    memoNote=""
    MoveStructures(theRec,"")
    if len(memoNote)>0 :
        # This record had one or more memos
    	theNote="Memos on "+theRec.alternateName()+"\n\n"+memoNote
        if theRec.canLinkRecordType_("NOTE") :
            # If possible attach as note to the record
            gnote=AddNoteRecord(gdoc,theNote)
            gnote.moveTo_(theRec)
            recsMoved+=1
        else :
            # For records that do not allow notes, save for later
            notMoved+=theNote

# Check for memos in this object's structures
def MoveStructures(parent,parentList) :
    global memoNote,numChanged
    for gcline in parent.structures() :
    	memo=gcline.memo()
    	if len(memo)>0 :
    	    # Has a memo, prepare to move it to notes
    	    moveText="Memo on"
    	    cparts=gcline.contents().partition("\n")
    	    if cparts[1]=="\n" or len(cparts[0])>25 :
    	        contents=cparts[0][:25]+"..."
    	    else :
    	        contents=cparts[0]
    	    tagList=parentList+gcline.name()
    	    moveText="Memo on \""+contents+"\""
            memoNote=memoNote+moveText+" ("+tagList+")\n   "+memo+"\n\n"
            numChanged=numChanged+1
            
            # If requested, delete the memo now
            if memoFate=="Delete" :
                gcline.setMemo_("")
        
        # recursively check structures in this structure
        MoveStructures(gcline, parentList+gcline.name() +".")

################### Main Script

# fetch application object
gedit = CheckVersionAndDocument("Move Memos to Notes",1.6,2)
if not(gedit) : quit()
gdoc = FrontDocument()

# decide if should change "All" individuals or "Selected" individuals
# For some reason need to send command to document even though AppleScript
# can send to application
whichOnes = GetOption("Move memos which records?",\
"Move memos to notes for 'All' records in the file or just the currently 'selected' records.",\
("All","Cancel","Selected"))

# fetch all or selected individual records
if whichOnes=="Selected" :
    recs = gdoc.selectedRecords()
elif whichOnes=="All" :
    recs = gdoc.gedcomRecords()
else :
    quit()

# decide what to do with memos
memoFate = GetOption("Would like to delete memos after moving them to notes?",\
"You can 'Keep' the existing memos (recommended) or 'Delete' them if needed.",\
("Keep","Cancel","Delete"))
if memoFate == "Cancel" : quit()

# Main name moving memos
gdoc.beginUndo()
numChanged=0
recsMoved=0
notMoved=""
numRecs=len(recs)
fractionStepSize=nextFraction=0.01
for i in range(numRecs) :
    MoveMemos(recs[i])
    
    # time for progress
    fractionDone = float(i+1)/float(numRecs)
    if fractionDone > nextFraction:
        ProgressMessage(fractionDone)
        nextFraction = nextFraction+fractionStepSize

# check any not moved and move to header notes
if len(notMoved)>0 :
    hn=gdoc.headers()[0].findStructuresTag_output_value_("NOTE","References",None)
    if len(hn)>0 :
        # append to existing header notes
        ns=hn[0]
        oldNotes=ns.contents()
        ns.setContents_(oldNotes+"\n\n"+notMoved)
    else :
        # create new header notes
        AddStructure(gdoc.headers()[0],{"name":"NOTE","contents":notMoved})
        
gdoc.endUndoAction_("Move Memos to Notes")

# output summary of the results
if numChanged==0:
    print "No memos were found in this file or the selected records"
else:
    if numChanged==1:
        print "One memo was moved to a note for one record"
    elif recsMoved==1:
        print numChanged,"memos were moved to a note for one record"
    else:
        print numChanged,"memos were moved to a notes for",recsMoved,"records"

    # inform of header use
    if len(notMoved)>0 :
        print "Some memos were moved to the header record notes because their parent records do not allow notes"


