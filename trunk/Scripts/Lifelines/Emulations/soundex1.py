#!/usr/bin/python
#
# Lifelines report soundex1.ll
# Author: James P. Jones
#
# Python/GEDitCOM II conversion: soundex1.py
# Author: John A. Nairn

# Load Apple's Scripting Bridge for Python
from lifelines import *

# verify document is open and version is acceptable
gdoc = ll_init("soundex1.ll report")

# LifeLines soundex1.ll program translation
idx = indiset()
for (n,indi) in forindi() :
    addtoset(idx,indi,n)
    
print "indexed "+d(n)+" persons."
print "\nbegin sorting"
namesort(idx)
print "done sorting"

cols("",11,"SOUNDEX CODES OF ALL SURNAMES IN DATABASE\n\n")
cols("",16,"   Surname      Soundex Code\n")
cols("",16," -------------  ------------\n")

last = " "
(indi,value,n,iter) = forindiset(idx)
while indi :
    if strcmp(surname(indi),last) :
        cols("",20,upper(surname(indi)),36,soundex(indi)+"\n")
        last = surname(indi)
        print ".",
    (indi,value,n) = forindiset(iter)

# finish report output
finish()

# Notes:
#
# The repeated calls to surname(indi) in the above loop is inefficient in GEDitCOM II.
# It would be much better to call the name once
#
#     psurname = surname(indi)
#
# and then replace all subsequent calls to surname(indi) with psurname

