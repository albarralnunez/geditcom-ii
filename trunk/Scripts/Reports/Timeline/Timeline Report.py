#!/usr/bin/python
#
# Timeline Report (Python Script for GEDitCOM II)
#

# Load Apple's Scripting Bridge for Python
from GEDitCOMII import *
from Foundation import *
from ScriptingBridge import *

################### Classes

# class to hold results in a series of NSMutableArrays (one for each day)
class EventsList:
    def __init__(self):
        self.events=NSMutableArray.alloc().initWithCapacity_(1000)
    def addEvent(self,etext):
        self.events.addObject_(etext)
    def sortEvents(self):
        if self.events.count()>1:
            self.events=self.events.sortedArrayUsingSelector_("caseInsensitiveCompare:")
    def count(self) :
        return self.events.count()
    def decodeEvent(self,index) :
        # list with [year number, year string,month-day,event text]
        evnt = self.events.objectAtIndex_(index)
        blks = evnt.split("|",1)
        dwords = blks[0].split()
        eyear = int(dwords[0])-200000
        if eyear<0 :
            estr = str(-eyear)+"BC"
        else :
            estr = dwords[0][2:]
        emd = ""
        if len(dwords)>1 :
            emd = dwords[1]
            if len(dwords)>2 :
                emd += " "+dwords[2]
        return [eyear,estr,emd,blks[1]]
 
################### Subroutines

# process event of type eTag in individual rec
# If valid date, add to the list
def ProcessEvent(rec,rname,eTag,eVerb):
    global elist
    tags = rec.findStructuresTag_output_value_(eTag,"references",None)
    if len(tags) == 0 : return
    for k in range(len(tags)) :
        event = tags[k]
        
        # get the date
        edate = DateInRange(event.eventDate())
        if edate == "" : continue
        
        # get verb if needed (event if none)
        if eVerb == None :
            eVerb = event.evaluateExpression_("TYPE")
            if eVerb == "" : continue
            eVerb = "had "+eVerb
        anevent = edate+"|"+rname+" "+eVerb
        
        # add place
        eplace = event.eventPlace()
        if eplace != "" :
            anevent += " in "+eplace
            
        elist.addEvent(anevent)

# Check if date is in the allow range and reformat for display
def DateInRange(edate) :
    global gdoc,sdn1,sdn2,sdnbc
    sdr = gdoc.sdnRangeFullDate_(edate)
    if sdr[0] == 0 : return ""
    if sdr[0] < sdn1 : return ""
    if sdn2>0 and sdr[0]>sdn2 : return ""
    dparts = gdoc.datePartsFullDate_(edate)
    eform = gdoc.dateStyleFullDate_withFormat_(dparts[1], "%y %N %D")
    dwords = eform.split()
    if sdr[0] < sdnbc :
        eform = str(200000 - int(dwords[0]))
        if len(dwords)>1 :
            eform += " "+dwords[1]
            if len(dwords)>2 :
                eform += " "+dwords[2]
    else :
        dbleyear = dwords[0].split("/",1)
        if len(dbleyear)>1 :
            eform = str(200001 + int(dbleyear[0]))
            if len(dwords)>1 :
                eform += " "+dwords[1]
                if len(dwords)>2 :
                    eform += " "+dwords[2]
        else :
            eform = "20"+eform
    return eform

# line for block in the table
def GetBlockLine(blkYear) :
    bline = "<tr class='blk'><td class='yd'>"
    if blkYear<0 :
        bline += str(-blkYear)+"BC</td>"
    else :
        bline += str(blkYear)+"</td>"
    return bline+"<td class='md'>&nbsp;</td><td>&nbsp;</td>\n"
    
################### Main Script

# fetch application object
gedit = CheckVersionAndDocument("Perpetual Calendar",0,0)
if not(gedit) : quit()
gdoc = FrontDocument()

# fetch all or selected individual records
whichOnes = GetOption("Make a timeline for the currently selected individuals "+\
"or for all of them?",None,["All","Cancel","Selected"])
if whichOnes == "Cancel" : quit()

