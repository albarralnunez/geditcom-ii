#!/usr/bin/python
#
# Lifelines report: showlines1.ll
# Author: Wetmore
#
# Python/GEDitCOM II conversion: showlines1.py
# Author: John A. Nairn

# Load lifelines Module
from lifelines import *

################### Subroutines

def show_line(indi, plist) :
    out("------------------------------------------------------------\n")
    while indi :
        cols(name(indi),32,stddate(birth(indi)),45,stddate(death(indi)))
        nl()
        print ".",
        moth = mother(indi)
        if moth :
            enqueue(plist, moth)
        indi = father(indi)

################### Main Script

ll_init("showlines1")

plist = list()
indi = getindi()
monthformat(4)
print "Each dot is an ancestor."
out("------------------------------------------------------------\n")
out("ANCESTRAL LINES OF -- "+name(indi)+"\n")
enqueue(plist, indi)
while indi:
    indi = dequeue(plist)
    show_line(indi, plist)
    
finish()

