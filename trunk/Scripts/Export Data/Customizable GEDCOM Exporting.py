#!/usr/bin/python
#
# Customizable GEDCOM Exporting (Python Script for GEDitCOM II)
# 4 DEC 2010
#
# This script exports all the data to a GEDCOM file by going through the data
# line by line. It is much slower than the built in GEDCOM exporting options
# of GEDitCOM II and thus you should never use this script unless you need
# a custom export process. To create a custom export you edit this script
# as follows:
#
# 1. Use Find command and search for the word "CUSTOMIZE" in this script
#     Each time it appears is a potential decision point where your
#     custom process must decide about what to include in the exported GEDCOM
#     file. Each option is preceded by some text that explains the decision
#     that is needed
# 2. The last option (#4) writes all records of each type in order. One potential
#     customization is to omit all records of one type. That can be done in
#     this section by commenting out one or more of the writeGEDCOM() lines
#
# For example, imagine you want to export a simplified file that omits all notes and
# sources. This customization can be done as follows:
#
# 1. In option #4, delete or comment out writeGEDCOM(gdoc.notes(),"note")
#     and writeGEDCOM(gdoc.sources(),"source")
# 2. Next you also want to delete links to these records in other reocrds.
#     In option #3 insert this check to omit these lines right after keepData = True
#
#        if sref.name() == "NOTE" or sref.name() == "SOUR"
#            keepData=False
#
# 3. Since the header record uses SOUR and NOTE for other reasons, you may want
#     to keep them in the header. This task is done in option #2 by inserting
#     these lines after lineByLine = True
#
#            if theType == "header" :
#                lineByLine=False
#

# Load Apple's Scripting Bridge for Python
from Foundation import *
from ScriptingBridge import *

global gedText

################### Subroutines

# Verify acceptable version of GEDitCOM II is running and a document is open.
# Return 1 or 0 if script can run or not.
def CheckAvailable(gedit,sName,vNeed) :
    vnum = gedit.versionNumber()
    if vnum<vNeed:
        errMsg = "The script '" + sName + "' requires GEDitCOM II, Version "\
        + str(vNeed) + " or newer.\nPlease upgrade and try again."
        print errMsg
        return 0

    if gedit.documents().count()<1 :
        errMsg = "The script '" + sName + \
        "' requires requires a document to be open\n"\
        + "Please open a document and try again."
        print errMsg
        return 0

    return 1

# Write all records of one type
def writeGEDCOM(recList,theType) :
    gdoc.notifyProgressFraction_message_(0.,"Writing "+theType+" records")
    fractionStepSize = nextFraction = 0.01
    recnum = 0
    totRecs = len(recList)
    global gedText
    for rec in recList :
        # CUSTOMIZE #1 :
        # You can examine this specific record to see if you want to include it in the
        #    exported GEDCOM file. Set the flag keepRecord to False to omit this record.
        #    Warning: If you omit one record of a certain type, you should omit all
        #    links to that record as well, but that might be a hard task to complete
        #    in this script. An easier task is to omit all records of a certain type,
        #    such as all NOTE records, but that is best done below in the code that calls
        #    this subroutine
        keepRecord = TRUE
        
        if keepRecord == True :
            # CUSTOMIZE #2 :
            # If you know you want all data in the record, it is faster to set the lineByLine
            #    flag to False so the script can grab all the GEDCOM at once. Normally,
            #    when customizing the GEDCOM export, you need to inspect each line of
            #    GEDCOM data in the writeStructures() subroutine and lineByLine should
            #    be left as True
            lineByLine = True
            
            if lineByLine == True:
                gedText.append(rec.firstLine())
                writeStructures(rec.structures())
            else :
                gedText.append(rec.gedcom())

        # report progress of this script
        recnum = recnum + 1
        fractionDone = float(recnum) / float(totRecs)
        if fractionDone > nextFraction:
            gdoc.notifyProgressFraction_message_(fractionDone,None)
            nextFraction = nextFraction + fractionStepSize
            
# Write one structure to the exported GEDCOM data
def writeStructures(sList) :
    global gedText
    for sref in sList :
        # CUSTOMIZE #3 :
        # You can examine each structure by its tag (sref.name()), level (sref.level()),
        #    or contents (ref.contents()) to decide if it should be included in the
        #    exported GEDCOM file. Set the keepData flag to false to omit it
        keepData = True
        
        if keepData == True :
            gedText.append(sref.firstLine())
            writeStructures(sref.structures())

################### Main Script

# fetch application object
gedit = SBApplication.applicationWithBundleIdentifier_("com.geditcom.GEDitCOMII")

# verify document is open and version is acceptable
if CheckAvailable(gedit,"Customizable GEDCOM Exporting",1.7)==0 :
    quit()

# current front document
gdoc = gedit.documents()[0]

# get file name (exit if canceled)
GEDFile=gdoc.userSaveFileExtensions_prompt_start_title_(["ged"],"Save the custom export to a GEDCOM file","NewGEDCOM.ged",None)
if GEDFile == "" :
    quit()

# start list for the GEDCOM lines
gedText = []

# CUSTOMIZE #4 :
# Export each type of record as a block of records
# To omit any records, comment out the line to export them
# Warning: If you omit records, you should omit any links to that record.
#     For example, if you omit NOTE records, you should customize elsewhere
#     in this script to omit all NOTE lines that link to those records
writeGEDCOM(gdoc.headers(),"header")
writeGEDCOM(gdoc.submissions(),"submission")
writeGEDCOM(gdoc.submitters(),"submitter")
writeGEDCOM(gdoc.individuals(),"individual")
writeGEDCOM(gdoc.families(),"family")
writeGEDCOM(gdoc.notes(),"note")
writeGEDCOM(gdoc.sources(),"source")
writeGEDCOM(gdoc.repositories(),"repository")
writeGEDCOM(gdoc.multimedia(),"multimedia")
writeGEDCOM(gdoc.researchLogs(),"research log")
gedText.append("0 TRLR")

# write to a file using Cocoa
nstring = NSString.stringWithString_(''.join(gedText))
(result,error) = nstring.writeToFile_atomically_encoding_error_(GEDFile,objc.YES,NSUTF8StringEncoding,objc.nil)
if result != True:
    errMsg = "An I-O error occurred trying to write the GEDCOM file"
    gdoc.userOptionTitle_buttons_message_(errMsg,["OK"],error.description())

