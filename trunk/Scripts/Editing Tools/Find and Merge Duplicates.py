#!/usr/bin/python
#
# Find and Merge Duplicates (Python Script for GEDitCOM II)
#
# Tasks:
# Option to merge records in an album
#

# Load Apple's Scripting Bridge for Python
from Foundation import *
from ScriptingBridge import *
import math
from GEDitCOMII import *

################### Cache

# Theses classes and methods cache data from records for great improvements in speed

# lookup a record or create it if first access
def lookup(recordCache,grec,rectype) :
    key = grec.id()
    if key in recordCache :
        return recordCache[key]
    if rectype == "INDI" :
        newCache = Person(grec,recordCache,key)
        recordCache[key] = newCache
        newCache.FindParentsAndSpouse(grec,recordCache)
    elif rectype == "FAM" :
        newCache = Family(grec,key)
        recordCache[key] = newCache
    elif rectype == "REPO" :
        newCache = Repository(grec,key)
        recordCache[key] = newCache
    elif rectype == "SOUR" :
        newCache = Source(grec,key)
        recordCache[key] = newCache
    elif rectype == "OBJE" :
        newCache = Multimedia(grec,key)
        recordCache[key] = newCache
    elif rectype == "SUBM" :
        newCache = Submitter(grec,key)
        recordCache[key] = newCache
    elif rectype == "NOTE" :
        newCache = Note(grec,key)
        recordCache[key] = newCache
    elif rectype == "_LOG" :
        newCache = ResearchLog(grec,key)
        recordCache[key] = newCache
    elif rectype == "_PLC" :
        newCache = Place(grec,key)
        recordCache[key] = newCache
    else :
        return None
    return newCache

# convert place to a set of names
def PlaceToSet(place) :
    placestrip = place.strip()
    if len(placestrip) == 0 : return None
    hier = placestrip.split(",")
    for i in range(len(hier)) :
        hier[i] = hier[i].strip().lower()
    return set(hier)

# Cache individual record
class Person :
    def __init__(self,grec,recordCache,key) :
        self.key = key					# required
        self.sex = grec.sex()
        self.readData(grec,recordCache)
    
    # read data that might change after merging (required)
    def readData(self,grec,recordCache) :
        thename = grec.name()
        self.check = thename +" ("+grec.evaluateExpression_("span")+")"
        self.name = thename.lower()
        self.fn = grec.firstName().lower();
        self.mn = grec.middleName().lower();
        self.sn = grec.surname().lower()
        self.fnsx = grec.soundexForText_(self.fn)
        self.mnsx = grec.soundexForText_(self.mn)
        self.snsx = grec.soundexForText_(self.sn)
        self.birth = [grec.birthSDN(),grec.birthSDNMax()]
        self.bplace = PlaceToSet(grec.birthPlace())
        self.death = [grec.deathSDN(),grec.deathSDNMax()]
        self.dplace = PlaceToSet(grec.deathPlace())

        # parents (find later)
        self.father = None
        self.mother = None
        
        # first spouse (find later)
        self.spouse = None
        self.marriage = [0,0]
        self.mplace = ""
    
    # Minimum match to define block in sorted index window
    def matchKey(self) :
        return self.name[:1]
    
    # Look for parents and spouse now. This has to want until the individual is
    # done to avoid an endless loop when tree has recursion errors
    def FindParentsAndSpouse(self,grec,recordCache) :
        # find parents
        parfam = grec.parentFamilies()
        if parfam :
            f = parfam[0].husband().get()
            if f :
                self.father = lookup(recordCache,f,"INDI")
            m = parfam[0].wife().get()
            if m :
                self.mother = lookup(recordCache,m,"INDI")
            
        # find first spouse
        spfam = grec.spouseFamilies()
        if spfam :
            fam = spfam[0]
            self.marriage = [fam.marriageSDN(),fam.marriageSDNMax()]
            self.mplace = PlaceToSet(fam.marriagePlace())
            s = fam.husband().get()
            if s :
                if s.id() != self.key :
                    self.spouse = lookup(recordCache,s,"INDI")
            if not(self.spouse) :
                s = fam.wife().get()
                if s :
                    if s.id() != self.key :
                        self.spouse = lookup(recordCache,s,"INDI")

