#!/usr/bin/python
#
# Python Template (Python Script for GEDitCOM II)

# Load GEDitCOM II Module
from GEDitCOMII import *

################### Subroutines

################### Main Script

# Preamble
gedit = CheckVersionAndDocument("Python Template",1.6,2)
if not(gedit) : quit()
gdoc = FrontDocument()

#print "Hello Python World"

# tests
so = ScriptOutput("Test","html")

alist = []
for (n,indi) in EveryIndividual() :
    alist.append(RecordLink(indi,True))

so.out(Centered(MakeList(alist,True)))

so.write()

