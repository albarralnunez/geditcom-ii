#!/usr/bin/python
#
# formatted_gedcom (Python Script for GEDitCOM II)
# Author: John Nairn

# Native conversion of formatted_gedcom.ll Lifelines program
# Author: Eggert

# Load Apple's Scripting Bridge for Python
from GEDitCOMII import *

################### Subroutines

# Subroutines
def header() :
    indenter = "".ljust(indent)
    rpt.out(delimiter+"0 HEAD\n")
    rpt.out(indenter+"1 SOUR LIFELINES 2.3.3\n")
    rpt.out(indenter+"1 DEST ANY\n")
    rpt.out(indenter+"1 DATE "+gdoc.dateToday()+"\n")
    rpt.out(indenter+"1 FILE "+outfile+"\n")
    rpt.out(indenter+"1 CHAR MACINTOSH\n")
    rpt.out(indenter+"1 COMM Formatted GEDCOM output produced by formatted_gedcom\n")
    rpt.out(delimiter+"0 @S1@ SUBM\n")
    rpt.out(indenter+"1 NAME James Robert Eggert\n")
    rpt.out(indenter+"1 ADDR 12 Bonnievale Drive\n")
    rpt.out(indenter+indenter+"2 CONT Bedford Massachusetts 01730\n")
    rpt.out(indenter+indenter+"2 CONT USA\n")
    rpt.out(indenter+"1 PHON 617-275-2004\n")
    
def formatted_gedcom(node) :
    rpt.out(delimiter)
    gc = node.gedcom().split("\n")
    for i in range(len(gc)) :
        if gc[i] :
            level = int(gc[i][:1])
            rpt.out("".ljust(level*indent)+gc[i]+"\n")
        
################### Main Script

# Preamble
scriptName = "formatted_gedcom.ll native conversion"
gedit = CheckVersionAndDocument(scriptName,1.6,2)
gdoc = FrontDocument()
outfile = gdoc.userSaveFileExtensions_start_title_(["txt"],None,"Save File Selection")
if not(outfile) : quit()
rpt = ScriptOutput(scriptName,"monospace",outfile)

delimiter = "--------------------------------------------------------------------------\n"
indent = 4

# The main method
header()
for (num0,person) in EveryIndividual() :
    formatted_gedcom(person)
for (num0,family) in EveryFamily() :
    formatted_gedcom(family)

rpt.out(delimiter+"0 TRLR\n"+delimiter)

# final output
rpt.write()
