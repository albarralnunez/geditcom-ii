#!/usr/bin/python
#
# Lifelines report count_desc.ll
# Author: Jim Eggert
#
# Python/GEDitCOM II conversion: count_desc.py
# Author: John A. Nairn

# Load Lifelines Emulation
from lifelines import *
from operator import add,neg

# verify document is open and version is acceptable
gdoc = ll_init("count_desc.ll program")

# LifeLines count_anc.ll program translation
person = getindi()
thisgen = indiset()
allgen = indiset()
addtoset(thisgen, person, 0)
print "Counting generation "
out("Number of descendants of "+key(person)+" "+name(person))
out(" by generation:\n")
thisgensize = 1
gen = neg(1)
while thisgensize :
    thisgensize = lengthset(thisgen)
    if thisgensize :
        gen = add(gen,1)
        print d(gen)+" ",
        out("Generation "+d(gen)+" has "+d(thisgensize)+" individual")
        if thisgensize > 1 : out("s")
        out(".\n")
        thisgen = childset(thisgen)
        allgen = union(allgen,thisgen)
out("Total unique descendants in generations 1-"+d(gen))
out(" is "+d(lengthset(allgen))+".\n")

# finish report output
finish()

