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

################### Subroutines

def AddRecPlaces(rec,rEvents,rVerb,pbox) :
    global pois,poiNum,poicache,firstRec,idcache,rectype
    
    # skip if done already
    key = rec.id()
    if key in idcache : return
    idcache[key] = "Done"
    
    # get name
    if rec.recordType()=="FAM" :
        recName = SpouseNames(rec)
    else :
        recName = rec.alternateName()
    if firstRec==None : firstRec = recName
    inAttr = False
    for i in range(len(rEvents)) :
        if rEvents[i]=="attr" :
            recName += "'s"
            inAttr = True
        es = rec.findStructuresTag_output_value_(rEvents[i],"references",None)
        for e in es :
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
                typeVerb = rVerb[i]
                if inAttr==False :
                    evnt = Event(e)
                    if typeVerb == "TYPE" :
                        type = e.evaluateExpression_("TYPE")
                        if len(type) > 0 :
                            typeVerb = "had an event of type "+type
                else :
                    evnt = Attribute(e)
                if plcname in poicache :
                    det = evnt.randomDescribe(recName,typeVerb,True)
                    poicache[plcname].append(det+addrDet)
                else :
                    if hasGPS==True :
                        bb = GetLatLonCentroid(plcname)
                    else :
                        prec = gdoc.places().objectWithName_(plcname)
                        if prec.exists()==True :
                            bb = FirstMapCentroid(prec)
                        else :
                            bb = []
                    if len(bb)>1 :
                        lat = bb[0].coordinate
                        lon = bb[1].coordinate
                        
                        # check if allowed
                        if pbox :
                            if lat<pbox[0] or lat>pbox[1] : continue
                            if pbox[2]>pbox[3] :
                                if lon<pbox[2] and lon>pbox[3] : continue
                            else :
                                if lon<pbox[2] or lon>pbox[3] : continue
                                    
                        # expand range and create POI
                        CheckRange(lat,lon)
                        poiNum += 1
                        det = evnt.randomDescribe(recName,typeVerb,True)
                        label = recName+" "+gdoc.localStringForKey_(rEvents[i])
                        poicache[plcname] = [lat,lon,poiNum,label,det+addrDet]
                
# expand bounding box if needed
def CheckRange(lat,lon) :
    global bbox
    if bbox==None :
        bbox = [lat-.1,lat+.1,lon-.1,lon+.1]
    else :
        if lat < bbox[0] : bbox[0] = lat
        if lat > bbox[1] : bbox[1] = lat
        if lon < bbox[2] : bbox[2] = lon
        if lon > bbox[3] : bbox[3] = lon
  
################### Main Script

# Preamble
gedit = CheckVersionAndDocument("Event Places for Window Records",1.6,2)
if not(gedit) : quit()
gdoc = FrontDocument()

iEvnts = ["BIRT","DEAT","BAPM","GRAD","RESI","CENS","EVEN",\
"attr","OCCU","EDUC"]
iVerb = ["was born","died","was baptised","graduated","lived","was recorded in a census","TYPE",\
"attr","occupation was","education was"]
fEvnts = ["MARR","DIV","EVEN"]
fVerb = ["were married","were divorced","TYPE"]

# initialize
bbox = None
poiNum=0
pois = []
poicache = {}
idcache = {}

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
            AddRecPlaces(subrec,iEvnts,iVerb,ebox)
        elif rectype=="FAM":
            AddRecPlaces(subrec,fEvnts,fVerb,ebox)
            husb = subrec.husband().get()
            if husb : AddRecPlaces(husb,iEvnts,iVerb,ebox)
            wife = subrec.wife().get()
            if wife : AddRecPlaces(wife,iEvnts,iVerb,ebox)
            chil = subrec.children()
            for child in chil : AddRecPlaces(child,iEvnts,iVerb,ebox)

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
    Alert("Did not find any places for any of the selected records")
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
[mcss,mscript,mbody] = createJSMap(mheight-160.,bbox,poiall,None,True)

# transfer to report and write it
rpt.css(mcss)
rpt.addhead(mscript)
if len(selRecs)>1 :
    firstRec += " and other individuals or families"
rpt.out("<h1>Mapped Places for "+firstRec+"</h1>\n")
rpt.out(mbody)
rpt.write()

# resize the window
wind = gedit.windows()[0]
wind.setBounds_(NSMakeRect(mh,mv,mwidth,mheight))

