#!/usr/bin/ruby
#
# GEDitCOM II Ruby Test Script
# 5 MAY 2010, by John A. Nairn

# Prepare to use Apple's Scripting Bridge for Ruby

require "osx/cocoa"
include OSX
OSX.require_framework 'ScriptingBridge'

################### Subroutines

# Check that the current version of GEDitCOM II is new enough for this script
# Also check if a document is open
# Return 0 to abort script or 1 if OK to continue
def CheckAvailable(gedit)
	if gedit.versionNumber()<1.29
		puts "This script requires GEDitCOM II, Version 1.3 or newer."
		return 0
	elsif gedit.documents().count()<1
		print "You have to open a document in GEDitCOM II to use this script"
		return 0
	end
	return 1
end

# convert string to AppleScript enumerated constant
def GCConstant(uniqueStr)
    if uniqueStr=="chart"
        byteForm = 0x74724348			# trCH
    elsif uniqueStr=="outline"
        byteForm = 0x74724F55			# trOU
    elsif uniqueStr=="the children"
        byteForm = 0x736B4348			# skCH
    elsif uniqueStr=="the events" 
        byteForm = 0x736B4556			# skEV
    elsif uniqueStr=="the spouses"
        byteForm = 0x736B5350			# skSP
    elsif uniqueStr=="charMacOS"
        byteForm = 0x784F7031			# xOp1
    elsif uniqueStr=="charANSEL"
        byteForm = 0x784F7032			# xOp2
    elsif uniqueStr=="charUTF8"
        byteForm = 0x784F7033			# xOp3
    elsif uniqueStr=="charUTF16"
        byteForm = 0x784F7034			# xOp4
    elsif uniqueStr=="charWindows"
        byteForm = 0x784F7035			# xOp5
    elsif uniqueStr=="linesLF"
        byteForm = 0x784F7036			# xOp6
    elsif uniqueStr=="linesCR"
        byteForm = 0x784F7037			# xOp7
    elsif uniqueStr=="linesCRLF"
        byteForm = 0x784F7038			# xOp8
    elsif uniqueStr=="mmGEDitCOM"
        byteForm = 0x784F7039			# xOp9
    elsif uniqueStr=="mmEmbed"
        byteForm = 0x784F7041			# xOpA
    elsif uniqueStr=="mmPhpGedView"
        byteForm = 0x784F7042			# xOpB
    elsif uniqueStr=="logsInclude"
        byteForm = 0x784F7043			# xOpC
    elsif uniqueStr=="logsOmit"
        byteForm = 0x784F7044			# xOpD
    elsif uniqueStr=="locked"
        byteForm = 0x724C636B			# rLck
    elsif uniqueStr=="privacy"
        byteForm = 0x72507276			# rPrv
    elsif uniqueStr=="unlocked"
        byteForm = 0x72556E6C			# rUnl
    else
        byteForm = 0
    end
    return byteForm
end

# return selected record (or None) if correct type
def GrabRecord(adoc,needType)
    selRec = adoc.selectedRecords()
    if selRec.length==0
        puts "No records were selected"
        return nil
    end
    aRec = selRec[0]
    if aRec.recordType() != needType and needType!="any"
        puts "The selected record is not the correct type"
        return nil
    end
    return aRec
end

################### Main Script

# fetch application object
gedit = OSX::SBApplication.applicationWithBundleIdentifier_("com.geditcom.GEDitCOMII")

# verify document is open and version is acceptable
if CheckAvailable(gedit)==0
	exit
end

# decide if should change "All" individuals or "Selected" individuals
# better to let user choose this option
gdoc=gedit.documents[0]

################### Create a Report

=begin
rpt = ["<div>\n"]
rpt.push("<h1>My Custom Report</h1>\n")

rpt.push("</div>")
theReport = rpt.join

p = {"name"=>"My Ruby Report","body"=>theReport}
newReport = gedit.classForScriptingClass_("report").alloc().initWithProperties_(p)
gdoc.reports.addObject_(newReport)
newReport.showBrowser()
=end

################### Work with documents

#newdoc=gedit.classForScriptingClass_("document").alloc().init()
#gedit.documents().addObject_(newdoc)

################### work with records

# access a record
#puts gdoc.gedcomRecords[6].gcid()
#puts gdoc.gedcomRecords.objectWithID_("@I34@").name()
#puts gdoc.gedcomRecords.objectWithName_("Burkhart, Caroline").recordType()

