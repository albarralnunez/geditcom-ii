#!/usr/bin/python
#
# Python/GEDitCOM II LifeLines Emulation Testing
# Author: John A. Nairn

# Load Lifelines Emulation
from lifelines import *
from operator import add,sub,mul,div,mod,neg,eq,ne,lt,gt,le,ge

# verify document is open and version is acceptable
gdoc = ll_init("LifeLines Emulation Testing")

# LifeLines Testing
i = getindi()
print tag(i)+" "+value(i)
nd = child(i)
while nd :
   print tag(nd)+" "+value(nd)
   nd = sibling(nd)

# finish report output
#finish()

