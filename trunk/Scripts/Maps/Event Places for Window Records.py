#!/usr/bin/python
#
# Places for Selected Record (Python Script for GEDitCOM II)
#
# INDI browser - places for that individual
# FAM browser - places for family, spouses, and children
# Tree Window - places for all visible members
# Index Window - places for records currently displayed
# Search Window - places for all search hits
#
# Needed
# Finish events
# It can be slow

# Load GEDitCOM II Module
from GEDitCOMII import *

################### Classes

# Cache repository record
class Place :
    def __init__(self,prec) :
        self.rec = prec
        self.bb = None
    
    # return bb for first map (only reads once)
    # if none bb or error return 1 element list wih error message
    def getBB(self) :
        if self.bb==None :
            bbmap = self.rec.structures().objectWithName_("_BOX")
            if bbmap.exists() == True :
                self.bb = GetLatLonCentroid(bbmap.evaluateExpression_("_BNDS"))
            else :
                self.bb = ["Place has no maps"]
        return self.bb
 
################### Subroutines

def AddRecPlaces(rec,rEvents,eType,pbox) :
    global pois,poiNum,poicache,firstRec,idcache,rectype
    global preccache,numEvents,totalEvents,eventRecords,startEvents
    
    # skip if done already
    key = rec.id()
    if key in idcache : return
    if eType!="INDIEvents" :
        idcache[key] = "Done"
    
    # get start count on first call for this record
    if eType!="INDIAttributes" :
        startEvents = numEvents
        
    # get name and type
    if rec.recordType()=="FAM" :
        recName = SpouseNames(rec)
    else :
        recName = rec.alternateName()
        
    # check for first record
    if firstRec==None :
        firstRec = recName
        if rec.recordType()=="FAM" : firstRec += " Family"
    
    if eType=="INDIAttributes" :
        recName += "'s"
        inAttr = True
    else :
        inAttr = False
    
    # get all events
    es = rec.findStructuresTag_output_value_(eType,"references",None)
    for e in es :
        tag = e.name()
        if tag in rEvents :
            totalEvents += 1
            typeVerb = rEvents[tag]
            
            # get name or GPS location
            plcname = e.evaluateExpression_("_GPS")
            addrDet = ""
            if len(plcname)==0 :
                hasGPS = False
                plcname = e.eventPlace()
            else :
                hasGPS = True
                addr = e.evaluateExpression_("ADDR")
                if len(addr)>0 :
                    addrLines = addr.split("\n")
                    addrDet = " (Address: "+', '.join(addrLines)+")"
            
            # if has place or GPS, create POI
            if plcname :
                type = ""
                if inAttr==False :
                    evnt = Event(e)
                    if typeVerb == "TYPE" :
                        type = e.evaluateExpression_("TYPE")
                        if len(type) > 0 :
                            typeVerb = "had an event of type "+type
                        else :
                            typeVerb = "had a generic event"
                elif tag=="RESI" :
                    # RESI must be the last attribute in the list
                    if recName[-2:]=="'s" :
                        recName = recName[:-2]
                    evnt = Event(e)
                else :
                    evnt = Attribute(e)
                if plcname in poicache :
                    det = evnt.randomDescribe(recName,typeVerb,True)
                    poicache[plcname].append(det+addrDet)
                    numEvents += 1
                else :
                    if hasGPS==True :
                        bb = GetLatLonCentroid(plcname)
                    else :
                        # read map from class if cached or add to cache and read
                        if plcname in preccache :
                            bb = preccache[plcname].getBB()
                        else :
                            prec = gdoc.places().objectWithName_(plcname)
                            if prec.exists()==True :
                                preccache[plcname] = Place(prec)
                                bb = preccache[plcname].getBB()
                            else :
                                bb = []
                    
                    if len(bb)>1 :
                        lat = bb[0].coordinate
                        lon = bb[1].coordinate
                        
                        # check if allowed
                        if pbox :
                            if lat<pbox[0] or lat>pbox[2] : continue
                            if pbox[1]>pbox[3] :
                                if lon<pbox[1] and lon>pbox[3] : continue
                            else :
                                if lon<pbox[1] or lon>pbox[3] : continue
                                    
                        # expand range and create POI
                        CheckRange(lat,lon)
                        poiNum += 1
                        det = evnt.randomDescribe(recName,typeVerb,True)
                        if len(type)>0 :
                            label = recName+" "+gdoc.localStringForKey_(type)
                        else :
                            label = recName+" "+gdoc.localStringForKey_(tag)
                        poicache[plcname] = [lat,lon,poiNum,label,det+addrDet]
                        numEvents += 1
    
    # If added events, count this record
    if eType!="INDIEvents" :
        if startEvents < numEvents : eventRecords += 1
    
# expand bounding box if needed
def CheckRange(lat,lon) :
    global bbox
    if bbox==None :
        bbox = [lat-.1,lon,lat+.1,lon]
    else :
        if lat < bbox[0] : bbox[0] = lat
        if lat > bbox[2] : bbox[2] = lat
        if lon < bbox[1] : bbox[1] = lon
        if lon > bbox[3] : bbox[3] = lon
  
################### Main Script

# Preamble
gedit = CheckVersionAndDocument("Event Places for Window Records",1.6,2)
if not(gedit) : quit()
gdoc = FrontDocument()

