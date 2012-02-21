#!/usr/bin/python
#
# GEDitCOMII Module of Utility Methhods
#
# Version History

#
# 1: Initial version posted with GEDitCOM 1.6, build 2
# 2: Posted with GEDitCOM 1.7
#
# Contents
#
# ScriptOutput Class
# RecordsSet and RecordForSet Classes
# Event Class
# Attribute Class
# Initialization
# Working With Records
# Working With Structures
# Individual Record Functions
# Family Record Functions
# Note Record Functions
# Place Record Functions
# Map Creating Utilities
# Module Property Functions
# HTML Helper Functions
# Utility Functions
# Date Functions
# Lat Lon Utilities
# User Interation
# Globals

# Load Apple's Scripting Bridge for Python
from Foundation import *
from ScriptingBridge import *
import shlex, subprocess, os, random, math

#----------------- ScriptOutput Class

# class to handle various types of LifeLines output
class ScriptOutput :
    def __init__(self,stitle,style,saveFile=None) :
        self.title = stitle
        self.style = style
        self.saveFile = saveFile
        self.text = []
        self.cssitems = []
        self.headitems = []
        self._monofont = "Courier"
        self._monosize = 9
        self._fontitem = -1
        if self.saveFile == None :
            if style == "monospace" :
                self.text.append("<div>\n<head><style type='text/css'>\n")
                self.text.append("pre { margin: 3px 0px 3px 0px;\n")
                self._fontitem = len(self.text)
                self.text.append("	border: none; padding: 0px;\n")
                self.text.append("	background-color: #ffffff; line-height: 1.2;}\n")
                self.text.append("body { margin-top: 3px;}\n")
                self.text.append("</style></head>\n")
                self.text.append("<pre>\n")
            elif style == "html" :
                self.text.append("<div>\n")
                self.headloc = len(self.text)
                self.cssitems.append("<style type='text/css'>\n")
        else :
            if style == "html" :
                self.text.append("<!DOCTYPE HTML PUBLIC '-//W3C//DTD HTML 4.01 Transitional//EN'\n")
                self.text.append("        'http://www.w3.org/TR/html4/loose.dtd'>\n")
                self.text.append("<html lang='en'>\n")
                self.text.append("<head>\n")
                self.text.append("  <meta http-equiv='content-type' content='text/html; charset=utf-8'>\n")
                self.text.append("  <title>"+self.title+"</title>\n")
                self.headloc = len(self.text)
                self.text.append("</head>\n")
                self.text.append("<body>\n")
                self.cssitems.append("<style type='text/css'>\n")
         
    # append the text to the report
    def out(self,reportText) :
        self.text.append(reportText)
    
    # def add css elements
    def css(self,csstext) :
        self.cssitems.append(csstext)
    
    # def add css elements
    def addhead(self,headtext) :
        self.headitems.append(headtext)

    # set font
    def setFont(self,mf) :
        self._monofont = mf
    
    # set font size
    def setFontSize(self,fs) :
        self._monosize = fs

    # pack pairs of arguments and append to report
    # [text,endcol,text,endcol,...] where endcol<0 to right justify
    def cols(self,args) :
        i = 0
        column = 0
        row = []
        while i < len(args)-1 :
            text = args[i]
            endcol = args[i+1]
            i += 2
            if endcol>0 :
            	length = endcol - column - 1
                row.append(text.ljust(length)[0:length])
                column = endcol - 1
            else :
                length = -endcol - column - 1
                row.append(text.rjust(length)[0:length])
                column = -endcol - 1
        if i < len(args) : row.append(args[i])
        self.out(''.join(row))
    
    # output the report
    def write(self,gdoc=None) :
        if not(gdoc) : gdoc = FrontDocument()
        if self.saveFile == None :
            if self.style == "monospace" :
                fontcss = "	font-size: "+str(self._monosize)+"pt; font-family: "+self._monofont+";\n"
                self.text.insert(self._fontitem,fontcss)
                self.text.append("\n</pre>\n</div>")
            elif self.style == "html" :
                if len(self.cssitems) > 1 or len(self.headitems) > 0 :
                    head = ["<head>\n"]
                    if len(self.cssitems) > 1 :
                        self.cssitems.append("</style>\n")
                        head.append(''.join(self.cssitems))
                    if len(self.headitems) > 0 :
                        head.append(''.join(self.headitems))
                    head.append("</head>\n")
                    self.text.insert(self.headloc,''.join(head))
                self.text.append("\n</div>")
            p = {"name":self.title, "body":''.join(self.text)}
            newReport = _gedit.classForScriptingClass_("report").alloc().initWithProperties_(p)
            gdoc.reports().addObject_(newReport)
            newReport.showBrowser()
        else :
            if self.style == "html" :
                head = []
                if len(self.cssitems) > 1 :
                    self.cssitems.append("</style>\n")
                    head.append(''.join(self.cssitems))
                if len(self.headitems) > 0 :
                    head.append(''.join(self.headitems))
                if len(head)>0 :
                    self.text.insert(self.headloc,''.join(head))
                self.text.append("\n</body>\n</html>")
            # write using python
            filetext = u''.join(self.text)
            f = open(self.saveFile, 'w')
            f.write(filetext.encode('utf-8'))
            f.close
            # write to a file using Cocoa
            #nstring = NSString.stringWithString_(u''.join(self.text))
            #print nstring.encode('utf-8')
            #(result,error) = nstring.writeToFile_atomically_encoding_error_(self.saveFile,objc.YES,NSUTF8StringEncoding,objc.nil)
            #if result != True:
            #    errMsg = "An I-O error occurred trying to write the vCard file"
            #    gdoc.userOptionTitle_buttons_message_(errMsg,["OK"],error.description())

#----------------- RecordsSet and RecordForSet Classes

# custom class to support person set
# table stores collection of RecordForSet objects (or a subclass if override makeObject)
# table has record ID as key, but subclass can change by overriding makeKey
# NOT DOCUMENTED
class RecordsSet :
    def __init__(self,other=None) :
        if not(other) :
            self.recs = []
            self.table = {}
        else :
            self.recs = list(other.recs)
            self.table = other.table.copy()
    
    # default key to the list base on id and value
    def makeKey(self,rec,value=0) :
        return rec.id()
    
    # default object to add to the record set
    # should be subclass of RecordForSet()
    def makeObject(self,rec,value=0) :
        return RecordForSet(rec,value)
    
    # return enumerator for all records in this list
    def enumerate(self) :
        return enumerate(self.recs)
    
    # true or false if has an (rec,value) pair
    def hasRecValue(self,rec,value) :
        if self.makeKey(rec,value) in self.table : return True
        return False
    
    # add rec with value (if not already in the set)
    def addRecord(self,rec,value) :
        key = self.makeKey(rec,value)
        if key not in self.table :
            rfs = self.makeObject(rec,value)
            self.table[key] = rfs
            self.recs.append(rfs)
    
    # add a predefined object (subclass of RecordForSet) and caller
    # must be sure not already in this set
    def addObjectWithKey(self,rfs,key) :
        self.table[key] = rfs
        self.recs.append(rfs)
    
    # unions of this set with other set
    def union(self,other) :
        for rfs in other.recs :
            key = self.makeKey(rfs.rec,rfs.value)
            if key not in self.table :
                self.addObjectWithKey(rfs,key)
    
    # add all unique ancestors from all individuals in sourceSet
    # to this set
    # assume current individuals have value set to their signed generation
    #    number and this will continue to total maxgen
    def ancestorSet(self,sourceSet,includeRoot=False,maxgen=1000) :
        for rfs in sourceSet.recs :
            if rfs.type == "INDI" :
                alist = GetAncestors(rfs.rec,None,maxgen-rfs.value)
                self.addAncestorList(alist,includeRoot,rfs.value)
    
    # add from standard GEDitCOM II ancestor list
    # add record and value =  generation number
    # option includeRoot means to include root person too
    def addAncestorList(self,alist,includeRoot=False,base=0) :
        a0 = 1
        if includeRoot : a0 = 0
        for ancest in alist[a0:] :
            # [gen,indi] or [gen,indi,ref#] or [gen,xref#]
            if not(isinstance(ancest[1], int)) :
                self.addRecord(ancest[1],base+ancest[0])
    
    # add all unique descendants from all individuals in sourceSet
    # to this set
    # assumes individual value is signed generation number and will go to
    #    number and this will continue to total maxgen
    def descendantSet(self,sourceSet,includeRoot=False,maxgen=1000) :
        for rfs in sourceSet.recs :
            if rfs.type == "INDI" :
                alist = GetDescendants(rfs.rec,None,maxgen+rfs.value)
                self.addDescendantList(alist,includeRoot,rfs.value)
    
    # add from standard GEDitCOM II ancestor list
    # add record and value =  generation number
    # option includeRoot means to include root person too
    def addDescendantList(self,dlist,includeRoot=False,base=0) :
        d0 = 1
        if includeRoot : d0 = 0
        for descend in dlist[d0:] :
            if len(descend) > 2 :
                # [gen,indi,ref#] or [gen,spouse,family]
                if isinstance(descend[2], int) :
                    self.addRecord(descend[1],base-descend[0])
            elif not(isinstance(descend[1], int)) :
                # [gen,indi] or [gen,xref#]
                self.addRecord(descend[1],base-descend[0])

    # all all records in this list with optional value
    def addList(self,alist,value=0) :
         for rec in alist :
             self.addRecord(rec,value)

    def nameSort(self) :
        global _recsetsort
        _recsetsort = 0
        self.recs.sort()
    
    def valueSort(self) :
        global _recsetsort
        _recsetsort = 1
        self.recs.sort()
    
    def valueNameSort(self) :
        global _recsetsort
        _recsetsort = 2
        self.recs.sort()
    
    def len(self) :
        return len(self.recs)
    
