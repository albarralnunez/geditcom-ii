#!/usr/bin/python
#
# GEDitCOM II Python Test Script
# 5 MAY 2010, by John A. Nairn

# Prepare to use Apple's Scripting Bridge for Python
from Foundation import *
from ScriptingBridge import *

#import sys
#sys.setdefaultencoding('utf-8')

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

# convert string to AppleScript enumerated constant
def GCConstant(uniqueStr):
    if uniqueStr=="chart":
        byteForm = 0x74724348			# trCH
    elif uniqueStr=="outline":
        byteForm = 0x74724F55			# trOU
    elif uniqueStr=="the children":
        byteForm = 0x736B4348			# skCH
    elif uniqueStr=="the events": 
        byteForm = 0x736B4556			# skEV
    elif uniqueStr=="the spouses":
        byteForm = 0x736B5350			# skSP
    elif uniqueStr=="charMacOS":
        byteForm = 0x784F7031			# xOp1
    elif uniqueStr=="charANSEL":
        byteForm = 0x784F7032			# xOp2
    elif uniqueStr=="charUTF8":
        byteForm = 0x784F7033			# xOp3
    elif uniqueStr=="charUTF16":
        byteForm = 0x784F7034			# xOp4
    elif uniqueStr=="charWindows":
        byteForm = 0x784F7035			# xOp5
    elif uniqueStr=="linesLF":
        byteForm = 0x784F7036			# xOp6
    elif uniqueStr=="linesCR":
        byteForm = 0x784F7037			# xOp7
    elif uniqueStr=="linesCRLF":
        byteForm = 0x784F7038			# xOp8
    elif uniqueStr=="mmGEDitCOM":
        byteForm = 0x784F7039			# xOp9
    elif uniqueStr=="mmEmbed":
        byteForm = 0x784F7041			# xOpA
    elif uniqueStr=="mmPhpGedView":
        byteForm = 0x784F7042			# xOpB
    elif uniqueStr=="logsInclude":
        byteForm = 0x784F7043			# xOpC
    elif uniqueStr=="logsOmit":
        byteForm = 0x784F7044			# xOpD
    elif uniqueStr=="locked":
        byteForm = 0x724C636B			# rLck
    elif uniqueStr=="privacy":
        byteForm = 0x72507276			# rPrv
    elif uniqueStr=="unlocked":
        byteForm = 0x72556E6C			# rUnl
    else:
        byteForm = 0
    return byteForm

# return selected record (or None) if correct type
def GrabRecord(adoc,needType):
    selRec = adoc.selectedRecords()
    if len(selRec)==0:
        print "No records were selected"
        return None
    aRec = selRec[0]
    if aRec.recordType() != needType and needType != "any":
        print "The selected record is not the correct type"
        return None
    return aRec

################### Main Script

# fetch application object
gedit = SBApplication.applicationWithBundleIdentifier_("com.geditcom.GEDitCOMII")

# verify document is open and version is acceptable

if CheckAvailable()==0 :
    quit()

# current front document
gdoc = gedit.documents()[0]

################### Create a Report

"""
rpt = ["<div>\n"]
rpt.append("<h1>My Custom Report</h1>\n")

rpt.append("</div>")
theReport = ''.join(rpt)
print theReport

p = {"name":"My Custom Report","body":theReport}
newReport = gedit.classForScriptingClass_("report").alloc().initWithProperties_(p)
print newReport
gdoc.reports().addObject_(newReport)
print newReport
newReport.showBrowser()
"""

################### work with documents

#newdoc=gedit.classForScriptingClass_("document").alloc().init()
#gedit.documents().insertObject_atIndex_(newdoc,0)
#gedit.documents().addObject_(newdoc)

################### work with records

# access a record

#print gdoc.gedcomRecords()[6].id()
#theName = gdoc.gedcomRecords().objectWithID_("@I34@").name()
#print theName.encode('utf-8')
#print gdoc.gedcomRecords().objectWithName_("Burkhart, Caroline").recordType()

#print gdoc.individuals()[5].name()
#print gdoc.families().objectWithID_("@F27@").husband()
#print gdoc.sources()[7].referencedBy()

# create new record
#p = {"name":"John Smith","sex":"M","id":"@I3@"}
#gindi=gedit.classForScriptingClass_("individual").alloc().initWithProperties_(p)
#print gindi
#gdoc.individuals().addObject_(gindi)
#print gindi
#gdoc.individuals().insertObject_atIndex_(newindi, 0)		# sorts into list regardless of index
#gdoc.individuals().replaceObjectAtIndex_withObject_(1,newindi)		# deletes one and inserts new one
#gindi.setBirthDate_("23 DEC 1965")			# above properties did not set birth date and place?
#gindi.setBirthPlace_("Hackensack, Bergen, NJ, USA")

