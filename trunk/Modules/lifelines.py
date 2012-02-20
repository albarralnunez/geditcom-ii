#!/usr/bin/python
#
# lifelines (Python Modulue for GEDitCOM II)
#
# Version History
#
# 1.0: Initial version 1 FEB 2011
# 1.01: 18 FEB 2011
#    Fixed some Leopard problems

import GEDitCOMII
import shlex, subprocess

###################### Classes

# custom class to support person set
# table stores collection of IndiForSet (indi, value)
# table has record ID- value as keys to added (indi,value) pairs
class SET :
    def __init__(self,other=None) :
        if not(other) :
            self.indis = []
            self.table = {}
        else :
            self.indis = list(other.indis)
            self.table = other.table.copy()
    
    # true or false if has an (indi,value) pair
    def hasIndiValue(self,indi,value) :
        key = indi.id()+str(value)
        if key in self.table : return True
        return False
    
    # add indi with value (if not already in the set)
    def addtoset(self,indi,value) :
        key = indi.id()+str(value)
        if key not in self.table :
            ifs = IndiForSET(indi,value)
            self.table[key] = ifs
            self.indis.append(ifs)
    
    # add indi for set if indi and value not already in set
    def addindiforset(self,oneifs) :
        key = oneifs.key+str(oneifs.value)
        if key not in self.table :
            self.table[key] = oneifs
            self.indis.append(oneifs)
    
    # delete first or all for one indi
    def deleteindi(self,indi,doall) :
        key = indi.id()
        i = 0
        while i < len(self.indis) :
            ifs = self.indis[i]
            if ifs.key == key :
                delkey = key+str(ifs.value)
                del self.table[delkey]
                self.indis.pop(i)
                if not(doall) : break;
            else :
                i += 1
    
    def length(self) :
        return len(self.indis)

    def namesort(self) :
        global _setsort
        _setsort = 0
        self.indis.sort()
    
    def keysort(self) :
        global _setsort
        _setsort = 1
        self.indis.sort()
    
    def valuesort(self) :
        global _setsort
        _setsort = 2
        self.indis.sort()
    
    # all all those in other set not already in this set
    def union(self,other) :
        for ifs in other.indis :
            self.addindiforset(ifs)
    
    # delete those in this set not in other set
    def intersect(self,other) :
        i = 0
        while i < len(self.indis) :
            ifs = self.indis[i]
            if not(other.hasIndiValue(ifs.indi,ifs.value)) :
                delkey = ifs.key+str(ifs.value)
                del self.table[delkey]
                self.indis.pop(i)
            else :
                i += 1

    # delete those in this set that are in other set
    def difference(self,other) :
        i = 0
        while i < len(self.indis) :
            ifs = self.indis[i]
            if other.hasIndiValue(ifs.indi,ifs.value) :
                delkey = ifs.key+str(ifs.value)
                del self.table[delkey]
                self.indis.pop(i)
            else :
                i += 1
     
    # unique individuals
    def uniqueset(self) :
        self.keysort()
        lastkey = ""
        i = 0
        while i < len(self.indis) :
            ifs = self.indis[i]
            if ifs.key == lastkey :
                delkey = ifs.key+str(ifs.value)
                del self.table[delkey]
                self.indis.pop(i)
            else :
                lastkey = ifs.key
                i += 1
        
# class to hold individual for a SET
class IndiForSET :
    def __init__(self,person,val=None) :
        self.indi = person
        self.lastfirst = person.name()
        if not(val) :
            self.value = 0
        else :
            self.value = val
        self.key = person.id()
    
    def getAncestors(self,gedit,gdoc) :
        outline = 0x74724F55
        self.indi.showAncestorsGenerations_treeStyle_(1000, outline)
        alist = gdoc.listedRecords()
        gedit.windows()[0].closeSaving_savingIn_(0,None)
        return alist
    
    def getDescendants(self,gedit,gdoc) :
        outline = 0x74724F55
        self.indi.showDescendantsGenerations_treeStyle_(1000, outline)
        alist = gdoc.listedRecords()
        gedit.windows()[0].closeSaving_savingIn_(0,None)
        return alist
    
    def getParents(self) :
        return self.indi.parents()
        
    def getSpouses(self) :
        return self.indi.spouses()
        
    def getChildren(self) :
        return self.indi.children()
    
    def getSiblings(self) :
        sibs = []
        fams = self.indi.parentFamilies()
        for fam in fams :
            chils = fam.children()
            for chil in chils :
                if chil.id() != self.key :
                    sibs.append(chil)
        return sibs
        
    def __cmp__(self,other) :
        global _setsort
        if _setsort == 0 :
            if self.lastfirst > other.lastfirst :
                return 1
            elif self.lastfirst < other.lastfirst :
                return -1
        elif _setsort == 1 :
            if self.key > other.key :
                return 1
            elif self.key < other.key :
                return -1
        else :
            if self.value > other.value :
                return 1
            elif self.value < other.value :
                return -1
        return 0