# Cache family record
class Family :
    def __init__(self,grec,key) :
        self.key = key					# required
        self.readData(grec,None)
    
    # read data that might change after merging (required)
    def readData(self,grec,recordCache) :
        self.check = grec.name()
        self.name = self.check
        h = grec.husband().get()
        if h :
            self.husband = h.id()
        else :
            self.husband = None
        w = grec.wife().get()
        if w :
            self.wife = w.id()
        else :
            self.wife = None
        self.marriage = [grec.marriageSDN(),grec.marriageSDNMax()]
        self.mplace = PlaceToSet(grec.marriagePlace())
        self.children = {}
        clist = grec.children()
        for chil in clist :
            self.children[chil.id()] = chil
            
    # Minimum match to define block in sorted index window
    def matchKey(self) :
        if self.husband :
            return self.husband
        else :
            return "nokey"
    
# Cache repository record
class Repository :
    def __init__(self,grec,key) :
        self.key = key				# required
        self.readData(grec,None)
    
    # read data that might change after merging (required)
    def readData(self,grec,recordCache) :
        self.check = grec.name()
        self.name = self.check.lower()
    
    # Minimum match to define block in sorted index window
    def matchKey(self) :
        return self.name[:1]
    
# Cache source record
class Source :
    def __init__(self,grec,key) :
        self.key = key				# required
        self.readData(grec,None)
    
    # read data that might change after merging (required)
    def readData(self,grec,recordCache) :
        self.check = grec.sourceTitle()
        self.name = self.check.lower()
        self.type = grec.sourceType()
    
    # Minimum match to define block in sorted index window
    def matchKey(self) :
        return "any"
    
# Cache multimedia object record
class Multimedia :
    def __init__(self,grec,key) :
        self.key = key				# required
        self.readData(grec,None)
    
    # read data that might change after merging (required)
    def readData(self,grec,recordCache) :
        self.check = grec.name()
        self.name = self.check.lower()
        self.path = grec.objectPath()
        if len(self.path) == 0 : self.path = None
    
    # Minimum match to define block in sorted index window
    def matchKey(self) :
        return "any"

# Cache submitter record
class Submitter :
    def __init__(self,grec,key) :
        self.key = key				# required
        self.readData(grec,None)
    
    # read data that might change after merging (required)
    def readData(self,grec,recordCache) :
        self.check = grec.name()
        self.name = self.check.lower()
    
    # Minimum match to define block in sorted index window
    def matchKey(self) :
        return self.name[:1]
    
# Cache notes record
class Note :
    def __init__(self,grec,key) :
        self.key = key				# required
        self.readData(grec,None)
    
    # read data that might change after merging (required)
    def readData(self,grec,recordCache) :
        self.check = grec.name()
        self.htmltext = None
        nt = grec.notesText().lower().strip()
        if len(nt) > 4 :
            if nt[:4] == "<div" :
                self.htmltext = nt
                self.notes = None
                return
        lines = nt.split("\n")
        self.notes = []
        for line in lines:
            if len(line) > 0 :
                self.notes.extend(line.split(" "))
        if len(self.notes) > 50 :
            self.notes = self.notes[:50]
        self.notes = ' '.join(self.notes)
    
    # Minimum match to define block in sorted index window
    def matchKey(self) :
        return "any"
    
# Cache research log record
class ResearchLog :
    def __init__(self,grec,key) :
        self.key = key				# required
        self.readData(grec,None)
    
    # read data that might change after merging (required)
    def readData(self,grec,recordCache) :
        self.check = grec.name()
        self.name = self.check.lower()
        self.object = grec.evaluateExpression_("_OBJECT").lower()
    
    # Minimum match to define block in sorted index window
    def matchKey(self) :
        return self.name[:1]

# Cache place record
class Place :
    def __init__(self,grec,key) :
        self.key = key				# required
        self.readData(grec,None)
        
    # read data that might change after merging (required)
    def readData(self,grec,recordCache) :
        self.check = grec.name()
        self.name = self.check.lower()
        self.place = PlaceToSet(self.name)
        hier = self.name.strip().split(",")
        if len(hier)>0 :
            self.firstPlace = hier[0].strip().lower()
        else :
            self.firstPlace = ""
        
    # Minimum match to define block in sorted index window
    def matchKey(self) :
        return self.name[:1]
    
