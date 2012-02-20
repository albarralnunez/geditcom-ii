#!/usr/bin/python
#
# Lifelines report: bkdes16-1.ll
# Author: Wetmore, Manis
#
# Python/GEDitCOM II conversion: bkdes16-1.py
# Author: John A. Nairn

# Load Lifelines Emulation
from lifelines import *
from operator import add,sub,mul,div,mod,neg,eq,ne,lt,gt,le,ge

# Subroutines
def pout(gen, indi) :
    print name(indi)
    cols("",10)
    ndots = 0
    while lt(ndots, gen) :
        out(". ")
        ndots = add(1,ndots)
    out("* "+name(indi))
    e = birth(indi)
    if e : out(", b. "+long(e))
    nl()
    (sp,fam,num,iter) = spouses(indi)
    while sp :
        cols("",10)
        ndots = 0
        while lt(ndots, gen) :
            out("  ")
            ndots = add(1,ndots)
        out("    m. "+name(sp))
        nl()
        (sp,fam,num) = spouses(iter)
    next = add(1,gen)
    if lt(next,15) :
        (fam,sp,num,iter) = families(indi)
        while fam :
            for (no0,child) in children(fam) :
                pout(next, child)
            (fam,sp,num) = families(iter)

# Preamble
gdoc = ll_init("bkdes16-1.ll program")

# The main method
indi = getindi()
cols("",10,"Report by:  Cliff Manis   MANIS / MANES Family History   P. O. Box 33937   San Antonio, TX  78265-3937 ")
nl()
cols("",10,"Phone:  1-512-654-9912")
nl()
cols("",10,"Date:   27 Jun 1992")
nl()
nl()
cols("",10,"DESCENDANTS OF: "+name(indi))
nl()
nl()
pout(0, indi)

# output
finish()
