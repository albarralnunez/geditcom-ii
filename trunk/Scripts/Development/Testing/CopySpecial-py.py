#!/usr/bin/python
#
# CopySpecial-py (Python Script for GEDitCOM II)

from Foundation import *
from ScriptingBridge import *

################### Subroutines

def CopyRecord(arec) :
    rt = arec.recordType()
    if rt=="INDI" :
        recData = arec.objectDescriptionOutputOptions_(["BD","BP","DD","DP","SN","MD","MP","CN","SEX","LIST","FM"])
    elif rt=="FAM" :
        recData = arec.objectDescriptionOutputOptions_(["BD","BP","DD","DP","MD","MP","CN","SEX","LIST"])
    elif rt=="OBJE" :
        recData = arec.objectDescriptionOutputOptions_(["BD","BP","LIST"])
    else :
        recData = arec.objectDescriptionOutputOptions_(["LIST"])
    return '\n'.join(recData)+"\n\n"


################### Main Script

# Preamble
gedit = SBApplication.applicationWithBundleIdentifier_("com.geditcom.GEDitCOMII")
gdoc = gedit.documents()[0]

# loop through all records
selrecs = gdoc.selectedRecords()
cdata = []
for rec in selrecs :
    cdata.append(CopyRecord(rec))
cstr = ''.join(cdata)

# write to pasteboard
pb = NSPasteboard.generalPasteboard()
pb.declareTypes_owner_(NSArray.arrayWithObject_("NSStringPboardType"),None)
pb.setString_forType_(cstr,"NSStringPboardType")

