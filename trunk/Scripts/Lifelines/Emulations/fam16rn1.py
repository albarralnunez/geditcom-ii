#!/usr/bin/python
#
# Lifelines report: fam16rn1.ll
# Author: Wetmore, Manis
#
# Python/GEDitCOM II conversion: fam16rn1.py
# Author: John A. Nairn

# Load Lifelines Emulation
from lifelines import *
from operator import add,sub,mul,div,mod,neg,eq,ne,lt,gt,le,ge

# Preamble
gdoc = ll_init("fam10c.ll program")

# The main method
fam = getfam()
if not(fam) :
     fatalerror("You have to select a family record before running this script")
dayformat(0)
monthformat(4)
dateformat(0)
tday = gettoday()	
h = husband(fam)
w = wife(fam)
cols("",6,"Report by:   Cliff Manis  " )
nl()
cols("",19,"MANIS / MANES Family History",50,"P. O. Box 33937   San Antonio, TX  78265-3937")
nl()
nl()
nl()
cols("",6,"HUSBAND:   "+fullname(h,1,1,50)+" (RN="+key(h)+")",80,"Report date:"+stddate(tday))
nl()
nl()
evt = birth(h)
cols("",6,"Born:  "+stddate(evt),35,"Place:  "+place(evt)+"\n")
evt = marriage(fam)
cols("",6,"Marr:  "+stddate(evt),35,"Place:  "+place(evt)+"\n")
evt = death(h)
cols("",6,"Died:  "+stddate(evt),35,"Place:  "+place(evt)+"\n")
cols("",6,"HUSBAND'S",50,"HUSBAND'S\n")
cols("",6,"FATHER:   "+name(father(h))+" (RN="+key(father(h))+")",50,\
"MOTHER:   "+name(mother(h))+" (RN="+key(mother(h))+")") 
nl()
nl()
cols("",6,"WIFE:   "+fullname(w,1,1,50)+" (RN="+key(w)+")")
nl()
nl()
evt = birth(w)
cols("",6,"Born:  "+stddate(evt),35,"Place:  "+place(evt)+"\n")
evt = death(w)
cols("",6,"Died:  "+stddate(evt),35,"Place:  "+place(evt)+"\n")
cols("",6,"WIFE'S",50,"WIFE'S\n")
cols("",6,"FATHER:   "+name(father(w))+" (RN="+key(father(w))+")",50,\
"MOTHER:   "+name(mother(w))+" (RN="+key(mother(w))+")")
nl()
nl()
cols("",6,"===============================================",53,\
"=======================================",92,"==========================\n")
cols("",8,"M/F",22,"CHILDREN",45,"WHEN BORN",62,"WHEN DIED",82,"WHERE BORN\n") 
cols("",45,"1st MARRIAGE",62,"SPOUSE\n")
cols("",6,"===============================================",53,\
"=======================================",92,"==========================\n")
for (num0,child) in children(fam) :
    num = num0+1
    cols("",6,d(num),9,sex(child),11,name(child)+" (RN="+key(child)+")",45,\
    stddate(birth(child)),62,stddate(death(child)),82,place(birth(child))+"\n")
    (fvar,svar,num,iter) = families(child)
    while fvar :
        if eq(num,1) :
            cols("",45,stddate(marriage(fvar)),62)
            if svar :
                out(name(svar)+" (RN="+key(svar)+")")
            nl()
            nl()
        (fvar,svar,num) = families(iter)
    if eq(nfamilies(child),0) :
        nl()

# output
finish()

