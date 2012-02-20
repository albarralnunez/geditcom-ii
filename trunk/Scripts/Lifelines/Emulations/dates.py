#!/usr/bin/python
#
# Lifelines report date.ll
# Author: Jim Eggert
#
# Python/GEDitCOM II conversion: dates.py
# Author: John A. Nairn

# Load Lifelines Emulation
from lifelines import *
from operator import add,sub,mul,div,mod,neg,eq,ne,lt,gt,le,ge

# define globals
today = None
tomonth = None
toyear = None
julian = None

# Define subroutines
def do_date(datenode) :
    (day,month,year) = extractdate(datenode)
    if le(month,0) or gt(month,12) :
        daysinmonth = 0
    elif eq(month,9) or eq(month,4) or eq(month,6) or eq(month,11) :
        daysinmonth = 30
    elif eq(month,2) :
        if eq(mod(year,4),0) and (julian or (ne(mod(year,100),0) or eq(mod(year,400),0))) :
            daysinmonth = 29
        else :
            daysinmonth = 28
    else :
        daysinmonth=31
    future = 0
    if gt(year,toyear) :
        future = 1
    elif eq(year,toyear) :
        if gt(month,tomonth) :
            future=1
        elif eq(month,tomonth) and gt(day,today) :
            future=1
    if gt(day,daysinmonth) or future : out("*")
    if lt(year,0) :
        cols(d(year),6)
    else :
        if lt(year,10) : out("0")
        if lt(year,100) : out("0")
        if lt(year,1000) : out("0")
        out(d(year))
    if lt(month,10) : out("0")
    out(d(month))
    if lt(day,10) : out ("0")
    out(d(day)+" ")

# Preamble methods
gdoc = ll_init("dates.ll program")

# The main method
julian = getint("Enter 0 for Gregorian (normal) or 1 for Julian (old) calendar")
(today,tomonth,toyear) = extractdate(gettoday())

tag_stack = list()

print "Printing all dates."
print "Be patient.  This may take a while.\n"

for (num, person) in forindi() :
    (node,level,iter) = traverse(person)
    while node :
        setel(tag_stack, level, tag(node))
        if (eq(strcmp(tag(node), "DATE"), 0)) :
            do_date(node)
            cols(value(node),22,"| ")
            for (tnum,a_tag) in forlist(tag_stack) :
                if lt(tnum+1, level) :
                    out(a_tag+" ")
                else :
                    break
            cols("| "+key(person),9)
            out(" "+name(person)+"\n")
        (node,level) = traverse(iter)

for (num, fam) in forfam() :
    (node,level,iter) = traverse(person)
    while node :
        setel(tag_stack, level, tag(node))
        if (eq(strcmp(tag(node), "DATE"), 0)) :
            do_date(node)
            cols(value(node),22,"| ")
            for (tnum,a_tag) in forlist(tag_stack) :
                if lt(tnum+1, level) :
                    out(a_tag+" ")
                else :
                    break
            cols("| "+key(fam),9)
            person = husband(fam)
            if person :
                relation = ", husb"
            elif wife(fam) :
                person = wife(fam)
                relation = ", wife"
            else :
                for (cnum,child) in children(fam) :
                    if (eq(cnum,0)) :
                        person = child
                        relation = ", chil"
            if person :
                cols(key(person)+" ",7)
                out(name(person)+relation)
            out("\n")
        (node,level) = traverse(iter)

# Generate final output
finish()