# Some ruby examples
#puts gdoc.individuals[5].name()
#puts gdoc.families.objectWithID_("@F27@").husband()
#puts gdoc.sources[7].referencedBy()

# create a record
#p = {"name"=>"John Smith","sex"=>"M"}
#gindi=gedit.classForScriptingClass_("individual").alloc().initWithProperties_(p)
#puts gindi
#gdoc.individuals.addObject_(gindi)
#puts gindi
#gdoc.individuals().insertObject_atIndex_(newindi, 0)		# sorts into list regardless of index
#gdoc.individuals().replaceObjectAtIndex_withObject_(1,newindi)		# deletes one and inserts new one
#gindi.setBirthDate_("23 DEC 1965")			# above properties did not set birth date and place?
#gindi.setBirthPlace_("Hackensack, Bergen, NJ, USA")

# create custom record
#p={"recordType"=>"_PLACE"}
#grec=gedit.classForScriptingClass_("gedcomRecord").alloc().initWithProperties_(p)
#puts grec
#gdoc.gedcomRecords.addObject_(grec)
#puts grec

# move a record
#gdoc.individuals().objectWithID_("@I7@").moveTo_(gdoc.families().objectWithID_("@F27@"))
#gdoc.sources()[2].moveTo_(gdoc.individuals().objectWithID_("@I41@"))
#gdoc.multimedia().objectWithName_("John Smith Portrait").moveTo_(gdoc.individuals().objectWithName_("Smith, John, Jr."))

# delete a record
#gdoc.individuals().objectWithName_("Smith, John, Jr.").delete()
#gdoc.families()[3].delete()
#gdoc.multimedia().objectWithID_("@M21@").delete()

################### work with GEDCOM data in records

#gindi=gdoc.individuals().objectWithID_("@I7@")

# read birth date
#bd = gindi.birthDate()
#puts bd

# set name
#gindi.setName_("John /Smith/, Sr.")
#puts gindi.name()

# set all to one value
#gdoc.individuals().setValue_forKey_("hello Ruby","contextInfo")
#puts gdoc.individuals().objectWithID_("@I7@").contextInfo().get()

# reference a structure
#nchi = gdoc.families.objectWithID_("@F128@").structures.objectWithName_("NCHI")
#puts nchi.exists
#if nchi.exists == true
#  puts nchi.contents()
#  nchi.setContents_("4")
#else
#  puts "No such structure"
#end

# reference a subordinate structure
#div = gdoc.families[9].structures.objectWithName_("DIV")
#if div.exists() == true
#  dd = div.structures.objectWithName_("DATE")
#  if dd.exists() == true
#    dd.setContents_("31 OCT 1940")
#  end
#end

# make new structures
#deat = gdoc.individuals().objectWithID_("@I45@").structures().objectWithName_("DEAT")
#p = {"name"=>"DATE","contents"=>"4 JUL 1776"}
#ddate = gedit.classForScriptingClass_("structure").alloc().initWithProperties_(p)
#deat.structures().addObject_(ddate)

#birt = gedit.classForScriptingClass_("structure").alloc().initWithProperties_({"name"=>"BIRT"})
#gdoc.individuals()[2].structures().insertObject_atIndex_(birt,3)

#birt = gedit.classForScriptingClass_("structure").alloc().initWithProperties_({"name"=>"BIRT"})
#gdoc.individuals()[2].structures().replaceObjectAtIndex_withObject_(2,birt)

# move structures
#gindi = gdoc.individuals[2]
#src = gindi.structures.objectWithName_("SPFX")
#p = {"name"=>src.name(),"contents"=>src.contents()}
#dest = gedit.classForScriptingClass_("structure").alloc().initWithProperties_(p)
#gindi.structures.objectWithName_("NAME").structures.addObject_(dest)
#src.delete()

# test restriction property constants
=begin
puts "**** Test restriction property constants"
indiRec = GrabRecord(gdoc,"INDI")
if indiRec!=nil
	resn=indiRec.restriction()
	if resn==GCConstant("locked")
		print "locked"
	elsif resn==GCConstant("privacy")
		print "privacy"
	elsif resn==GCConstant("unlocked")
		print "unlocked"
	else
		print "unknown constant"
	end
end
=end

################### work with dates

# built in SDNs

