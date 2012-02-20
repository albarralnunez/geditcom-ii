#!/usr/bin/python
#
# Date Searching (Python Script for GEDitCOM II)

# Load GEDitCOM II Module
from GEDitCOMII import *

################### Subroutines

# Search on set of records for date
def DateSearch(recs,dateref) :
    global numDates,hits
    global reci,numRecs,nextFraction
    
    for i in range(len(recs)) :
        rec=recs[i]
        dates = rec.findStructuresTag_output_value_("DATE","list",None)
        numDates += len(dates)
        for j in range(len(dates)) :
            onedate = dates[j]
            onerng = rec.sdnRangeFullDate_(onedate[0])
            qual = DateQuality(dateref,onerng)
            if qual>0. :
                hits.append([onedate[0],qual])

        # time for progress
        reci = reci +1
        fractionDone = float(reci)/float(numRecs)
        if fractionDone > nextFraction:
            ProgressMessage(fractionDone)
            nextFraction = nextFraction+fractionStepSize
            
################### Main Script

# Preamble
gedit = CheckVersionAndDocument("Date Searching",1.6,2)
if not(gedit) : quit()
gdoc = FrontDocument()

# get the date
mydate = gdoc.userInputPrompt_buttons_initialText_title_("Prompt Text",\
["OK","Cancel"], "7 DEC 1941", None)
if mydate[0]=="Cancel" : quit()

# get range
myrng = gdoc.sdnRangeFullDate_(mydate[1])
if myrng[0]==0 :
    Alert("The date you entered ("+mydate[1]+") is not a valid date")
    quit()

# globals
SetTauCutoff(50.,2.)
numDates = 0
hits = []

reci = 0
fractionStepSize=nextFraction=0.01
numRecs = len(gdoc.individuals())+len(gdoc.families())
DateSearch(gdoc.individuals(),myrng)
DateSearch(gdoc.families(),myrng)

print "Number of dates searched: "+str(numDates)
print "Matching to date: "+mydate[1]
[tau,cutoff] = GetTauCutoff()
print "tau = "+str(tau)+" days"
print "cutoff = "+str(cutoff)
print "hits = "+str(len(hits))
print ""

if len(hits)==0 : quit()

# dumb sort
ordered = [hits[0]]
for i in range(1,len(hits)) :
    qual = hits[i][1]
    j = 0
    while j<len(ordered) :
        if qual>ordered[j][1] :
            ordered.insert(j,hits[i])
            j = len(ordered)+10
        else :
            j += 1
    if j == len(ordered) :
        ordered.append(hits[i])

for i in range(len(ordered)) :
    print str(i+1)+".\t"+ordered[i][0]+"\t"+str(ordered[i][1])