# Class to hold record for a RecordsSet
# val can be numbers or any object that supports str(val)
# NOT DOCUMENTED
class RecordForSet :
    def __init__(self,record,val=0) :
        self.rec = record
        self.name = record.name()
        self.value = val
        self.key = record.id()
        self.type = record.recordType()

    def __cmp__(self,other) :
        global _recsetsort
        if _recsetsort == 0 :
            if self.name > other.name :
                return 1
            elif self.name < other.name :
                return -1
        elif _recsetsort == 1 :
            if self.value > other.value :
                return 1
            elif self.value < other.value :
                return -1
        else :
            if self.value > other.value :
                return 1
            elif self.value < other.value :
                return -1
            if self.name > other.name :
                return 1
            elif self.name < other.name :
                return -1
        return 0

#----------------- Event Class

# Wrapper for an events
# will load date and place and will clean up place to
#   separation by ", " and empty fields removed
# NOT DOCUMENTED
class Event :
    def __init__(self,evnt) :
        self.event = evnt
        self.date = evnt.eventDate()
        self.sdn = [-1,-1]
        self.place = evnt.eventPlace().strip()
        if self.place :
            hier = self.place.split(",")
            i = 0
            while i < len(hier) :
                hier[i] = hier[i].strip()
                if len(hier[i]) == 0 :
                    hier.pop(i)
                else :
                    i += 1
            self.place = ', '.join(hier)
        self.phrase = None
            
    # Describe this event with following terms
    # Age is optional, date prefaced by qualifier words, in, or on, as needed
    # Gedcom words will be replaced by better words
    # any missing parts omitted
    # no parts returns empty string
    #    verb [at age (age)] (date) in (place)
    #    e.g. "died at age 84 on 12 OCT 1856 in Boston, MA, USA"
    def describe(self,verb,atAge=False) :
        if self.phrase != None : return self.phrase
        # Get date phrase (or empty)
        phrase = ""
        if self.date :
            eparts = self.event.datePartsFullDate_(self.date)
            if len(eparts) > 2 and eparts[1] != "" :
                # has at least one valid date
                if len(eparts[0]) > 0 :
                    # uses qualifier words
                    q1 = eparts[0].upper()
                    if q1 in _gedWords :
                        phrase = _gedWords[q1]+" "
                    elif q1 :
                        phrase = q1+" "
                    phrase += eparts[1]
                    if len(eparts[2]) > 0 :
                        q2 = eparts[2].upper()
                        if q2 in _gedWords :
                            phrase += " "+_gedWords[q2]
                        elif q2 :
                            phrase += " "+q2
                        if len(eparts[3]) > 0 :
                            phrase += " " +eparts[3]
                elif eparts[1] != "" :
                    # assume only one date
                    self.SDNRange()
                    if self.sdn[0] == self.sdn[1] and self.sdn[0] != 0 :
                        phrase = "on "+eparts[1]
                    elif self.sdn[0] != self.sdn[1] :
                        phrase = "in "+eparts[1]
    
        # put together (optionally with age)
        age = None
        if atAge :
            age = self.event.evaluateExpression_("AGE")
            if age : verb = verb + " at age "+age
        full = ""
        space = ""
        if verb : space = " "
        
        # combine with date and place (phrase will be empty if no date)
        if phrase :
            full = verb+space+phrase
            if self.place : full += " in "+self.place
        elif self.place :
            full = verb+space+"in "+self.place
        elif age :
            full = verb
        self.phrase = full
        return self.phrase
    
    # Describe this event with following terms
    # Age is optional, date prefaced by qualifier words, in, or on, as needed
    # Gedcom words will be replaced by better words
    # any missing parts omitted
    # no parts returns empty string
    # randomly select from
    #    nounMid verb [at age (age)] (date) in (place)
    #      e.g. "Sam Adams died at age 84 on 12 OCT 1856 in Boston, MA, USA"
    #    (date) [at age (age)], nounMid verb in (place)
    #      e.g. "On 12 Oct 1856 at age 84, Sam Adams died in Boston, MA, USA"
    #    nounMid verb in (place) (date) [at age (age)]
    #      e.g. "Sam Adams died in Boston, MA USA On 12 Oct 1856 at age 84"
    def randomDescribe(self,nounMid,verb,atAge=False,freq=[.33,.67]) :
        if self.phrase != None : return self.phrase
        
        # pick style
        rand = random.random()
        pstyle = 3
        if rand < freq[0] :
            pstyle = 1
        elif rand < freq[1] :
            pstyle = 2
            
        # Get date phrase (or empty)
        dphrase = ""
        if self.date :
            eparts = self.event.datePartsFullDate_(self.date)
            if len(eparts) > 2 and eparts[1] != "" :
                # has at least one valid date
                if len(eparts[0]) > 0 :
                    # uses qualifier words
                    q1 = eparts[0].upper()
                    if q1 in _gedWords :
                        dphrase = _gedWords[q1]+" "
                    elif q1 :
                        dphrase = q1+" "
                    dphrase += eparts[1]
                    if len(eparts[2]) > 0 :
                        q2 = eparts[2].upper()
                        if q2 in _gedWords :
                            dphrase += " "+_gedWords[q2]
                        elif q2 :
                            dphrase += " "+q2
                        if len(eparts[3]) > 0 :
                            dphrase += " " +eparts[3]
                elif eparts[1] != "" :
                    # assume only one date
                    self.SDNRange()
                    if self.sdn[0] == self.sdn[1] and self.sdn[0] != 0 :
                        dphrase = "on "+eparts[1]
                    elif self.sdn[0] != self.sdn[1] :
                        dphrase = "in "+eparts[1]
    
        # get age
        age = ""
        if atAge :
            age = self.event.evaluateExpression_("AGE")
            if age : age = "at age "+age
        
        # assumes nounMid and verb are non-empty strings
        if pstyle == 1 :
            # nounMid verb [at age (age)] (date) in (place)
            full = CapitalOne(nounMid) + " " + verb
            if age != "" : full += " " + age
            if dphrase != "" : full += " " + dphrase
            if self.place != "" : full += " in " + self.place
        
        elif pstyle == 2 :
            # (date) [at age (age)], nounMid verb in (place)
            full = ""
            if dphrase != "" :
                full = CapitalOne(dphrase)
                if age != "" : full += " " + age
                full += ", "
            elif age != "" :
                full = CapitalOne(age) + ", "
            if full == "" :
                full = CapitalOne(nounMid) + " " + verb
            else :
                full += nounMid + " " + verb
            if self.place != "" : full += " in " + self.place
        
        else :
            # nounMid verb in (place) (date) [at age (age)]
            full = CapitalOne(nounMid) + " " + verb
            if self.place != "" : full += " in " + self.place
            if dphrase != "" : full += " " + dphrase
            if age != "" : full += " " + age

        self.phrase = full
        return self.phrase
    
    # return sdn range (find it if needed)
    def SDNRange(self) :
        if self.sdn[0] >= 0 : return self.sdn
        if not(self.date) :
            self.sdn = [0,0]
        else :
            self.sdn = self.event.sdnRangeFullDate_(self.date)
        return self.sdn