# custom class to support LifeLines event methods
class EVENT :
    def __init__(self,e,useDate=None,usePlace=None) :
        self.structure = e
        if not(useDate) :
            self.date = e.eventDateUser()
            self.place = e.eventPlace()
        else :
            self.date = useDate
            self.place = usePlace
    
    def long(self) :
        if self.date :
            if self.place :
                return self.date+", "+self.place
            else :
                return self.date
        return self.place
    
    def short(self) :
        return self.long()
    
    # for qualified date, return first date unqualified
    def stddate(self) :
        global _dateFormat
        doc = _doc()
        parts = doc.datePartsFullDate_(self.date)
        if len(parts) > 1 :
            return doc.dateStyleFullDate_withFormat_(parts[1],_dateFormat)
        else :
           return ""

# class to support iterations
class Iterate :
    def __init__(self,alist,info) :
        self.iter = -1
        self.ilist = alist
        self.info = info
        self.counter = 0
    
    def next_spouse(self) :
        self.iter += 1
        if self.iter >= len(self.ilist) :
            return (None,None,self.counter+1)
        fam = self.ilist[self.iter]
        h = fam.husband().get()
        if h :
            if h.id() != self.info :
                self.counter += 1
                return (h,fam,self.counter)
        w = fam.wife().get()
        if w :
            if w.id() != self.info :
                self.counter += 1
                return (w,fam,self.counter)
        return self.next_spouse()
    
    def next_family(self) :
        self.iter += 1
        if self.iter >= len(self.ilist) :
            return [None,None,self.iter+1]
        fam = self.ilist[self.iter]
        h = fam.husband().get()
        if h :
            if h.id() != self.info :
                return [fam,h,self.iter+1]
        w = fam.wife().get()
        if w :
            if w.id() != self.info :
                return [fam,w,self.iter+1]
        return [fam,None,self.iter+1]
    
    def next(self) :
        self.iter += 1
        if self.iter >= len(self.ilist) :
            return [None,self.iter+1]
        return [self.ilist[self.iter],self.iter+1]

    def next_node(self) :
        self.iter += 1
        if self.iter >= len(self.ilist) :
            return None
        return self.ilist[self.iter]
        
##################### Function Translations

# ------------ Arithimetic and Logic Functions

# include rest with
# from operator import add,sub,mul,div,mod,neg,eq,ne,lt,gt,le,ge

# exponentiation
def exp(x, y) :
    return x ** y

def andll(x,y) :
    return x+y
    
# not supported
def incr(x) :
    raise Exception("incr(x) is not supported is this Lifelines emulator.\n   Use x += 1 instead.")

# not supported
def decr(x) :
    raise Exception("decr(x) is not supported is this Lifelines emulator.\n   Use x -= 1 instead.")

# ------------ Person Functions

# individual full name
def name(person,makeupper=True) :
    if not(person) : return ""
    if makeupper :
        parts = _doc().namePartsGedcomName_(person.evaluateExpression_("NAME"))
        return parts[0]+parts[1].upper()+parts[2]
    else :
        return person.alternateName()

# individual name with options
def fullname(person,makeupper,normal,trunc) :
    if not(person) : return ""
    parts = _doc().namePartsGedcomName_(person.evaluateExpression_("NAME"))
    if makeupper : parts[1] = parts[1].upper()
    if normal :
        fn = ''.join(parts)
    else :
        fn = parts[1]+", "+parts[0]+parts[2]
    if trunc < len(fn) : return fn[0:trunc]
    return fn
    
# the persons surname
def surname(person) :
    if not(person) : return ""
    return person.surname()
    
# name before surname
def givens(person) :
    parts = _doc().namePartsGedcomName_(person.evaluateExpression_("NAME"))
    return parts[0].strip()

# name trimeed to trunc characters if needed
def trimname(person,trunc) :
    nm = name(person)
    if len(nm)>trunc : return nm[0:trunc]
    return nm
    
# find first birth event and return EventData class with that event
def birth(person) :
    if not(person) : return None
    try :
        e = person.structures().objectWithName_("BIRT").get()
        if not(e) : return None
    except :
        return None
    return EVENT(e)

# find first birth event and return EventData class with that event
def death(person) :
    if not(person) : return None
    try :
        e = person.structures().objectWithName_("DEAT").get()
        if not(e) : return None
    except:
        return None
    return EVENT(e)

# find first baptism ot christening
def baptism(person) :
    if not(person) : return None
    try :
        e = person.structures().objectWithName_("BAPM").get()
    except :
        e = None
    if not(e) :
        try :
            e = person.structures().objectWithName_("CHR").get()
            if not(e) : return None
        except :
            return None
    return EVENT(e)

# find first birth event and return EventData class with that event
def burial(person) :
    if not(person) : return None
    try :
        e = person.structures().objectWithName_("BURI").get()
        if not(e) : return None
    except :
        return None
    return EVENT(e)

# individual's father
def father(person) :
    if not(person) : return None
    f = person.father().get()
    if f : return f
    return None