iEvnts = { "BIRT":"was born","DEAT":"died","BAPM":"was baptised","CHR":"was christened",\
"GRAD":"graduated","CENS":"was recorded in a census","BURI":"was buried",\
"IMMI":"immigrated","EMMI":"emmigrated","NATU":"was naturalized","ADOP":"was adopted",\
"ORDN":"was ordained","EVEN":"TYPE" }
#  RESI has to be last in the attribute list
iAttrs = { "OCCU":"occupation was","EDUC":"education was","RESI":"lived"}
fEvnts = {"MARR":"were married","DIV":"were divorced","CENS":"were recorded in a census",\
"EVEN":"TYPE" }

# initialize
bbox = None
poiNum=0
pois = []
poicache = {}
idcache = {}
preccache = {}

# counts
# len(poicache) is number of mapped points
totalEvents = 0        # total number of possible
numEvents = 0          # number of events mapped
eventRecords = 0       # number of records with events

# get listed records (pick out of tree windows)
selRecs = gdoc.listedRecords()
wt = gdoc.windowType()
if wt=="AncestorController" or wt == "DescendantController" :
    getRecs = []
    for recdata in selRecs :
        if recdata[1]==" " or isinstance(recdata[1], int) : continue
        getRecs.append(recdata[1].get())
    selRecs = getRecs

# process each one by type
firstRec = None
numRecs = len(selRecs)
fractionStepSize=nextFraction=0.01
for i in range(numRecs) :
    # update progress
    fractionDone = float(i)/float(numRecs)
    if fractionDone > nextFraction:
        ProgressMessage(fractionDone)
        nextFraction = nextFraction+fractionStepSize

    # handle record by type
    arec = selRecs[i]
    subrecs = []
    if arec.recordType()=="_PLC" :
        ebox = GetBoundingBox(arec.evaluateExpression_("_BOX._BNDS"))
        if len(ebox)<4 : continue
        subids = arec.referencedBy()
        for onerec in subids :
            indirec = gdoc.individuals().objectWithID_(onerec).get()
            if indirec :
                subrecs.append(indirec)
            else :
                famrec = gdoc.families().objectWithID_(onerec).get()
                if famrec : subrecs.append(famrec)
    else :
        ebox = None
        subrecs = [arec]
    
    # look records found
    for subrec in subrecs :
        rectype = subrec.recordType()
        if rectype=="INDI":
            AddRecPlaces(subrec,iEvnts,"INDIEvents",ebox)
            AddRecPlaces(subrec,iAttrs,"INDIAttributes",ebox)
            famses = subrec.spouseFamilies()
            for famrec in famses :
                AddRecPlaces(famrec,fEvnts,"FAMEvents",ebox)
        elif rectype=="FAM":
            AddRecPlaces(subrec,fEvnts,"FAMEvents",ebox)
            husb = subrec.husband().get()
            if husb :
                AddRecPlaces(husb,iEvnts,"INDIEvents",ebox)
                AddRecPlaces(husb,iAttrs,"INDIAttributes",ebox)
            wife = subrec.wife().get()
            if wife :
                AddRecPlaces(wife,iEvnts,"INDIEvents",ebox)
                AddRecPlaces(wife,iAttrs,"INDIAttributes",ebox)
            chil = subrec.children()
            for child in chil :
                AddRecPlaces(child,iEvnts,"INDIEvents",ebox)
                AddRecPlaces(child,iAttrs,"INDIAttributes",ebox)

ProgressMessage(1.0)

# assemble pois now
for key in poicache :
    plist = poicache[key]
    lat = plist[0]
    lon = plist[1]
    num = plist[2]
    if len(plist)==5 :
        label = plist[3]
        det = plist[4]
    else :
        label = plist[3]+" and other events (click to see)"
        det = '</p><p>'.join(plist[4:])
    pois.append(MakeMapPOI(lat,lon,num,label,det))
    
# were any found
if bbox==None :
    msg = "Either the current front window has no individual or family records"
    msg += " or none of them have mappable events."
    Alert("Did not find any mappable events for the records in the current front window.",msg)
    quit()

# combine pois
poiall = ''.join(pois)

# create map report
rpt = ScriptOutput(GetScriptName(),"html")

# enlarge to screen size and create map
screen = GetMainScreenSize()
mh = screen[0]+10.
mv = screen[1]+10.
mwidth = screen[2]-20.
mheight = screen[3]-20.
[mcss,mscript,mbody] = createJSMap(mheight-185.,bbox,poiall,None,True)

# transfer to report and write it
rpt.css(mcss)
rpt.addhead(mscript)
if len(selRecs) > 1:
    firstRec = str(len(selRecs))+" individuals or families from "+gdoc.name()
rpt.out("<h1>Mapped Events for "+firstRec+"</h1>\n")

if len(poicache)==1 :
    rpt.out("<p>This map shows one location ")
else :
    rpt.out("<p>This map shows "+str(len(poicache))+" locations ")
if numEvents==1 :
    rpt.out("for one events ")
else :
    rpt.out("for "+str(numEvents)+" events ")
if eventRecords == 1 :
    rpt.out("from one individual or family")
else :
    rpt.out("from "+str(eventRecords)+" individuals or families")
numSkipped = totalEvents - numEvents
if numSkipped==0:
    rpt.out(" ")
else :
    if numSkipped==1 :
        rpt.out(". One event was skipped because it")
    else :
        rpt.out(". "+str(numSkipped)+" events were skipped because they")
    rpt.out(" did not have (lat,lon) information ")
rpt.out("(generated on "+gdoc.dateToday()+").")
rpt.out("</p>\n")
rpt.out(mbody)
rpt.write()

# resize the window
wind = gedit.windows()[0]
wind.setBounds_(NSMakeRect(mh,mv,mwidth,mheight))

