#!/usr/bin/python
#
# Lifelines report coverage.ll
# Authors: Wetmore, Woodbridge, Eggert
#
# Python/GEDitCOM II conversion: converage.py
# Author: John A. Nairn

# Load Lifelines Emulation
from lifelines import *
from operator import add,sub,mul,div,mod,neg,eq,ne,lt,gt,le,ge

# verify document is open and version is acceptable
gdoc = ll_init("coverage.ll program")

# LifeLines coverage.ll program translation
indi0 = getindi()
print "Collecting data .... "
ilist = list()
glist = list()
garray = list()        
dtable = table()
darray = list()
enqueue(ilist, indi0)
enqueue(glist, 1)
indi = dequeue(ilist)
while indi:
    gen = dequeue(glist)
    i = getel(garray, gen)
    i = add(i,1)
    setel(garray, gen, i)
    if not(lookup(dtable, key(indi))) :
        insert(dtable, key(indi), gen)
        i = getel(darray, gen)
        i = add(i,1)
        setel(darray, gen, i)
    par = father(indi)
    if par:
        enqueue(ilist, par)
        enqueue(glist, 1+gen)
    par = mother(indi)
    if par :
        enqueue(ilist, par)
        enqueue(glist, 1+gen)
    indi = dequeue(ilist)

i = 1
tot = 1
num = getel(garray, i)
dnum = getel(darray, i)
numsum = num
dnumsum = dnum
out("Ancestor Coverage Table for "+name(indi0)+"\n\n")
cols("Gen",6,"Total",16,"Found",26,"(Diff)",38,"Percentaage\n\n")
while num:
    cols(d(sub(i,1)),6)
    if i < 31 :
        cols(d(tot),16-5)
    else :
        cols("",16-5)
    cols(d(num),26-15)
    if num != dnum :
        cols("("+d(dnum)+")",38-25)
    else :
        cols("",38-25)
    if i < 31 :
        u = mul(num,100)
        q = div(u,tot)
        m = mod(u,tot)
        m = mul(m,100)
        m = div(m,tot)
        out(d(q)+".")
        if m < 10 : out("0")
        out(d(m)+" %")
        tot = mul(2,tot)
    out("\n")
    
    i = add(i,1)
    num = getel(garray, i)
    dnum = getel(darray, i)
    numsum = add(numsum,num)
    dnumsum = add(dnumsum,dnum)
    print str(i)+"  "+str(num)

out("\n")
cols("all",16,d(numsum),26)
if numsum != dnumsum :
    out("("+d(dnumsum)+")\n")
    
# finish report output
finish()