#---------------------- Attribute Class

# Wrapper for an attribute - changes description from events
# NOT DOCUMENTED
class Attribute(Event) :
    def __init__(self,evnt) :
        Event.__init__(self,evnt)
        self.attribute = evnt.contents()

    # Special case of Event.describe()
    #    verb attribute [at age (age)] (date) in (place)
    #    e.g. "was brewer at age 84 on 12 OCT 1856 in Boston, MA, USA"
    def describe(self,verb,atAge=False) :
        if self.phrase != None : return self.phrase
        if verb :
            averb = verb+" "+self.attribute
        else :
            averb = self.attribute
        return Event.describe(self,averb,atAge)
            
    # Pass possessive in nounMid and attribute name as well or in verb
    #    nounMid verb attribute [at age (age)] (date) in (place)
    #      e.g. "Sam Adams' occupation was brewer at age 84 on 12 OCT 1856 in Boston, MA, USA"
    #    (date) [at age (age)], nounMid verb attribute in (place)
    #      e.g. "On 12 Oct 1856 at age 84, Sam Adams' occupation was brewer in Boston, MA, USA"
    #    nounMid verb attribute in (place) (date) [at age (age)]
    #      e.g. "Sam Adams' occupation was brewer in Boston, MA USA On 12 Oct 1856 at age 84"
    def randomDescribe(self,nounMid,verb,atAge=False,freq=[.33,.67]) :
        if self.phrase != None : return self.phrase
        if verb :
            averb = verb+" "+self.attribute
        else :
            averb = self.attribute
        return Event.randomDescribe(self,nounMid,averb,atAge,freq)
    
#---------------------- Initialization

# Verify acceptable version of GEDitCOM II is running and a document is open.
# Return application object if script is done or None if checks faile
def CheckVersionAndDocument(sName,vNeed,bNeed=1) :
    # get application object into module private global
    global _gedit,_scriptName
    _gedit = SBApplication.applicationWithBundleIdentifier_("com.geditcom.GEDitCOMII")
    _scriptName = sName
    
    vnum = _gedit.versionNumber()
    if vnum >= 1.6 : vnum += _gedit.buildNumber()/100.
    vTest = vNeed + bNeed/100.
    if vnum < vTest:
        errMsg = "The script '" + sName + "' requires GEDitCOM II, Version "\
        + str(vNeed) + ", build "+str(bNeed)+" or newer.\nPlease upgrade and try again."
        print errMsg
        return None

    if _gedit.documents().count()<1 :
        errMsg = "The script '" + sName + \
        "' requires requires a document to be open\n"\
        + "Please open a document and try again."
        print errMsg
        return None

    return _gedit

# Returns the front document
def FrontDocument() :
    if _gedit.documents().count() > 0 :
        return _gedit.documents()[0]
    return None
    
#----------------- Working With Records

# return all selected records of a certain type
def GetSelectedType(rtype,gdoc=None) :
    if not(gdoc) : gdoc = FrontDocument()
    recs = gdoc.selectedRecords()
    pred = NSPredicate.predicateWithFormat_("recordType LIKE \""+rtype+"\"")
    onetype = recs.filteredArrayUsingPredicate_(pred)
    return onetype

#----------------- Working With Structures

# Create structure, add to end of specified record or structure
# return the new structure object
def AddStructure(grec,p) :
    ns = _gedit.classForScriptingClass_("structure").alloc().initWithProperties_(p)
    grec.structures().addObject_(ns)
    return ns

#----------------- Individual Record Functions

# Find the first selected individual record, or return None
# If provided prompt and no individual selected, let user choose
# with that prompt
def GetIndividual(gdoc=None,prompt=None) :
    if not(gdoc) : gdoc = FrontDocument()
    selRecs = gdoc.selectedRecords()
    for rec in selRecs :
        if rec.recordType()=="INDI":
            return rec
    if prompt :
        gdoc.userSelectByType_fromList_prompt_("INDI",None,prompt)
        while True :
            rec = gdoc.pickedRecord().get()
            if rec != "" : break
        if rec != "Cancel" : return rec
    return None

# enumeration over every individual: for (n,indi) in EveryIndividual(gdoc)
def EveryIndividual(gdoc=None) :
    if not(gdoc) : gdoc = FrontDocument()
    return enumerate(gdoc.individuals())

# individual's father (or None instead of "")
def GetFather(person) :
    if not(person) : return None
    f = person.father().get()
    if f : return f
    return None

# individual's mother (or None instead of "")
def GetMother(person) :
    if not(person) : return None
    m = person.mother().get()
    if m : return m
    return None

# get list of all ancestors of an individual
# list format is described in help for listed records property
def GetAncestors(indi,gdoc=None,maxgen=1000) :
    if not(gdoc) : gdoc = FrontDocument()
    outline = 0x74724F55
    indi.showAncestorsGenerations_treeStyle_(maxgen, outline)
    alist = gdoc.listedRecords()
    # both these can cause error message in Console for a new window
    _gedit.windows()[0].closeSaving_savingIn_(0x6E6F2020,None)
    #gdoc.closeChild()
    return alist
    
# get list of all descendants of an individual
# list format is described in help for listed records property
def GetDescendants(indi,gdoc=None,maxgen=1000) :
    if not(gdoc) : gdoc = FrontDocument()
    outline = 0x74724F55
    indi.showDescendantsGenerations_treeStyle_(maxgen, outline)
    alist = gdoc.listedRecords()
    # this can cause error message in Console for a new window
    _gedit.windows()[0].closeSaving_savingIn_(0x6E6F2020,None)
    #gdoc.closeChild()
    return alist

#----------------- Family Record Functions

# Find the first selected family record, or return None
def GetFamily(gdoc=None,prompt=None) :
    if not(gdoc) : gdoc = FrontDocument()
    selRecs = gdoc.selectedRecords()
    for rec in selRecs :
        if rec.recordType()=="FAM":
            return rec
    if prompt :
        gdoc.userSelectByType_fromList_prompt_("FAM",None,prompt)
        while True :
            rec = gdoc.pickedRecord().get()
            if rec != "" : break
        if rec != "Cancel" : return rec
    return None

# enumeration over every individual: for (n,fam) in EveryFamily(gdoc)
def EveryFamily(gdoc=None) :
    if not(gdoc) : gdoc = FrontDocument()
    return enumerate(gdoc.families())

# get alternate names such as John Hirst and Carolyn Kister
# NOT DOCUMENTED
def SpouseNames(famrec) :
    husb = famrec.husband().get()
    if husb :
        husb = husb.alternateName()
    else :
        husb = "Unknown Spouse"
    wife = famrec.wife().get()
    if wife :
        wife = wife.alternateName()
    else :
        wife = "Unknown Spouse"
    return husb+" and "+wife

#----------------- Note Record Functions

# Create a note record with given notes text
# return the newrecord object"note"
def AddNoteRecord(gdoc=None,noteText="New Notes") :
    if not(gdoc) : gdoc = FrontDocument()
    p = {"notesText": noteText}
    grec = _gedit.classForScriptingClass_("note").alloc().initWithProperties_(p)
    gdoc.notes().addObject_(grec)
    return grec
    
