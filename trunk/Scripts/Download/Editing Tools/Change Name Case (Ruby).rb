#!/usr/bin/ruby
#
# Name Case script
# GEDitCOM II Ruby Script
# 3 MAY 2010, by John A. Nairn
#
# This script changes names of all or selected individuals to be
# all UPPERCASE, to be Uppercase SURNAMES, or to be Title Case Names.
#	
# The Uppercaase SURNAMES options does not change non-surname parts of the name.
# To change names in all upper case to upper case surnames only, first change
# to Title Case Names and then do a second pass for Uppercase SURNAMES.

# Some ruby examples
#gdoc=gedit.documents[0]
#puts gdoc.individuals[5].name
#puts gdoc.individuals.objectWithID_("@I8@").name

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
whichOnes=gdoc.userOptionTitle_buttons_message_("Which names should be changed?",
    ["All","Cancel","Selected"],
    "Change 'All' individuals in the file or just the currently 'selected' individuals.")

# fetch all or selected individual records
if whichOnes=="Selected"
	recs = gdoc.selectedRecords
elsif whichOnes=="All"
	recs = gdoc.individuals
else
	exit
end

# decide the new name case as "upper", "uppersurname", or "title"
# better to let user choose it
nameCase=gdoc.userOptionTitle_buttons_message_("How should the name case be changed?",
    ["UPPERCASE","Uppercase SURNAMES","Title Case"],
    "Make names all uppercase, just the surname uppercase, or use title case.")

print "Changing name case of ",whichOnes," individuals to ",nameCase,"\n"
if nameCase=="UPPERCASE"
    nameCase="upper"
elsif nameCase=="Uppercase SURNAMES"
    nameCase="uppersurname"
else
    nameCase="title"
end

# Main name changing loop
gedit.activate()
gdoc.beginUndo()
numChanged=0
recs.each do |indi|
	if indi.recordType=="INDI"
		oldName=indi.evaluateExpression_("NAME")
		indi.setName_(indi.formatNameValue_case_(oldName,nameCase))
		numChanged=numChanged+1
	end
end
gdoc.endUndoAction_("Change Name Case")

# output summary of the results
if numChanged==1
	puts "One name was changed"
else
	print numChanged," names were changed\n"
end