# individual's mother
def mother(person) :
    if not(person) : return None
    m = person.mother().get()
    if m : return m
    return None

# not supported
def nextsib(x) :
    raise Exception("nextsib(INDI) is not supported is this Lifelines emulator.")

# not supported
def prevsib(x) :
    raise Exception("prevsib(INDI) is not supported is this Lifelines emulator.")

# sex M, F, or U
def sex(person) :
    sx = person.sex().upper()
    if sx!="M" and sx!="F" : sx = "U"
    return sx
    
# check if person is male
def male(person) :
    return person.sex() == 'M'

# check if person is male
def female(person) :
    return person.sex() == 'F'

# pronoun
def pn(person,style) :
    sx = sex(person)
    if style == 0 :
        if sx == "M" : return "He"
        if sx == "F" : return "She"
        return "He/She"
    elif style == 1 :
        if sx == "M" : return "he"
        if sx == "F" : return "she"
        return "he/she"
    elif style == 2 :
        if sx == "M" : return "His"
        if sx == "F" : return "Her"
        return "His/Her"
    elif style == 3 :
        if sx == "M" : return "his"
        if sx == "F" : return "her"
        return "his/her"
    else :
        if sx == "M" : return "him"
        if sx == "F" : return "her"
        return "him/her"

# number of spouses
def nspouses(person) :
    return len(person.spouses())

# number of families
def nfamilies(person) :
    return len(person.spouseFamilies())

# first parents record
def parents(person) :
    parfam = person.parentFamilies()
    if parfam : return parfam[0]
    return None

# first TITL line
def title(person) :
    return person.evaluateExpression_("TITL")
    
# key is record ID without the @ signs
def key(person,stripIorF=False) :
    if not(person) : return ""
    return person.id()[1:-1]

# soundex code for the person surname
def soundex(person) :
    return person.surnameSoundex()

# not supported
def inode(x) :
    raise Exception("inode(INDI) is not supported is this Lifelines emulator.\y   You can use individual in place of root node.")

# not supported
def root(x) :
    raise Exception("root(INDI) is not supported is this Lifelines emulator.\y   You can use individual in place of root node.")

# fetch individual by key
def indi(key,doc=None) :
    if not(doc) : doc = _doc()
    if len(key) > 0 :
        if key[0] == '@' and key[-1] == '@' :
            return doc.individuals().objectWithID_(key).get()
    return doc.individuals().objectWithID_("@"+key+"@").get()

# first individual in current order
def firstindi(doc=None) :
    if not(doc) : doc = _doc()
    if len(doc.individuals()) > 0 :
        return doc.individuals()[0]
    else :
        return None

# not supported
def nextindi() :
    raise Exception("nextindi() is not supported is this Lifelines emulator.")

# not supported
def previndi() :
    raise Exception("previndi() is not supported is this Lifelines emulator.")

# start a spouse loop
def spouses(person) :
    if _classHack(type(person).__name__,"Individual") :
        iter = Iterate(person.spouseFamilies(), person.id())
        f = iter.next_spouse()
        return (f[0],f[1],f[2],iter)
    return person.next_spouse()

# start a family as spouse loop
def families(person) :
    if _classHack(type(person).__name__,"Individual") :
        iter = Iterate(person.spouseFamilies(), person.id())
        f = iter.next_family()
        return (f[0],f[1],f[2],iter)
    return person.next_family()

# start individual loop
def forindi(gdoc=None) :
    if not(gdoc) : gdoc = _doc()
    return enumerate(gdoc.individuals())

# ------------ Family Functions

# marriage event
def marriage(fam) :
    if not(fam) : return None
    try :
        e = fam.structures().objectWithName_("MARR").get()
        if not(e) : return None
    except :
        return None
    return EVENT(e)

# husband
def husband(fam) :
    h = fam.husband().get()
    if h : return h
    return None

# husband
def wife(fam) :
    w = fam.wife().get()
    if w : return w
    return None

# number of children
def nchildren(fam) :
    return len(fam.children())

# first child
def firstchild(fam) :
    chil = fam.children()
    if len(chil) > 0 : return chil[0]
    return None

# not supported
def fnode(x) :
    raise Exception("fnode(INDI) is not supported is this Lifelines emulator.\y   You can use family in place of root node.")

# last child
def lastchild(fam) :
    chil = fam.children()
    if len(chil) > 0 : return chil[-1]
    return None

# fetch individual by key
def fam(key,doc=None) :
    if not(doc) : doc = _doc()
    if len(key) > 0 :
        if key[0] == '@' and key[-1] == '@' :
            return doc.families().objectWithID_(key).get()
    return doc.families().objectWithID_("@"+key+"@").get()

# first family in current order
def firstfam(doc=None) :
    if not(doc) : doc = _doc()
    if len(doc.families()) > 0 :
        return doc.families()[0]
    else :
        return None

# not supported
def nextfam() :
    raise Exception("nextfam() is not supported is this Lifelines emulator.")

# not supported
def prevfam() :
    raise Exception("prevfam() is not supported is this Lifelines emulator.")

