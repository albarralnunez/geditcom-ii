#!/usr/bin/python
#
# GEDitCOM II Export vCard Script
# 17 AUG 2010
#
# This script will export all or selected records to a standard vCard
# file (with extension vcf). These cards are normally used in address
# or contacts software and thus normally only make sentence for individuals
# with address. Thus this script can optionally be restricted to individuals
# with known address in residence (or RESI) events. If an individual has
# multiple address, all will be included in the vCard.
#
# Each individual vCard will include following information (if available)
#   name
#   birthdates
#   all residence address (including phones, emails, and URLS)
#   main record emails and URLs
#   portrait image
#   the first set of notes

# Prepare to use Apple's Scripting Bridge for Python
from Foundation import *
from ScriptingBridge import *
import base64

################### Subroutines

# Verify acceptable version of GEDitCOM II is running and a document is open.
# Return 1 or 0 if script can run or not.
def CheckAvailable(gedit,sName,vNeed):
    vnum = gedit.versionNumber()
    if vnum<vNeed:
        errMsg = "The script '" + sName + "' requires GEDitCOM II, Version "\
        + str(vNeed) + " or newer.\nPlease upgrade and try again."
        print errMsg
        return 0

    if gedit.documents().count()<1:
        errMsg = "The script '" + sName + \
        "' requires requires a document to be open\n"\
        + "Please open a document and try again."
        print errMsg
        return 0

    return 1
    
# get email and url lines
def FindEmailAndURLs(sref,thedoc):
    eandu = ""
    objes = sref.findStructuresTag_output_value_("OBJE","references",None)
    for obje in objes:
        mmid = obje.contents()
        objerec = thedoc.multimedia().objectWithID_(mmid)
        if objerec != None:
            form = objerec.evaluateExpression_("FORM")
            if form.lower() == "url":
                theurl = objerec.evaluateExpression_("_FILE")
                parse = theurl.split(":",1)
                if parse[0].lower() == "mailto":
                    if len(parse)>1:
                        eandu = eandu + "\nEMAIL:" + parse[1]
                else:
                    eandu = eandu + "\nURL:" + theurl
    return eandu
                
# return vCard for one individual
def GetVCard(indiRec,thedoc,resiOnly):
    # check for residenceis
    resis = indiRec.findStructuresTag_output_value_("RESI","references",None)
    if len(resis) == 0 and resiOnly == "Yes":
        return ""

    vCard = 'BEGIN:VCARD\nVERSION:2.1'

    # Name N:Surname;Given Names;;;Name Suffix.
    rawName = idata[0][recnum]
    namePieces = indiRec.namePartsGedcomName_(rawName)
    vCard = vCard + "\nN;CHARSET=UTF-8:" + namePieces[1] + ";" + namePieces[0] + ";;;" + namePieces[2]
    
    # Formatted name - or name as spoken
    vCard = vCard + "\nFN;CHARSET=UTF-8:" + idata[1][recnum]
    
    # birthdate
    bsdn = idata[2][recnum]
    if bsdn!=0 and bsdn == idata[3][recnum]:
        isoDate = indiRec.dateTextSdn_withFormat_(bsdn,"%y%N%D")
        vCard = vCard + "\nBDAY:" + isoDate
    
    # addresses and phone numbers
    rdata = gdoc.bulkReaderSelector_target_argument_(["evaluate","evaluate","evaluate","evaluate",\
    "evaluate","evaluate","evaluate"],resis,["ADDR","ADDR.ADR1","ADDR.ADR2","ADDR.CITY","ADDR.STAE",\
    "ADDR.POST","ADDR.CTRY"])
    for rr in range(len(resis)):
        # main residence
        resi=resis[rr]
        addr = rdata[0][rr]
        if addr != "":
            vCard = vCard + "\nADR;CHARSET=UTF-8;HOME:"
            addrLines = addr.splitlines()
            vCard = vCard + ';'.join(addrLines)
            if len(addrLines) == 1:
                vCard = vCard + ";;"
            elif len(addrLines) == 2:
                vCard = vCard + ";"
    
        # address by separate fields
        # ADR;HOME:ADR1;ADR2;;CITY;STAE;POST;CTRY
        adr1 = rdata[1][rr]
        adr2 = rdata[1][rr]
        city = rdata[1][rr]
        stae = rdata[1][rr]
        post = rdata[1][rr]
        ctry = rdata[1][rr]
        adrLabel = adr1 + ";" + adr2 + ";;" + city + ";" + stae + ";" + post + ";" + ctry
        if adrLabel != ";;;;;;":
            vCard = vCard + "\nADR;CHARSET=UTF-8;HOME:" + adrLabel
    
        # phone numbers
        phones = resi.findStructuresTag_output_value_("PHON","references",None)
        for phone in phones:
            tel = phone.contents();
            if tel != "":
                vCard = vCard + "\nTEL;HOME:" + tel

        # email and URLS
        vCard = vCard + FindEmailAndURLs(resi,thedoc)

    # main individual email and URLS
    vCard = vCard + FindEmailAndURLs(indiRec,thedoc)

    # is there a photo?
    portrait = idata[4][recnum]
    if portrait != "N":
        porObje = idata[5][recnum]
        if porObje!="":
            obje=thedoc.multimedia().objectWithID_(porObje)
            if obje != None:
                objePath = obje.objectPath()
                if objePath != "":
                    try:
                        f = open(objePath,'rb')
                        imageData = f.read()
                        f.close()
                    except IOError:
                        # just skip if file not found
                        cantOpen = True
                    else:
                        vCard = vCard + "\nPHOTO;BASE64:"
                        encodedData = base64.b64encode(imageData)
                        for i in xrange((len(encodedData)/76)+1):
    				        vCard = vCard + "\n  " + encodedData[i*76:(i+1)*76]                

    # notes from main record (at most 1)
    noteid = idata[6][recnum]
    if noteid != "":
        noterec = thedoc.notes().objectWithID_(noteid)
        if noterec != None:
            notetext = noterec.notesText()
            if notetext.find("<div>") < 0:
                noteLines = notetext.splitlines()
                vCard = vCard + "\nNOTE;CHARSET=UTF-8;QUOTED-PRINTABLE:" + '=0D=0A='.join(noteLines)        

    # end
    vCard = vCard + "\nEND:VCARD"
    return vCard

