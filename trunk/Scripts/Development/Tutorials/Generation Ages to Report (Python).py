#!/usr/bin/python
#
# Generational Ages Report Script
# 17 JAN 2011, by John A. Nairn
#	
# This script generates a report of average ages of all spouses when
# they got married and when their children were born.
#	
# The report can be for all spouses in the file or just for spouses
# in the currently selected family records.

# Load GEDitCOM II Module
from GEDitCOMII import *

################### Subroutines

# Collect data for the generation ages report
def CollectAges(famList):
    global numHusbAge,sumHusbAge,numFathAge,sumFathAge
    global numWifeAge,sumWifeAge,numMothAge,sumMothAge

    # initialize counters
    numHusbAge=sumHusbAge=numFathAge=sumFathAge=0
    numWifeAge=sumWifeAge=numMothAge=sumMothAge=0
    
    # progress reporting interval
    fractionStepSize=nextFraction=0.01
    numFams=len(famList)
    for (i,fam) in enumerate(famList):
        # read family record information
        husbRef = fam.husband()
        wifeRef = fam.wife()
        chilList = fam.children()
        mdate = fam.marriageSDN()
        
        # read parent birthdates
        hbdate = wbdate = 0
        if husbRef != "":
            hbdate = husbRef.birthSDN()
        if wifeRef != "":
            wbdate = wifeRef.birthSDN()
        
        # spouse ages at marriage
        if mdate>0:
            if hbdate>0:
                sumHusbAge = sumHusbAge + GetAgeSpan(hbdate,mdate)
                numHusbAge = numHusbAge+1
           
            if wbdate>0:
                sumWifeAge = sumWifeAge + GetAgeSpan(wbdate,mdate)
                numWifeAge = numWifeAge+1
                
        # spouse ages when children were born
        if hbdate > 0 or wbdate > 0:
            for chilRef in chilList:
                cbdate = chilRef.birthSDN()
                if cbdate > 0 and hbdate > 0:
                    sumFathAge = sumFathAge + GetAgeSpan(hbdate,cbdate)
                    numFathAge = numFathAge + 1
                if cbdate > 0 and wbdate > 0:
                    sumMothAge = sumMothAge + GetAgeSpan(wbdate,cbdate)
                    numMothAge = numMothAge + 1
                    
        # time for progress
        fractionDone = float(i+1)/float(numFams)
        if fractionDone > nextFraction:
            ProgressMessage(fractionDone)
            nextFraction = nextFraction+fractionStepSize

# Write the results now in the global variables to a
# GEDitCOM II report using <html> style
def WriteToReport():
    # begin report with <h1> for title
    fname = gdoc.name()
    rpt.out("<h1>Generational Age Analysis in " + fname + "</h1>\n")

    # start <table> and give it a <caption> and add header, start body
    rpt.out(MakeTable("begin","caption","Summary of spouse ages when married and when children were born"))
    rpt.out(MakeTable("head",["Age Item","Husband","Wife"],"body"))
    
    # rows for ages when married and when children were borm
    InsertRow("Avg. Age at Marriage", numHusbAge, sumHusbAge, numWifeAge, sumWifeAge)
    InsertRow("Avg. Age at Childbirth", numFathAge, sumFathAge, numMothAge, sumMothAge)

    # end the <tbody> and <table> elements
    rpt.out(MakeTable("endbody","end"))

# Insert table row with husband and wife results
def InsertRow(rowLabel, numHusb, sumHusb, numWife, sumWife):
    tr = [rowLabel]
    if numHusb > 0:
        tr.append("{0:.2f}".format(sumHusb / numHusb))
    else:
        tr.append("-")
    if numWife > 0:
        tr.append("{0:.2f}".format(sumWife / numWife))
    else:
        tr.append("-")
    rpt.out(MakeTable("row l r r",tr))
    
################### Main Script

# Preamble
gedit = CheckVersionAndDocument("Generation Ages to Report (Python)",1.6,2)
if not(gedit) : quit()
gdoc = FrontDocument()

# choose all or currently selected family records
whichOnes = GetOption("Get report for All or just Selected family records",\
None,["All", "Cancel", "Selected"])
if whichOnes=="Cancel":quit()

# Get of list of the choosen family records
if whichOnes=="All":
    fams = gdoc.families()
else:
    fams = GetSelectedType("FAM")

# No report if no family records were found
if len(fams)==0:
    Alert("No family records were selected")
    quit()

# Collect all report data in a subroutine
CollectAges(fams)

# write to report and then done
rpt = ScriptOutput(GetScriptName(),"html")
WriteToReport()
rpt.write()