# start children iteration
def children(fam) :
    return enumerate(fam.children())

# start family loop
def forfam(gdoc=None) :
    if not(gdoc) : gdoc = _doc()
    return enumerate(gdoc.families())

# ------------ List Functions

# is it empty
def empty(alist) :
    if not(alist) : return True
    if len(alist) == 0 : return True
    return False

# length
def length(alist) :
    return len(alist)

# append value to a list
def enqueue(list,value) :
    list.append(value)

# pop off first item in the list
def dequeue(list) :
    if len(list) :
        return list.pop(0)
    return None

# append value to a list
def requeue(list,value) :
    list.insert(-1,value)

# push to stack (at the end)
def push(list,value) :
    list.append(value)
    
# return last item of a list and remove it
def pop(alist) :
    if len(alist) > 0 :
        return alist.pop(-1)
    return None

# get element of a list (1 based)
def getel(list,index) :
    if index > len(list) : return 0
    return list[index-1]

# set element of a list (1 based)
def setel(list,index,value) :
    while index > len(list) :
        list.append(None)
    list[index-1] = value

# start children iteration
def forlist(alist) :
    return enumerate(alist)

# ------------ Table Functions

# create a table
def table() :
    return {}

# insert value by its key
def insert(dict,key,value) :
    dict[key] = value

# look for value by key or return None
def lookup(dict,key) :
    if key in dict :
        return dict[key]
    return None

# ------------ Node Functions

# not implemented
def xref(x) :
    raise Exception("xref(NODE) is not supported is this Lifelines emulator.")
    
# return tag of GEDCOM structure
def tag(node) :
    if _classHack(type(node).__name__,"Structure") :
        return node.name()
    return node.recordType()

# return tag of GEDCOM structure
def value(node) :
    if _classHack(type(node).__name__,"Structure") :
        return node.contents()
    return node.id()

# parent (need get() in case it is a record)
def parent(node) :
    if _classHack(type(node).__name__,"Structure") :
        return node.parentStructure().get()
    return None

# first child structure (or None)
def child(node) :
    nodes = node.structures()
    if len(nodes) > 0 :
        return nodes[0]
    return None

# next structure at same level
def sibling(node) :
    if _classHack(type(node).__name__,"Structure") :
        return node.nextStructure().get()
    return None
   	
# not implemented
def savenode(x) :
    raise Exception("savenode(NODE) is not supported is this Lifelines emulator.")

# start children iteration
def fornodes(node) :
    return enumerate(node.structures())

# load all structures (nodes) into a list
def traverse(node) :
    if node.__class__.__name__ == "Iterate" :
        nd = node.next_node()
        if not(nd) : return (None,None)
        return (nd, nd.level())
    nodes = []
    _addstructures(nodes,node.structures())
    iter = Iterate(nodes, None)
    nd = iter.next_node()
    if not(nd) : return (None,None,iter)
    return (nd, nd.level(),iter)

# ------------ Event and Date Functions

# the date
def date(evnt) :
    if not(evnt) : return ""
    return evnt.date

# the place
def place(evnt) :
    if not(evnt) : return ""
    return evnt.place

# the year as string
def year(evnt) :
    if not(evnt) : return ""
    if evnt.date == "" :
        return ""
    else :
        dmy = _doc().dateNumbersFullDate_(evnt.date)
        if len(dmy) < 3 : return ""
        return str(dmy[2])

# long date
def long(evnt) :
    if not(evnt) : return ""
    return evnt.long()

# long date
def short(evnt) :
    if not(evnt) : return ""
    return evnt.short()

# create event for today
def gettoday() :
    return EVENT(None,_doc().dateToday(),"")

# change day format
def dayformat(df) :
    global _dayFormat,_dateCode
    if df == 1 :
        _dayFormat = "%D"
    else :
        _dayFormat = "%d"
    dateformat(_dateCode)

# change month format
def monthformat(df) :
    global _monthFormat,_dateCode
    if df == 1 :
        _monthFormat = "%N"
    elif df == 3 or df == 5 :
        _monthFormat = "%M"
    elif df == 4 or df == 6 :
        _monthFormat = "%m"
    else :
        _monthFormat = "%n"
    dateformat(_dateCode)

# change date format
def dateformat(df) :
    global _dateFormat,_dateCode
    if df == 0 :
        _dateFormat = _dayFormat+" "+_monthFormat+" %y %b"
    elif df == 1 :
        _dateFormat = _monthFormat+" "+_dayFormat+", %y %b"
    elif df == 2 :
        _dateFormat = _monthFormat+"/"+_dayFormat+"/%y %b"
    elif df == 3 :
        _dateFormat = _dayFormat+"/"+_monthFormat+"/%y %b"
    elif df == 4 :
        _dateFormat = _monthFormat+"-"+_dayFormat+"-%y %b"
    elif df == 5 :
        _dateFormat = _dayFormat+"-"+_monthFormat+"-%y %b"
    elif df == 6 :
        _dateFormat = _monthFormat+_dayFormat+"%y %b"
    elif df == 7 :
        _dateFormat = _dayFormat+_monthFormat+"%y %b"
    elif df == 8 :
        _dateFormat = "%y "+_monthFormat+" "+_dayFormat+" %b"
    elif df == 9 :
        _dateFormat = "%y/"+_monthFormat+"/"+_dayFormat+" %b"
    elif df == 10 :
        _dateFormat = "%y-"+_monthFormat+"-"+_dayFormat+" %b"
    else :
        _dateFormat = "%y"+_monthFormat+_dayFormat+" %b"
    _dateCode = df