# If the text begins in <div, assume this is html content
#   (assumes no leading white space). If not html, return [None,None]
# If is html, look for comments (in order in list) in format <!--cmnt   -->
# If found, return [comment found,entire text of comment]
# If no comment found, return [None,""]
# For example, to look for html note name use GetHTMLComment(ntext,"name")
def GetHTMLComment(ntext,comments) :
    if len(ntext) < 5 : return [None,None]
    if ntext[:4].lower() != "<div" : return [None,None]
    for cmnt in comments :
        sub = ntext.find("<!--"+cmnt)
        if sub < 0 : continue
        endsub = ntext.find("-->",sub+4)
        if endsub < 0 : continue
        return [cmnt,ntext[sub+4+len(cmnt):endsub]]
    return [None,""]
    
#--------------------------- Place Record Functions

# find place record among selected records
def GetPlace(gdoc=None,prompt=None) :
    if not(gdoc) : gdoc = FrontDocument()
    selRecs = gdoc.selectedRecords()
    for rec in selRecs :
        if rec.recordType()=="_PLC":
            return rec
    if prompt :
        gdoc.userSelectByType_fromList_prompt_("_PLC",None,prompt)
        while True :
            rec = gdoc.pickedRecord().get()
            if rec != "" : break
        if rec != "Cancel" : return rec
    return None

# Get centroid of first map for a place record
# return [lat,lon] or [error message]
def FirstMapCentroid(plc):
    bbmap = plc.structures().objectWithName_("_BOX")
    if bbmap.exists() == True :
        return GetLatLonCentroid(bbmap.evaluateExpression_("_BNDS"))
    return ["Place has no maps"]

#--------------------------- Map Creating Utilities

# height if map element in pixels
# rect = [S, W, N, E] of bounding box as floats
# mapPOIs = java script code with pois
# mapBB = [stroke color, opacity, fill color, opacity] or None to omit
# style = ROADMAP, 
def createJSMap(height,rect,mapPOIs=None,mapBB=None,clickLatLon=False,mapStyle="ROADMAP") :
    css = ["#mapPane {"]
    css.append("    width:100%;")
    css.append("    border:thin solid black;")
    css.append("    height:"+str(height)+"px;\n}")
    if clickLatLon == True :
        css.append("#status {")
        css.append("    width:100%;")
        css.append("    height:20px;")
        css.append("    font-family: sans-serif;")
        css.append("    font-size: small;")
        css.append("    border-left:thin solid black;")
        css.append("    border-bottom:thin solid black;")
        css.append("    border-right:thin solid black;")
        css.append("    background-color: #CCC;\n}")
        css.append("#cl {")
        css.append("    margin: 0 0 0 0;")
        css.append("    padding-left: 18px;")
        css.append("    padding-top: 2px;\n}")
    
    html = ["<script type='text/javascript' src='http://maps.google.com/maps/api/js?sensor=false'></script>"]
    html.append("<script type='text/javascript'>")
    html.append("window.onload = function ()")
    html.append("{   s = "+'{0:.6g}'.format(rect[0])+";")
    html.append("    n = "+'{0:.6g}'.format(rect[2])+";")
    html.append("    w = "+'{0:.6g}'.format(rect[1])+";")
    html.append("    e = "+'{0:.6g}'.format(rect[3])+";")
    html.append("    sw = new google.maps.LatLng(s, w);")
    html.append("    ne = new google.maps.LatLng(n, e);")
    html.append("    var BB = [")
    html.append("      sw,")
    html.append("      new google.maps.LatLng(n, w),")
    html.append("      ne,")
    html.append("      new google.maps.LatLng(s, e)")
    html.append("    ];")
    if mapBB :
        html.append("    mapBB = new google.maps.Polygon({")
        html.append("        paths: BB,")
        html.append("        strokeColor: \""+mapBB[0]+"\",")
        html.append("        strokeOpacity: "+'{0:.2g}'.format(mapBB[1])+",")
        html.append("        strokeWeight: 2,")
        html.append("        fillColor: \""+mapBB[2]+"\",")
        html.append("        fillOpacity: "+'{0:.2g}'.format(mapBB[1]))
        html.append("    });")
    html.append("    cv = (n+s)/2.;")
    html.append("    ch = (w+e)/2.;")
    html.append("    var latlng = new google.maps.LatLng(cv,ch);")
    html.append("    var myOptions = {")
    html.append("      zoom: 4,")
    html.append("      center: latlng,")
    html.append("      mapTypeId: google.maps.MapTypeId."+mapStyle.upper())
    html.append("    };")
    html.append("    var map = new google.maps.Map(document.getElementById(\"mapPane\"),myOptions);")
    html.append("    var bounds = new google.maps.LatLngBounds(sw,ne);")
    html.append("    map.fitBounds(bounds);")
    if mapBB :
        html.append("    mapBB.setMap(map);")
    if mapPOIs :
        html.append(mapPOIs)
    if clickLatLon == True :
        html.append("    google.maps.event.addListener(map, 'click', function(event) {")
        html.append("        displayClickLatLng(event.latLng);")
        html.append("    });")
        if mapBB :
            html.append("    google.maps.event.addListener(mapBB, 'click', function(event) {")
            html.append("        displayClickLatLng(event.latLng);")
            html.append("    });")
    html.append("};")
    if clickLatLon == True :
        html.append("function displayClickLatLng(location) {")
        html.append("    lat = location.lat();")
        html.append("    lat = Math.round(lat*10000)/10000;")
        html.append("    lon = location.lng();")
        html.append("    lon = Math.round(lon*10000)/10000;")
        html.append("    document.getElementById('status').innerHTML = '<p id=\"cl\"><b>Click-location:</b> ('+lat+', '+lon+')</p>';")
        html.append("}")
    if mapPOIs :
        html.append("function attachMessage(map, marker, message) {")
        html.append("   var infowindow = new google.maps.InfoWindow({")
        html.append("      content: message,")
        html.append("      maxWidth:600")
        html.append("   });")
        html.append("   google.maps.event.addListener(marker, 'click', function() {")
        html.append("      infowindow.open(map,marker);")
        html.append("   });")
        html.append("}")
    html.append("</script>")
    
    body = ["<div id=\"mapPane\"></div>"]
    if clickLatLon == True :
        body.append("<div id='status'><p id='cl'><i>click to display latitude and longitude</i></p></div>")
    
    return ['\n'.join(css),'\n'.join(html),'\n'.join(body)]

# create javascript for map POI
# lat,lon as floats
# num - unique number for current map
# poiname - text when hover over poi
# details - html content for click window (if any get surrounded by <p>)
def MakeMapPOI(lat,lon,num,poiname,details=None) :
    latstr = '{0:.6g}'.format(lat)
    lonstr = '{0:.6g}'.format(lon)
    poiID = str(num)
    onepoi=["    poi"+poiID+" = new google.maps.LatLng("+latstr+","+lonstr+");\n"]
    onepoi.append("    mark"+poiID+" = new google.maps.Marker({position: poi"+poiID)
    poiname = poiname.replace("\"","\\\"")
    onepoi.append(", map: map, title: \""+poiname+"\"});\n")
    if details :
        details = "<p>"+details.replace("\"","\\\"")+"</p>"
        onepoi.append("    attachMessage(map,mark"+poiID+",\""+details+"\");\n")
    return ''.join(onepoi)
    
#--------------------------- Module Property Functions

# the name - as set in start up
def GetScriptName():
    return _scriptName
    
# file name of current script (or this module if None passed)
# i.e., last component of the file path
# NOT DOCUMENTED
def CurrentScript(afile=None) :
    if not(afile) : afile = __file__
    return os.path.abspath(afile).rsplit("/",1)[1]

# full path of folder for current script (or this module if None passed)
# NOT DOCUMENTED
def CurrentScriptFolder(afile=None) :
    if not(afile)  : afile = __file__
    return os.path.abspath(afile).rsplit("/",1)[0]

