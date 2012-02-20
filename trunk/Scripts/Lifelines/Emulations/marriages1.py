#!/usr/bin/python
#
# Lifelines report: marriages1.ll
# Author: Tom Wetmore, with modifications by Cliff Manis
#
# Python/GEDitCOM II conversion: marriages1.py
# Author: John A. Nairn

# Load GEDitCOM II Module
from lifelines import *
from operator import gt

ll_init("marriages1")

idx = indiset()
for (n0,indi) in forindi() :
    if male(indi) and gt(nspouses(indi),0) :
        addtoset(idx,indi,0)
        print "y",
    else :
        print "n",
print
print "beginning sort"
namesort(idx)   
print "ending sort"
cols("Male Person",30,"Date",50,"Female Person\n")
out("-----------------------------------------")
out("-------------------------------------\n")
(husb,val,n,iter) = forindiset(idx)
while husb :
    cols(fullname(husb,1,0,29),30)
    (wife,famv,m,iters) = spouses(husb)
    while wife :
        if m>1 : cols("",30)
        cols(trim(date(marriage(famv)),20),20)
        out(fullname(wife, 1,0,29)+"\n")
        (wife,famv,m) = spouses(iters)
    print ".",
    (husb,val,n) = forindiset(iter)

finish()