# output date in current cormat
def stddate(evnt) :
    if not(evnt) : return ""
    return evnt.stddate()  
    
# ------------ Value Extraction Functions

# extract places. If node is not PLAC, look for child place
def extractdate(node) :
    if node.__class__.__name__ == "EVENT" :
        thedate = node.date
    elif node.name() == "DATE" :
        thedate = node.contents()
    else :
        nodes = node.structures()
        try :
            node = nodes.objectWithName_("DATE").get()
            if not(node) : return (0,0,0)
        except:
            return (0,0,0)
        thedate = node.contents()
    if len(thedate) == 0 : return (0,0,0)
    dmy = _doc().dateNumbersFullDate_(thedate)
    if len(dmy) < 3 : return (0,0,0)
    return (dmy[0],dmy[1],dmy[2])

# extract names
def extractnames(node) :
    if _classHack(type(node).__name__,"Individual") :
        try :
            node = node.structures().objectWithName_("NAME").get()
            if not(node) : return [[],0,0]
        except :
            return [[],0,0]
    else :
        if node.name() != "NAME" : return [[],0,0]
    nameparts = _doc().namePartsGedcomName_(node.contents())
    parts = nameparts[0].strip().split(" ")
    surname = nameparts[1].strip()
    if surname != "" :
        parts.append(surname)
        surloc = len(parts)
    else :
        surloc = 0
    postname = nameparts[2].strip()
    if postname != "" :
        parts.extend(postname.split(" "))
    for i in range(len(parts)) :
        parts[i] = parts[i].strip()
    return (parts,len(parts),surloc)
        
# extract places. If node is not PLAC, look for child place
def extractplaces(node) :
    if node.__class__.__name__ == "EVENT" :
        theplace = node.place
    elif node.name() == "PLAC" :
        theplace = node.contents()
    else :
        nodes = node.structures()
        try :
            node = nodes.objectWithName_("PLAC").get()
            if not(node) : return (None,0)
        except :
            return (None,0)
        theplace = node.contents()
    hier = theplace.split(",")
    for i in range(len(hier)) :
        hier[i] = hier[i].strip()
    return (hier,len(hier))

# extract tokens
def extracttokens(text,delim) :
    tokens = text.split(delim)
    return (tokens,len(tokens))

# ------------ User Interaction Functions

# get individual or quit trying
def getindi(doc=None,prompt="") :
    if not(doc) : doc = _doc()
    indi = GEDitCOMII.GetIndividual(doc)
    if not(indi) :
        doc.userSelectByType_fromList_prompt_("INDI",None,"Select an individual for this script")
        while True :
            indi = doc.pickedRecord().get()
            if indi != "" : break
        if indi == "Cancel" : quit()
    return indi

# some programs use this ?
def getindimsg(prompt="") :
    return getindi(_doc(),prompt)

# get individual
def getfam(doc=None,prompt="") :
    if not(doc) : doc = _doc()
    fam = GEDitCOMII.GetFamily(doc)
    if not(fam) :
        doc.userSelectByType_fromList_prompt_("FAM",None,"Select a family for this script")
        while True :
            fam = doc.pickedRecord().get()
            if fam != "" : break
        if fam == "Cancel" : quit()
    return fam

# get integer (or None if canceled)
def getint(prompt="Enter an integer") :
    return GEDitCOMII.GetInteger(prompt,None,0,None,None)

# get string (or None if canceled)
def getstr(inittext="",prompt="Enter a string") :
    return GEDitCOMII.GetString(prompt,inittext,_title)

# some programs use this ?
def getstrmsg(inittext="",prompt="Enter a string") :
    return getstr(inittext,prompt)

# not implemented
def choosechild(x,doc=None) :
    if not(doc) : doc = _doc()
    ilist = x.children()
    doc.userSelectByType_fromList_prompt_(None, ilist,"Select a child")
    while True :
        indi = doc.pickedRecord().get()
        if indi != "" : break
    if indi == "Cancel" : indi = None
    return indi

# not implemented
def choosefam(indi,doc=None) :
    if not(doc) : doc = _doc()
    ilist = indi.spouseFamilies()
    if len(ilist) == 0 : return None
    doc.userSelectByType_fromList_prompt_(None, ilist,"Select a family for "+name(indi))
    while True :
        fam = doc.pickedRecord().get()
        if fam != "" : break
    if fam == "Cancel" : fam = None
    return fam