# name of GEDitCOM II with version number
# NOT DOCUMENTED
def AppVersion() :
    # get application object into module private global
    global _gedit
    vnum = _gedit.versionNumber()
    bnum = _gedit.buildNumber()
    if bnum<=1 :
       return "GEDitCOM II, Version "+"{0:.1f}".format(vnum)
    else :
       return "GEDitCOM II, Version "+"{0:.1f}".format(vnum)+ " b"+str(bnum)

#--------------------------- HTML Helper Functions

# Make Table - option+[parameter] pairs, can break into multiple calls
# begin - start with <table> element
# end - end with </table> element
# caption,text - insert caption
# head,list - insert full row of header cells
# body - start table body
# endbody - end table body
# row,list - row of table cells
def MakeTable(*args) :
    i = 0
    table = []
    while i < len(args) :
        if args[i] == "begin" :
            table.append("<table>\n")
        
        elif args[i] == "end" :
            table.append("</table>\n")
        
        elif args[i] == "caption" :
            table.append("<caption>")
            if i+1 < len(args) :
                table.append(args[i+1])
                i += 1
            table.append("</caption>\n")
        
        elif args[i].startswith("head") :
            table.append("<thead>\n")
            if i+1 < len(args) :
                table.append(TableRow(args[i+1],"th",args[i][5:]))
                i += 1
            table.append("</thead>\n")
        
        elif args[i] == "body" :
            table.append("<tbody>\n")
        
        elif args[i] == "endbody" :
            table.append("</tbody>\n")
        
        elif args[i].startswith("row") :
            if i+1 < len(args) :
                table.append(TableRow(args[i+1],"td",args[i][4:]))
                i += 1
        
        else :
            return "<tr><td><b> Invalid Table Data: "+args[i]+" </b></td></tr>"
        
        i += 1
    return ''.join(table)

# Construct of an html table and each cell is type cell (td or th)
# cell is whitespace delimited list of c l r or class name for that cell
# NOT DOCUMENTED
def TableRow(row,cell,style) :
    csty = style.split()
    trow = "<tr>\n"
    scell = "<"+cell+">"
    ecell = "</"+cell+">"
    for j in range(len(row)) :
        if j < len(csty) :
            if csty[j] == "c" :
                scell = "<"+cell+" align='middle'>"
            elif csty[j] == "r" :
                scell = "<"+cell+" align='right'>"
            elif csty[j] == "l" :
                scell = "<"+cell+" align='left'>"
            else :
                scell = "<"+cell+" class='"+csty[j]+"'>"
        else :
            scell = "<"+cell+">"
        trow += scell + row[j] + ecell
    trow += "\n</tr>\n"
    return trow

# Contruct full list from list.
# ordered True for numbered or false for not
def MakeList(data,ordered=False) :
    if ordered :
        tag = "ol"
    else :
        tag = "ul"
    alist = ["<"+tag+">"]
    for i in range(len(data)) :
        alist.append("<li>"+data[i]+"</li>")
    alist.append("</"+tag+">")
    return "\n".join(alist)

# link to record in reference (True to use alternate name)
def RecordLink(ref,alternate=False) :
    if alternate :
        linkText = ref.alternateName()
    else :
        linkText = ref.name()
    return "<a href='"+ref.id()+"'>"+linkText+"</a>"

# center a block of text
def Centered(ctext) :
    return "<center>\n"+ctext+"\n</center>\n"

#--------------------------- Utility Functions

# shell command line and output
# output is tuple (stdoutdata,stderrdata,return code (int))
def DoCommand(command_line) :
    p = subprocess.Popen(command_line, stdout=subprocess.PIPE, shell=True, stderr=subprocess.PIPE)
    output = p.communicate()
    return [output[0],output[1],p.poll()]

# save to file. If error alerts user (if silent is False) and return error message
# If succeeds return None
def WriteUTF8File(saveFile,text,silent=False) :
    nstring = NSString.stringWithString_(text)
    (result,error) = nstring.writeToFile_atomically_encoding_error_(saveFile,objc.YES,NSUTF8StringEncoding,objc.nil)
    if result != True:
        if silent : return error.description()
        errMsg = "An I-O error occurred trying to write the UTF8 text file"
        gdoc.userOptionTitle_buttons_message_(errMsg,["OK"],error.description())
        return error.description()
    return None

# convert integer between 1 and 4999 to uppercase roman numeral
# see also: http://en.wikipedia.org/wiki/Roman_numerals
def RomanNumeral(number) :
    if number<1 or number>4999 : return str(number)
    result = ""
    for value, numeral in sorted(_numerals.items(), reverse=True):
        while number >= value:
            result += numeral
            number -= value
    return result

# cardinal number 0 to 10 (lowercase), number to string otherwise
def Cardinal(anum) :
    if anum <0 or anum>10 : return str(anum)
    return _cardinal[anum]
    
# Send fraction and message to the progress panel
def ProgressMessage(fraction,msg=None) :
    _gdoc = FrontDocument()
    if fraction==None : fraction = -1
    _gdoc.notifyProgressFraction_message_(fraction,msg)

# convert string to AppleScript enumerated constant
def GetConstant(uniqueStr):
    if uniqueStr=="chart":
        byteForm = 0x74724348			# trCH
    elif uniqueStr=="outline":
        byteForm = 0x74724F55			# trOU
    elif uniqueStr=="the children":
        byteForm = 0x736B4348			# skCH
    elif uniqueStr=="the events": 
        byteForm = 0x736B4556			# skEV
    elif uniqueStr=="the spouses":
        byteForm = 0x736B5350			# skSP
    elif uniqueStr=="the multimedia":
        byteForm = 0x736B4D4D			# skMM
    elif uniqueStr=="char_MacOS":
        byteForm = 0x784F7031			# xOp1
    elif uniqueStr=="char_ANSEL":
        byteForm = 0x784F7032			# xOp2
    elif uniqueStr=="char_UTF8":
        byteForm = 0x784F7033			# xOp3
    elif uniqueStr=="char_UTF16":
        byteForm = 0x784F7034			# xOp4
    elif uniqueStr=="char_Windows":
        byteForm = 0x784F7035			# xOp5
    elif uniqueStr=="lines_LF":
        byteForm = 0x784F7036			# xOp6
    elif uniqueStr=="lines_CR":
        byteForm = 0x784F7037			# xOp7
    elif uniqueStr=="lines_CRLF":
        byteForm = 0x784F7038			# xOp8
    elif uniqueStr=="mm_GEDitCOM":
        byteForm = 0x784F7039			# xOp9
    elif uniqueStr=="mm_Embed":
        byteForm = 0x784F7041			# xOpA
    elif uniqueStr=="mm_PhpGedView":
        byteForm = 0x784F7042			# xOpB
    elif uniqueStr=="logs_Include":
        byteForm = 0x784F7043			# xOpC
    elif uniqueStr=="logs_Omit":
        byteForm = 0x784F7044			# xOpD
    elif uniqueStr=="places_Include":
        byteForm = 0x784F7045			# xOpE
    elif uniqueStr=="places_Omit":
        byteForm = 0x784F7046			# xOpF
    elif uniqueStr=="books_Include":
        byteForm = 0x784F7047			# xOpG
    elif uniqueStr=="books_Omit":
        byteForm = 0x784F7048			# xOpH
    elif uniqueStr=="settings_Embed":
        byteForm = 0x784F7049			# xOpI
    elif uniqueStr=="settings_Omit":
        byteForm = 0x784F704A			# xOpJ
    elif uniqueStr=="thumbnails_Embed":
        byteForm = 0x784F704B			# xOpK
    elif uniqueStr=="thumbnails_Omit":
        byteForm = 0x784F704C			# xOpL
    elif uniqueStr=="locked":
        byteForm = 0x724C636B			# rLck
    elif uniqueStr=="privacy":
        byteForm = 0x72507276			# rPrv
    elif uniqueStr=="unlocked":
        byteForm = 0x72556E6C			# rUnl
    else:
        byteForm = 0
    return byteForm

# capitalize first letter on string
def CapitalOne(target):
    if len(target)==0 : return ""
    return target[:1].upper() + target[1:]