# get timeline range
sdr = gdoc.sdnRangeFullDate_("1 JAN 0001")
sdnbc = sdr[0]
y1 = None
y2 = None
prompt = "Enter range of years (e.g., '1600 to 1900', 'to 1850', or 'from 1700')"+\
" for the timeline or leave empty for all events."
while True :
    tr = GetString(prompt,"","Select Timeline Range")
    if tr == None : quit()
    words = tr.split()
    ny = len(words)
    try :
        if ny == 0 :
            sdn1 = 0
            sdn2 = 0
            trange = "Timeline for All Years"
        elif ny == 1 :
            y1 = int(words[0])
            if y1<0 : words[0] = str(-y1)+" B.C."
            sdr = gdoc.sdnRangeFullDate_(words[0])
            if sdr[0] > 0 :
                sdn1 = sdr[0]
                sdn2 = 0
                trange = "Timeline From "+words[0]
        elif ny == 2:
            # options are to #, from #, # to, or # #
            if words[0].lower() == "to" :
                sdn1 = 0
                y2 = int(words[1])
                if y2<0 : words[1] = str(-y2)+" B.C."
                sdr = gdoc.sdnRangeFullDate_(words[1])
                if sdr[1] > 0 :
                    sdn2 = sdr[1]
                    trange = "Timeline To "+words[1]
            elif words[0].lower() == "from" :
                sdn2 = 0
                y1 = int(words[1])
                if y1<0 : words[1] = str(-y1)+" B.C."
                sdr = gdoc.sdnRangeFullDate_(words[1])
                if sdr[0] > 0 :
                    sdn1 = sdr[0]
                    trange = "Timeline From "+words[1]
            elif words[1].lower() == "to" :
                sdn2 = 0
                y2 = int(words[0])
                if y2<0 : words[0] = str(-y2)+" B.C."
                sdr = gdoc.sdnRangeFullDate_(words[0])
                if sdr[0] > 0 :
                    sdn1 = sdr[0]
                    trange = "Timeline From "+words[0]
            else :
                y1 = int(words[0])
                y2 = int(words[-1])
                if y1<0 : words[0] = str(-y1)+" B.C."
                sdr = gdoc.sdnRangeFullDate_(words[0])
                if sdr[0]>0 :
                    sdn1 = sdr[0]
                    if y2<0 : words[-1] = str(-y2)+" B.C."
                    sdr = gdoc.sdnRangeFullDate_(words[-1])
                    if sdr[1]>0 :
                        sdn2 = sdr[1]
                        trange = "Timeline From "+words[0]+" To "+words[1]
        else :
            y1 = int(words[0])
            y2 = int(words[-1])
            if y1<0 : words[0] = str(-y1)+" B.C."
            sdr = gdoc.sdnRangeFullDate_(words[0])
            if sdr[0]>0 :
                sdn1 = sdr[0]
                if y2<0 : words[-1] = str(-y2)+" B.C."
                sdr = gdoc.sdnRangeFullDate_(words[-1])
                if sdr[1]>0 :
                    sdn2 = sdr[1]
                    trange = "Timeline From "+words[0]+" To "+words[-1]
        if sdn1>0 and sdn2>0 and sdn1>sdn2 :
            temp = sdn1
            sdn1 = sdn2
            sdn2 = temp
            trange = "Timeline From "+words[-1]+" To "+words[0]
        break
    except :
        msg1 = "The entered date range is not valid"
        msg = "Enter a range of years (e.g., '1600 to 1900', "+\
        "'to 1850', or 'from 1700'). For BC dates use negative numbers"+\
        " and no earlier than 4700 B.C. (i.e., > -4700)."
        GetOption(msg1,msg,["OK"])
        
# get birth and death SDNs of desired individuals
if whichOnes=="Selected" :
    recs = gdoc.selectedRecords()
    pred = NSPredicate.predicateWithFormat_("recordType LIKE \"INDI\"")
    indis = recs.filteredArrayUsingPredicate_(pred)
    iprops=["birthSDN","deathSDNMax"]
    bddata = gdoc.bulkReaderSelector_target_argument_(iprops,indis,None)
    
elif whichOnes=="All" :
    bddata = []
    indis = gdoc.individuals()
    bddata.append(indis.arrayByApplyingSelector_("birthSDN"))
    bddata.append(indis.arrayByApplyingSelector_("deathSDNMax"))

# counters for progress
fractionStepSize=nextFraction=0.01
ProgressMessage(-1.,"Looking up timeline events")

# number of records to process
numRecs=len(indis)
elist = EventsList()
cache = {}

