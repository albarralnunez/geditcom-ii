#!/usr/bin/python
#
# Decode Lat Lon (Python Script for GEDitCOM II)

# Load GEDitCOM II Module
from GEDitCOMII import *
import math

# Get size of main screen only (one with menu bar
# Return visible area [x,y,width,height] accounting for dock and menu bar
def GetMainScreenSize() :
    screen = NSScreen.mainScreen()
    screenRect = screen.visibleFrame()
    return [screenRect.origin.x,screenRect.origin.y,NSWidth(screenRect),NSHeight(screenRect)]
    
################### Main Script

# Preamble
gedit = CheckVersionAndDocument("Decode Lat Lon",1.6,2)
if not(gedit) : quit()
gdoc = FrontDocument()

print str(GetScreenSize())
print str(GetMainScreenSize())

print str(kmPerLongitudeDegree(0.))
trials = ["-75.1697","45","-1"]
for i in range(len(trials)) :
    print "Input: "+trials[i]
    gc = GlobalCoordinate(trials[i])
    if gc.error==None :
        print "   number: "+gc.signedNumber()
        print "   compass: "+gc.compassNumber()
        print "   dms: "+gc.dmsNumber(False,True).encode('utf-8')
        print "   dms: "+gc.dmsNumber(False,False).encode('utf-8')
    else :
        print "   error: "+gc.error