# open web site in a browsr
def OpenWebSite(website) :
    thesite = NSString.stringWithString_(website)
    theurl = NSURL.URLWithString_(thesite)
    NSWorkspace.sharedWorkspace().openURL_(theurl)

# Get screen size by assuming it is desktop window bounds
# May have issue if multiple screen?
def GetScreenSize() :
    fndr = SBApplication.applicationWithBundleIdentifier_("com.apple.Finder")
    props = fndr.desktop().containerWindow().properties()
    bnds = str(props["bounds"])
    bnds = bnds.replace("{","")
    bnds = bnds.replace("}","")
    bnds = bnds.split(",")
    return [float(bnds[-2]),float(bnds[-1])]

#--------------------------- Date Functions

# Convert two date SDNs to years from first date to second date
def GetAgeSpan(beginDate, endDate) :
    return (endDate - beginDate) / 365.25

# compare dates for match quality where date1 and date2 are two ranges
# return 0 of can't compare, -1 if conflict, or ranking 0 to 1
def DateQuality(date1,date2) :
    global _tau,_cutoff
    
    # check for no date
    qual = 0.
    if date1[0]==0 or date2[0]==0 :
        return qual
	
    # reorder with wider one second
    dy = date2[1]-date2[0]
    dx = date1[1]-date1[0]
    if dx > dy :
        x = [date2[0],date2[1]]
        y = [date1[0],date1[1]]
        dy = dx
        dx = x[1]-x[0]
    else :
        x = [date1[0],date1[1]]
        y = [date2[0],date2[1]]
    
    # check signs
    if y[1] < x[1] :
        x = [-x[1],-x[0]]
        y = [-y[1],-y[0]]
    
    # check for x within y
    if x[0]>=y[0] and x[1]<=y[1] :
        x[0] = y[0]+0.5*(dy-dx)
        x[1] = x[0]+dx
    
    # quality function
    if y[0] >= x[1] :
        if x[1] > x[0] :
            e1 = -(y[0]-x[0])/_tau
            e2 = -(y[0]-x[1])/_tau
            e3 = -(y[1]-x[0])/_tau
            e4 = -(y[1]-x[1])/_tau
            qual = -math.exp(e1)+math.exp(e2)+math.exp(e3)-math.exp(e4)
            qual *= _tau*_tau/(dx*dy)
        else :
            if y[1] > y[0] :
                e1 = -(y[0]-x[0])/_tau
                e2 = -(y[1]-x[1])/_tau
                qual = math.exp(e1)-math.exp(e2)
                qual *= _tau/dy
            else :
                e1 = -(y[1]-x[0])/_tau
                qual = math.exp(e1)
    elif y[0] >= x[0] :
        e1 = -(x[1]-y[0])/_tau
        e2 = -(y[0]-x[0])/_tau
        e3 = -(y[1]-x[0])/_tau
        e4 = -(y[1]-x[1])/_tau
        qual = math.exp(e1)-math.exp(e2)+math.exp(e3)-math.exp(e4)
        qual = _tau*(2*(x[1]-y[0])+_tau*qual)/(dx*dy)
    else :
        if x[1] > x[0] :
            e1 = -(x[0]-y[0])/_tau
            e2 = -(x[1]-y[0])/_tau
            e3 = -(y[1]-x[0])/_tau
            e4 = -(y[1]-x[1])/_tau
            qual = -math.exp(e1)+math.exp(e2)+math.exp(e3)-math.exp(e4)
            qual *= _tau*_tau/(dx*dy)
            qual += 2.*_tau/dy
        else :
            e1 = -(x[0]-y[0])/_tau
            e2 = -(y[1]-x[1])/_tau
            qual = -math.exp(e1)-math.exp(e2)
            qual *= _tau/dy
            qual += 2.*_tau/dy

    if qual < _cutoff : qual = -1.
    return qual

# Set globals for date match
def SetTauCutoff(atau,years) :
    global _tau,_cutoff
    _tau = atau
    _cutoff = math.exp(-365.*years/_tau)

# Retrieve Globals
def GetTauCutoff() : 
    return [_tau,_cutoff]

#--------------------------- Lat Lon Utilities

