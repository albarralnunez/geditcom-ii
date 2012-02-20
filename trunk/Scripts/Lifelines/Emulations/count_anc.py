#!/usr/bin/python
#
# Lifelines report count_anc.ll
# Author: Jim Eggert
#
# Python/GEDitCOM II conversion: count_anc.py
# Author: John A. Nairn

# Load Lifelines Emulation
from lifelines import *

# verify document is open and version is acceptable
gdoc = ll_init("count_anc.ll program")

# LifeLines count_anc.ll program translation
person = getindi()
thisgen = indiset()
allgen = indiset()
addtoset(thisgen, person, 0)
print "Counting generation "
out("Number of ancestors of "+key(person)+" "+name(person))
out(" by generation:\n")
thisgensize = 1
gen = 1
while thisgensize :
    thisgensize = lengthset(thisgen)
    if thisgensize :
        gen = gen-1
        print d(gen)+" ",
        out("Generation "+d(gen)+" has "+d(thisgensize)+" individual")
        if thisgensize > 1 : out("s")
        out(".\n")
        thisgen = parentset(thisgen)
        allgen = union(allgen,thisgen)
out("Total unique ancestors in generations "+d(gen)+" to -1 is ")
out(d(lengthset(allgen))+".\n")

# finish report output
finish()