################### Subroutines

# Check the quality of merging two records of the specified type
# It assumed the records are acutally of that type
def MergeQuality(rec1,rec2,recType) :
    if recType == "INDI" :
        return MergeQualityINDI(rec1,rec2,0)
    elif recType == "FAM" :
        return MergeQualityFAM(rec1,rec2)
    elif recType == "REPO" :
        return 100.*WordMatchQuality(rec1.name,rec2.name)
    elif recType == "SOUR" :
        return MergeQualitySOUR(rec1,rec2)
    elif recType == "OBJE" :
        return MergeQualityOBJE(rec1,rec2)
    elif recType == "NOTE" :
        return MergeQualityNOTE(rec1,rec2)
    elif recType == "SUBM" :
        return 100.*WordMatchQuality(rec1.name,rec2.name)
    elif recType == "_LOG" :
        return MergeQualityLOG(rec1,rec2)
    elif recType == "_PLC" :
        return MergeQualityPLC(rec1,rec2)
    return -1.

# individual records
def MergeQualityINDI(rec1,rec2,gen) :
    global testing
    
    # check keys - if same record return bonus (2 instead of 1)
    if gen != 0 :
        if (rec1.key == rec2.key) and not(testing) :
            return 2.
        
    # mismatch sex is conflict
    if rec1.sex != rec2.sex :
        return -1.
    
    # check names
    nameScore = NameQuality(rec1,rec2)
    if nameScore < 0. : return nameScore
    
    # check birth dates
    birthScore = DateQuality(rec1.birth,rec2.birth)
    if birthScore >= 0.9999 : birthScore += .5
    if birthScore < 0. : return -1.
    
    # check birth place
    birthPlaceScore = PlaceQuality(rec1.bplace,rec2.bplace)
    if birthPlaceScore < 0. : return -1.
    
    # check death dates
    deathScore = DateQuality(rec1.death,rec2.death)
    if deathScore >= 0.9999 : deathScore += .5
    if deathScore < 0. : return -1.
            
    # check birth place
    deathPlaceScore = PlaceQuality(rec1.dplace,rec2.dplace)
    if deathPlaceScore < 0. : return -1.
    
    # individual score
    bdmatch = 2.*birthScore+birthPlaceScore+2.*deathScore+deathPlaceScore
    indiScore = (4.*nameScore + bdmatch)/10.
    
    # related person - don't check further relations
    if gen > 0 : return indiScore
    
    # parents
    [fatherScore,motherScore] = [0.,0.]
    if rec1.father and rec2.father :
        fatherScore = MergeQualityINDI(rec1.father,rec2.father,1)
        if fatherScore < 0. : return -1.
    if rec1.mother and rec2.mother :
        motherScore = MergeQualityINDI(rec1.mother,rec2.mother,1)
        if motherScore < 0. : return -1.
    
    # first spouse (but mismatch is not a conflist)
    spouseScore = 0.
    if rec1.spouse and rec2.spouse :
        spouseScore = MergeQualityINDI(rec1.spouse,rec2.spouse,1)
        if spouseScore < 0 : spouseScore = 0.
    
    # first marriage dates
    marriageScore = DateQuality(rec1.marriage,rec2.marriage)
    if marriageScore >= 0.9999 : marriageScore += .5
    if marriageScore < 0 : marriageScore = 0.
    
    # first marriage place
    marriagePlaceScore = PlaceQuality(rec1.mplace,rec2.mplace)
    if marriagePlaceScore < 0. : marriagePlaceScore = 0.

    # require some match in birth info, father, or mother, spouse name, marriage date otherwise not enough info
    bdother = bdmatch+fatherScore+motherScore+spouseScore+marriageScore
    if bdother <= 1.e-10 : return -1
    match = 2.*indiScore+fatherScore+motherScore+0.5*(spouseScore+marriageScore+marriagePlaceScore)
    
    # maximum 100
    if match > 5.5 : match = 5.5
    return 100.*match/5.5

