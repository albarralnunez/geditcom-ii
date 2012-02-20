#!/usr/bin/python
#
# places (Python Script for GEDitCOM II)
# This script translates the following LifeLines places.ll

# Load Apple's Scripting Bridge for Python
from lifelines import *
from GEDitCOMII import GetOption

# verify document is open and version is acceptable
gdoc=ll_init("places.ll report")

# LifeLines places.ll program translation
tag_stack = list()
place_names = list()

reverse = 0
yesno = GetOption("Reverse place name components?",None,["Yes","Cancel","No"])
if yesno == "Cancel" : quit()
if yesno == "Yes" : reverse = 1
print "Printing all places.\n"
print "Be patient.  This may take a while.\n"

for (pnum,person) in forindi() :
    (node,level,niter) = traverse(person)
    while node :
        setel(tag_stack, level, tag(node))
        if tag(node) == "PLAC" :
            (place_names,num) = extractplaces(node)
            if (reverse) :
                out(pop(place_names))
                while True :
                    p = pop(place_names)
                    if not(p) : break;
                    out(", "+p)
            else :
                out(dequeue(place_names))
                while True :
                    p = dequeue(place_names)
                    if not(p) : break;
                    out(", "+p)
            out("  | "+key(person)+" "+name(person)+" |")
            for i in range(0,level-1) :
                out(" "+tag_stack[i])
            out("\n")
        (node,level) = traverse(niter)

for (fnum,fam) in forfam() :
    (node,level,niter) = traverse(fam)
    while node :
        setel(tag_stack, level, tag(node))
        if tag(node) == "PLAC" :
            (place_names,num) = extractplaces(node)
            if (reverse) :
                out(pop(place_names))
                while True :
                    p = pop(place_names)
                    if not(p) : break;
                    out(", "+p)
            else :
                out(dequeue(place_names))
                while True :
                    p = dequeue(place_names)
                    if not(p) : break;
                    out(", "+p)
            out("  | "+key(fam)+" (")
            person = husband(fam)
            if person :
                relation = ", husb"
            else :
                person = wife(fam)
                if person :
                    relation=", wife"
                else :
                    for (cnum0,child) in children(fam) :
                        if eq(cnum0,0) :
                            person = child
                            relation = ", chil"
            if (person) :
                out(key(person)+" "+name(person)+relation)
            out(") |")
            for i in range(0,level-1) :
                out(" "+tag_stack[i])
            out("\n")
        (node,level) = traverse(niter)

# finish report output
finish()
