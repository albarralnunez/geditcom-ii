#!/usr/bin/python
#
# Lifelines report ancestor2.ll
# Authors: Wetmore, Cliff Manis
#
# Python/GEDitCOM II conversion: ancestor2.py
# Author: John A. Nairn

# Load Lifelines Emulation
from lifelines import *

# verify document is open and version is acceptable
gdoc = ll_init("ancestors2.ll program")

# LifeLines ancestors2.ll program translation
a = indiset()
monthformat(4)
#b = indiset() is not needed, it is created below
i = getindi()
addtoset(a,i,0)
b = ancestorset(a)
namesort(b)
out("ANCESTORS OF -- "+upper(name(i))+"    ("+key(i)+")\n\n")
(i,x,n,iter) = forindiset(b)
while i :
    cols(fullname(i,1,0,36),38,key(i),49,stddate(birth(i)),-64,stddate(death(i)),-79)
    nl()
    (i,value,n) = forindiset(iter)

# finish report output
finish()


