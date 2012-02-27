#!/usr/bin/python
#
# GEDCOM with Embedded Notes (Python Script for GEDitCOM II)
# 27 FEB 2012
#
# Occasionally you find "brain-dead" GEDCOM utilites that cannot handle
# GEDCOM files with note records. They instead insist on notes embedded
# in the records (a practice that was deprecated and discouraged in the
# GEDCOM standard over 20 years ago). This script will export a file that
# might work with such utilities by embeddng all notes and removing all
# note records. If a utility cannot handle NOTE records, it might have
# other issues as well, but the export file from this script at least gives
# you something to try.
#
# Some other comments about the exported GEDCOM are:
#    1. The exported character set will by UTF-8. Some old GEDCOM utilities
#        cannot handle that, but it only matters if you have many accented
#        or non-ASCII characters. 
#    2. Multimedia objects will be linked by paths that may be relative to
#        your GEDitCOM II file or that file's multimedia folders. You may
#        lose all multimedia links when importing to other software, but
#        most other software lose them anyway. The GEDitCOM II built-in
#        exporting has more options for multimedia, but does not have this
#        embedded notes option.
#    3. Custom place (_PLC), book style (_BOK), and research log (_LOG)
#        records will not be exported. The _LOG links will be removed
#        to prevent bad links.
#    4. The text of notes will be copied, but other data in note records,
#        such as source links, will not be exported 
#

# Load Apple's Scripting Bridge for Python
from GEDitCOMII import *

################### Subroutines

# Write all records of one type
def writeGEDCOM(recList,theType) :
    global gedText
    gdoc.notifyProgressFraction_message_(0.,"Writing "+theType+" records")
    fractionStepSize = nextFraction = 0.01
    recnum = 0
    totRecs = len(recList)
    for rec in recList :
        # See if this record has notes. If not, just grab the entire
        #    GEDCOM now (which is much faster). If the record has notes,
        #    then have to process it line by line
        noteNum=rec.evaluateExpression_("countAll.NOTE")
        if noteNum=="0" :
            logNum=rec.evaluateExpression_("countAll._LOG")
            if logNum=="0" :
                gedText.append(rec.gedcom())
            else :
                gedText.append(rec.firstLine())
                writeStructures(rec.structures())
        else :
            gedText.append(rec.firstLine())
            writeStructures(rec.structures())
        
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
        tagName=sref.name()
        if tagName=="NOTE" :
            # read text of the notes
            # embed in the output breaking an new line and for long line
            concText=sref.evaluateExpression_("contents.CONC")
            concLines=concText.split("\n")
            contStart = str(sref.level()+1)+" CONT "
            concStart = str(sref.level()+1)+" CONC "
            noteLine = str(sref.level())+" NOTE "+concLines[0]
            gedText.append(breakLine(noteLine,concStart))
            for i in range(1,len(concLines)) :
                gedText.append(breakLine(contStart+concLines[i],concStart))
        elif tagName!="_LOG" :
            # If not a NOTE or _LOG line, just write our and
            # recursive process subordinate data
            gedText.append(sref.firstLine())
            writeStructures(sref.structures())

# break line with CONC lines
def breakLine(mtext,cstart) :
    blines=[]
    while len(mtext)>80 :
        spce = mtext.find(" ",70)
        if spce<0 : spce=79
        blines.append(mtext[:spce]+"\n")
        mtext=cstart+mtext[spce:]
    if len(mtext)>0 : blines.append(mtext+"\n")
    return ''.join(blines)

################### Main Script

# Preamble
gedit = CheckVersionAndDocument("GEDCOMwith Embedded Notes",1.7,1)
if not(gedit) : quit()
gdoc = FrontDocument()

# get file name (exit if canceled)
GEDFile=gdoc.userSaveFileExtensions_prompt_start_title_(["ged"],"Save the custom export to a GEDCOM file","NewGEDCOM.ged",None)
if GEDFile == "" : quit()

# start list for the GEDCOM lines
gedText = []

# Export each type of record, but skip NOTE records
writeGEDCOM(gdoc.headers(),"header")
writeGEDCOM(gdoc.submissions(),"submission")
writeGEDCOM(gdoc.submitters(),"submitter")
writeGEDCOM(gdoc.individuals(),"individual")
writeGEDCOM(gdoc.families(),"family")
#writeGEDCOM(gdoc.notes(),"note")
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
    Alert(errMsg,error.description())

