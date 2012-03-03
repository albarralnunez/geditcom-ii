#!/usr/bin/python
#
# Merge Duplicate Notes (Python Script for GEDitCOM II)
#
# By: John A. Nairn
# Date: March 1, 2012
#
# This script will go through all note records in your file and merge
# those that have the exact same text (ignoring case and leading
# and trailing white space).
#
# When dones, multiple notes may refer to the same record. This approach
# is an efficient way to store data and changing the notes in one record
# changes them all, so it can streamline editing of your data.
#
# A drawback, however, is that when changing the notes for one record
# you may not actually want to change them for all. For example, say you
# have a note "veteren of the Civil War" attached to multiple people in
# your file, all of whom are veterens. Then one day, you learn more about
# one of those veterens and decide to change the note to be:
#
#   "Geeoge was a major in the Union Army in the Civil War"
#
# This changes means the note is only about one person, but because other
# people are linked to the same note, it will now say that for them too.
# The solution is to make a new note if whenever you want to personalize
# a note that is linked to other people.
#
# In summary:
# 1. Run this script to quickly consolidate your notes by merging them
# 2. When later editing notes, create a new note when you want to change
#     that note to be abou only on person
# 3. If the note will stay generic, you can edit it anyplace and it will
#     be edited for anyone linked to that note.
# 4. You may need a system to mark a note as generic to be sure you do
#     not edit it to add individual-specific information.
#
# One way to check if note is linked to more than on person is to open the
# notes record and chose menu command View->Referenced By. You will see
# a list of all records linked to those notes and see if it is linked to
# multiple records.

# Load Apple's Scripting Bridge for Python
from GEDitCOMII import *

################### Classes and Subroutines

# Cache notes record
class Note :
    def __init__(self,grec) :
        self.rec = grec
        self.notes = grec.notesText()
        self.cmp = self.notes.lower().strip()
    
    # before merging, make notes exactly the same
    def setNotes(self,other) :
        self.rec.setNotesText_(other.notes)
        
    # comparison
    def __eq__(self,other) :
        if self.cmp == other.cmp :
            return True
        return False
    
################### Main Script

# fetch document
gedit = CheckVersionAndDocument("Merge Duplicate Notes",1.6,2)
if not(gedit) : quit()
gdoc = FrontDocument()

# decide what to merge and show in index window
merging = "NOTE"
display = "view"
gdoc.displayByName_byType_sorting_(None,merging,display)

# track results
merged = []

# get starting record
gdoc.userSelectByType_fromList_prompt_(merging,None,"Select starting record for merging")
while True :
    arec = gdoc.pickedRecord().get()
    if arec != "" : break
if arec == "Cancel" : quit()
index = 0
key = arec.id()
numNotes = len(gdoc.notes())
while index < numNotes :
    if gdoc.notes()[index].id() ==  key : break
    index += 1
if index >= numNotes-1 : index-=1

# read first record
target = Note(gdoc.notes()[index])
index += 1
numTimes = 0

# loop until done
while index < len(gdoc.notes()) :
    # get next record
    ProgressMessage(float(index)/float(len(gdoc.notes())))
    nextNote = Note(gdoc.notes()[index])
    
    if nextNote==target :
        if len(merged)==0 : gdoc.beginUndo()
        nextNote.setNotes(target)
        target.rec.mergeWithRecord_force_(nextNote.rec,True)
        numTimes += 1
        if numTimes == 1 :
            merged.append("<a href='"+target.rec.id()+"'>"+target.rec.name()+"</a> with ")
            merged.append("1 duplicate")
        else :
            merged[-1] = str(numTimes)+" duplicates"
    
    else :
        # go to next one
        index += 1
        target = nextNote
        numTimes = 0

# end the undo
if len(merged)>0 : gdoc.endUndoAction_("Merge Duplicate Notes")

# summarize the results
rpt = ["<div>\n<h1>Merging Duplicate Notes in File "+gdoc.name()+"</h1>\n\n"]

if len(merged) == 2 :
    rpt.append("<p>You merged 1 pair of duplicate note records. ")
    ess = ""
else :
    rpt.append("<p>You merged "+str(len(merged)/2)+" pairs of duplicate note records. ")
    ess = "s"
if len(merged) > 0 :
    rpt.append("<ol>\n")
    index = 0
    while index < len(merged) :
        rpt.append("<li>"+merged[index]+merged[index+1]+"</li>\n")
        index += 2
    rpt.append("</ol>\n\n")

# finish up
rpt.append("</div>")

# show the report
p = {"name":"Merging Duplicate Note Records", "body":''.join(rpt)}
newReport = gedit.classForScriptingClass_("report").alloc().initWithProperties_(p)
gdoc.reports().addObject_(newReport)
newReport.showBrowser()