# Family records
def MergeQualityFAM(rec1,rec2) :
    # check husbands
    hscore = 0.
    if rec1.husband and rec2.husband :
        if rec1.husband == rec2.husband :
            hscore = 1.
        else :
            return -1.
            
    # check wives
    wscore = 0.
    if rec1.wife and rec2.wife :
        if rec1.wife == rec2.wife :
            wscore = 1.
        else :
            return -1.
    
    # bonus for both spouses
    if hscore + wscore > 1.999 : hscore += 1.
    
    # marriage date
    mdscore = DateQuality(rec1.marriage,rec2.marriage)
    if mdscore >= 0.9999 : mdscore += .5
    if mdscore < 0. : return -1.
    
    # marriage place
    mpscore = PlaceQuality(rec1.mplace,rec2.mplace)
    if mpscore < 0. : return -1.
    
    # children matches (exact)
    cscore = 0.
    maxmatches = len(rec1.children)
    if maxmatches > 0 and len(rec2.children) > 0 :
        keys = rec2.children.keys()
        matches = 0
        if len(keys) > maxmatches : maxmatches = len(keys)
        for key in keys :
            if key in rec1.children :
                matches += 1
        cscore = float(matches)/float(maxmatches)
    
    # total scores
    fs = 100.*(hscore+wscore+0.5*(cscore+mdscore+mpscore))/3.5
    if fs > 100. : fs = 100.
    return fs

# Family records
def MergeQualitySOUR(rec1,rec2) :
    # must be same type
    if rec1.type != rec2.type : return -1.
    
    wscore = WordMatchQuality(rec1.name,rec2.name)
    if wscore < 0 : return -1.
    return 100.*wscore

# Family records
def MergeQualityOBJE(rec1,rec2) :
    if not(rec1.path) or not(rec2.path) :  return -1.
    if rec1.path != rec2.path : return -1.
    return 100.

# Family records
def MergeQualityNOTE(rec1,rec2) :
    # if either has html, must match it all, if one not, no match
    if not(rec1.notes) :
        if rec2.notes : return -1.
        if rec1.htmltext != rec2.htmltext : return -1.
        return 100.
    elif not(rec2.notes) :
        return -1.
    
    # exact match
    if rec1.notes == rec2.notes : return 100.
    
    # word matching
    wscore = WordMatchQuality(rec1.notes,rec2.notes)
    if wscore < 0 : return -1.
    return 100.*wscore

# Research Log Records
def MergeQualityLOG(rec1,rec2) :
    nameQual = WordMatchQuality(rec1.name,rec2.name)
    if rec1.object and rec2.object :
    	nameQual += WordMatchQuality(rec1.object,rec2.object)
    return 50.*nameQual

# Place Records
# score = 0.8*matches/minUnits + 0.2 (if first unit matches)
# and regire 60 or more to accept
def MergeQualityPLC(rec1,rec2) :
    placeScore = PlaceQuality(rec1.place,rec2.place)
    minUnits = min(len(rec1.place),len(rec2.place))
    if minUnits < 1 : return -1
    placeScore *= 0.8
    if len(rec1.firstPlace)>0 and len(rec2.firstPlace)>0 :
        if rec1.firstPlace == rec2.firstPlace :
            placeScore += 0.2
    if placeScore < 0.595 : return -1
    return 100.*placeScore

