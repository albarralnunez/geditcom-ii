#!/usr/bin/python
#
# Lifelines report formatted_gedcom.ll
# Authors: Eggert
#
# Python/GEDitCOM II conversion: formatted_gedcom.py
# Author: John A. Nairn

# Load Lifelines Emulation
from lifelines import *
from operator import add,lt

# Subroutines
def header() :
    out(delimiter+"0 HEAD\n")
    out(indenter+"1 SOUR LIFELINES 2.3.3\n")
    out(indenter+"1 DEST ANY\n")
    out(indenter+"1 DATE "+date(gettoday())+"\n")
    out(indenter+"1 FILE "+outfile()+"\n")
    out(indenter+"1 CHAR MACINTOSH\n")
    out(indenter+"1 COMM Formatted GEDCOM output produced by formatted_gedcom\n")
    out(delimiter+"0 @S1@ SUBM\n")
    out(indenter+"1 NAME James Robert Eggert\n")
    out(indenter+"1 ADDR 12 Bonnievale Drive\n")
    out(indenter+indenter+"2 CONT Bedford Massachusetts 01730\n")
    out(indenter+indenter+"2 CONT USA\n")
    out(indenter+"1 PHON 617-275-2004\n")

def formatted_gedcom(node,key) :
    out(delimiter)
    out("0 @"+key+"@ "+tag(node)+"\n")
    (subnode,level,iter) = traverse(node)
    while subnode :
        counter = 0
        while lt(counter,level) :
            out(indenter)
            counter = add(counter,1)
        out(d(level)+" "+tag(subnode)+" "+value(subnode)+"\n")
        (subnode,level) = traverse(iter)

# verify document is open and version is acceptable
outfile()
gdoc = ll_init("formatted_gedcom.ll program")

delimiter = "--------------------------------------------------------------------------\n"
indenter = "    "

# The main method
header()
for (num0,person) in forindi() :
    formatted_gedcom(person,key(person))
for (num0,family) in forfam() :
    formatted_gedcom(family,key(family))

out(delimiter+"0 TRLR\n"+delimiter)

# final output
finish()