# not implemented
def chooseindi(aset,doc=None) :
    if not(doc) : doc = _doc()
    ilist = []
    (i,v,n,iter) = forindiset(aset)
    while i :
        ilist.append(i)
        (i,v,n) = forindiset(iter)
    if len(ilist) == 0 : return None
    doc.userSelectByType_fromList_prompt_(None, ilist,"Select an individual from this set")
    while True :
        indi = doc.pickedRecord().get()
        if indi != "" : break
    if indi == "Cancel" : indi = None
    return indi

# not implemented
def choosespouse(indi,doc=None) :
    if not(doc) : doc = _doc()
    splist = indi.spouses()
    if len(splist) == 0 : return None
    doc.userSelectByType_fromList_prompt_(None,splist,"Select a spouse of "+name(indi))
    while True :
        indi = doc.pickedRecord().get()
        if indi != "" : break
    if indi == "Cancel" : indi = None
    return indi
 
# not implemented
def choosesubset(x) :
    raise Exception("choosesubset(SET) is not supported is this Lifelines emulator.")

# get item from a list (or 0 if canceled)
def menuchoose(items,prompt="Pick an item") :
    res = GEDitCOMII.GetOneItem(items,prompt,_title)
    if res[0] == None : return 0
    return res[1]

# error message and quit
def fatalerror(msg,details="") :
    GEDitCOMII.Alert(msg,details)
    quit()
    
# ------------ String Functions

# convert to lower case
def lower(text) :
    return text.lower()

# convert to upper case
def upper(text) :
    return text.upper()

# capitalize
def capitalize(text) :
    return text.capitalize()

# trim to length
def trim(text, value) :
    if len(text)>value :
        return text[0:value-1]
    return text

# right justyfy
def rjustify(text, width) :
    text.rjust(width)[0:width]

# copy of the string
def save(text) :
    return str(text)

# copy of the string
def strsave(text) :
    return str(text)

# concatonate
def concat(*s) :
    return ''.join(s)

# concatonate
def strconcat(*s) :
    return ''.join(s)

# length
def strlen(text) :
    return len(text)

# substring (i1 and i2 are 1 based)
def substring(text, i1, i2) :
    return text[i1-1:i2]

# nth occurance of subs in text
def index(text, subs, n) :
    start = 0
    end = -1
    if n==0 : return 0
    while n>0 :
       offset = text.find(subs,start,end)
       if offset < 0 : return 0
       start = offset+1
    return start
        
# number to stringdef d(num) :
    return str(num)

# cardinal number 
def card(n) :
    return GEDitCOMII.Cardinal(n)

# ordinal number
def ord(value) :
    try:
        value = int(value)
    except ValueError:
        return value

    if value % 100//10 != 1:
        if value % 10 == 1:
            ordval = u"%d%s" % (value, "st")
        elif value % 10 == 2:
            ordval = u"%d%s" % (value, "nd")
        elif value % 10 == 3:
            ordval = u"%d%s" % (value, "rd")
        else:
            ordval = u"%d%s" % (value, "th")
    else:
        ordval = u"%d%s" % (value, "th")
    return ordval

# number to letter (a,b,c...)
def alpha(x) :
    if x<1 or x > 26 : return str(x)
    return str(chr(96+x))

# roman numerical
def roman(x) :
    return GEDitCOMII.RomanNumeral(x).lower()

# get soundexdef strsoundex(text) :
    return _doc().soundexForText_(text)

# string to intdef strtoint(text) :
    try :
        ret = int(text)
        return ret
    except:
        return text

# string to int
def atoi(text) :
    return strtoint(text)

# comparedef strcmp(s1, s2) :
    if s1 < s2 : return -1
    elif s1 == s2 : return 0
    return 1

# are they equal
def eqstr(s1, s2) :
    return s1 == s2

# are they not equal
def nestr(s1, s2) :
    return s1 != s2


# ------------ Output Mode Functions

# set linemode (it is default)
def linemode() :
    global _ll_mode
    _ll_mode = "linemode"

# set page mode
def pagemode(nr,nc) :
    global _numCols,_numRows,_ll_mode
    _numCols = nc
    _numRows = nr
    _ll_mode = "pagemode"
    _clearBuffer()

# set page mode column
def col(col1) :
    global _posCol,_posRow
    if col1<1 or col1 > _numCols :
        raise Exception("Selected column #"+str(col1)+" is out of range for current page")
    col1 -= 1
    if _posCol > col1 : _incrementRow()
    _posCol = col1
    
# set position (convert to zero based)
def pos(row1,col1) :
    global _posRow,_posCol
    if row1<1 or row1 > _numRows :
        raise Exception("Selected row #"+str(row1)+" is out of range for current page")
    if col1<1 or col1 > _numCols :
        raise Exception("Selected column #"+str(col1)+" is out of range for current page")
    _posRow = row1-1
    _posCol = col1-1

# set to row
def row(row1) :
    global _posRow,_posCol
    if row1<1 or row1 > _numRows :
        raise Exception("Selected row #"+str(row1)+" is out of range for current page")
    _posRow = row1-1
    _posCol = 0