# loop over individuals, process birth and death
for i in range(numRecs):
    # skip if born after time line end
    minSDN=bddata[0][i]
    if sdn2>0 and minSDN>sdn2 : continue
    
    # skip if died before time line start
    maxSDN=bddata[1][i]
    if maxSDN<sdn1 : continue
    
    # grab some date
    rec=indis[i]
    iname = rec.alternateName()
    
    # process birth for this individual (if has one)
    if minSDN>0 :
        ProcessEvent(rec,iname,"BIRT","was born")
    
    # process death for this individual (if has one)
    if minSDN>0 :
        ProcessEvent(rec,iname,"DEAT","died")
    
    # get other events
    ProcessEvent(rec,iname,"BURI","was buried")
    ProcessEvent(rec,iname,"CHR","was christened")
    ProcessEvent(rec,iname,"NATU","was naturalized")
    ProcessEvent(rec,iname,"EMIG","emigrated")
    ProcessEvent(rec,iname,"IMMI","immigrated")
    ProcessEvent(rec,iname,"ADOP","was adopted")
    ProcessEvent(rec,iname,"EVEN",None)
    
    # family events
    fams = rec.spouseFamilies()
    for j in range(len(fams)) :
        famrec = fams[j]
        key = famrec.id()
        if key not in cache :
            cache[key] = True
            # H - W Family
            fname = famrec.alternateName()
            fpart = fname.split(" Family")
            hw = fpart[0].split("-")
            fname = hw[0]+" and "+hw[1]
            ProcessEvent(famrec,fname,"MARR","were married")
            ProcessEvent(famrec,fname,"DIV","were divorced")
            ProcessEvent(famrec,fname,"EVEN",None)
        
    # EVEN - generic events

    # get unique marriage dates 
    
    # time for progress
    fractionDone = float(i)/float(numRecs)
    if fractionDone > nextFraction:
        ProgressMessage(fractionDone)
        nextFraction = nextFraction+fractionStepSize


# Sort the events
ProgressMessage(-1.,"Sorting the events")
elist.sortEvents()

# make the report
ProgressMessage(-1.,"Preparing report output")

rpt = ScriptOutput(CurrentScript(),"html")
rpt.out("<h1>"+trange+"</h1>\n")

# style
rpt.css("table { border: none; margin-left: 12pt; }\n")
rpt.css("table tbody td { border: none; padding: 4px 8px; vertical-align: top; }\n")
rpt.css("td.yd { text-align: right; }\n")
rpt.css("td.md { border-right: thin solid #444444; width: 40px; }\n")
rpt.css("tr.blk { background-color: #D1E9D1; }\n")

prevYear = 0
num = elist.count()
if num==0 :
    if whichOnes == "All" :
        rpt.out("<p>No events were found in the time range for any individuals.</p>")
    else :
        rpt.out("<p>No events were found in the time range for any selected individuals.</p>")
else :
    # blocks
    blocksize = 25
    eline = elist.decodeEvent(0)
    blkYear = 100*int(eline[0]/100)
    if blkYear > eline[0] : blkYear -= 100
    
    # start table advance past opening block if needed
    rpt.out("<table>")
    needBlk = False
    if y1 != None :
        while y1 >= blkYear :
            blkYear += blocksize
        if y1 < eline[0] :
            rpt.out(GetBlockLine(y1))
        elif y1 == eline[0] :
            needBlk = True
    
    # loop over rows
    for i in range(num) :
        eline = elist.decodeEvent(i)
        
        # blocks
        while eline[0] > blkYear :
            rpt.out(GetBlockLine(blkYear))
            blkYear += blocksize
        if eline[0] == blkYear or needBlk == True :
            rpt.out("<tr class='blk'>\n")
            blkYear += blocksize
            needBlk = False
        else :
            rpt.out("<tr>\n")
        
        # year, md, and details
        if eline[0] == prevYear :
            rpt.out("<td class='yd'>&nbsp;</td>\n")
        else :
            rpt.out("<td class='yd'>"+eline[1]+"</td>\n")
            prevYear = eline[0]
        rpt.out("<td class='md'>"+eline[2]+"</td>\n")
        rpt.out("<td>"+eline[3]+"</td>\n")
        rpt.out("</tr>\n")
    
    # last lines then close table
    if y2 != None:
        if prevYear < y2 :
            while y2 > blkYear :
                rpt.out(GetBlockLine(blkYear))
                blkYear += blocksize
            if y2 != blkYear :
                rpt.out(GetBlockLine(y2))
    rpt.out("</table>")

# output
rpt.write()
