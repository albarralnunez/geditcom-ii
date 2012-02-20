#!/usr/bin/python
#
# dates (Python Script for GEDitCOM II)
# Author: John Nairn

# Native conversion of dates.ll Lifelines program
# Author: Jim Eggert

# Load Apple's Scripting Bridge for Python
from GEDitCOMII import *

################### Subroutines

# Define subroutines
def do_date(datenode) :
    adate = datenode.contents()
    (sdnmin,sdnmax) = gdoc.sdnRangeFullDate_(adate)
    if sdnmin==0 and sdnmax == 0 :
        dd = "*00000000"
    else :
        nums = gdoc.dateNumbersFullDate_(adate)
        if nums[2] < 0 :
            dd = "-"
            nums[2] = -nums[2]
        else :
            dd = ""
        if nums[2] < 10 :
            dd += "000"+str(nums[2])
        elif nums[2]<100 :
            dd += "00"+str(nums[2])
        elif nums[2]<1000 :
            dd += "0"+str(nums[2])
        else :
            dd += str(nums[2])
        if nums[1] < 10 :
            dd += "0"+str(nums[1])
        else :
            dd += str(nums[1])
        if nums[0] < 10 :
            dd += "0"+str(nums[0])
        else :
            dd += str(nums[0])
    parts = gdoc. datePartsFullDate_(adate)
    if len(parts) > 1 :
        fdate = parts[1]
    else :
        fdate = ""
    
    pars = []
    par = datenode.parentStructure()
    while True :
        pars.insert(0,par.name())
        if par.level() < 2 : break
        par = par.parentStructure()
    return [dd, fdate, " ".join(pars)]

# Preamble
scriptName = "dates.ll native conversion"
gedit = CheckVersionAndDocument(scriptName,1.6,2)
gdoc = FrontDocument()
rpt = ScriptOutput(scriptName,"html")

# The main method
[sdn,sdnmax] = gdoc.sdnRangeFullDate_(gdoc.dateToday())

ProgressMessage(None,"Printing all dates.")
ProgressMessage(None,"Be patient.  This may take a while.\n")

rpt.out(MakeTable("begin","head",["Date","Date Text","Tags","Key","Name"],"body"))
for (num, person) in EveryIndividual() :
    dates = person.findStructuresTag_output_value_("DATE","references",None)
    for onedate in dates :
        row = do_date(onedate)
        key = person.id()
        row.append(key[1:-1])
        row.append(person.name())
        rpt.out(MakeTable("row",row))

for (num, fam) in EveryFamily() :
    dates = fam.findStructuresTag_output_value_("DATE","references",None)
    for onedate in dates :
        row = do_date(onedate)
        person = fam.husband().get()
        if person :
            relation = ", husb"
        else :
            person = fam.wife().get()
            if person :
                relation = ", wife"
            else :
                chils = fam.children()
                if len(chils) > 0 :
                    person = chils[0]
                    relation = ", child"
        if person :
            key = person.id()
            row.append(key[1:-1])
            row.append(person.name()+relation)
        else :
            row.append("")
            row.append("")
        rpt.out(MakeTable("row",row))

rpt.out(MakeTable("endbody","end"))

# Generate final output
rpt.write()
