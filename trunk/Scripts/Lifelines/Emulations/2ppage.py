#!/usr/bin/python
#
# Lifelines report: 2ppage.ll
# Author: Wetmore, Manis
#
# Python/GEDitCOM II conversion: 2ppage.py
# Author: John A. Nairn

# Load Lifelines Emulation
from lifelines import *
from operator import add,sub,mul,div,mod,neg,eq,ne,lt,gt,le,ge

# Subroutines

def oneout(i) :
    f = father(i)
    m = mother(i)

    out("  FULL NAME:   "+name(i))
    col(46)
    out("("+key(i)+")")
    nl()
    nl()
    out("     FATHER:   "+name(f))
    col(46)
    out("("+key(f)+")")
    nl()
    out("     MOTHER:   "+name(m))
    col(46)
    out("("+key(m)+")")
    nl()
    nl()
    out("  Born:        "+stddate(birth(i))+" at "+place(birth(i)))
    nl()
    outmarriages(i)
    nl()
    out("  Died:        "+stddate(death(i))+" at "+place(death(i)))
    nl()
    nl()
    outchildren(i)

def outmarriages(i) :
    (s,f,n,iter) = spouses(i)
    while s :
        if eq(1, n) :
            out("  Married:     "+stddate(marriage(f)))
            nl()
            out("  Married to:  "+name(s))
        else :
            out("  Remarried:   "+stddate(marriage(f)))
            nl()
            out("  Remarried to:"+name(s))
        col(46)
        out("("+key(s)+")")
        nl()
        (s,f,n) = spouses(iter)
        
def outchildren(i) :
    j = 0
    (f,s,n,iter) = families(i)
    while f :
        j = add(j, nchildren(f))
        (f,s,n) = families(iter)
    out("  Number of Children:     "+d(j))
    nl()
    j = 1
    (f,s,n,iter) = families(i)
    while f :
        for (m0,c) in children(f) :
            out("   "+d(j)+".  "+name(c))
            col(46)
            out("("+key(c)+")")
            col(57)
            out("Born:  "+stddate(birth(c)))
            nl()
            j = add(j,1)
        (f,s,n) = families(iter)

# Preamble
pagemode(66,80)
gdoc = ll_init("2ppage.ll program")

# The main method
monthformat(4)

tday = stddate(gettoday())

page = 1

num = float(count("INDI"))
for (n0,i) in forindi() :
    n = n0+1
    if mod(n,2) :
        pos(2,1)
        out("  = = = =  MANES / MANIS  Family  History  &  Genealogy  = = =  "+tday)
        nl()
        pos(65,1)
        out("  = = =   Cliff Manis, PO Box 33937, San Antonio, TX 78265  = = "+d(page))
        nl()
        page = add(page,1)
        pos(4,1)
        oneout(i)
    else :
        pos(34,1)
        oneout(i)
        pageout()
    message(None,float(n)/num)
if mod(n0,2) :
    pageout()

# script output
finish()