# Class to store single coordinate
# coordinate is signed value
# direction is 0 (lat), 1 (lon), 2 (distance), 3 (unknown)
class GlobalCoordinate :
    def __init__(self,gps=None,expect=3,coord=0.,dir=1) :
        self.coordinate = coord
        self.direction = dir
        self.error = None
        if(gps) :
            self.error = self.setFromString(gps,expect)
            if self.error : self.direction = 3
    
    # Convert string to coordinate. String can be 
    #	(sign) (int).(int)
    #	(number) (direction)
    #	(sign) (int).(int).(int)	(dots can special minute or second chars)
    #	(int).(int).(int) (direction)
    # Here direction can be any text beginning in N, E, W, or S (case insensitive)
    #   direction can be M or K (case insensitive) to mean a distance in miles
    #   or kilometers (output in km). Number cannot be DMS if a distance
    # expect can be 0 to 3 for expected directions
    #		error if specify and does not match. If unknown and no direction given
    #		it will be a longitude
    def setFromString(self,coord,expect) :
        sign = 0;				# it can be -1 (has - sign) or +1 (has plus sign)
        # 0, 1, 2, 3 for in degrees (or number), minutes (or fraction),  seconds
		#      and seconds decimal or 4 when has four numbers already
        currentDigits = -1;		
        hasDMS = False;			# has degrees, minutes, or seconds delimiter
        scale = 1.0;			# if need to scale a distance
        degrees = []
        minutes = []
        seconds = []
        secdecs = []
        if expect==3 :
            self.direction = 1
        else :
            self.direction = expect
        compassDir = ['e','E','n','N','s','S','w','W']
        degreeSign = [unichr(0x00B0),unichr(0x02DA)]
        distLetter = ['m','M','k','K']
        minsecSign = ["'",unichr(34),unichr(8242),unichr(8243)]
        
        i = 0
        maxi = len(coord)
        while i<maxi :
            gc = coord[i]
            #print str(i)+":"+gc
            
            # plus sign
            if gc=='+' :
                if sign!=0 or currentDigits>=0 :
                    # already has a sign or sign in middle of number
                    return "Invalid or extra plus sign"
                sign = 1
            
            # minus sign
            elif gc=='-' :
                if sign!=0 or currentDigits>=0 :
                    # already has a sign or sign in middle of number
                    return "Invalid or extra minus sign"
                sign = -1
            
            # a digit
            elif gc.isdigit() :
                # check each case
                if currentDigits==4 :
                    return "Coordinate has more than three numbers (degrees, minutes, and seconds)"
                elif currentDigits==3 :
                    secdecs.append(gc)
                elif currentDigits==2 :
                    seconds.append(gc)
                elif currentDigits==1 :
                    minutes.append(gc)
                elif currentDigits==0 :
                    degrees.append(gc)
                else :
                    currentDigits = 0
                    degrees.append(gc)
            
            # decimal point
            elif gc=='.' :
                if currentDigits<0 :
                    # skipping degrees (make them zero) (e.g. ".34")
                    currentDigits = 1          # mode directly to minutes
                elif currentDigits>=4 :
                    return "Too many delimiters for degrees, minutes, and seconds"
                else :
                    # 0 to 1, 1 to 2, 2 to 3, or 3 to 4
                    currentDigits += 1
             
            # degree sign
            elif gc in degreeSign :
                if currentDigits<0 :
                    return "Degrees symbol must be after a number"
                elif currentDigits>0 :
                    return "Degrees symbol can only be after the first number"
                else :
                    # 0 to 1
                    currentDigits += 1
                hadDMS = True
             
            # minutes or seconds
            elif gc in minsecSign :
                if currentDigits<0 :
                    return "Minutes and seconds symbols must be after a number"
                
                # convert prime and double prime to single and double quote
                if gc==minsecSign[2] :
                    gc = minsecSign[0]
                elif gc==minsecSign[3] :
                    gc = minsecSign[1]
                
                # look for next character to see if two consecutive minutes symbols to be seconds
                if gc==minsecSign[0] and i+1<maxi :
                    gcnext = coord[i+1]
                    if gcnext==minsecSign[0] or gcnext==minsecSign[2] :
                        gc = minsecSign[1]
                        i += 1
                
                # ending minutes number
                if gc==minsecSign[0] :
                    if currentDigits==0 :
                        # first number is minutes (e.g. 34'55'')
                        minutes = degrees
                        degrees = []
                    elif currentDigits>=2 :
                        return "Minutes symbol in an invalid location";
                    
                    # only seconds are left
                    currentDigits = 2;
                    hasDMS = True
                
                # ending seconds number
                else :
			        if currentDigits==0 :
			            # first number is seconds (e.g. 45'')
			            seconds = degrees
			            degrees = []
			            minutes = []
			        elif currentDigits==1 :
			            # second number is seconds (e.g. 32'45'')
			            seconds = minutes
			            minutes = []
			        elif currentDigits>3 :
			            return "Seconds symbol in an invalid location"
			        
			        # all done now
			        currentDigits = 4
			        hasDMS = True

            # a compus letter
            elif gc in compassDir :
                if currentDigits<0 :
                    return "The coordinate has no number"
                
                # set sign
                if gc=='e' or gc=='E' or gc=='n' or gc=='N' :
                    sign = 1
                else :
                    sign = -1
                
                # set type of coordinate
                if gc=='e' or gc=='E' or gc=='w' or gc=='W' :
                    self.direction = 1        # longitude
                else :
                    self.direction = 0        # latitude
                
                # error if invalid direction
                if expect!=self.direction and expect!=3 :
                    return "Invalid compass direction for expected coordinate"
                 
                # time to stop
                i = maxi
             
            # a distance in miles or kilometers
            elif gc in distLetter :
                if currentDigits<0 :
                    return "The distance has no number"
                
                if hasDMS or currentDigits>1 :
                    return "Distances in miles or kilometers cannot be in degrees, minutes, and seconds."
                
                # set scaling
                if gc=='m' or gc=='M' :
                    scale = 1.609344
                 
                # set to a distance and verify OK
                self.direction = 2
                if expect!=self.direction and expect!=3 :
                    return "Invalid distance found when expected a compass direction"
		
                # time to stop
                i = maxi
             
            # error if not white space (160 is nonbreaking space)
            elif gc!=' ' and gc!='\t' and gc!='\r' and gc!='\n' and gc!=unichr(160) :
                return "Invalid character in the coordinate ("+gc+")"
            
            # on to next character
            i += 1
            
        # no digits were entered
        if currentDigits<0 : return "The coordinate has no number"
            
        # get degrees
        degstr = ''.join(degrees)
        if len(degstr)==0 :
            degVal = 0
        else :
            degVal = int(degstr)
        
        # calculate coordinate now
        if hasDMS or currentDigits>1 :
            # degrees/minutes/seconds
            
            # minutes
            minstr = ''.join(minutes)
            lmin = len(minstr)
            if lmin==0 :
                minVal = 0.
            elif lmin<=2 :
                minVal = float(minstr)/100.
            else :
                return "Minutes can only have two digits"
            
            # seconds
            secstr = ''.join(seconds)
            lsec = len(secstr)
            if lsec==0 :
                secVal = 0.
            elif lmin<=2 :
                secVal = float(secstr)/100.
            else :
                return "Seconds can only have two digits before decimal"
            
            # seconds decimal
            decstr = ''.join(secdecs)
            ldec = len(decstr)
            if ldec>7 :
                decstr = decstr[:7]
                ldec = 7
            if ldec>0 :
                secdecVal = float(decstr)/10.**ldec
            else :
                secdecVal = 0
            secVal += secdecVal/100.
            
            # check range
            if(minVal>=.6 or secVal>=.6) :
                return "Minutes or seconds must be less than 60"
            
            # get coordinate
            self.coordinate = degVal + minVal/0.6 + secVal/36.0
		
        else :
            minstr = ''.join(minutes)
            lmin = len(minutes)
            if lmin>7 :
                minstr = minstr[:7]
                lmin=7
            if lmin>0 :
                minVal = float(minstr)/10.**lmin
            else :
                minVal = 0.
        
            self.coordinate = scale*(float(degVal)+minVal)
        
        # apply sign
        if sign<0. : self.coordinate = -self.coordinate
        
        # check ragne for latitudes and longitudes
        if self.direction==0 :
            if self.coordinate>90. or self.coordinate<-90. :
                return "Latitudes must be between -90 and 90"
        elif self.direction==1 :
            if self.coordinate>180. or self.coordinate<-180. :
                return "Longitudes must be between -180 and 180"
        
        return None
        
    # return as a signed number
    def signedNumber(self) :
        return '{0:.7g}'.format(self.coordinate)
    
    # return as compass number
    def compassNumber(self) :
        # distance in km
        if self.direction==2 : return self.signedNumber()
        
        # latitude else longitude
        if self.direction==0 :
            if self.coordinate<0. :
                return '{0:.7g}'.format(-self.coordinate)+"S"
            else :
                return '{0:.7g}'.format(self.coordinate)+"N"
        else :
            if self.coordinate<0. :
                return '{0:.7g}'.format(-self.coordinate)+"W"
            else :
                return '{0:.7g}'.format(self.coordinate)+"E"
                
    # return DMS number
    # useSign True for signed number of False for compass letters
    # useMarks True for deg/min/sec symbols or False fo periods
    def dmsNumber(self,useSign=False,useMarks=False) :
        # distance in km
        if self.direction==2 : return self.signedNumber()
        
        if useMarks :
            degMark = unichr(0x02DA)
            minMark = "'"
            secMark = unichr(34)
        else :
            degMark = "."
            minMark = "."
            secMark = ""
        
        if self.coordinate<0 :
            cabs = -self.coordinate
        else :
            cabs = self.coordinate
        
        degrees = int(cabs)
        minutesd = 60.*(cabs-float(degrees))
        minutes = int(minutesd)
        seconds = 60.*(minutesd-float(minutes))
        
        secs = '{0:.2g}'.format(seconds)
        unsigned = str(degrees)+degMark+str(minutes)+minMark+secs+secMark
        
        if useSign:
            if self.coordinate<0. :
                return "-"+unsigned
            return signed
        
        else :
            if self.direction==0 :
                # latitude
                if self.coordinate<0. :
                    return unsigned+"S"
                return unsigned+"N"
            else :
                # longitude
                if self.coordinate<0. :
                    return unsigned+"W"
                return unsigned+"E"
    
    # convert coordinate to degrees (or just one number if a distance)
    def convertToDMS(self) :
        if self.direction==2 : return [coordinate,0.,0.]
        
        if self.coordinate<0 :
            cabs = -self.coordinate
            sign = -1
        else :
            cabs = self.coordinate
            sign = 1
        
        degrees = int(cabs)
        minutesd = 60.*(cabs-float(degrees))
        minutes = int(minutesd)
        seconds = 60.*(minutesd-float(minutes))
        return [sign*degrees,minutes,seconds]
    
    # is it a latitude
    def isLatitude(self) :
        return self.direction==0
    
    # is it a longitude
    def isLongitude(self) :
        return self.direction==1
    
    # is it a distance
    def isDistance(self) :
        return self.direction==2
                
# find km per degree of longitude and given latitude (in degrees)
def kmPerLongitudeDegree(atLat) :
    lat = atLat*0.01745329      # convert to radians (pi/180)
    clat = math.cos(lat)
    a = clat*clat*0.0000761524;		 # number is sin(pi/180)^2
    c = 2. * math.atan(math.sqrt(a/(1-a)))
    return 6371*c;					# 6731 is radius of earth in km

# find km per degree of latitude (longitude does not matter)
def kmPerLatitudeDegree() :
    return 111.195

