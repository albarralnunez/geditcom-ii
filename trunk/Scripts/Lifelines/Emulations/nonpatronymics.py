#!/usr/bin/python
#
# Lifelines report: nonpatronymics.ll
# Author: Jim Eggert
#
# Python/GEDitCOM II conversion: nonpatronymics.py
# Author: John A. Nairn

# Load GEDitCOM II Module
from lifelines import *
from operator import ne,eq,add,sub

ll_init("nonpatronymics")

n = 0
ns = 0
header = 0
for (num0,indi) in forindi() :
    num1 = num0+1
    fath = father(indi)
    if fath :
        if ne(0,strcmp(surname(indi),surname(fath))) :
            if (eq(header,0)) :
                out("Dissimilar surnames\n")
                out("   Similar surnames\n")
                header = 1
            if eq(strcmp(soundex(indi),soundex(fath)),0) :
                out("   ")
                ns = add(ns,1)
            out(d(num1)+" "+name(indi))
            out(" <> ")
            out(name(fath))
            nl()
            n = add(n,1)
nl()
out(d(num1)+" individuals scanned.\n")
out(d(n)+" nonpatronymic inheritances found")
if eq(n,0) :
    out(".\n")
else :
    out(",\n")
    out(d(sub(n,ns))+" of which were soundex-dissimilar.\n")

finish()