# create custom record
#p={"recordType":"_PLACE"}
#gindi=gedit.classForScriptingClass_("gedcomRecord").alloc().initWithProperties_(p)
#print gindi
#gdoc.gedcomRecords().addObject_(gindi)
#print gindi

# move a record
#gdoc.individuals().objectWithID_("@I7@").moveTo_(gdoc.families().objectWithID_("@F27@"))
#gdoc.sources()[2].moveTo_(gdoc.individuals().objectWithID_("@I41@"))
#gdoc.multimedia().objectWithName_("John Smith Portrait").moveTo_(gdoc.individuals().objectWithName_("Smith, John, Jr."))

# create and attach note
#gnote=gedit.classForScriptingClass_("note").alloc().init()
#gdoc.notes().addObject_(gnote)
#gnote.setNotesText_("This place information has following note")
#gnote.moveTo_(gdoc.individuals().objectWithID_("@I7@"))

# delete a record
#gdoc.individuals().objectWithName_("Smith, John, Jr.").delete()
#gdoc.families()[3].delete()
#gdoc.multimedia().objectWithID_("@M21@").delete()

################### work with GEDCOM data in records

#gindi=gdoc.individuals().objectWithID_("@I7@")

# read birth date
#bd = gindi.birthDate()
#print bd

# set name
#gindi.setName_("John /Smith/, Sr.")
#print gindi.name()

# set all to one value
#gdoc.individuals().setValue_forKey_("hello","contextInfo")
#print gdoc.individuals().objectWithID_("@I7@").contextInfo().get()

# reference a structure
#nchi = gdoc.families().objectWithID_("@F128@").structures().objectWithName_("NCHI")
#print nchi
#print nchi.exists()
#if nchi.exists() == True:
#  print nchi.contents()
#  nchi.setContents_("4")
#else:
#  print "No such structure"

# reference a subordinate structure
#div = gdoc.families()[9].structures().objectWithName_("DIV")
#if div.exists() == True:
#  dd = div.structures().objectWithName_("DATE")
#  if dd.exists() == True:
#      dd.setContents_("31 OCT 1940")

# make new structure
#deat = gdoc.individuals().objectWithID_("@I45@").structures().objectWithName_("DEAT")
#p = {"name":"DATE","contents":"4 JUL 1776"}
#ddate = gedit.classForScriptingClass_("structure").alloc().initWithProperties_(p)
#deat.structures().addObject_(ddate)

#birt = gedit.classForScriptingClass_("structure").alloc().initWithProperties_({"name":"BIRT"})
#gdoc.individuals()[2].structures().insertObject_atIndex_(birt,3)

#birt = gedit.classForScriptingClass_("structure").alloc().initWithProperties_({"name":"BIRT"})
#gdoc.individuals()[2].structures().replaceObjectAtIndex_withObject_(2,birt)

# move structures
#gindi = gdoc.individuals()[2]
#src = gindi.structures().objectWithName_("SPFX")
#p = {"name":src.name(),"contents":src.contents()}
#dest = gedit.classForScriptingClass_("structure").alloc().initWithProperties_(p)
#gindi.structures().objectWithName_("NAME").structures().addObject_(dest)
#src.delete()

# entire GEDCOM data
#gindi = gdoc.individuals()[2]
#recText = gindi.gedcom()
#recText = "0 @I44@ INDI\n1 NAME Raised A. /Cain/"
#gindi.setGedcom_(recText)

# restriction propery constants
"""
print "**** Test restriction property constants"
indiRec = GrabRecord(gdoc,"INDI")
if indiRec!=None:
	resn=indiRec.restriction()
	if resn==GCConstant("locked"):
		print "locked"
	elif resn==GCConstant("privacy"):
		print "privacy"
	elif resn==GCConstant("unlocked"):
		print "unlocked"
	else:
		print "unknown constant"
"""

################### work with dates

# built in SDNs

# individual birth and death dates
#gindi = gdoc.individuals()[4]
#bdmin = gindi.birthSDN()
#print bdmin
#bdmax = gindi.birthSDNMax()
#print bdmax
#ddrange = (gindi.deathSDN(),gindi.deathSDNMax())
#print ddrange

# family marriage date
#gfam = gdoc.families()[1]
#mrange = [gfam.marriageSDN(),gfam.marriageSDNMax()]
#print mrange