# individual birth and death dates
#gindi = gdoc.individuals()[4]
#bdmin = gindi.birthSDN()
#puts bdmin
#bdmax = gindi.birthSDNMax()
#puts bdmax
#ddrange = [gindi.deathSDN(),gindi.deathSDNMax()]
#puts ddrange

# family marriage date
#gfam = gdoc.families()[1]
#mrange = [gfam.marriageSDN(),gfam.marriageSDNMax()]
#puts mrange

# get an event date
#edmin = gindi.structures().objectWithName_("CENS").eventSDN()
#puts edmin

# age calculations
#gindi = gdoc.individuals()[4]
#ageAtDeath = (gindi.deathSDN()-gindi.birthSDN())/365.25   # age based on minimum SDNs
#puts ageAtDeath
#minAge = (gindi.deathSDN()-gindi.birthSDNMax())/365.25    # minimum possible age
#puts minAge
#maxAge = (gindi.deathSDNMax()-gindi.birthSDN())/365.25    # maximum possible age
#puts maxAge

#puts gdoc.dateTextSdn_(2455032)

################### work with albums

# create an album

#p = {"name"=>"Ruby Album"}
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
#gdoc.displayByName_byType_sorting_(nil,"INDI",nil)
#gdoc.populateAlbum_("Ruby Album")

################## scripting commands

# begin undo/end undo - see below under detachChild_spouse_ command

# consolidateMultimediaToFolder_changeLinks_preservePaths_()
=begin
puts "**** Test consolidateMultimediaToFolder_changeLinks_preservePaths_()"
gdoc.consolidateMultimediaToFolder_changeLinks_preservePaths_("/Users/nairnj/Desktop/consol",false,true)
puts "Done"
=done

# copyFile
=begin
puts "**** Test copyFileDestination_()"
mmRec = GrabRecord(gdoc,"OBJE")
if mmRec != nil
    fileExt = mmRec.evaluateExpression_("FORM")
    fileName = "/Users/nairnj/Desktop/tofile."+fileExt
    mmRec.copyFileDestination_(fileName)
end
=end

# dateFormatFullDate_()
=begin
puts "**** Test dateFormatFullDate_() command"
puts gdoc.dateFormatFullDate_("1 AUG 1291")
=end

# datePartsFullDate_()
=begin
puts "**** Test datePartsFullDate_() command"
puts gdoc.datePartsFullDate_("FROM 2 JUL 1776 TO 6 JUL 1776")
=end

# dateTextSdn_()
=begin
puts "**** Test dateTextSdn_() command"
puts gdoc.dateTextSdn_(2455032)
=end

# dateToday()
=begin
puts "**** Test dateToday() command"
puts gdoc.dateToday()
sdns = gdoc.sdnRangeFullDate_(gdoc.dateToday())
puts sdns
=end

# objectDescriptionOutputOptions_()
# "LIST", "SAY", "LINKS", "MAINLINK", "HTML", "PRON", "SEX", "BD", "BP", "DD", "DP", "MD", "MP", "FM", "SN", "CN"
=begin
puts "**** Test objectDescriptionOutputOptions_() command"
aRec = GrabRecord(gdoc,"any")
if aRec == nil
    exit
end
puts aRec.objectDescriptionOutputOptions_(["PRON", "SEX", "BD", "BP", "DD", "DP", "MD", "MP", "FM", "SN", "CN"])
=end

# detachChild_spouse_()
=begin
puts "**** Test detachChild_spouse_() and beginUndo/end undo"
famRec = GrabRecord(gdoc,"FAM")
if famRec == nil
    exit
end
gdoc.beginUndo()
famRec.detachChild_spouse_(nil,"husband")
famRec.detachChild_spouse_(nil,"wife")
#famRec.detachChild_spouse_(nil,"both")
chils = famRec.children()
chils.each do |chil|
    print "   detach child ID ",chil.gcid(),"\n"
    famRec.detachChild_spouse_(chil.gcid(),nil)
end
gdoc.endUndoAction_("Family Detachments")
=end

# displayByName_byType_sorting_()
=begin
puts "**** Test displayByName_byType_sorting_() command"
gdoc.displayByName_byType_sorting_(nil,"INDI","view")
=end

# evaluateExpression_()
=begin
puts "**** Test evaluateExpression_() command"
cd=gdoc.individuals()[5].evaluateExpression_("CENS.DATE")
puts cd
=end

