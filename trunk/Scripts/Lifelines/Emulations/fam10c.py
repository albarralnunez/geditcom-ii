#!/usr/bin/python
#
# Lifelines report: fam10c.ll
# Author: Manis
#
# Python/GEDitCOM II conversion: fam10c.py
# Author: John A. Nairn

# Load Lifelines Emulation
from lifelines import *
from operator import add,sub,mul,div,mod,neg,eq,ne,lt,gt,le,ge

# Preamble
gdoc = ll_init("fam10c.ll program")

# The main method
fam = getfam()
dayformat(0)
monthformat(4)
dateformat(0)
tday = gettoday()
h = husband(fam)
w = wife(fam)
cols("",55,"Date: "+stddate(tday))
nl()
out("Family Report (fam10)")
nl()
nl()
cols("HUSBAND:   "+fullname(h,1,1,50),63,"(RN="+key(h)+")")
nl()
nl()
evt = birth(h)
cols("Born:  "+stddate(evt),25,"Place:  "+place(evt))
nl()
evt = marriage(fam)
cols("Marr:  "+stddate(evt),25,"Place:  "+place(evt))
nl()
evt = death(h)
cols("Died:  "+stddate(evt),25,"Place:  "+place(evt))
nl()
nl()
cols("HUSBAND'S FATHER:   "+name(father(h)),63,"(RN="+key(father(h))+")")
nl()
cols("HUSBAND'S MOTHER:   "+name(mother(h)),63,"(RN="+key(mother(h))+")")
nl()
nl()
cols("WIFE:   " +fullname(w,1,1,50),63,"(RN="+key(w)+")")
nl()
nl()
evt = birth(w)
cols("Born:  "+stddate(evt),25,"Place:  "+place(evt))
nl()
evt = death(w)
cols("Died:  "+stddate(evt),25,"Place:  "+place(evt))
nl()
nl()
cols("WIFE'S FATHER:   "+name(father(w)),63,"(RN="+key(father(w))+")")
nl()
cols("WIFE'S MOTHER:   "+name(mother(w)),63,"(RN="+key(mother(w))+")")
nl()
nl()
out("========================================================================")
nl()
cols("#  M/F",12,"Childrens Names",63,"RECORD NUM")
nl()
out("========================================================================")
nl()
for (num0,child) in children(fam) :
    num = num0+1
    cols(d(num),4,sex(child),12,name(child),63,"(RN="+key(child)+")")
    nl()
    cols("",4,"Born:",13,stddate(birth(child)),26,place(birth(child)))
    nl()
    cols("",4,"Died:",13,stddate(death(child)),26,place(death(child)))
    nl()
    (fvar,svar,num,iter) = families(child)
    while fvar :
        if eq(num,1) :
            cols("",4,"Marr:",13,stddate(marriage(fvar)),26)
            if svar :
                cols(name(svar),63-25,"(RN="+key(svar)+")")
            nl()
        (fvar,svar,num) = families(iter)
    if eq(nfamilies(child),0) : nl()
    cols("",4,"---------------------------------------------------------")
    nl()

# output
finish()
