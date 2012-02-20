#!/usr/bin/python
#
# Perpetual Calendar (Python Script for GEDitCOM II)
#
# It will look for all individuals with exact birth and/or death dates
# and add them to the calendar. It will look for all families with
# exact marraige dates and add them as well. The results will be
# output to a report.
#
# You can select to include, birth, death, and/or marriage dates in
# the calendar
#
# The calendar can be for all individuals and families int he file or
# just for selected records. If selected records are used, birth
# and death dates will come from selected individual records and
# marriages will come from selected family records

# Load Apple's Scripting Bridge for Python
from GEDitCOMII import *
from Foundation import *
from ScriptingBridge import *

################### Classes

# class to hold results in a series of NSMutableArrays (one for each day)
class MonthEvents:
    def __init__(self,mname,days):
        self.fullName=mname
        self.abbrevName=mname[0:3]
        self.events=[]
        for ie in range(days):
            self.events.append(NSMutableArray.alloc().initWithCapacity_(50))
    def addEvent(self,day,etext):
        if day>0 and day<=len(self.events):
            self.events[day-1].addObject_(etext)
    def numberOfDays(self):
        return len(self.events)
    def getEvents(self,day):
        if self.events[day-1].count()==0:
            return ""
        else:
            sortEvents=self.events[day-1].sortedArrayUsingSelector_("caseInsensitiveCompare:")
            return sortEvents.componentsJoinedByString_("<br>\n")

################### Subroutines

# process two arrays of SDNs and output event when they match and are not zero
def ProcessSDNs(rr,bdata,offset,etext):
    global reci,nextFraction
    for i in range(len(rr)):
        minSDN=bdata[offset][i]
        if minSDN!=0 and minSDN==bdata[offset+1][i]:
            rec=rr[i]
            nums=gdoc.dateTextSdn_withFormat_(minSDN,"%d %n %y").split(" ")
            dnum=int(nums[0])
            mnum=int(nums[1])
            if mnum>0 and mnum<13:
                linked = "<a href='"+rec.id()+"'>"+rec.alternateName()+"</a>"
                d[mnum-1].addEvent(dnum,nums[2]+": "+linked+etext)
        
        # time for progress
        reci = reci +1
        fractionDone = float(reci)/float(numRecs)
        if fractionDone > nextFraction:
            ProgressMessage(fractionDone)
            nextFraction = nextFraction+fractionStepSize

################### Main Script

# fetch application object
gedit = CheckVersionAndDocument("Perpetual Calendar",1.6,2)
if not(gedit) : quit()
gdoc = FrontDocument()

# fetch all or selected individual records
choices = [";Birth dates",";Death dates",";Marriage dates"]
prompt = "Select which dates to include in the calendar and then click to prepare for \"All\" or just the currently \"Selected\" individual and family records"
otitle = "Perpertual Calendar"
option = gdoc.userChoiceListItems_prompt_buttons_multiple_title_(choices,prompt,["All","Cancel","Selected"],True,otitle)
whichOnes=option[0]
if whichOnes=="Cancel":
    quit()
doBirths = "Birth dates" in option[1]
doDeaths = "Death dates" in option[1]
doMarriages = "Marriage dates" in option[1]
ProgressMessage(-1.,"Reading date information from all records")
if whichOnes=="Selected" :
    recs = gdoc.selectedRecords()
    
    # filter to just INDI records and read dates
    if doBirths==True or doDeaths==True:
        pred = NSPredicate.predicateWithFormat_("recordType LIKE \"INDI\"")
        indis = recs.filteredArrayUsingPredicate_(pred)
        iprops=[]
        if doBirths==True:
            iprops+=["birthSDN","birthSDNMax"]
        if doDeaths==True:
            iprops+=["deathSDN","deathSDNMax"]
        bddata = gdoc.bulkReaderSelector_target_argument_(iprops,indis,None)
    else:
        indis = []
    
    # filter to just FAM records and read dates
    if doMarriages==True:
        pred = NSPredicate.predicateWithFormat_("recordType LIKE \"FAM\"")
        fams = recs.filteredArrayUsingPredicate_(pred)
        mdata = gdoc.bulkReaderSelector_target_argument_(["marriageSDN","marriageSDNMax"],fams,None)
    else:
        fams = []
    del recs
    
elif whichOnes=="All" :
    # read individual dates
    if doBirths==True or doDeaths==True:
        bddata = []
        indis = gdoc.individuals()
        if doBirths==True:
            bddata.append(indis.arrayByApplyingSelector_("birthSDN"))
            bddata.append(indis.arrayByApplyingSelector_("birthSDNMax"))
        if doDeaths==True:
            bddata.append(indis.arrayByApplyingSelector_("deathSDN"))
            bddata.append(indis.arrayByApplyingSelector_("deathSDNMax"))
    else:
        indis = []
    
    # read marriage dates
    if doMarriages==True:
        mdata = []
        fams = gdoc.families()
        mdata.append(fams.arrayByApplyingSelector_("marriageSDN"))
        mdata.append(fams.arrayByApplyingSelector_("marriageSDNMax"))
    else:
        fams = []

# number of records to process
numRecs=len(fams)
if doBirths==True:
    numRecs+=len(indis)
if doDeaths==True:
    numRecs+=len(indis)

# clear array for all dates
d = []
d.append(MonthEvents("January",31))
d.append(MonthEvents("February",29))
d.append(MonthEvents("March",31))
d.append(MonthEvents("April",30))
d.append(MonthEvents("May",31))
d.append(MonthEvents("June",30))
d.append(MonthEvents("July",31))
d.append(MonthEvents("August",31))
d.append(MonthEvents("September",31))
d.append(MonthEvents("October",31))
d.append(MonthEvents("November",30))
d.append(MonthEvents("December",31))

# counters for progress
fractionStepSize=nextFraction=0.01
ProgressMessage(-1.,"Preparing the perpetual calendar")
reci=0

# births
dstart = 0
if doBirths==True:
    ProcessSDNs(indis,bddata,0," was born")
    dstart = 2

# deaths
if doDeaths==True:
    ProcessSDNs(indis,bddata,dstart," died")

   # marriages
if doMarriages==True:
    ProcessSDNs(fams,mdata,0," were married")

# create index
ProgressMessage(1.,"Formatting the final report")
rpt = ScriptOutput(CurrentScript(),"html")
rpt.out("<h1>Perpetual Calendar</h1>\n")

# style
rpt.css("table { margin-left:auto; margin-right:auto; }\n")
rpt.css("table tbody td { border-bottom: 1px solid #ccc;")
rpt.css("   vertical-align:text-top; }\n")
rpt.css("td.daynum { text-align:center; font-weight: bold; }\n")
rpt.css("td.events { width:500px; }\n")

# index
mindex = "<p style='text-align:center;'>|"
for i in range(12):
    mindex = mindex+"<a href='#"+d[i].fullName+"'>"+d[i].abbrevName+"</a>|\n"
mindex = mindex + "</p>\n"

# build tables
for i in range(12):
    if i>0:
        rpt.out("</table><p></p>")
    rpt.out("<a name='"+d[i].fullName+"'></a>"+mindex+"<table>")
    rpt.out("<thead><tr><th colspan='2'>"+d[i].fullName+"</th></tr></thead>")
    rpt.out("<tbody>")
    for j in range(d[i].numberOfDays()):
        rpt.out("<tr><td class='daynum'>"+str(j+1)+"</td>")
        rpt.out("<td class='events'>"+d[i].getEvents(j+1)+"</td></tr>")
    rpt.out("</tbody>")
rpt.out("</table>")
            
# output
rpt.write()