# get an event date
#edmin = gindi.structures().objectWithName_("CENS").eventSDN()
#print edmin

# age calculations
#gindi = gdoc.individuals()[4]
#ageAtDeath = (gindi.deathSDN()-gindi.birthSDN())/365.25   # age based on minimum SDNs
#print ageAtDeath
#minAge = (gindi.deathSDN()-gindi.birthSDNMax())/365.25    # minimum possible age
#print minAge
#maxAge = (gindi.deathSDNMax()-gindi.birthSDN())/365.25    # maximum possible age
#print maxAge

#print gdoc.dateTextSdn_withFormat_(2455032,None)

################### work with albums

# create an album

#p = {"name":"Python Album"}
#album=gedit.classForScriptingClass_("album").alloc().initWithProperties_(p)
#gdoc.albums().addObject_(album)
#gdoc.albums().insertObject_atIndex_(album,0) 		# works but is the same

# move record to an album
#gdoc.individuals()[0].moveTo_(album)
#gdoc.individuals()[1].moveTo_(album)
#gdoc.individuals()[2].moveTo_(album)

# remove record from an album
#album.gedcomRecords()[0].delete()

# populateAlbum_() command
#gdoc.displayByName_byType_sorting_(None,"INDI",None)
#gdoc.populateAlbum_(None)

################## scripting commands

# begin undo/end undo
"""
see below under detachChild_spouse_ command
"""

# can link to
#print gdoc.individuals()[0].canLinkRecordType_("NOTE")

# consolidateMultimediaToFolder_changeLinks_preservePaths_()
"""
print "**** Test consolidateMultimediaToFolder_changeLinks_preservePaths_()"
gdoc.consolidateMultimediaToFolder_changeLinks_preservePaths_("/Users/nairnj/Desktop/consol",False,True)
print "Done"
"""

# copyFileDestination_()
"""
print "**** Test copyFileDestination_()"
mmRec = GrabRecord(gdoc,"OBJE")
if mmRec != None:
    fileExt = mmRec.evaluateExpression_("FORM")
    fileName = "/Users/nairnj/Desktop/tofile."+fileExt
    mmRec.copyFileDestination_(fileName)
"""

# dateFormatFullDate_()
"""
print "**** Test dateFormatFullDate_() command"
print gdoc.dateFormatFullDate_("1 AUG 1291")
"""

# datePartsFullDate_()
"""
print "**** Test datePartsFullDate_() command"
print gdoc.datePartsFullDate_("FROM 2 JUL 1776 TO 6 JUL 1776")
"""

# dateTextSdn_()
"""
print "**** Test dateTextSdn_withFormat_() command"
print gdoc.dateTextSdn_withFormat_(2455032,None)
"""

# dateToday()
"""
print "**** Test dateToday() command"
print gdoc.dateToday()
sdns = gdoc.sdnRangeFullDate_(gdoc.dateToday())
print sdns
"""

# objectDescriptionOutputOptions_()
"""
# "LIST", "SAY", "LINKS", "MAINLINK", "HTML", "PRON", "SEX", "BD", "BP", "DD", "DP", "MD", "MP", "FM", "SN", "CN"
print "**** Test objectDescriptionOutputOptions_() command"
aRec = GrabRecord(gdoc,"any")
if aRec == None:
    quit()
print aRec.objectDescriptionOutputOptions_(["PRON", "SEX", "BD", "BP", "DD", "DP", "MD", "MP", "FM", "SN", "CN"])
"""

# detachChild_spouse_()
"""
print "**** Test detachChild_spouse_() and beginUndo/end undo"
famRec = GrabRecord(gdoc,"FAM")
if famRec == None:
    quit()
gdoc.beginUndo()
famRec.detachChild_spouse_(None,"husband")
famRec.detachChild_spouse_(None,"wife")
famRec.detachChild_spouse_(None,"both")
chils = famRec.children()
for chil in chils:
    print "   detach child ID ",chil.id()
    famRec.detachChild_spouse_(chil.id(),None)
gdoc.endUndoAction_("Family Detachments")
"""

# displayByName_byType_sorting_()
"""
print "**** Test displayByName_byType_sorting_() command"
gdoc.displayByName_byType_sorting_("Second Album",None,"view")
"""

# evaluateExpression_()
"""
print "**** Test evaluateExpression_() command"
cd=gdoc.individuals()[5].evaluateExpression_("CENS.DATE")
print cd
"""

