#!/usr/bin/python
#
# Remove Duplicate Family Links (Python Script for GEDitCOM II)
#
# Goes through all individual records and checks their family
# links (FAMS and FAMC). If any record has more then one link
# to the same family, the duplicate links are removed.

# Load GEDitCOM II Module
from Foundation import *
from ScriptingBridge import *
from GEDitCOMII import *

################### Subroutines

def removeLinks(rec) :
    global removed
    fams = rec.findStructuresTag_output_value_("FAMS","list",None)
    while len(fams) > 1 :
        onelink = fams.pop()
        if len(onelink) == 2 :
            for other in fams :
                if len(other) == 2 and (onelink[0] == other[0]) :
                    # found match
                    rec.structures()[onelink[1]-1].delete()
                    removed += 1
                    break
        
    famc = rec.findStructuresTag_output_value_("FAMC","list",None)
    while len(fams) > 1 :
        onelink = famc.pop()
        if len(onelink) == 2 :
            for other in famc :
                if len(other) == 2 and (onelink[0] == other[0]) :
                    # found match
                    rec.structures()[onelink[1]-1].delete()
                    removed += 1
                    break

################### Main Script

# fetch document
gedit = CheckVersionAndDocument("Find and Merge Duplicates",1.6,2)
if not(gedit) : quit()
gdoc = FrontDocument()

removed = 0
recs = gdoc.individuals()
fractionStepSize = nextFraction = 0.01
numrecs = len(recs)
gdoc.beginUndo()
for i in range(numrecs) :
    removeLinks(recs[i])
    fractionDone = float(i)/float(numrecs)
    if fractionDone > nextFraction:
        gdoc.notifyProgressFraction_message_(fractionDone,None)
        nextFraction = nextFraction + fractionStepSize
gdoc.endUndoAction_("Remove Duplicate Links")

msg ="Removed "+str(removed)+" duplicate family link"
if removed != 1 : msg = msg + "s"
Alert("Remove Duplicate Family Links script is done",msg)