# two strings of words score (0 to 1)
def WordMatchQuality(text1,text2) :
    if text1 == text2 :
        return 1.
        
    # get lines
    lines1 = text1.split("\n")
    lines2 = text2.split("\n")
    
    # get words
    words1 = []
    for line in lines1:
        if len(line) > 0 :
            words1.extend(line.split(" "))
    words2 = []
    for line in lines2:
        if len(line) > 0 :
            words2.extend(line.split(" "))
    
    # loop over non-empty text1 words
    i1 = 0
    i2 = 0
    matches = 0.
    while i1 < len(words1) and i2 < len(words2) :
        if len(words1[i1]) == 0 :
            i1 += 1
            continue
        if len(words2[i2]) == 0 :
            i2 += 1
            continue
        # compare word i1 to word i2
        match = WordCompare(words1[i1],words2[i2])
        if match > 0. :
            i1 += 1
            i2 += 1
            matches += match
            continue
        # compare i1+1 to i2
        if i1+1 < len(words1) :
            match = WordCompare(words1[i1+1],words2[i2])
            if match > 0. :
                i1 += 2
                i2 += 1
                matches += match-0.2
                continue
        # compare i1 to i2+1
        if i2+1 < len(words2) :
            match = WordCompare(words1[i1],words2[i2+1])
            if match > 0. :
                i1 += 1
                i2 += 2
                matches += match-0.2
                continue
        # reached a mismatch
        return -1.
    
    # return number of matches per word
    maxmatch = len(words1)
    if len(words2) > maxmatch : maxmatch = len(words2)
    res = matches/float(maxmatch)
    if res < .5 : return -1.
    return res

# compare two words by text, soundex, and first letter
def WordCompare(w1,w2) :
    if w1 == w2 : return 1.
    # watch out for numbers
    try:
        num1 = int(w1)
        num2 = int(w2)
        return -1
    except:
        pass
    if gdoc.soundexForText_(w1) == gdoc.soundexForText_(w2) :
        return 0.75
    if w1[:1] == w2[:1] : return 0.2
    return -1.

# came names of two individual records
def NameQuality(rec1,rec2) :
    # check last criterion first
    if rec1.snsx != rec2.snsx : return -1
    
    # are they identical (ci)
    if rec1.name == rec2.name : return 1.
    
    # check for exact match (ci) in existing name parts
    conflict = False
    if rec1.fn and rec2.fn :
        if rec1.fn != rec2.fn : conflict = True
    if not(conflict) and rec1.mn and rec2.mn :
        if rec1.mn != rec2.mn : conflict = True
    if not(conflict) and rec1.sn and rec2.sn :
        if rec1.sn != rec2.sn : conflict = True
    if not(conflict) : return 0.66
        
    # check soundex of name parts
    conflict = False
    if rec1.fn and rec2.fn :
        if rec1.fnsx != rec2.fnsx : conflict = True
    if not(conflict) and rec1.mn and rec2.mn :
        if rec1.mnsx != rec2.mnsx : conflict = True
    if not(conflict) and rec1.sn and rec2.sn :
        if rec1.snsx != rec2.snsx : conflict = True
    if not(conflict) : return 0.33
        
    # name conflict
    return -1.

# Place match by degree of overlap in the hierarchy terms
def PlaceQuality(place1,place2) :
    # if no place for either one, exit
    if not(place1) or not(place2) : return 0
    
    # which has the list terms (exit if one is empty)
    minUnits = min(len(place1),len(place2))
    if minUnits == 0 : return 0.
    
    # find intersection
    match = place1 & place2
    
    # find fraction of possible matches
    if len(match) == 0 : return -1.
    maxUnits = max(len(place1),len(place2))
    return float(len(match))/float(maxUnits)
    
# extract places (but must be this node and not child one)
def PlaceToList(place) :
    hier = place.split(",")
    for i in range(len(hier)) :
        hier[i] = hier[i].strip()
    return hier

#  test scores by comparing each record to itself
def TestMergeScores(recs) :
    global merging,cache,gdoc
    
    totscore = 0.
    highscore = 0.
    lowscore = 100.
    for index in range(len(recs)) :
        # get first character of next record
        rec = lookup(cache,recs[index],merging)
        merit = MergeQuality(rec,rec,merging)
        totscore += merit
        if merit > highscore : highscore = merit
        if merit < lowscore : lowscore = merit
        fraction = float(index)/float(len(recs))
        gdoc.notifyProgressFraction_message_(fraction,rec.check+" = "+s1(merit))
    
    print "\nAverage score = "+s1(totscore/float(len(recs)))
    print "Low score = "+s1(lowscore)
    print "High score = "+s1(highscore)

# format score with two digits :
def s1(score) :
    return str(int(10*score)/10.)

