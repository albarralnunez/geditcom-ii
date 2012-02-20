#!/usr/bin/python
from GEDitCOMII import *

# Front document
gedit = CheckVersionAndDocument("Open_Location_in_GeoHack",1.7,1)
if not(gedit) : quit()
gdoc = FrontDocument()
gedit.setMessageVisible_(False)

# decode lat lon
details = gdoc.editingDetails()
if len(details)<3 :
    Alert("The current editing field does not have a latitude and longitude.")
    quit()
latlon = GetLatLonCentroid(details[2].contents())
if len(latlon)==1 :
    Alert(latlon[0])
    quit()

# convert to DMS and open URL
lat = latlon[0].convertToDMS()
lon = latlon[1].convertToDMS()
secs = '{0:.2g}'.format(lat[2])
if lat[0]>0 :
    ghurl2 = str(lat[0])+"_"+str(lat[1])+"_"+secs+"_N"
else :
    ghurl2 = str(-lat[0])+"_"+str(lat[1])+"_"+secs+"_S"
secs = '{0:.2g}'.format(lon[2])
if lon[0]>0 :
    ghurl3 = str(lon[0])+"_"+str(lon[1])+"_"+secs+"_E"
else :
    ghurl3 = str(-lon[0])+"_"+str(lon[1])+"_"+secs+"_W"
ghurl = "http://toolserver.org/~geohack/geohack.php?params="+ghurl2+"_"+ghurl3
OpenWebSite(ghurl)
