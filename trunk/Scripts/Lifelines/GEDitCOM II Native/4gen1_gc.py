#!/usr/bin/python
#
# 4gen1 (Python Script for GEDitCOM II)
# Author: John Nairn

# Native conversion of 4gen.ll Lifelines program
# Author: Wetmore, Thomas Trask

# Load Apple's Scripting Bridge for Python
from GEDitCOMII import *

################### Subroutines

def pedout(indi,gen,cell) :
    if indi :
        block(indi,gen,cell)
        if gen<= 3 :
           # 1->4, 2->2, 3->1
           shift = 2 ** (3-gen)
           gen += 1
           fath = GetFather(indi)
           moth = GetMother(indi)
           pedout(fath,gen,cell-shift)
           pedout(moth,gen,cell+shift)

def block(indi,gen,cell) :
    global cells
    blck = indi.name()
    bd = indi.birthDate()
    if bd != "" :
       blck += "<br>\n&nbsp;&nbsp;b. "+bd
    bp = indi.birthPlace()
    if bp != "" :
       blck += "<br>\n&nbsp;&nbsp;bp. "+bp
    if gen > 1 :
        skip = "<tr><td colspan='"+str(gen-1)+"'></td>"
    else :
        skip = "<tr>"
    cells.pop(cell-1)
    cells.insert(cell-1,skip+"<td colspan='"+str(5-gen)+"' class='pedi'>"+blck+"</td></tr>")

################### Main Script

# Preamble
scriptName = "4gen1.ll native conversion"
gedit = CheckVersionAndDocument(scriptName,1.6,2)
gdoc = FrontDocument()
rpt = ScriptOutput(scriptName,"html")
rpt.css("* { font-size: 9pt; }")
rpt.css("table { border: none; }")
rpt.css("table tbody td {border: none; }")
rpt.css(".pedi {border-left: thin solid #444; padding: 4pt 2pt; }")

# individual
indi = GetIndividual()
if not(indi) :
    Alert("The have to select an individual before running this script",\
    "Select an individual and try again")
    quit()
    
# empty cells
cells = []
for i in range(15) :
    cell = i+1
    if cell%8 == 0 :
       gen = 1
    elif cell%4 ==0 :
       gen = 2
    elif cell%2 == 0 :
       gen = 3
    else :
       gen = 4
    if gen > 1 :
        skip = "<tr><td colspan='"+str(gen-1)+"'>&nbsp;</td>"
    else :
        skip = "<tr>"
    cells.append(skip+"<td colspan='"+str(5-gen)+"' class='pedi'>&nbsp;</td></tr>")

# loop over individuals
pedout(indi,1,8)

rpt.out("<table>\n")
rpt.out("<tr><td width='70'></td><td width='70'></td><td width='70'></td><td width='312'></td></tr>\n")
rpt.out("\n".join(cells))
rpt.out("</table>\n")

# Output report
rpt.write()
