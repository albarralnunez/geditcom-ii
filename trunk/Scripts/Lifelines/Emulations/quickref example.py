#!/usr/bin/python
#
# Lifelines report: Example program in quickref.pdf
# Author: Wetmore, Thomas Trask
#
# Python/GEDitCOM II conversion: quickref example.py
# Author: John A. Nairn

# Load Lifelines Emulation
from lifelines import *
from operator import add,mul

# Preamble
gdoc = ll_init("quickref example program")

# main() method
indi = getindi()
ilist = list()
alist = list()
enqueue(ilist, indi)
enqueue(alist, 1) 
while length(ilist) :    indi = dequeue(ilist)
    ahnen = dequeue(alist)
    out(d(ahnen)+". "+name(indi)+"\n")
    e = birth(indi)
    if e : out("    b. "+long(e)+"\n")
    e = death(indi)
    if e : out("    d. "+long(e)+"\n")
    par = father(indi)
    if par:        enqueue(ilist, par)
        enqueue(alist, mul(2,ahnen))
    par = mother(indi)    if par:        enqueue(ilist, par)
        enqueue(alist, add(1,mul(2,ahnen)))
finish()