# arc distance on surface of earth in km
# pt1 and pt2 are [lat,lon] pairs
def kmDistanceBetween(pt1,pt2):
    # phi = 90 - latitude
    phi1 = (90.0 - pt1[0])*0.01745329
    phi2 = (90.0 - pt2[0])*0.01745329
        
    # theta = longitude
    theta1 = pt1[1]*0.01745329
    theta2 = pt2[1]*0.01745329
        
    # For two locations in spherical coordinates 
    # (1, theta1, phi1) and (1, theta2, phi2)
    # cosine( arc length ) = 
    #    sin phi1 sin phi2 cos(theta1-theta2) + cos phi1 cos phi2
    alcos = (math.sin(phi1)*math.sin(phi2)*math.cos(theta1 - theta2) + 
           math.cos(phi1)*math.cos(phi2))
    return math.acos(alcos)*6731      # 6731 is radius of earth in km

# Take list of comma-separated lat, lon, and distance numbers
# and return list of GlobalCoordinate objects
# If any have formatting errors return [item #, error message]
def DecodeLatLonList(gpsStr) :
    gpsStr = gpsStr.replace("(","")
    gpsStr = gpsStr.replace(")",",")
    gpsStr = gpsStr.replace("[","")
    gpsStr = gpsStr.replace("]",",")
    gpses = gpsStr.split(",")
    gpsGCs = []
    for i in range(len(gpses)) :
        gcstr = gpses[i].strip()
        if len(gcstr)>0 :
            gc = GlobalCoordinate(gpses[i],3)
            if gc.error==None :
                gpsGCs.append(gc)
            else :
                return [i+1,gc.error]
    return gpsGCs

# Take list of GPS coordinates
# If two or three, assume lat,lon in first two
# If four or more, assume two pairs of lat lon and return average
# If 0 or 1 or bad formating return error message in one-element list
# No checking that lat or lon are actually lat or lon
def GetLatLonCentroid(gpsStr) :
    gpsGCs = DecodeLatLonList(gpsStr)
    if len(gpsGCs)==0 : return ["No latitude or longitudes were found in the text"]
    if len(gpsGCs)==1 : return ["Only one latitude or longitudes was found in the text"]
    if isinstance(gpsGCs[0], int) :
        msg = "Coordinate #"+str(gpsGCs[0])+" has invalid format: "+gpsGCs[1]
        return [msg]
    if len(gpsGCs)<4 :
        return [gpsGCs[0],gpsGCs[1]]
    else :
        # average first two pairs
        mid = 0.5*(gpsGCs[0].coordinate+gpsGCs[2].coordinate)
        lat = GlobalCoordinate(None,0,mid,0)
        if gpsGCs[1].coordinate > gpsGCs[3].coordinate :
            # must cross -180
            mid = 0.5*(gpsGCs[1].coordinate+gpsGCs[3].coordinate+360.)
            if mid>180. : mid -= 360.
        else :
            mid = 0.5*(gpsGCs[1].coordinate+gpsGCs[3].coordinate)
        lon = GlobalCoordinate(None,1,mid,1)
        return [lat,lon]    

# Take list of GPS coordinates
# If two or three, assume lat,lon centroid in first two
#    third (if there) is size of box, otherwise size=5km
# If four or more, assume two pairs of lat lon
# Return coordinates for [s, w, n, e]
# If fails return error message in one-element list
# No checking that lat or lon are actually lat or lon
def GetBoundingBox(gpsStr) :
    gpsGCs = DecodeLatLonList(gpsStr)
    if len(gpsGCs)==0 : return ["No latitude or longitudes were found in the text"]
    if len(gpsGCs)==1 : return ["Only one latitude or longitudes was found in the text"]
    if isinstance(gpsGCs[0], int) :
        msg = "Coordinate #"+str(gpsGCs[0])+" has invalid format: "+gpsGCs[1]
        return [msg]
    if len(gpsGCs)<4 :
        if len(gpsGCs)==3 :
            spanLat = gpsGCs[2].coordinate
        else :
            spanLat = 5.
        spanLong = 0.5*spanLat/kmPerLongitudeDegree(gpsGCs[0].coordinate)
        spanLat = 0.5*spanLat/kmPerLatitudeDegree()
        return [gpsGCs[0].coordinate-spanLat,gpsGCs[1].coordinate-spanLong,\
        gpsGCs[0].coordinate+spanLat,gpsGCs[1].coordinate+spanLong]
    else :
        # switch s and n if backwards, but not w and e (may span -180)
        if gpsGCs[0].coordinate<gpsGCs[2].coordinate :
            s = gpsGCs[0]
            n = gpsGCs[2]
        else :
            s = gpsGCs[2]
            n = gpsGCs[0]
        return [s.coordinate,gpsGCs[1].coordinate,n.coordinate,gpsGCs[3].coordinate]

#--------------------------- User Interation

# Alert window with one or two messages and only an OK button to dismiss
def Alert(mainText,message="") :
    gdoc = FrontDocument()
    gdoc.userOptionTitle_buttons_message_(mainText,["OK"],message)
    
# Get integer from user. title is window title and prompt is prompt
# istart is number initially loaded in the editing field
# The number is returned as integer and is verified to be between
# imin and imax (either can be None if limit does not matter)
# return None is canceled
def GetInteger(prompt,title,istart=0,imin=None,imax=None) :
    gdoc = FrontDocument()
    while True :
        r = gdoc.userInputPrompt_buttons_initialText_title_(prompt,["OK","Cancel"],str(istart),title)
        if r[0] == "Cancel" :
            return None
        try :
            intval = int(r[1])
            if imin != None :
                if intval < imin :
                    raise ValueError()
            if imax != None :
                if intval > imax :
                    raise ValueError()
            return intval
        except :
    	    msg = "You must enter an integer"
    	    if imax != None or imin != None :
    	        if imax == None :
    	            msg = msg + " greater than or equal to "+str(imin)
    	        elif imin == None :
    	            msg = msg + " less than or equal to "+str(imax)
    	        else :
    	            msg = msg + " between "+str(imin)+" and "+str(imax)
    	    msg = msg+"."
            gdoc.userOptionTitle_buttons_message_(msg,["OK"],"Try again and enter a valid integer.")

# Let user select from 1 to 3 options (must add Cancel if want that option)
# Clicked option is return
# provide prompt for the user msg for more details (can be None)
def GetOption(prompt,msg,options) :
    gdoc = FrontDocument()
    return gdoc.userOptionTitle_buttons_message_(prompt,options,msg)

# Let user enter some text, return text or None if canceled
def GetString(prompt="Enter a string",initial="",title=None) :
    gdoc = FrontDocument()
    if title == None : title = CurrentScript()
    res = gdoc.userInputPrompt_buttons_initialText_title_(prompt,["OK","Cancel"],initial,title)
    if res[0] == "Cancel" : return None
    return res[1]

# Get one item from any length list - return (item text, item number 1 based) or (None,None) if canceled
def GetOneItem(items,prompt="Select an item",title=None) :
    gdoc = FrontDocument()
    if title == None : title = CurrentScript()
    res = gdoc.userChoiceListItems_prompt_buttons_multiple_title_(items,prompt,["OK","Cancel"],False,title)
    if res[0] == "Cancel" : return (None,None)
    return (res[1][0],res[2][0])

#----------------- Globals

_gedit = None
_gedWords = {"ABT":"about","EST":"about","BEF":"before","AFT":"after","FROM":"from",\
"TO":"to","BET":"between","AND":"and","CAL":"calculated","INT":"interpreted"}
_recsetsort = 0
_scriptName = "GEDitCOM II Python Script"
_numerals = { 1 : "I", 4 : "IV", 5 : "V", 9 : "IX", 10 : "X", 40 : "XL",\
50 : "L", 90 : "XC", 100 : "C", 400 : "CD", 500 : "D", 900 : "CM", 1000 : "M" }
_cardinal = ["zero","one","two","three","four","five","six","seven","eight","nine","ten"]
_tau = 60.
_cutoff = math.exp(-365.*2./_tau)

# handle attempt to run the modulus
if __name__ == "__main__" :
     print "This GEDitCOMII.py module cannot be run as a script."
     print "You should run scripts that use this module instead."