# output buffer
def pageout() :
    _lines.out("\n".join(_pbuffer))
    _clearBuffer()
    
# new line
def nl() :
    global _ll_mode
    if _ll_mode == "pagemode" :
        _incrementRow()
    else :
        _lines.out("\n")

# space
def sp() :
    return " "

# quot
def qt() :
    return "\""
    
# not implements
def newfile(x,y) :
    raise Exception("newfile(STRING,BOOL) is not implemented.\nUse python file methods instead.")

# get save file
def outfile() :
    global _savefile
    if not(_lines) :
        _savefile = "Yes"
    else :
        return _lines.saveFile
    
# not implements
def copyfile(x) :
    raise Exception("copyfile(STRING) is not implemented.\nUse python file methods instead.")

# ------------ Person Set Functions and GEDCOM Extraction

# create a SET - a class to mimic LifeLines SET
def indiset() :
    return SET()

# add to set
def addtoset(aset,indi,value) :
    aset.addtoset(indi,value)

# delete individual (these sets only allow one per individual)
def deletefromset(aset,indi,doall) :
    aset.deleteindi(indi)

# length of set
def lengthset(aset) :
    return aset.length()

# return new set that is union of two other sets
def union(set1,set2) :
    if set1.length() > set2.length() :
        uset = SET(set1)
        uset.union(set2)
    else :
        uset = SET(set2)
        uset.union(set1)
    return uset

# return new set intersection of two other sets
def intersect(set1,set2) :
    if set1.length() > set2.length() :
        uset = SET(set2)
        uset.intersect(set1)
    else :
        uset = SET(set1)
        uset.intersect(set2)
    return uset
    
# return new set with items in set1 but not in set2
def difference(set1,set2) :
    uset = SET(set1)
    uset.difference(set2)
    return uset
    
# return new set of unique parents of all individuals in set
def parentset(set) :
    pset = SET()
    for indi in set.indis :
        addValue = indi.value
        pars = indi.getParents()        for par in pars :
            pset.addtoset(par,addValue)
    return pset

# return new set of unique parents of all individuals in set
def spouseset(set) :
    sset = SET()
    for indi in set.indis :
        addValue = indi.value
        spses = indi.getSpouses()        for spse in spses :
            sset.addtoset(spse,addValue)
    return sset

# return new set of siblngs of all individual in set
def siblingset(set) :
    sset = SET()
    for indi in set.indis :
        addValue = indi.value
        sibs = indi.getSiblings()        for sib in sibs :
            sset.addtoset(sib,addValue)
    return sset

# return new set of uniwue children of all individuals in set
def childset(set) :
    cset = SET()
    addValue = None
    for indi in set.indis :
        addValue = indi.value
        children = indi.getChildren()        for chil in children :
            cset.addtoset(chil,addValue)
    return cset

# return new set of all ancestors of all individuals in set
def ancestorset(set,doc=None) :
    if not(doc) : doc=_doc()
    aset = SET()
    for indi in set.indis :
        alist = indi.getAncestors(_gedit,doc)        for ancest in alist[1:] :
            # [gen,indi] or [gen,indi,ref#] or [gen,xref#]
            if not(isinstance(ancest[1], int)) :
                aset.addtoset(ancest[1],ancest[0])
    return aset

# return new set of all descendants of all individual in set
def descendentset(set,doc=None) :
    return descendantset(set,doc)
    
def descendantset(set,doc=None) :
    if not(doc) : doc=_doc()
    aset = SET()
    for indi in set.indis :
        alist = indi.getDescendants(_gedit,doc)        for descend in alist[1:] :
            if len(descend) > 2 :
                # [gen,indi,ref#] or [gen,spouse,family]
                if isinstance(descend[2], int) :
                    aset.addtoset(descend[1],descend[0])
            elif not(isinstance(descend[1], int)) :
                # [gen,indi] or [gen,xref#]
                aset.addtoset(descend[1],descend[0])
    return aset
    
# unique set
def uniqueset(aset) :
    aset.uniqueset()
    
# sort by name
def namesort(aset) :
    aset.namesort()

# sort by key
def keysort(aset) :
    aset.keysort()

# sort by name
def valuesort(aset) :
    aset.valuesort()

# load all structures (nodes) into a list
def forindiset(aset) :
    if aset.__class__.__name__ == "Iterate" :
        f = aset.next()
        if f[0] :
    	    return (f[0].indi,f[0].value,f[1])
        else :
            return (None,None,f[1])
    iter = Iterate(aset.indis,None)
    f = iter.next()
    if f[0] :
    	return (f[0].indi,f[0].value,f[1],iter)
    else :
        return (None,None,f[1],iter)

# ------------ Record Update Functions

# not implemented
def createnode(x,y) :
    raise Exception("createnode(STRING, STRING) is not supported is this Lifelines emulator.")

# not implemented
def addnode(x,y,z) :
    raise Exception("addnode(NODE, NODE, NODE) is not supported is this Lifelines emulator.")

