#!/usr/bin/python
#
# Places in this File (Python Script for GEDitCOM II)
#
# Watch out for quotes in place names
# Add URL to pop up box
# Does it have to change browser default window size

# Load GEDitCOM II Module
from GEDitCOMII import *

# Preamble
gedit = CheckVersionAndDocument("Places in this File",1.7,1)
if not(gedit) : quit()
gdoc = FrontDocument()

# Pick world or a continent and then all or selected records
clist = ["Entire World","Africa","Asia","Antarctic","Australia",\
"Europe","North America","South America"]
res = gdoc.userChoiceListItems_prompt_buttons_multiple_title_(clist,
"Map entire world or in one continent",["All Places","Selected Places","Cancel"],\
False,"Places Map")
if res[0] == "Cancel" : quit()
cname = res[1][0]
cbox = None
if cname == "Africa" :
    cbox = [-46.900452,37.56712,-25.35874,63.525379]
elif cname == "Asia" :
    cbox = [-12.56111,82.50045,19.6381,180]
elif cname == "Antarctic" :
    cbox = [-90,-53.00774,-180,180]
elif cname == "Australia" :
    cbox = [-53.05872,-6.06945,105.377037,-175.292496]
elif cname == "Europe" :
    cbox = [27.636311,81.008797,-31.266001,39.869301]
elif cname == "North America" :
    cbox = [5.49955,83.162102,-167.276413,-52.23304]
elif cname == "South America" :
    cbox = [-59.450451,13.39029,-109.47493,-26.33247]

# find the place records
if res[0] == "Selected Places" :
    precs = GetSelectedType("_PLC")
    if len(precs) == 0 :
        Alert("None of the currently selected records are place records")
        quit()
else :
    precs = gdoc.places()
    if len(precs) == 0 :
        Alert("This file does not have any place records")
        quit()

# check each one
bbox = None
pois = []
fractionStepSize=nextFraction=0.01
numRecs = len(precs)
for i in range(numRecs) :
    fractionDone = float(i+1)/float(numRecs)
    if fractionDone > nextFraction:
        ProgressMessage(fractionDone)
        nextFraction = nextFraction+fractionStepSize
        
    plc = precs[i]
    bbmap = plc.structures().objectWithName_("_BOX")
    if bbmap.exists() == False : continue
    bbname = plc.name()
    bb = GetLatLonCentroid(bbmap.evaluateExpression_("_BNDS"))
    if len(bb)<=1 : continue
    
    # get lat lon and check if OK
    lat = bb[0].coordinate
    lon = bb[1].coordinate
    if cbox!=None :
        if lat<cbox[0] or lat>cbox[1] : continue
        if cname == "Australia" :
            if lon<cbox[2] and lon>cbox[3] : continue
        else :
            if lon<cbox[2] or lon>cbox[3] : continue
    
    # see if need to expand bounding box
    if bbox==None :
        if lon<0. and cname=="Australia" :
            bbox = [lat-.1,lat+.1,lon+359.9,lon+360.1]
        else :
            bbox = [lat-.1,lat+.1,lon,lon]
    else :
        if lat < bbox[0] : bbox[0] = lat
        if lat > bbox[1] : bbox[1] = lat
        if lon<0. and cname=="Australia" :
            if lon+360. < bbox[2] : bbox[2] = lon+360.
            if lon+360. > bbox[3] : bbox[3] = lon+360.
        else :
            if lon < bbox[2] : bbox[2] = lon
            if lon > bbox[3] : bbox[3] = lon
    
    # create POI
    det = "Place Record: <a href='"+plc.id()+"'>"+bbname+"</a>"
    purl = plc.structures().objectWithName_("_URL")
    if purl.exists() == True :
        purlText = purl.contents().strip()
        det = det + "<br>URL: <a href='"+ purlText +"' target='new'>"+ purlText +"</a>"
    pois.append(MakeMapPOI(lat,lon,i,bbname,det))

ProgressMessage(1.0)
        
# were any found
if bbox==None :
    msg = "Did not find any places in this file with a valid bounding box"
    if cname!="Entire World" :
        msg += " and also within the continent of "+cname
    Alert(msg)
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
if bbox[3]>180. : bbox[3]-=360.
[mcss,mscript,mbody] = createJSMap(mheight-160.,bbox,poiall,None,True)

# transfer to report and write it
rpt.css(mcss)
rpt.addhead(mscript)
if cname!="Entire World" :
    rpt.out("<h1>Mapped Places in "+cname+" from file "+gdoc.name()+"</h1>\n")
else :
    rpt.out("<h1>Mapped Places from file "+gdoc.name()+"</h1>\n")
rpt.out(mbody)
rpt.write()

# resize the window
wind = gedit.windows()[0]
wind.setBounds_(NSMakeRect(mh,mv,mwidth,mheight))
