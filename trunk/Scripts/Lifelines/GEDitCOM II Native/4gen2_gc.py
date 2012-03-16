#!/usr/bin/python
#
# 4gen2 (Python Script for GEDitCOM II)
# Author: John Nairn

# Native conversion of 4gen.ll Lifelines program but
# now with an alternate format
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
    if gen==4 :
        famc = indi.evaluateExpression_("FAMC")
        if famc!="" : blck += unichr(0x2192)
    bd = indi.lifeSpan()
    if bd != "" :
       blck += "<br>\n<div class='life'>&nbsp;&nbsp;("+bd+")</life>"
    cells.pop(4*cell-3)
    cells.insert(4*cell-3,"<td colspan='"+str(5-gen)+"' rowspan='2' class='pedi'>"+blck+"</td></tr>\n")

################### Main Script

# Preamble
scriptName = "4gen1.ll native conversion"
gedit = CheckVersionAndDocument(scriptName,1.6,2)
gdoc = FrontDocument()
rpt = ScriptOutput(scriptName,"html")
rpt.css("* { font-size: 12pt; }\n")
rpt.css("table { border: none; }\n")
rpt.css("table tbody td {border: none; }\n")
rpt.css(".pedi {border-left: thin solid #444; border-bottom: none; padding: 4pt 2pt; }\n")
rpt.css(".life { font-size: 9pt; }\n")
rpt.css(".b {border-bottom: thin solid #444; font-size: 9pt; }\n")
rpt.css(".l {border-left: thin solid #444; font-size: 9pt; }\n")
rpt.css(".t {border-top: thin solid #444; font-size: 9pt; }\n")
rpt.css(".n { font-size: 9pt; }\n")

# individual
indi = GetIndividual()
if not(indi) :
    Alert("The have to select an individual before running this script",\
    "Select an individual and try again")
    quit()

sty = ["nnb","nnl","nb","nl","nll","nlt","b","l","llb","lll",\
"ll","lt","lnl","lnt","","","lnb","lnl","lb","ll","lll","llt",\
"l","t","nlb","nll","nl","nt","nnl","nnt"]

# empty cells
# four per name, replace second one with acutal name if found
cells = []
for i in range(len(sty)) :
    tds = ""
    for j in range(len(sty[i])) :
        tds += "<td class='"+sty[i][j:j+1]+"'>&nbsp;</td>"
    cells.append("<tr>"+tds)
    if i%2 == 0 :
        cells.append("<td colspan='"+str(4-len(sty[i]))+"' rowspan='2' class='pedi'>&nbsp;</td></tr>\n")
    else :
        cells.append("</tr>\n")

# loop over individuals
pedout(indi,1,8)

rpt.out("<table>\n")
rpt.out("<tr><td width='70'></td><td width='70'></td><td width='70'></td><td width='312'></td></tr>\n")
rpt.out("".join(cells))
rpt.out("</table>\n")

# Output report
rpt.write()