# not implemented
def deletenode(x) :
    raise Exception("deletenode(NODE) is not supported is this Lifelines emulator.")

# ------------ Record Linking Functions

def reference(gid) :
    if len(gid) < 2 or len(gid) > 22 : return false
    return gid[0]=='@' and gid[-1]=='@'

def dereference(gid) :
    return _doc().gedcomRecords().objectWithID_(gid).get()
        
def getrecord(gid) :
    return _doc().gedcomRecords().objectWithID_(gid).get()
    
# ------------ Miscellaneous Functions

# not implemented
def lock(x) :
    raise Exception("lock(INDI|FAM) is not supported is this Lifelines emulator.")

# not implemented
def unlock(x) :
    raise Exception("unlock(INDI|FAM) is not supported is this Lifelines emulator.")

# name
def database() :
    return _doc().name()

# version number
def version() :
    vnum = int(10*_gedit.versionNumber())
    if vnum >= 16 :
        bnum = _gedit.buildNumber()
        if vnum == 1 : vnum = 0
        bstr = "."+str(bnum)
    else :
        bstr = ""
    return str(vnum/10.)+bstr

def system(command_line) :
    args = shlex.split(command_line)
    p = subprocess.Popen(args, stdout=subprocess.PIPE)
    output = p.communicate()[0]
    return output

# ------------ GEDitCOM II Functions

# script should call this in the beginning
def ll_init(title) :
    global _gedit,_lines,_title,_savefile
    _gedit = GEDitCOMII.CheckVersionAndDocument(title,1.7,1)
    if not(_gedit) : quit()
    if _savefile :
        _savefile = _doc().userSaveFileExtensions_prompt_start_title_(["txt"],None,None,"Save File Selection")
        if not(_savefile) : quit()
    _lines = GEDitCOMII.ScriptOutput(title,_outputMode,_savefile)
    _title = title
    return _doc()


# output any text
def out(text) :
    global _posCol,_numRows,_numCols,_pbuffer,_ll_mode,_posRow
    if _ll_mode == "pagemode" :
        maxLength = _numCols - _posCol
        if len(text) > maxLength :
           text = text.ljust(maxLength)
        if len(_pbuffer[_posRow]) == _posCol :
            _pbuffer[_posRow] = _pbuffer[_posRow] + text
        elif len(_pbuffer[_posRow]) < _posCol :
            _pbuffer[_posRow] = _pbuffer[_posRow].ljust(_posCol) + text
        else :
            pre = _pbuffer[_posRow][:_posCol]
            if len(_pbuffer[_posRow]) <= _posCol+len(text) :
                _pbuffer[_posRow] = pre + text
            else :
                post = _pbuffer[_posRow][_posCol+len(text):]
                _pbuffer[_posRow] = pre + text + post
        _posCol += len(text)
        if _posCol >= _numCols : _incrementRow()
    else :
        _lines.out(text)
    
# output as columns
def cols(*args) :
    _lines.cols(args)

# finish report
def finish(doc=None) :
    if not(doc) : doc = _doc()
    _lines.write(doc)

# progress message
def message(msg,fract=-1.) :
	_doc().notifyProgressFraction_message_(fract,msg)

# count individual or families
def count(type,doc=None) :
    if not(doc) : doc = _doc()
    if type == "INDI" : return len(doc.individuals())
    if type == "FAM" : return len(doc.families())
    return 0
    
##################### Private Functions and Initialization

_gedit = None
_dayFormat = "%d"
_monthFormat = "%M"
_dateFormat = _dayFormat+" "+_monthFormat+" %y %b"
_dateCode = 0
_lines = None
_outputMode = "monospace"
_ll_mode = "linemode"
_title = "Lifelines Emulation Program"
_numCols = 0
_numRows = 0
_pbuffer = None
_posRow = 0
_posCol = 0
_setsort = 0
_savefile = None

# get any doc (here the front one) to do functions
def _doc() :
    return _gedit.documents()[0]

# called recursively to add all structures (in order) to the list
def _addstructures(nodelist,items) :
    for node in items:
        nodelist.append(node)
        if len(node.structures()) > 0 :
            _addstructures(nodelist,node.structures())

# clear page mode buffer
def _clearBuffer() :
    global _pbuffer,_numRows,_numCols,_posRow,_posCol
    _posRow = 0
    _posCol = 0
    _pbuffer = []
    for i in range(_numRows) :
        _pbuffer.append("")

# force new row (or page if needed)
def _incrementRow() :
    global _posRow,_numRows,_posCol
    _posRow += 1
    _posCol = 0
    if _posRow >= _numRows : pageout()

# hack workaround to scripting bridge issues
# being in GEDitCOMII and end in parameter
def _classHack(cls,type) :
    if len(cls) < 10 + len(type) : return False
    if cls[-len(type):] != type : return False
    if cls[:10] != "GEDitCOMII" : return False
    return True
    
if __name__ == "__main__" :
     print "This module lifelines.py cannot be run as a script."
     print "Try a Lifelines emulation script that uses this module instead."

