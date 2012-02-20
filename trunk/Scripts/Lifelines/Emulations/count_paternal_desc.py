#!/usr/bin/python
#
# Lifelines report count_paternal_desc.ll
# Author: Jim Eggert
#
# Python/GEDitCOM II conversion: count_paternal_desc.py
# Author: John A. Nairn

# Load Lifelines Emulation
from lifelines import *
from operator import add,gt

# verify document is open and version is acceptable
gdoc = ll_init("count_paternal_desc")

# LifeLines count_paternal_desc.ll program translations
person = getindi()
thisgen = indiset()
allgen = indiset()
allmalegen = indiset()
addtoset(thisgen,person, 0)
if (male(person)) : addtoset(allmalegen, person, 0)
print "Counting generation "
out("Number of paternal descendants of "+key(person)+" "+name(person))
out(" by generation:\n")
thisgensize = 1
gen = -1
while thisgensize :
    thisgensize = 0
    thismalesize = 0
    thismalegen = indiset()
    (person,val,thisgensize,iter) = forindiset(thisgen)
    while person :
        if male(person) :
            thismalesize = add(thismalesize,1)
            addtoset(thismalegen,person,0)
        (person,val,thisgensize) = forindiset(iter)
    thisgensize -= 1     # loop ends and 1 more then gen size
        
    if thisgensize :
        gen = add(gen,1)
        print d(gen)," ",
        out("Generation "+str(gen)+" has "+str(thisgensize))
        out(" paternal descendant")
        if gt(thisgensize,1) : out("s")
        out(" of which "+d(thismalesize)+" are male.\n")
        thisgen = childset(thismalegen)
        allgen = union(allgen,thisgen)
        allmalegen = union(allmalegen,thismalegen)
        
out("Total unique paternal descendants in generations 1-"+d(gen))
out(" is "+d(lengthset(allgen)))
out(" of which "+d(lengthset(allmalegen)))
out(" are male paternal descendants.\n")

# finish report output
finish()
