#!/usr/bin/python
#
# Lifelines report 6gen1.ll
# Author: Tom Wetmore, Cliff Manis
#
# Python/GEDitCOM II conversion: 6gen1.py
# Author: John A. Nairn

# Load Lifelines Emulation
from lifelines import *
from operator import add,sub,mul,div,mod,neg,eq,ne,lt,gt,le,ge

# Subroutines
def pedout(indi, gen, max, top, bot) :
    if (le(gen,max)) :
        gen = add(1,gen)
        fath = father(indi)
        moth = mother(indi)
        height = add(1,sub(bot,top))
        offset = div(sub(height,1),2)
        block(indi,add(top,offset),mul(8,sub(gen,2)))
        half = div(height,2)
        pedout(fath,gen,max,top,sub(add(top,half),1))
        pedout(moth,gen,max,add(top,half),bot)

def block(indi, row, col) :
    print ".",
    row = add(3,row)
    col = add(3,col)
    pos(row,col)
    if indi :
        out(name(indi))
    else :
        out("_______________")

# Preamble
pagemode(70,80)
gdoc = ll_init("6gen1.ll program")

# The main method
indi = getindi()
pedout(indi,1,6,1,64)
pageout()

# Get output
finish()