################### Main Script

# fetch application object
gedit = SBApplication.applicationWithBundleIdentifier_("com.geditcom.GEDitCOMII")

# verify document is open and version is acceptable (actually needs 1.5 build 2)
if CheckAvailable(gedit,"Export vCards",1.7)==0 :
    quit()

# current front document
gedit.setMessageVisible_(False)
gdoc = gedit.documents()[0]

# decide if should export "All" individuals or "Selected" individuals optionally restricting
# to those with known residences
choices = ["Selected Individuals","Selected Individuals with Known Residences",\
"All Individuals","All Individuals with Known Residences"]
prompt = "Select which individuals should be exported to vCard file"
otitle = "Export vCards"
option = gdoc.userChoiceListItems_prompt_buttons_multiple_title_(choices,prompt,["OK","Cancel"],False,otitle)
if option[0] == "Cancel":
    quit()
item = option[2][0]
if item == 1:
    recs = gdoc.selectedRecords()
    needResi="No"
elif item == 2:
    recs = gdoc.selectedRecords()
    needResi="Yes"
elif item == 3:
    recs = gdoc.individuals()
    needResi="NO"
else:
    recs = gdoc.individuals()
    needResi="Yes"

# gave save file name
desktop = NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES).objectAtIndex_(0)
fname = gdoc.userSaveFileExtensions_prompt_start_title_(["vcf"],None,desktop,"Export vCard File")
if fname == "":
    quit()

# loop over the records adding individuals to allCards string
fractionStepSize = nextFraction = 0.01
precede = ""
allCards = ""
totRecs = len(recs)
recnum=0
gedit.setMessageVisible_(True)
gdoc.notifyProgressFraction_message_(-1.,"Reading relevant data from all records")
idata = gdoc.bulkReaderSelector_target_argument_(["evaluate","alternateName","birthSDN","birthSDNMax",\
"evaluate","evaluate","evaluate","recordType"],recs,["NAME","","","","_NOPOR","OBJE","NOTE",""])
gdoc.notifyProgressFraction_message_(-1.,"Preparing the vCard file")
for indi in recs:
    # add only if record is an individual record (selected records may not be individuals)
    if idata[7][recnum]=="INDI":
        oneCard = GetVCard(indi,gdoc,needResi)
        if oneCard != "":
            allCards = allCards + precede + oneCard
            precede = "\n"
    
    # report progress of this script
    recnum = recnum + 1
    fractionDone = float(recnum) / float(totRecs)
    if fractionDone > nextFraction:
        gdoc.notifyProgressFraction_message_(fractionDone,None)
        nextFraction = nextFraction + fractionStepSize

# output to file
if allCards == "":
    gedit.setMessageVisible_(False)
    errMsg = "No vCards were found from the selected set of records" 
    gdoc.userOptionTitle_buttons_message_(errMsg,["OK"],"You chose '" + option[1][0] + "'")
    quit()

# write to a file using Cocoa
nstring = NSString.stringWithString_(allCards)
(result,error) = nstring.writeToFile_atomically_encoding_error_(fname,objc.YES,NSUTF8StringEncoding,objc.nil)
if result != True:
    errMsg = "An I-O error occurred trying to write the vCard file"
    gdoc.userOptionTitle_buttons_message_(errMsg,["OK"],error.description())
