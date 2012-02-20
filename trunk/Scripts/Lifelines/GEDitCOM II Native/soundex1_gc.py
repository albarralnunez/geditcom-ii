#!/usr/bin/python
#
# soundex1 (Python Script for GEDitCOM II)
# Author: John Nairn

# Native conversion of soundex.ll Lifelines program
# Author: James P. Jones

# Load Apple's Scripting Bridge for Python
from GEDitCOMII import *

################### Main Script

# Preamble
scriptName = "soundex1.ll native conversion"
gedit = CheckVersionAndDocument(scriptName,1.6,2)
gdoc = FrontDocument()
rpt = ScriptOutput(scriptName,"html")
rpt.css("table { border: none; }")
rpt.css("table thead th {border-bottom: thin solid #000000; border-left: none;"+\
" color: black; padding: 0pt 0pt 2pt 0pt; background-color:#ffffff;}")
rpt.css("table tbody td {border: none; padding: 1pt 6pt; }")

# display records and sort by view name
gdoc.displayByName_byType_sorting_(None,"INDI","view")

# heading
rpt.out("<h1>SOUNDEX CODES OF ALL SURNAMES IN "+gdoc.name()+"</h1>\n")
rpt.out(MakeTable("begin","head l c",["Surname","Soundex Code"],"body"))

# loop over individuals
last = ""
indis = gdoc.individuals()
for indi in indis :
    surn = indi.surname()
    if surn != last :
        rpt.out(MakeTable("row l c",[surn.upper(),gdoc.soundexForText_(surn)]))
        last = surn
rpt.out(MakeTable("endbody","end"))

# Output report
rpt.write()
