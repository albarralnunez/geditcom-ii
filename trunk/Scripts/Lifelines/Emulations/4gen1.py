#!/usr/bin/python
#
# Lifelines report: 4gen1.ll
# Author: Wetmore, Thomas Trask
#
# Python/GEDitCOM II conversion: 4gen1.py
# Author: John A. Nairn

# Load Lifelines Emulation
from lifelines import *
from operator import add,sub,mul,div,mod,neg,eq,ne,lt,gt,le,ge

# Subroutines

def pedout(indi, gen, max, top, bot) :
    if indi and le(gen,max) :
        gen = add(1,gen)
        fath = father(indi)
        moth = mother(indi)
        height = add(1,sub(bot,top))
        offset = div(sub(height,8),2)
        block(indi,add(top,offset),mul(10,sub(gen,2)))
        half = div(height,2)
        pedout(fath,gen,max,top,sub(add(top,half),1))
        pedout(moth,gen,max,add(top,half),bot)

def block(indi, row, col) :
    print ".",
    row = add(3,row)
    col = add(3,col)
    pos(row,col)
    out(name(indi))
    row = add(row,1)
    pos(row,col)
    e = birth(indi)
    out(" b. ")
    if e and date(e) : out(date(e))
    row = add(row,1)
    pos(row,col)
    out(" bp. ")
    if e and place(e) : out(place(e))

# Preamble
pagemode(64,80)
gdoc = ll_init("4gen1.ll program")

# The main method
indi = getindi()
pedout(indi,1,4,1,64)
pageout()

# Script output
finish()