# exportGedcomFilePath_withOptions_()
=begin
puts "**** Test exportGedcomFilePath_withOptions_() command"
arg1="charUTF16"
arg2="linesLF"
arg3="mmGEDitCOM"
arg4="logsInclude"
print arg1+", "+arg2+", "+arg3+", "+arg4+"\n"
gdoc.exportGedcomFilePath_withOptions_("/Users/nairnj/Desktop/rbExport.ged",[GCConstant(arg1),GCConstant(arg2),GCConstant(arg3),GCConstant(arg4)])
=end

# findStructuresTag_output_value_()
=begin
puts "**** Test findStructuresTag_output_value_() command"
cd=gdoc.individuals[1].findStructuresTag_output_value_("PLAC",nil,nil)
puts cd
=end

# formatNameValue_case_()
# See "Change Name Case" script

# localStringForKey_()
puts "**** Test localStringForKey_() command"
cd=gdoc.localStringForKey_("BIRT")
puts cd


# mergeWithRecord_()
=begin
puts "**** Test mergeWithRecord_() command"
indiRec = GrabRecord(gdoc,"INDI")
if indiRec!=nil
	indiRec.mergeWithRecord_("@I9@")
end
=end

# notifyProgressFraction_message_()
# See "Generation Ages to Report" script

# populateAlbum_()

# safeHtmlRawText_insertPs_reformatLinks_()
=begin
puts "**** Test safeHtmlRawText_insertPs_reformatLinks_() command"
someText = "Character > & < should be changed"
puts "Input: "+someText
outText = gdoc.safeHtmlRawText_insertPs_reformatLinks_(someText,"all",nil)
puts "Output: "+outText
=end

# print
#print "*** Text printPrintDialog_withProperties_()"
#gedit.print_printDialog_withProperties_(gdoc,True,None)

# sdnRangeFullDate_()
=begin
puts "**** Test sdnRangeFuleDate_() command"
sdns = gdoc.sdnRangeFullDate_("FROM 1920 TO 1929")
predFormat = "(birthSDN > "+sdns[0].stringValue()+") AND (birthSDNMax < "+sdns[1].stringValue()+")"
puts predFormat
pred = NSPredicate.predicateWithFormat_(predFormat)
fetched = gdoc.individuals().filteredArrayUsingPredicate_(pred)
fetched.each do |indi|
   puts indi.birthDate()
end
=end

# showAncestorsGenerations_treeStyle_()
=begin
puts "**** Test showAncestorsGenerations_treeStyle_() command"
indiRec = GrabRecord(gdoc,"INDI")
if indiRec !=nil
    # second is 'trCH' for chart and 'trOU' for outline
    indiRec.showAncestorsGenerations_treeStyle_(4,GCConstant("chart"))
end
=end

# showBrowser()
# see Generation to Ages (Ruby) tutorial

# showDescendantsGenerations_treeStyle_()
=begin
puts "**** Test showDescendantsGenerations_treeStyle_() command"
indiRec = GrabRecord(gdoc,"INDI")
if indiRec !=nil
    # second is 'trCH' for chart and 'trOU' for outline
    indiRec.showDescendantsGenerations_treeStyle_(4,GCConstant("outline"))
end
=end

# sortData_
# the children = skCH = 0x736B4348 /the events = skEV = 0x736B4556 /the spouses = skSP = 0x736B5350 
=begin
puts "**** Test sortData_() command"
aRec = GrabRecord(gdoc,"any")
if aRec!=nil
    aRec.sortData_(GCConstant("the spouses"))
end
=end

#user choice
=begin
fname=gdoc.userChoiceListItems_prompt_buttons_multiple_title_(["item 1","item 2","item 3"],"Prompt Text",["OK","Cancel"],FALSE,"Panel Title")
puts fname
=end

#user input
=begin
fname=gdoc.userInputPrompt_buttons_initialText_title_("Prompt Text",["OK","Cancel"],"default text","Panel Title")
puts fname
=end

# user openFile
=begin
fname=gdoc.userOpenFileExtensions_start_(["ged","gedpkg"],"/Users/nairnj/Desktop")
puts fname
=end

# user openFolder
=begin
fname=gdoc.userOpenFolderStart_("/Users/nairnj")
puts fname
=end

# user option
# see Generation to Ages (Ruby) tutorial

# user saveFile
=begin
fname=gdoc.userSaveFileExtensions_start_title_(["txt"],"/Users/nairnj/Newfile.txt","Ruby Save Panel")
puts fname
=end


