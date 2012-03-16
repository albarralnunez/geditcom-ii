#!/usr/bin/python
#
# ReadRecord (Python Script for GEDitCOM II)
#
# Tell Me About the Record

from Foundation import *
from ScriptingBridge import *

################### Subroutines

# replace scripting addition say command
# Uses current volume and default voice
def SayText(utext) :
    speech = NSSpeechSynthesizer.alloc().initWithVoice_(None)
    result = speech.startSpeakingString_(utext)
    if result!=0 :
        while True :
            if speech.isSpeaking()==False :
                break;
    else :
        print "Speech synthesis failed"
    speech.release()

################### Main Script

# Preamble
gedit = SBApplication.applicationWithBundleIdentifier_("com.geditcom.GEDitCOMII")
gdoc = gedit.documents()[0]

# adjust volume if needed
oldVolume = gedit.volume()
print str(oldVolume)
resetVol = False
if oldVolume<0.2 :
    gedit.setVolume_(0.6)
    resetVol = True

# loop through all records
selrecs = gdoc.selectedRecords()
for rec in selrecs :
    rt = rec.recordType()
    if rt=="INDI" :
        des = rec.objectDescriptionOutputOptions_(["BD","BP","DD","DP","SN","MD","MP","CN","SEX","SAY"])
    elif rt=="FAM" :
        des = rec.objectDescriptionOutputOptions_(["BD","BP","DD","DP","MD","MP","CN","SEX","SAY"])
    elif rt=="HEAD" :
        vers = rec.evaluateExpression_("SOUR.VERS")
        if vers!="" :
            vers = ", version " + vers
        des = "This is the header record for this genealogy file. "
        des += "It was created by jed it com two" + vers + ". "
        hnote = rec.evaluateExpression_("NOTE")
        if len(hnote)>0 :
            beg = hnote.find("This GEDCOM file was originally")
            if beg>=0 :
                endnote = hnote.find(").",beg+11)
                if endnote>=0 :
                    orig = "This jed com "+hnote[beg+11:endnote+2]
                    print orig
                    des += orig
    elif rt=="OBJE" :
        des = rec.objectDescriptionOutputOptions_(["SAY","BD","BP"])
    elif rt=="SUBN" :
        des = "This is the submission record for the file. It is used by members of the LDS Church for Temple Ready submissions of genealogy records."
    else :
        # SUBM, SUBM, NOTE, REPO, _PLC, _BOK
        des = rec.objectDescriptionOutputOptions_(["SAY"])
    
    if des!="" :
        SayText(des)
    else :
        SayText("I don't know anything about this type of custom record.")

# reset volume
if resetVol==True : gedit.setVolume_(oldVolume)