# format line for output report
def rptline(scr,r1,r2=None) :
    lne = []
    lne.append("<a href='"+r1.key+"'>"+r1.check+"</a>")
    if r2 :
        lne.append(" and ")
        lne.append("<a href='"+r2.key+"'>"+r2.check+"</a>")
    lne.append(" (score = "+s1(scr)+")\n")
    return ''.join(lne)

################### Main Script

# fetch document
gedit = CheckVersionAndDocument("Find and Merge Duplicates",1.6,2)
if not(gedit) : quit()
gdoc = FrontDocument()

# for date matching
SetTauCutoff(55.,2.)

# Testing mode
# If this is set to True, each record compared with itself to get
# summary of how well the algorithm recognizes known identical
# records. No merging is done and it prints a summary of
# the match qualities
testing = False

# decide what to merge (3-letter one add space on the end)
# Order REPO, SUBM, SOUR, NOTE, OBJE, (_LOG), INDI, FAM
prompt = "Select type of records to merge\n(the types are listed in the recommended order)"
rts = ["Repositories (REPO)","Sources (SOUR)",\
"Notes (NOTE)","Multimedia Objects (OBJE)","Research Logs (_LOG)",\
"Submitters (SUBM)","Individuals (INDI)","Families (FAM) ","Places (_PLC)"]
(item,itemNum) = GetOneItem(rts,prompt,GetScriptName())
if not(item) : quit()
merging = item[-5:].strip()[:-1]

# to store data for speed
cache = {}

# collect the records
options = ["LIST","BD","BP","DD","DP","MD","MP","FM","SN","CN"]
display = "view"
if merging == "INDI" :
    recs = gdoc.individuals()
elif merging == "FAM" :
    recs = gdoc.families()
    display = "HUSB.view"
elif merging == "REPO" :
    recs = gdoc.repositories()
elif merging == "SOUR" :
    recs = gdoc.sources()
elif merging == "NOTE" :
    recs = gdoc.notes()
elif merging == "OBJE" :
    recs = gdoc.multimedia()
elif merging == "SUBM" :
    recs = gdoc.submitters()
elif merging == "_PLC" :
    recs = gdoc.places()
else :
    recs = gdoc.researchLogs()

# display records and sort by view name
gdoc.displayByName_byType_sorting_(None,merging,display)

# testing - compare to themselves, report and exit
if testing :
    TestMergeScores(recs)
    quit()

# block searching
firstKey = ""
merged = []
mergedTotal = 0.
notMerged = []
notMergedTotal = 0.

# get starting record
gdoc.userSelectByType_fromList_prompt_(merging,None,"Select starting record for merging")
while True :
    arec = gdoc.pickedRecord().get()
    if arec != "" : break
if arec == "Cancel" : quit()
index = 0
key = arec.id()
while index < len(recs) :
    if recs[index].id() ==  key : break
    index += 1