# exportGedcomFilePath_withOptions_()
"""
print "**** Test exportGedcomFilePath_withOptions_() command"
arg1="charWindows"
arg2="linesCR"
arg3="mmGEDitCOM"
arg4="logsOmit"
print arg1+", "+arg2+", "+arg3+", "+arg4
gdoc.exportGedcomFilePath_withOptions_("/Users/nairnj/Desktop/pyExport.ged",[GCConstant(arg1),GCConstant(arg2),GCConstant(arg3),GCConstant(arg4)])
"""

# findStructuresTag_output_value_()
"""
print "**** Test findStructuresTag_output_value_() command"
cd=gdoc.individuals()[1].findStructuresTag_output_value_("PLAC",None,None)
print cd
"""

# formatNameValue_case_()
# See "Change Name Case" script

# localStringForKey_()
"""
print "**** Test localStringForKey_() command"
cd=gdoc.localStringForKey_("BIRT")
print cd
"""

# mergeWithRecord_()
"""
print "**** Test mergeWithRecord_() command"
indiRec = GrabRecord(gdoc,"INDI")
if indiRec!=None:
	indiRec.mergeWithRecord_("@I9@")
"""

# notifyProgressFraction_message_()
# See "Generation Ages to Report" script

# populateAlbum_()

# safeHtmlRawText_insertPs_reformatLinks_
"""
print "**** Test safeHtmlRawText_insertPs_reformatLinks_() command"
someText = "Character > & < should be changed"
print "Input: "+someText
outText = gdoc.safeHtmlRawText_insertPs_reformatLinks_(someText,"all",None)
print "Output: "+outText
"""

# print
#print "*** Text printPrintDialog_withProperties_()"
#gedit.print_printDialog_withProperties_(gdoc,True,None)

# sdnRangeFullDate_() and search by date range
"""
print "**** Test sdnRangeFuleDate_() command"
sdns = gdoc.sdnRangeFullDate_("FROM 1920 TO 1929")
predFormat = "(birthSDN > "+sdns[0].stringValue()+") AND (birthSDNMax < "+sdns[1].stringValue()+")"
print predFormat
pred = NSPredicate.predicateWithFormat_(predFormat)
fetched = gdoc.individuals().filteredArrayUsingPredicate_(pred)
for indi in fetched:
   print indi.birthDate()
"""


# showAncestorsGenerations_treeStyle_()
"""
print "**** Test showAncestorsGenerations_treeStyle_() command"
indiRec = GrabRecord(gdoc,"INDI")
if indiRec!=None:
    # second is 'trCH' for chart and 'trOU' for outline
    indiRec.showAncestorsGenerations_treeStyle_(4,GCConstant("outline"))
"""

# showBrowser()
# see Generation to Ages (Python) tutorial

# showBrowserpaneWithId_()
#gfam = gdoc.families()[1]
#gfam.showBrowserpaneWithId_("Events")

# showDescendantsGenerations_treeStyle_()
"""
print "**** Test showDescendantsGenerations_treeStyle_() command"
indiRec = GrabRecord(gdoc,"INDI")
if indiRec!=None:
    # second is 'trCH' for chart and 'trOU' for outline
    indiRec.showDescendantsGenerations_treeStyle_(4,GCConstant("chart"))
"""

# sortData_()
# the children = skCH = 0x736B4348 /the events = skEV = 0x736B4556 /the spouses = skSP = 0x736B5350
"""
print "**** Test sortData_() command"
aRec = GrabRecord(gdoc,"any")
if aRec!=None:
    aRec.sortData_(GCConstant("the spouses"))
"""

#user choice
"""
fname=gdoc.userChoiceListItems_prompt_buttons_multiple_title_(["item 1","item 2","item 3"],"Prompt Text",["OK","Cancel"],TRUE,"Panel Title")
print fname
"""

#user input
"""
fname=gdoc.userInputPrompt_buttons_initialText_title_("Prompt Text",["OK","Cancel"],"default text","Panel Title")
print fname
"""


# user openFile
"""
fname=gdoc.userOpenFileExtensions_prompt_start_title_(["ged","gedpkg"],"Open a file now","/Users/nairnj/Desktop/","Python Open Panel")
print fname
"""

# user openFolder
"""
fname=gdoc.userOpenFolderPrompt_start_title_("Choose a folder now","/Users/nairnj/","Open Panel Title")
print fname
"""

# user option
# see Generation to Ages (Python) tutorial

# user saveFile
"""
fname=gdoc.userSaveFileExtensions_prompt_start_title_(["txt"],"Choose save location","/Users/nairnj/Newfile.txt","Python Save Panel")
print fname
"""




