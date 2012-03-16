#!/usr/bin/python
#
# Move Part of Place to Address (Python Script for GEDitCOM II)
# By: John A. Nairn
# Date: 29 FEB 2012
#
# Select one or more place records. For each one, delete text that is an
# address leaving the place name remaining. This script will
# change the place record to the place name and move the address
# part you delete to address field associated with each place that
# uses that name. Finally, if the new place name matches and existing
# place, you will get the option to merge the two place records (and
# normally should do so).

# Load GEDitCOM II Module
from GEDitCOMII import *

# Preamble
gedit = CheckVersionAndDocument("Move Part of Place to Address",1.7,1)
if not(gedit) : quit()
gdoc = FrontDocument()

# globals
ptitle = "Move Part of Place to Address"
prompt = "Delete the address (if there) in this place name leaving the remaining characters"
prompt += " unchanged as the text to be the new place name"
prompt += " (to change nothing, delete no characters or click 'Skip')."
pbtns = ["Move","Cancel","Skip"]
perror = "The place name you left was not found in the original name."
pmsg = "You should delete just the address parts and leave a contiguous string of remaining"
pmsg += " characters the same as in the original name. Click 'OK' and try again."

# get selected place record
numEdits = 0
hasAPlace = False
selRecs = gdoc.selectedRecords()
for rec in selRecs :
    if rec.recordType()!="_PLC":
        continue
    
    # get name
    hasAPlace = True
    oldName = rec.name()
    while True :
        res = gdoc.userInputPrompt_buttons_initialText_title_(prompt,pbtns,oldName,ptitle)
        if res[0] == "Cancel" : quit()
        if res[0] == "Skip" : break
    
        placeName = res[1]
        nst = oldName.find(placeName)
        if nst < 0 :
            Alert(perror,pmsg)
        else :
            addr = ""
            if nst>0 : addr = oldName[:nst]
            term = nst+len(placeName)
            if term < len(oldName) : addr += oldName[term:]
            addr = addr.strip()
            addr = addr.strip(",")
            addrLines = addr.split(",")
            if len(addrLines) > 1 :
                for ii in range(len(addrLines)) :
                    addrLines[ii] = addrLines[ii].strip()
                addr = '\n'.join(addrLines)
            break
    
    if res[0] == "Skip" : continue
    if placeName == oldName : continue
    
    # move addr to place fields in all cited records
    cited = rec.referencedBy()
    for ifamID in cited :
        ifam = gdoc.individuals().objectWithID_(ifamID).get()
        if ifam==None :
            ifam = gdoc.families().objectWithID_(ifamID).get()
        if ifam == None : continue
        
        plcflds = ifam.findStructuresTag_output_value_("PLAC","references",oldName)
        for evnt in plcflds :
            if evnt.level() != 2 : continue
            parent = evnt.parentStructure()
            if numEdits == 0 : gdoc.beginUndo()
            numEdits += 1
            # look for existing address or create one
            addrFld = parent.structures().objectWithName_("ADDR")
            if addrFld.exists() == True :
                oldAddr = addrFld.contents()
                if oldAddr != "" : oldAddr += "\n"
                addrFld.setContents_(oldAddr+addr)
            else :
                AddStructure(parent,{"name":"ADDR", "contents":addr})
    
    # before changing name, see if that name is already there
    prec = gdoc.places().objectWithName_(placeName)
    if prec.exists() == False : prec = None

    # change place name of place record
    if numEdits == 0 : gdoc.beginUndo()
    numEdits += 1
    rec.setName_(placeName)
    
    # Decide if should merge with another place record
    if prec != None :
        mprmpt = "You now have two places named '"+placeName+"' and should probably merge them."
        mmsg = "Click 'Merge' to merge now or 'Skip' to merge later."
        picked = gdoc.userOptionTitle_buttons_message_(mprmpt,["Merge","Skip"],mmsg)
        if picked == "Merge" :
            rec.mergeWithRecord_force_(prec,True)
   

# end undo if it started
if numEdits > 0 :
    gdoc.endUndoAction_("Move Part of Place to Address Fields")

# were they any places
if hasAPlace == False :
    Alert("You have to select one or more place records to use the '"+ptitle+"' script.")