# loop until done
while index < len(recs) :
    # get first character of next record
    rec = lookup(cache,recs[index],merging)
    recDescribe = None
    gdoc.notifyProgressFraction_message_(float(index)/float(len(recs)),"Checking: "+rec.check)
    nextKey = rec.matchKey()
    if nextKey != firstKey :
        firstKey = nextKey
        blockEnd = -1
	
    # merge rec with any record in current block
    mindex = index+1
    while mindex < len(recs) :
        mrec = lookup(cache,recs[mindex],merging)
	    
        # see if reached end of merging block (same first letter)
        if blockEnd < 0 :
            nextKey = mrec.matchKey()
            if nextKey != firstKey : break
        elif mindex > blockEnd :
            break
	    
        # see if rec and mrec are merge candidates
        merit = MergeQuality(rec,mrec,merging)
	    
        if merit > 0. :
            if not(recDescribe) :
                recList = recs[index].objectDescriptionOutputOptions_(options)
                recDescribe = '\n'.join(recList)
            dList = recs[mindex].objectDescriptionOutputOptions_(options)
            d2 = '\n'.join(dList)
            prompt = "The following records match with score = "+s1(merit)
            if merging == "NOTE" :
                if len(recDescribe)>600 : recDescribe = recDescribe[:600]+"..."
                if len(d2)>600 : d2 = d2[:600]+"..."
            msg = recDescribe +"\n\n"+d2
            choice = GetOption(prompt,msg,["Don't Merge","Merge","Cancel"])
            
            if choice == "Cancel" :
                index = len(recs)
                break;
            elif choice == "Don't Merge" :
                notMerged.append(rptline(merit,rec,mrec))
                notMergedTotal += merit
            else :
                recsource = recs[index]
                rectarget = recs[mindex]
                option = ""
                if merging == "INDI" :
                    rec1name = recsource.evaluateExpression_("NAME")
                    rec2name = rectarget.evaluateExpression_("NAME")
                    if rec1name != rec2name :
                        prompt = "Which name should be used in the merged record?"
                        msg = "1 = "+rec.check+"\n2 = "+mrec.check
                        option = GetOption(prompt,msg,["Use 1","Use 2","Cancel"])
                        if option == "Cancel" :
                            notMerged.append(rptline(merit,rec,mrec))
                            notMergedTotal += merit
                        elif option == "Use 2" :
                            recsource.setName_(rec2name)
                        else :
                            rectarget.setName_(rec1name)
                elif merging == "REPO"  or merging == "SOUR" or merging == "SUBM" or merging == "_PLC" :
                    if rec.check != mrec.check :
                        prompt = "Which name should be used in the merged record?"
                        msg = "1 = "+rec.check+"\n2 = "+mrec.check
                        option = GetOption(prompt,msg,["Use 1","Use 2","Cancel"])
                        if option == "Cancel" :
                            notMerged.append(rptline(merit,rec,mrec))
                            notMergedTotal += merit
                        elif option == "Use 2" :
                            if merging == "SOUR" :
                                recsource.setSourceTitle_(mrec.check)
                            else :
                                recsource.setName_(mrec.check)
                        else :
                            if merging == "SOUR" :
                                rectarget.setSourceTitle_(rec.check)
                            else :
                                rectarget.setName_(rec.check)
                if option!="Cancel" :
                    recsource.mergeWithRecord_force_(rectarget,True)
                    rec.readData(recsource,cache)
                    if merging == "INDI" : rec.FindParentsAndSpouse(recsource,cache)
                    recList = recsource.objectDescriptionOutputOptions_(options)
                    recDescribe = '\n'.join(recList)
                    merged.append(rptline(merit,rec))
                    mergedTotal += merit
                    mindex -= 1
                    if blockEnd > 0 : blockEnd -= 1
            
        # on to next merge candidate
        mindex += 1
	
    # on to next base record
    index += 1

# summarize the results
rpt = ["<div>\n<h1>Merging Records in File "+gdoc.name()+"</h1>\n\n"]

if len(merged) == 1 :
    rpt.append("<p>You merged 1 pair of records. ")
    ess = ""
else :
    rpt.append("<p>You merged "+str(len(merged))+" pairs of records. ")
    ess = "s"
if len(merged) > 0 :
    rpt.append(" The average score for merged records was "+s1(mergedTotal/len(merged))+". ")
    rpt.append(" You may want to open the following record"+ess+" to clean up ")
    rpt.append("data that could be merged better:</p>\n")
    
    rpt.append("<ol>\n")
    for nm in merged :
        rpt.append("<li>"+nm+"</li>\n")
    rpt.append("</ol>\n\n")

if len(notMerged) > 0 :
    if len(notMerged) == 1:
        rpt.append("<p>You left 1 pair of records unmerged. ")
    else :
        rpt.append("<p>You left "+str(len(notMerged))+" pairs of records unmerged. ")
    rpt.append(" Their average score was "+s1(notMergedTotal/len(notMerged))+". ")
    rpt.append("You can check these records now to see if they can be merged. ")
    rpt.append("Some links may be broken if that record was later merged into another record.</p>\n\n")

    rpt.append("<ol>\n")
    for nm in notMerged :
        rpt.append("<li>"+nm+"</li>\n")
    rpt.append("</ol>\n\n")

# finish up
rpt.append("</div>")

# show the report
p = {"name":"Merging Records", "body":''.join(rpt)}
newReport = gedit.classForScriptingClass_("report").alloc().initWithProperties_(p)
gdoc.reports().addObject_(newReport)
newReport.showBrowser()

