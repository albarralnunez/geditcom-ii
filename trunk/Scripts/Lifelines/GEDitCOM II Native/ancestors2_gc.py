#!/usr/bin/python
#
# ancestors2 (Python Script for GEDitCOM II)
# Author: John Nairn

# Native conversion of ancestors2.ll Lifelines program
# Author: Wetmore, Cliff Manis

# Load Apple's Scripting Bridge for Python
from GEDitCOMII import *

################### Subroutines

def shortdate(ld) :
    if ld == "" : return ld
    parts = gdoc.datePartsFullDate_(ld)
    if len(parts) > 1 :
        return parts[1]
    return ""

################### Main Script

# Preamble
scriptName = "ancestors2.ll native conversion"
gedit = CheckVersionAndDocument(scriptName,1.6,2)
gdoc = FrontDocument()
rpt = ScriptOutput(scriptName,"html")

# individual
indi = GetIndividual(gdoc,"Select an individual")
if not(indi) :
    Alert("The have to select an individual before running this script",\
    "Select an individual and try again")
    quit()

# get ancestors and move to a RecordsSet
ancestors = RecordsSet()
ancestors.addAncestorList(GetAncestors(indi,gdoc))
ancestors.nameSort()

# table of ancestors
rpt.out(MakeTable("begin","head",["Name","Gen.","Born","Died"],"body"))
for (n,rs) in ancestors.enumerate() :
    rpt.out(MakeTable("row l c r r",[rs.name,str(rs.value),shortdate(rs.rec.birthDate()),\
    shortdate(rs.rec.deathDate())]))
rpt.out(MakeTable("endbody","end"))

# final output
rpt.write()
