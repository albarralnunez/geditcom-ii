#!/usr/bin/python
#
# Lifelines report pdesc1.ll
# Author: Tom Wetmore with
#   Cliff Manis, James P. Jones, and Jim Eggert
#
# Python/GEDitCOM II conversion: pdesc1.py
# Author: John A. Nairn

# Load Lifelines Emulation
from lifelines import *
from operator import add,sub,mul,div,mod,neg,eq,ne,lt,gt,le,ge

# verify document is open and version is acceptable
gdoc = ll_init("pdesc1.ll program")

# LifeLines count_anc.ll program translation
def pout(gen, indi) :
    message(name(indi)+"\n")
    cols("",add(5,mul(4,gen)),d(add(gen,1))+"-- ")
    outp(indi)
    next = add(1,gen)
    (fam,sp,num,iter) = families(indi)
    while fam :
        cols("",add(5,mul(4,gen))," sp-")
        outp(sp)
        if lt(next,15) :
            for (no0,child) in children(fam) :
                pout(next,child)
        (fam,sp,num) = families(iter)

def outp(indi) :
    out(fullname(indi, 1, 1, 40))
    out(" ("+long(birth(indi))+" - "+long(death(indi))+")\n")

# main() method
indi = getindi()
cols("",35,"DECENDANCY CHART\n\n")
cols("",5,"=======================================================================\n\n")
pout(0, indi)

# finish report output
finish()

