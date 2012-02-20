#!/usr/bin/python
#
# Lifelines report: ahnentafel.ll
# Author: Wetmore, Thomas Trask
#
# Python/GEDitCOM II conversion: ahnentafel.py
# Author: John A. Nairn

# Load Lifelines Emulation
from lifelines import *
from operator import add,sub,mul,div,mod,neg,eq,ne,lt,gt,le,ge

# Preamble
gdoc = ll_init("ahnentafel.ll program")

# LifeLines ahnentafel.ll program translation

indi = getindimsg("Whose Ahnentafel do you want?")
out("Ahnentafel of "+name(indi)+"\n\n")
message("Computing ahnentafel of "+name(indi))
message("  Dots show persons per generation\n")
ilist = list()
alist = list()
glist = list()
ktab  = table()
enqueue(ilist,indi)
enqueue(alist,1)
enqueue(glist,1)
gen = 0
indi = dequeue(ilist)
while indi :
    ahnen = dequeue(alist)
    newgen = dequeue(glist)
    if ne(gen, newgen) :
        out("Generation "+upper(roman(newgen))+".\n\n")
        message(roman(newgen)+" ")
        gen = newgen
    before = lookup(ktab, key(indi))
    if (before) :
        out(d(ahnen)+". Same as "+d(before)+".\n")
    else :
        message(".")
        insert(ktab, key(indi), ahnen)
        out(d(ahnen)+". "+name(indi)+"\n")
        e = birth(indi)
        if e : out("    b. "+long(e)+"\n")
        e = death(indi)
        if e : out("    d. "+long(e)+"\n")
        out("\n")
        par = father(indi)
        if par :
            enqueue(ilist, par)
            enqueue(alist, mul(2,ahnen))
            enqueue(glist, add(gen, 1))
        par = mother(indi)
        if par :
            enqueue(ilist, par)
            enqueue(alist, add(1,mul(2,ahnen)))
            enqueue(glist, add(gen, 1))
    indi = dequeue(ilist)

# Script output
finish()
