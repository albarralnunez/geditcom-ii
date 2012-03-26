#!/usr/bin/python
#
# Ancestors Generations Report (Python Script for GEDitCOM II)
#
# For details on using this script, see the tutorial at
#
#     http://www.geditcom.com.tutorials/latexbook.html
#
# Remaining Tasks
#
# index portraits
# Descendant - be more efficient if possible
#
# Version History (set in scriptVersion Variable)
# 1: 2 FEB 2011
# 2: 15 FEB 2011 - fixed some Leopard problems
# 3: 19 FEB 2011 - added divorce event
# 4: 20 FEB 2011 - checks for unmmarried couples and labels them partners
# 5: 22 MAR 2011 - New SafeTeX() method to handle more special characters
#                    and handle quotes better. Also randomly selects alternate
#                    phrases for events, residences, and introduction to events
#                    and attributes
# 6: 5 DEC 2011 - Manuy new features to support GEDitCOM II version 1.7 and
#                    its new Book Style records
# 7: 24 FEB 2012 - fixed characters, addresses to more events and attributres,
#                    improved attribute formatting, create BookPreparation
#                    module, fixed some spelling

# Set preferences at top to speed it up
#
# Ancestor report (decendant = none)
# Descendandants only (ancest = none)

# Load GEDitCOM II Module
from GEDitCOMII import *
from BookPreparation import *
import os, shutil, random

# ----------- Preferences Start
# Any predefined variables will be used as entered
# Any set to None will lead to a prompt to enter the setting

# Folder to contain the Generations_LaTeX_Book-# folder
# Warning - a predefined folder must exist and not end in /
fldr = None
overwrite = False

# Book author's name and email
author = None
email = None

# Generations of ancestors and descendants (=1000 for all)
# For none, ancestGen = 0 or descendGen < -ancestGen, do use string
ancestGen = 1000
descendGen = None

# font point size - only 9, 10, 11, 12, or 14 allowed
fontSize = None
fontFamily = None
lineSpread = None

# paper type "US Letter" or "A4"
paperType = None

# final book style "Hardcover Noval", "Large Textbook" or "Full Page"
bookSize = None

# try to typeset in the script
commandLineTypeset = False

# user chapters
introduction = None
introTeX = None
aboutAuthor = None
aboutTeX = None

# copyright (all supported from Book Style records
cOwner = None
cGrantees = None

# defs style
styleSheet = "Default"

# notes and portraits ("hideOwner","hideFamily","hideAll","hideNone")
notesOption = None
porOption = None

# ----------- Preferences End

################### Classes

# Subclass of Records Set for this script
class PersonSet(RecordsSet) :
    # special object to add
    def makeObject(self,rec,value=0) :
        return PersonForSet(rec,value)
    
    # link ids to person numbers after sorting
    def GetXrefs(self) :
        self.xref = {}
        for (n,rfs) in enumerate(self.recs) :
            self.xref[rfs.key] = str(n+1)
    
    # return xref number
    def xrefID(self,recid) :
        if not(recid) : return ""
        if recid in self.xref :
            return " ({\\bf "+self.xref[recid]+"})"
        return ""
    
    # get or look up birth sdn max
    def birthSDNMax(self,recid) :
        if recid in self.table :
            rfs = self.table[recid]
            return rfs.birthSDNMax()
        sdnMax = 0
        indi = gdoc.individuals().objectWithID_(recid)
        if indi :
            bd = indi.birthDate()
            if bd :
                [sdnMin,sdmMax] = gdoc.sdnRangeFullDate_(bd)
        return sdnMax
    
    # get spouse (as PersonForSet) of individual (in pfs) in a fam
    def getSpouse(self,fam,pfs) :
        s = None
        h = fam.husband().get()
        if h :
            recid = h.id()
            if recid != pfs.key : s = h
        if not(s) :
            w = fam.wife().get()
            if w:
                recid = w.id()
                if recid != pfs.key : s = w
        if not(s) : return None
        # look in ancestor set
        if recid in self.table : return self.table[recid]
        # look in others set
        if recid in others.table : return others.table[recid]
        # create, add to others, and return
        rfs = PersonForSet(s,pfs.value)
        others.addObjectWithKey(rfs,recid)
        return rfs
    
    # get child object (creating if needed)
    def getChild(self,indi) :
        recid = indi.id()
        # look in ancestor set
        if recid in self.table : return self.table[recid]
        # look in others set
        if recid in others.table : return others.table[recid]
        # create, add to others, and return
        rfs = PersonForSet(indi,0)
        others.addObjectWithKey(rfs,recid)
        return rfs
    
    # get parents if in the book
    def getParentsInBook(self,rfs) :
        if not(rfs) : return [None,None]
        f = rfs.rec.father().get()
        if f :
            recid = f.id()
            if recid in self.table :
                f = self.table[recid]
            else :
                f = None
        m = rfs.rec.mother().get()
        if m :
            recid = m.id()
            if recid in self.table :
                m = self.table[recid]
            else :
                m = None
        return [f,m]

# subclass of RecordForSet to handle individual details
class PersonForSet(RecordForSet) :
    def __init__(self,record,val=None) :
        RecordForSet.__init__(self,record,val)
        self.altname = SafeTex(record.alternateName()).strip()
        self.parts = gdoc.namePartsGedcomName_(record.evaluateExpression_("NAME"))
        self.parts[0] = SafeTex(self.parts[0].strip())
        self.parts[1] = SafeTex(self.parts[1])
        self.parts[2] = SafeTex(self.parts[2])
        self.first = SafeTex(record.firstName())
        self.rents = None
        self.tree = None
        self.span = " ("+record.lifeSpan()+")"
        self.alive = -1     # -1 ?, 0 died, 1 has data that might be alive
        sex = record.sex()
        if sex == "M" :
            self.child = "son"
            self.pronoun = "He"
            self.poss = "His"
        elif sex == "F" :
            self.child = "daughter"
            self.pronoun = "She"
            self.poss = "Her"
        else :
            self.child = "son or daughter"
            self.pronoun = "He or she"
            self.poss = "His or her"
        try :
            e = record.structures().objectWithName_("BIRT").get()
            if e :
                self.birth = BookEvent(e,"was born")
            else :
                self.birth = None
        except :
            self.birth = None
        try :
            e = record.structures().objectWithName_("DEAT").get()
            if e :
                self.death = BookEvent(e,"died",True)
                self.alive = 0
            else :
                self.death = None
        except :
            self.death = None
        if self.death == None :
            if self.birth :
                [mn,mx] = self.birth.SDNRange()
                if mx > 0 :
                    if sdnToday - mx < maxAge :
                        self.alive = 1
                    else :
                        self.alive = 0
        try :
            e = record.structures().objectWithName_("BURI").get()
            if e :
                self.burial = BookEvent(e,None,False,None,[.33,.67],False)
                self.alive = 0
            else :
                self.burial = None
        except :
            self.burial = None
    
    # return parent names in a string
    def parents(self) :
    	if self.rents != None : return self.rents
        f = self.rec.father().get()
        m = self.rec.mother().get()
        if f :
            self.rents = SafeTex(f.alternateName())+ancestors.xrefID(f.id())
            if m : self.rents += " and "+SafeTex(m.alternateName())+ancestors.xrefID(m.id())
        elif m :
            self.rents = SafeTex(m.alternateName())+ancestors.xrefID(m.id())
        else :
            self.rents = "unknown parents"
        # while here check for information on alive or dead
        if self.alive < 0 :
            if f :
                sdnMax = ancestors.birthSDNMax(f.id())
                if sdnMax > 0 :
                    if sdnToday - sdnMax < maxParentAge :
                        self.alive = 1
                    else :
                        self.alive = 0
            if m and self.alive < 0 :
                sdnMax = ancestors.birthSDNMax(m.id())
                if sdnMax > 0 :
                    if sdnToday - sdnMax < maxParentAge :
                        self.alive = 1
                    else :
                        self.alive = 0
        return self.rents
    
    # return birth date and place phrase
    def born(self) :
        if not(self.birth) : return None
        return self.birth.phrase
    
    # return birth date and place phrase
    def died(self) :
        if not(self.death) : return None
        return self.death.phrase
    
    # burial phrase
    def buried(self) :
        if not(self.burial) : return None
        return self.burial.FormatBurial()
    
    # style = -1 for pronoun, 0 for first name, 1 for full name
    # style = -2 for " and"
    def nameStyle(self,style) :
        if style == 1 : return self.altname
        if style == 0 : return self.first
        if style == -1 : return self.pronoun
        return " and"

    # getNPB - name, child of parents, and birth date and place
    # finish with terminator (must be string, "" for no terminator)
    def getNPB(self,term="",style=1) :
        fpb = [self.nameStyle(style)]
        # child of parents and birth date
        if self.born() :
            if self.parents()=="unknown parents" :
                fpb.append(" "+self.born())
            else :
                fpb.append(", the "+self.child+" of "+self.parents()+", "+self.born())
        else :
            fpb.append(" "+self.iswas()+" the "+self.child+" of "+self.parents())
        if term : fpb.append(term)
        return ''.join(fpb)
    
    # getFD - name and death info
    # optional get cause in another sentense
    def getFD(self,term="",style=1,cause=False) :
        if not(self.death) : return ""
        dp = self.died()
        if dp : dp = self.nameStyle(style)+" "+dp
        if not(cause) : return dp+term
        
        # add cause of death
        if dp or style < 0 :
            uposs = self.poss
            poss = self.poss.lower()
        else :
            poss = self.nameStyle(style)+"'s"
            uposs = poss
            
        # pick cause
        rand = random.random()
        if rand < 0.33 :
            verb = "The cause of "+poss+" death was"
        elif rand < 0.67 :
            verb = uposs+" death was caused by"
        else :
            verb = self.pronoun+" died from"
        cp = self.death.FormatCause(verb)
        if cp :
            if dp : dp += ". "
            dp += cp
        if dp : dp += term
        return dp
    
    # retrieve bitrh SDN max
    def birthSDNMax(self) :
        if not(self.birth) : return None
        [sdnMin,sdnMax] = self.birth.SDNRange()
        return sdnMax
    
    # if if data alive, otherwise was
    def iswas(self) :
        if self.alive > 0 : return "is"
        return "was"
    
    # get full path to this person's protrait or return None
    def portrait(self) :
        if porOption == "hideAll" : return ""
        nopor = self.rec.evaluateExpression_("_NOPOR")
        if nopor : return None
        mm = self.rec.evaluateExpression_("OBJE")
        if len(mm) == 0 : return None
        mmrec = gdoc.multimedia().objectWithID_(mm)
        if not(mmrec) : return None
        if porOption != "hideNone" :
            # setting is hideOwner or hideFamily
            # Owner - always hide
            # Family - hide if setting is hideFamily
            dist = mmrec.evaluateExpression_("_DIST")
            if dist == "Owner" : return None
            if dist == "Family" and porOption == "hideFamily" :
                return None
        path = mmrec.objectPath()
        if path : return path
        return None
    
    def indexTag(self) :
        if self.parts[0] :
            return "\\index{"+self.parts[1]+self.parts[2]+", "+self.parts[0]+"}"
        else :
            return "\\index{"+self.parts[1]+self.parts[2]+"}"

################### Subroutines

# Output all generic events of one type
# Uses global preface and genname
def GenericEvent(rfs,gtag,verb,freq=[0.33,0.67]) :
    global preface,eName
    evens = rfs.rec.findStructuresTag_output_value_(gtag,"references",None)
    for e in evens :
        if not(verb) :
            even = e.evaluateExpression_("TYPE")
            if not(even) : continue
            even = "had an event described as "+even
            ge = BookEvent(e,SafeTex(even),True,eName,freq)
        else :
            ge = BookEvent(e,verb,True,eName,freq)
        if ge.phrase :
            rpt.out(preface+ge.phrase)
            preface = ""
            rpt.out(GetSources(ge.event)+". ")
            gnotes = GetNotes(ge.event)
            if gnotes :
                rpt.out(gnotes)
                eName = rfs.first
            else :
                eName = rfs.pronoun.lower()

# Output all attributes of one type
# Uses global preface and eName (possessive)
# atype is verb such as "occupation was"
def GenericAttribute(rfs,gtag,atype) :
    global preface,eName
    evens = rfs.rec.findStructuresTag_output_value_(gtag,"references",None)
    for e in evens :
        if gtag == "OCCU" :
            rand = random.random()
            if rand < 0.5 :
                atype = "occupation was as a"
            else:
                atype = "job was as a"
        ge = BookAttribute(e,atype,True,preface+eName)
        if not(ge.attribute) : continue
        rpt.out(ge.phrase)
        preface = ""
        rpt.out(GetSources(ge.event)+". ")
        gnotes = GetNotes(ge.event)
        if gnotes :
            rpt.out(gnotes)
            eName = rfs.first+"'s"
        else :
            eName = rfs.poss

# Output section for one person
def OutputPerson(rfs,inum) :
    global preface,eName
    
    # Name, parents, and birth date
    rpt.out(rfs.getNPB("",1))
    if rfs.birth :
        rpt.out(GetSources(rfs.birth.event)+". ")
        rpt.out(GetNotes(rfs.birth.event))
    else :
        rpt.out(". ")
    # Example of moving "other events" to this section instead of events section below
    # To move, uncomment these lines and comment out corresponding GenericEvent() line
    # in the "other events" section below
    #preface = ""
    #eName = rfs.pronoun
    #GenericEvent(rfs,"BAPM","was baptised")
    
    # marriages
    famses = rfs.rec.spouseFamilies()
    spseNames = []
    for fams in famses :
        umr = fams.evaluateExpression_("_UMR")
        spse = ancestors.getSpouse(fams,rfs)
        if umr == "Y" :
            if spse :
                rpt.out(rfs.pronoun+" partnered with "+ spse.altname+". ")
                spseNames.append(spse)
            else :
                rpt.out(rfs.pronoun+" partnered with an unknown person. ")
                spseNames.append(None)
        else :
            if spse :
                rpt.out(rfs.pronoun+" married "+ spse.altname)
                spseNames.append(spse)
            else :
                rpt.out(rfs.pronoun+" married an unknown spouse")
                spseNames.append(None)
            # marriage event
            try :
                m = fams.structures().objectWithName_("MARR").get()
                if m :
                    marr = BookEvent(m," ")
                    rpt.out(marr.phrase)
                    rpt.out(GetSources(m)+". ")
                    mnotes = GetNotes(m)
                    if mnotes : rpt.out(mnotes)
                    if rfs.alive < 0 :
                        [mn,mx] = marr.SDNRange()
                        if mx > 0 :
                            if sdnToday - mx < maxMarriedDays :
                                rfs.alive = 1
                            else :
                                rfs.alive = 0
                else :
                    rpt.out(". ")
            except :
                rpt.out(". ")
            try :
                d = fams.structures().objectWithName_("DIV").get()
                if d :
                    div = BookEvent(d," They divorced")
                    if div.phrase :
                        rpt.out(div.phrase)
                    else :
                        rpt.out(" They divorced")
                    rpt.out(GetSources(d))
                    rpt.out(". ")
            except :
                d = None
        # spouse details
        if spse :
            rpt.out(spse.indexTag())
            rpt.out(spse.getNPB("",0))
            if spse.birth : rpt.out(GetSources(spse.birth.event))
            rpt.out(spse.getFD("",-2,False))
            if spse.death : rpt.out(GetSources(spse.death.event))
            rpt.out(". ")

    # death
    dd = rfs.getFD("",0,True)
    if dd :
        rpt.out(dd)
        if rfs.death :
            rpt.out(GetSources(rfs.death.event)+". ")
            rpt.out(GetNotes(rfs.death.event))
        else :
            rpt.out(". ")
    
    # burial
    buri = rfs.buried()
    if buri :
        rpt.out(rfs.pronoun+" "+buri+GetSources(rfs.burial.event)+". ")
        rpt.out(GetNotes(rfs.burial.event))
    
    # children
    rpt.out("\n\n")
    for (n,fams) in enumerate(famses) :
        # skip if this person is female and the spouse is also an ancestor
        chils = fams.children()
        if spseNames[n] :
            spseID = ancestors.xrefID(spseNames[n].key)
            spseName = spseNames[n].altname+spseID
        else :
            spseID = ""
            spseName = "an unknown spouse"
        if len(chils) == 0 :
            rpt.out(rfs.altname+" and "+spseName+" had no known children.\n\n")
            continue
        # see if children shown elsewhere
        if rfs.pronoun == "She" and spseID :
            if len(chils) == 1 :
                rpt.out("The one known child of "+rfs.altname+" and "+spseNames[n].altname+\
                " is shown under "+spseName+".\n\n")
            else :
                rpt.out("The children of "+rfs.altname+" and "+spseNames[n].altname+\
                " are shown under "+spseName+".\n\n")
            continue
        # show children here 
        if len(chils) == 1 :
            rpt.out("The one known child of "+rfs.altname+" and "+spseName+" is:\n\n")
        else :
            rpt.out("The children of "+rfs.altname+" and "+spseName+" are:\n\n")
        
        # do each child
        rpt.out("\\begin{children}\n")
        for chil in chils :
            rpt.out("\\item ")
            OutputChild(chil,inum)
        rpt.out("\\end{children}\n\n")
    
    # census data
    censi = rfs.rec.findStructuresTag_output_value_("CENS","references",None)
    if censi :
        rpt.out(rfs.altname+" has been located in "+Cardinal(len(censi))+" census record")
        if len(censi) != 1 : rpt.out("s")
        rpt.out(". ")
        for cens in censi :
            ce = BookEvent(cens,None)
            rpt.out(ce.FormatCensus(rfs.pronoun.lower())+GetSources(cens)+". ")
            rpt.out(GetNotes(cens))
        rpt.out("\n\n")
    
    # other events
    #    he/she verb [at age (age)] (date) in (place)
    #    (date) [at age (age)], he/she verb in (place)
    #    he/she verb in (place) (date) [at age (age)]
    rand = random.random()
    if rand < .25 :
        preface = "Here are some other known events in "+rfs.altname+"'s life. "
    elif rand < .50 :
        preface = "The following events in "+rfs.altname+"'s life have been documented. "
    elif rand < .75 :
        preface = "Several more events in "+rfs.altname+"'s life are known. "
    else :
        preface = rfs.altname+"'s other life events that are known are as follows. "
    eName = rfs.pronoun.lower()
    GenericEvent(rfs,"BAPM","was baptised")
    GenericEvent(rfs,"CHR","was christened")
    GenericEvent(rfs,"ADOP","was adopted")
    GenericEvent(rfs,"BARM","had a Bar Mitzvah")
    GenericEvent(rfs,"BASM","had a Bas Mitzvah")
    GenericEvent(rfs,"ORDN","was ordained")
    GenericEvent(rfs,"NATU","naturalized",[.5,.5])
    GenericEvent(rfs,"EMIG","emigrated",[.5,.5])
    GenericEvent(rfs,"IMMI","immigrated",[.5,.5])
    GenericEvent(rfs,"GRAD","graduated")
    GenericEvent(rfs,"RETI","retired",[.5,.5])
    GenericEvent(rfs,"CREM","was cremated")
    GenericEvent(rfs,"EVEN",None)
    if preface == "" : rpt.out("\n\n")
    
    # attributes
    rand = random.random()
    if rand < .25 :
        preface = "Here are some facts about "+rfs.altname+". "
    elif rand < .50 :
        preface = "Some other facts about "+rfs.altname+" are as follows. "
    elif rand < .75 :
        preface = "The documented attributes of "+rfs.altname+" are as follows. "
    else :
        preface = "Here are some of "+rfs.altname+"'s attributes. "
    eName = rfs.pronoun
    GenericEvent(rfs,"RESI","lived",[0,.5])
    eName = rfs.poss
    iswas = rfs.iswas()
    GenericAttribute(rfs,"OCCU","OCCU")
    GenericAttribute(rfs,"RELI","religion "+iswas)
    GenericAttribute(rfs,"TITL","title "+iswas)
    GenericAttribute(rfs,"DSCR","physical description "+iswas+" described as")
    GenericAttribute(rfs,"EDUC","education "+iswas)
    GenericAttribute(rfs,"NATI","national or tribal origin was "+iswas)
    if rfs.alive == 0 :
        GenericAttribute(rfs,"SSN","social security number was")
    if preface == "" : rpt.out("\n\n")
   
    # notes
    rpt.out(GetNotes(rfs.rec))
    
    # tree
    if rfs.tree :
        if len(rfs.tree) > 1 :
            rpt.out(rfs.tree[1])
            
        treeName = rfs.tree[0]
        if treeName[:1] == "*" :
            sibling = True
            treeName = treeName[1:]
        else :
            sibling = False
        rpt.out("\n\nThe ancestors of "+rfs.altname)
        rpt.out(" are shown in a tree in Fig.~\\ref{"+treeName+"}")
        if sibling == True :
            rpt.out(", which is a tree for a sibling. ")
        else :
            rpt.out(". ")
    
    # sources
    srcs = GetSources(rfs.rec)
    if srcs :
        if not(treeName) : rpt.out("\n\n")
        rpt.out("Some of information about this person came from source "+srcs+". ")
    
    # terminator
    rpt.out("\n\n")

# height of maximum tree size
def TreeHeight() :
    [s1,s2,s3] = [1.5,.85,.5]
    if maxTreeGens >= 4 :
        trow = int(s1*float(fontSize))
    elif maxTreeGens == 3 :
        trow = int(s2*float(fontSize))
    else :
        trow = int(s3*float(fontSize))
    return 31*trow


# generate tree for this individual if needed
#     Index people in the tree
#     Can branches be removed if missing all names
#     14 pt font not working for book or tree sizing
def MakeTree(rfs) :
    global treeNum,treeName,hgap,maxTreeGens,ttxt,hasMore,hasPlus
    
    # if no trees exit
    if maxTreeGens == 0 : return
    
    # if already in tree, no need to continue
    if rfs.tree : return
    
    # father and mother (exit if none or already in tree)
    [f,m] = ancestors.getParentsInBook(rfs)
    if not(f) and not(m) : return
    if f and m :
        if f.tree and m.tree : rfs.tree = ["*"+f.tree[0]]
    elif f :
        if f.tree : rfs.tree = ["*"+f.tree[0]]
    elif m :
        if m.tree : rfs.tree = ["*"+m.tree[0]]
    if rfs.tree : return
    gens = 1
    
    # grandparents
    [pp,pm] = ancestors.getParentsInBook(f)
    [mp,mm] = ancestors.getParentsInBook(m)
    if pp or pm or mp or mm : gens = 2
    
    # great grandparents
    if maxTreeGens > 2 :
        [ppp,ppm] = ancestors.getParentsInBook(pp)
        [pmp,pmm] = ancestors.getParentsInBook(pm)
        [mpp,mpm] = ancestors.getParentsInBook(mp)
        [mmp,mmm] = ancestors.getParentsInBook(mm)
        if ppp or ppm or pmp or pmm or mpp or mpm or mmp or mmm : gens = 3
    
    # great great grandparents
    if maxTreeGens > 3 :
        [pppp,pppm] = ancestors.getParentsInBook(ppp)
        [ppmp,ppmm] = ancestors.getParentsInBook(ppm)
        [pmpp,pmpm] = ancestors.getParentsInBook(pmp)
        [pmmp,pmmm] = ancestors.getParentsInBook(pmm)
        [mppp,mppm] = ancestors.getParentsInBook(mpp)
        [mpmp,mpmm] = ancestors.getParentsInBook(mpm)
        [mmpp,mmpm] = ancestors.getParentsInBook(mmp)
        [mmmp,mmmm] = ancestors.getParentsInBook(mmm)
        if pppp or pppm or ppmp or ppmm : gens = 4
        if pmpp or pmpm or pmmp or pmmm : gens = 4
        if mppp or mppm or mpmp or mpmm : gens = 4
        if mmpp or mmpm or mmmp or mmmm : gens = 4
    
    [s1,s2,s3] = [1.5,.85,.5]
    hgap = 0.1
    if gens == 4 :
        trow = int(s1*float(fontSize))
        theight = 31
        toff = 1
        hoff = 0
    
    elif gens == 3 :
        trow = int(s2*float(fontSize))
        hgap *= s1/s2
        theight = 29
        toff = 2.5
        hoff = 0
    
    else :
        trow = int(s3*float(fontSize))
        hgap *= s1/s3
        if gens == 2 :
            theight = 25
            toff = 7
            hoff = 1
        else :
            theight = 17
            toff = 10
            hoff = 2
    
    # has a tree
    treeNum = treeNum+1
    treeName = "tree"+str(treeNum)
    
    # length scaled to font size
    hasMore = False
    hasPlus = False
    ttxt = []
    ttxt.append("\n\n\\begin{figure}\n\\begin{center}\n")
    ttxt.append("\\setlength{\\unitlength}{"+str(trow)+"pt}\n")
    twidth = int(72.*(finalPaperWidth - bindMargin - rightMargin)/float(trow))
    hlen = 0.3*twidth/4.
    hoff = int(hlen*hoff)
    ttxt.append("\\begin{picture}("+str(twidth)+","+str(theight)+")("+str(-hoff)+","+str(toff)+")\n")
    
    # self
    ttxt.append("\\put(0,7.5){\\line(0,1){16}}\n")
    treePerson(rfs,0,16)

    # father and mother
    ttxt.append("\\multiput(0,7.5)(0,16){2}{\\line(1,0){"+str(hlen)+"}}\n")
    if gens > 1 :
        ttxt.append("\\multiput("+str(hlen)+",3.5)(0,16){2}{\\line(0,1){8}}\n")
    if f :
        treePerson(f,hlen,24)
    else :
        treeNonbook(rfs.rec.father().get(),hlen,24)
    if m :
        treePerson(m,hlen,8)
    else :
        treeNonbook(rfs.rec.mother().get(),hlen,8)
    
    # grand parents
    arrow = False
    if maxTreeGens == 2 : arrow = True
    if gens > 1 :
        ttxt.append("\\multiput("+str(hlen)+",3.5)(0,8){4}{\\line(1,0){"+str(hlen)+"}}\n")
        if gens > 2:
            ttxt.append("\\multiput("+str(2*hlen)+",1.5)(0,8){4}{\\line(0,1){4}}\n")
        treePerson(pp,2*hlen,28,arrow)
        treePerson(pm,2*hlen,20)
        treePerson(mp,2*hlen,12,arrow)
        treePerson(mm,2*hlen,4,arrow)
    
    # great grandparents
    if maxTreeGens == 3 : arrow = True
    if gens > 2 :
        ttxt.append("\\multiput("+str(2*hlen)+",1.5)(0,4){8}{\\line(1,0){"+str(hlen)+"}}\n")
        if gens > 3 :
            ttxt.append("\\multiput("+str(3*hlen)+",.5)(0,4){8}{\\line(0,1){2}}\n")
        treePerson(ppp,3*hlen,30,arrow)
        treePerson(ppm,3*hlen,26,arrow)
        treePerson(pmp,3*hlen,22,arrow)
        treePerson(pmm,3*hlen,18,arrow)
        treePerson(mpp,3*hlen,14,arrow)
        treePerson(mpm,3*hlen,10,arrow)
        treePerson(mmp,3*hlen,6,arrow)
        treePerson(mmm,3*hlen,2,arrow)
    
    # great great grandparents
    if gens > 3 :
        ttxt.append("\\multiput("+str(3*hlen)+",.5)(0,2){16}{\\line(1,0){"+str(hlen)+"}}\n")
        if gens > 4 :
            ttxt.append("\\multiput("+str(4*hlen)+",0)(0,2){16}{\\line(0,1){1}}\n")
        treePerson(pppp,4*hlen,31,True)
        treePerson(ppmp,4*hlen,27,True)
        treePerson(ppmm,4*hlen,25,True)
        treePerson(pmpp,4*hlen,23,True)
        treePerson(pmpm,4*hlen,21,True)
        treePerson(pmmp,4*hlen,19,True)
        treePerson(pmmm,4*hlen,17,True)
        treePerson(mppp,4*hlen,15,True)
        treePerson(mppm,4*hlen,13,True)
        treePerson(mpmp,4*hlen,11,True)
        treePerson(mpmm,4*hlen,9,True)
        treePerson(mmpp,4*hlen,7,True)
        treePerson(mmpm,4*hlen,5,True)
        treePerson(mmmp,4*hlen,3,True)
        treePerson(mmmm,4*hlen,1,True)
    
    ttxt.append("\\end{picture}\n")
    ttxt.append("\\end{center}\n")
    ttxt.append("\\caption{"+CapitalOne(Cardinal(gens))+" generation")
    if gens > 1 : ttxt.append("s")
    ttxt.append(" of ancestors of "+rfs.altname+".")
    if hasMore == True :
        ttxt.append(" An arrow after a name means that person has additional known ancestors in this book.")
    if hasPlus == True :
        ttxt.append(" A '+' sign means that person has known ancestors not in this book.")
    ttxt.append("\\label{"+treeName+"}}\n")
    ttxt.append("\\end{figure}\n\n")
    
    # append to this person
    rfs.tree.append(''.join(ttxt))

# output person to the tree and provide coordinates
def treePerson(rfs,h,v,arrow=False) :
    global treeName,hgap,ttxt,hasMore
    if not(rfs) : return
    ttxt.append("\\put("+str(h+hgap)+","+str(v-.5)+"){\\makebox(0,0)[l]{")
    rfsID = ancestors.xrefID(rfs.key)
    ttxt.append(rfs.altname+"$^"+rfsID[2:-1]+"$")
    if rfs.span != " ()" : ttxt.append(rfs.span)
    # don't mark as in tree if has more ancestors
    if arrow :
        if rfs.parents() != "unknown parents" :
            ttxt.append("$\\to$")
            hasMore = True
        elif not(rfs.tree) :
            rfs.tree = [treeName]
    elif not(rfs.tree) :
        rfs.tree = [treeName]
    ttxt.append(rfs.indexTag()+"}}\n")

# output person to the tree and provide coordinates
def treeNonbook(indi,h,v) :
    global hgap,ttxt,hasPlus
    if not(indi) : return
    ttxt.append("\\put("+str(h+hgap)+","+str(v-.5)+"){\\makebox(0,0)[l]{")
    ttxt.append(SafeTex(indi.alternateName()).strip())
    nspan = indi.lifeSpan()
    if nspan != "()" : ttxt.append(" "+nspan)
    famc = indi.evaluateExpression_("FAMC")
    if famc != "" :
        ttxt.append(" +")
        hasPlus = True
    ttxt.append("}}\n")

# output child in a child list item
def OutputChild(chil,inum) :
    # get person object
    cfs = ancestors.getChild(chil)
    rpt.out(cfs.indexTag())
    cfsID = ancestors.xrefID(cfs.key)
    cborn = cfs.born()
    if cborn :
        rpt.out(cfs.altname+", a "+cfs.child+", "+cborn+GetSources(cfs.birth.event)+". ")
    else :
        rpt.out(cfs.altname+"'s"+cfsID+" birth date is not known. ")
    dd = cfs.getFD("",0,False)
    if dd : rpt.out(dd+GetSources(cfs.death.event)+". ")
    
    # marriages (unless done ealier)
    famses = cfs.rec.spouseFamilies()
    if cfsID:
        cnum = int(cfsID[7:-2])
        if len(famses) == 0 :
            if cnum < inum :
                rpt.out("More details on this child were given earlier"+cfsID+". ")
            else :
                rpt.out("More details on this child are given later"+cfsID+". ")
        else :
            thefam = "family"
            if len(famses) > 1 : thefam = "families"
            if cnum < inum :
                rpt.out("More details on this child and on "+cfs.poss.lower()+" "+thefam+" were given earlier"+cfsID+". ")
            else :
                rpt.out("More details on this child and on "+cfs.poss.lower()+" "+thefam+" are given later"+cfsID+". ")
    else :
        # for non ancestors, add burial
        buri = cfs.buried()
        if buri : rpt.out(cfs.pronoun+" "+buri+". ")
        
        for fams in famses :
            umr = fams.evaluateExpression_("_UMR")
            spse = ancestors.getSpouse(fams,cfs)
            if umr == "Y" :
                if spse :
                    rpt.out(rfs.pronoun+" partnered with "+ spse.altname+". ")
                else :
                    rpt.out(rfs.pronoun+" partnered with an unknown person. ")
            else :
                if spse :
                    rpt.out(cfs.pronoun+" married "+ spse.altname)
                else :
                    rpt.out(cfs.pronoun+" married an unknown spouse")
                # marriage event
                try :
                    m = fams.structures().objectWithName_("MARR").get()
                    if m :
                        marr = BookEvent(m," ")
                        rpt.out(marr.phrase+GetSources(m))
                    rpt.out(". ")
                except :
                    rpt.out(". ")
                try :
                    d = fams.structures().objectWithName_("DIV").get()
                    if d :
                        div = BookEvent(d," They divorced")
                        if div.phrase :
                            rpt.out(div.phrase)
                        else :
                            rpt.out(" They divorced")
                        rpt.out(GetSources(d))
                        rpt.out(". ")
                except :
                    d = None
            # spouse details
            if spse :
                rpt.out(spse.indexTag())
                rpt.out(spse.getNPB("",0))
                if spse.birth : rpt.out(GetSources(spse.birth.event))
                rpt.out(spse.getFD("",-2,False))
                if spse.death : rpt.out(GetSources(spse.death.event))
                rpt.out(". ")
    # end this child
    rpt.out("\n")

# handle portrait at this location
def QueuePortrait(rfs) :
    global pside
    if not(doPortraits) : return
    # portrait first
    por = rfs.portrait()
    if por :
        pname = por.rsplit("/",1)[-1]
        pparts = pname.rsplit(".",1)
        if len(pparts) > 1 :
            pext = pparts[1].lower()
            if pext == "jpeg" : pext = "jpg"
            if pext == "tiff" : pext = "tif"
            if pext in supexts :
                destIDName = "P"+rfs.key[1:-1]
                destFile = None
                if supexts[pext]=="No" and convertCmd!=None :
                    gdoc.notifyProgressFraction_message_(1,"Converting "+pname+" to png file\n   (Hint: use jpg, pdf, or png portraits for faster books)")
                    destFile = rootFldr+"/portraits/"+ destIDName +".png"
                    output = DoCommand(convertCmd+" '"+por+"' '"+destFile+"'")
                    if output[1] :
                        gdoc.notifyProgressFraction_message_(1,"Error converting portait at path "+por+"\n"+output[1])
                        destFile = None
                    else :
                        pqueue.append([len(rpt.text),n+1,rfs.altname,destIDName,rfs.indexTag()])
                if destFile==None :
                    destFile = rootFldr+"/portraits/"+ destIDName +"."+pext
                    try :
                        shutil.copyfile(por,destFile)
                        pqueue.append([len(rpt.text),n+1,rfs.altname,destIDName,rfs.indexTag()])
                    except :
                        gdoc.notifyProgressFraction_message_(1,"Error copying portrait at path "+por)
 
# Output portraits now
def DequeuePortraits(all=False) :
    global pqueue,pindex,pqueue,pscale
    if len(pqueue) == 0 : return
    if len(pqueue) == 3 :
        porargs = "\\portraits"\
        +"{{"+str(pqueue[0][1])+" "+pqueue[0][2]+"}}{"+pqueue[0][3]+"}"\
        +"{{"+str(pqueue[1][1])+" "+pqueue[1][2]+"}}{"+pqueue[1][3]+"}"\
        +"{{"+str(pqueue[2][1])+" "+pqueue[2][2]+"}}{"+pqueue[2][3]+"}"\
        +"{0.32}{"+pscale[2]+"}{"+pside[pindex]+"}\n"\
        +pqueue[0][4]+pqueue[1][4]+pqueue[2][4]+"\n\n"
        ploc = pqueue[1][0]
    elif len(pqueue) == 2 and all :
        porargs = "\\portraits"\
        +"{{"+str(pqueue[0][1])+" "+pqueue[0][2]+"}}{"+pqueue[0][3]+"}"\
        +"{{"+str(pqueue[1][1])+" "+pqueue[1][2]+"}}{"+pqueue[1][3]+"}"\
        +"{}{}{0.49}{"+pscale[1]+"}{"+pside[pindex]+"}\n"\
        +pqueue[0][4]+pqueue[1][4]+"\n\n"
        ploc = pqueue[0][0]
    elif len(pqueue) == 1 and all :
        porargs = "\\portraits"\
        +"{{"+str(pqueue[0][1])+" "+pqueue[0][2]+"}}{"+pqueue[0][3]+"}"\
        +"{}{}{}{}{.99}{"+pscale[0]+"}{"+pside[pindex]+"}\n"\
        +pqueue[0][4]+"\n\n"
        ploc = pqueue[0][0]
    else :
        return
    rpt.text.insert(ploc,porargs)
    pindex = 1-pindex
    pqueue = []

################### Main Script

# Preamble
scriptVersion = 7
scriptName = "Generations LaTeX Book"
gedit = CheckVersionAndDocument(scriptName,1.7,1)
gdoc = FrontDocument()

# globals
# "Yes" means use as is, "No" means to convert to png if possible
supexts = {"jpg":"Yes","pdf":"Yes","png":"Yes","gif":"No","psd":"No","tif":"No","bmp":"No"}
today = gdoc.dateToday()
[sdnToday,sdnMax] = gdoc.sdnRangeFullDate_(today)
maxAge = 90.*365.25
maxParentAge = 110.*365.25
maxMarriedDays = 75.*365.25
pside = ["b","t"]
pindex = 0
doPortraits = True			# True or false to include portraits
others = RecordsSet()
pqueue = []
pscale = ("0.3","0.6","0.9")
treeNum = 0                # number of trees
maxTreeGens = 4            # can be 2, 3, or 4 to size for book page

# look for convert command (but which command fails)?
convertCmd = "convert"

# check for book settings
selRecs = gdoc.selectedRecords()
if len(selRecs) == 0 :
    Alert("No records were selected",\
    "You have to select one or more source individuals or a book style record before running this script.")
    quit()

bookRec = selRecs[0]
if bookRec.recordType() == "_BOK" :
    settings = bookRec.bookSettings()
    
    # inidividuals
    selRecs = settings["individuals"]
    
    # author
    author = settings["author"]
    email = settings["email"]
    
    # generations
    ancestGen = settings["ancestors"]
    if ancestGen.lower() == "all" :
        ancestGen = 1000
    elif ancestGen.lower() == "none" :
        ancestGen = 0
    else :
        try :
            ancestGen = int(ancestGen)
            if ancestGen < 0 : ancestGen = 0
        except :
            ancestGen = None
    if ancestGen != None:
        descendGen = settings["descendants"]
        if descendGen == "all" :
            descendGen = 1000
        elif descendGen == "none" :
            descendGen = -1000
        else :
            try :
                descendGen = int(descendGen)
                if descendGen <= -ancestGen : descendGen = -1000
            except :
                descendGen = None
    
    # font settings (by menu)
    fontFamily = settings["fontFamily"]
    fontSize = settings["fontSize"]
    lineSpread = settings["lineSpread"]
    try :
        lineSpread = float(lineSpread)
        if lineSpread < 0.8 : lineSpread = 0.8
    except :
        lineSpread = None
        
    # page style
    paperType = settings["paperSize"]
    bookSize = settings["pageSize"]
    
    # save folder
    fldr = bookRec.saveFolder()
    if fldr == "" : fldr = None
    if settings["overwrite"] == "Y" : overwrite = True
    
    # suto typesetting
    if settings["typeset"] == "Y" : commandLineTypeset = True
    
    # user chapters
    introduction = settings["introduction"]
    if len(introduction) == 0 :
        introduction = None
    introTeX = settings["introTeX"]
    aboutAuthor = settings["aboutAuthor"]
    if len(aboutAuthor) == 0 :
        aboutAuthor = None
    aboutTeX = settings["aboutTeX"]
    
    # defs style
    styleSheet = settings["styleSheet"]
    
    # notes option
    notesOption = settings["notesOption"]
    
    # portrait option
    porOption = settings["porOption"]
    
    # copyright options
    if "owner" in settings :
        cOwner = settings["owner"]
        cGrantees = settings["grantees"]

# collect and sort ancestors
source = PersonSet()
source.addList(selRecs,0)
source.GetXrefs()

# get root individuals
rootsFlat = ""
numRoots = 0
last = ""
for rfs in source.recs :
    if rfs.type != "INDI" : continue
    numRoots += 1 
    if numRoots > 1 :
        rootsFlat += last + ", "
    last = rfs.altname
if numRoots > 1 :
    if numRoots == 2 : rootsFlat = rootsFlat[:-2]+" "
    rootsFlat += "and "
rootsFlat += last

# check for none
if numRoots == 0 :
    Alert("No individuals were selected",\
    "You have to select one or more source individuals before running this script.")
    quit()

# if folder specified, make sure it exists
# fldr None means running as script of running fro record and folder field is empty
# pickFolder means user picked a folder while running the script
pickedFolder = False

# if got folder name from record
# if it exists, then use it
chooseMsg = "Choose a folder to contain the folder of output LaTeX files for the book"
if fldr != None :
    # strip final / if there
    if fldr != "" :
        if fldr[-1] == "/" :
            fldr = fldr[:-1]
    if not(os.path.exists(fldr)) :
        if bookRec.recordType() == "_BOK" :
            prmpt = "The save folder in the Book Style record does not exist"
            msg = "Would like to use a default folder, select a new one, or cancel the book?"
            opt = GetOption(prmpt,msg,["Use Default","Select","Cancel"])
            if opt == "Cancel" :
                quit()
            elif opt == "Use Default" :
                fldr = None
            else :
                fldr = gdoc.userOpenFolderPrompt_start_title_(chooseMsg,None,None)
                pickedFolder = True
                overwrite = False
                if not(fldr) : quit()
                rootName = "GEDitCOM_LaTeX_Book"
                rootFldr = fldr + "/" + rootName
        else :
            fldr = None
    else :
        # must have at least one "/"
        # get rootName = just folder name, fldr = folder holding folder
        #    and rootFolder for full folder name
        parts = fldr.rpartition("/")
        if len(parts) > 2 and parts[0] :
            fldr = parts[0]
            rootName = parts[2]
            rootFldr = fldr+"/"+parts[2]
        else :
            fldr = None

# if from book record
# 1. If no folder provided or it no longer exists, write
#        to subfolder in Books folder
# 2. If has valid folder, use it as from above
if bookRec.recordType() == "_BOK" :
    if not(fldr) :
        # if no longer exists, switch to default folder
        fldr = gdoc.path()
        if fldr and fldr!="" :
            parts = gdoc.path().rpartition("/")
            fldr = parts[0] + "/Books"
            if not(os.path.exists(fldr)) :
                try :
                    os.mkdir(fldr)
                except: 
                    Alert("Error trying to create 'Books' folder beside the current document")
                    quit()
            rootName = bookRec.name().replace("/","_")
            rootName = rootName.replace("'","-")
            qt = "\""
            rootName = rootName.replace(qt,"-")
            rootFldr = fldr + "/" + rootName
            overwrite = False
            pickedFolder = True
        else:
            Alert("You have to save a new file before using Book records.")
            quit()
     
elif not(fldr) :
    # if not from book record, prompt for folder now if needed
    # and create rootFldr using default Name
    fldr = gdoc.userOpenFolderPrompt_start_title_(chooseMsg,None,None)
    pickedFolder = True
    overwrite = False
    if not(fldr) : quit()
    rootName = "GEDitCOM_LaTeX_Book"
    rootFldr = fldr + "/" + rootName

# create new folder (if not overwriting)
if overwrite == False :
    pathExtra = 0
    while True :
        rootFldr = fldr+"/" + rootName
        if pathExtra > 0 :
            rootFldr += "_"+str(pathExtra)
        if not(os.path.exists(rootFldr)) : break;
        pathExtra += 1
   
    # create the folder
    try :
        os.mkdir(rootFldr)
    except: 
        Alert("Error trying to create the folder at the selected location")
        quit()

# save new folder if user picked it
if pickedFolder == True :
    if bookRec.recordType() == "_BOK" :
        bookRec.setSaveFolder_(rootFldr)

# get preferences
if ancestGen == None or descendGen == None :
    prompt = "Enter number of ancestor and descendant generations"+\
    " from the root generation to include in the book. Enter 'all' or"+\
    " 'none' if desired"
    if ancestGen == None : ancestGen = 1000
    if descendGen == None : descendGen = -1000
    while True :
        if ancestGen > 999 :
            initstr = "all "
        elif ancestGen < 1 :
            initstr = "none "
        else :
            initstr = str(ancestGen)+" "
        if descendGen > 999 :
            initstr += "all"
        elif descendGen <= -ancestGen :
            initstr += "none"
        else :
            initstr += str(descendGen)
        gens = GetString(prompt,initstr,"Select Generations")
        if gens == None : quit()
        gwords = gens.split()
        if len(gwords) != 2 :
            Alert("You must enter exactly two items separated by white space.",\
            "Try again by entering two items.")
            continue
            
        if gwords[0].lower() == "all" :
            ancestGen = 1000
        elif gwords[0].lower() == "none" :
            ancestGen = 0
        else :
            try :
                ancestGen = int(gwords[0])
                if ancestGen < 0 : ancestGen = 0
            except :
                Alert("The number of ancestor generations must be an integer, 'all', or 'none'.",\
                "Try again by entering one of these options.")
                continue

        if gwords[1].lower() == "all" :
            descendGen = 1000
        elif gwords[1].lower() == "none" :
            descendGen = -1000
        else :
            try :
                descendGen = int(gwords[1])
                if descendGen <= -ancestGen : descendGen = -1000
            except :
                Alert("The number of descendant generations must be an integer, 'all', or 'none'.",\
                "Try again by entering one of these options.")
                continue
        
        if ancestGen == 0 and descendGen < 0 :
            Alert("You entered values that result in neither ancestors nor descendants and that is not allowed",\
            "Try again by entering different options.")
            continue
       
        break

# notes options
if notesOption == None :
    # notes ("hideOwner","hideFamily","hideAll","hideNone")
    options = ["Include all","Omit 'Owner'","Omit 'Owner' and 'Family","Omit all"]
    notesPick = GetOneItem(options,"Select notes to be included","Notes Options")
    if notesPick[0] == None : quit()
    if notesPick[1] == 1 :
        notesOption = "hideNone"
    elif notesPick[1] == 4 :
        notesOption = "hideAll"
    elif notesPick[1] == 2 :
        notesOption = "hideOwner"
    else :
        notesOption = "hideFamily"
SetNotesOption(notesOption)

# portrait options
if porOption == None :
    # notes ("hideOwner","hideFamily","hideAll","hideNone")
    options = ["Include all","Omit 'Owner'","Omit 'Owner' and 'Family","Omit all"]
    porPick = GetOneItem(options,"Select portraits to be included","Notes Options")
    if porPick[0] == None : quit()
    if porPick[1] == 1 :
        porOption = "hideNone"
    elif porPick[1] == 4 :
        porOption = "hideAll"
    elif porPick[1] == 2 :
        porOption = "hideOwner"
    else :
        porOption = "hideFamily"

# author
if not(author) :
    author = GetString("Enter the name of the author for the book.","name","Author's Name")
    if author == None : quit()
    author = SafeTex(author)
    if bookRec.recordType() == "_BOK" :
        bookRec.setAuthorName_(author)
    
# author
if not(email) :
    email = GetString("Enter the author's email (or blank to omit).","author@gmail.com","Author's Email")
    if email == None : quit()
    email = SafeTex(email)
    if bookRec.recordType() == "_BOK" :
        bookRec.setAuthorEmail_(email)
    
# font size
if fontSize == None :
    # LaTeX document class only supports 3 sizes (9 and 14 be rescaling)
    options = [" 9 pt", "10 pt","11 pt","12 pt","14 pt"]
    fontPick = GetOneItem(options,"Select font size for the book","Font Size")
    if fontPick[0] == None : quit()
    fontSize = int(fontPick[0][:2])

# font family
if fontFamily == None :
    options = ["Computer Modern Roman", "Times","Palatino","Bookman","New Century Schoolbook",
    "Charter","Helvetica","Avant-Garde","Zapf Chancery","Courier"]
    fontPick = GetOneItem(options,"Select font family for the book","Font Family")
    fontFamily = fontPick[0]
    if fontPick[0] == None : quit()

# line spread
if lineSpread == None:
    prompt = "Enter line spread as factor to increase line spacing"+\
    " (1.0 means single spaced lines)"
    while True :
        gens = GetString(prompt,"1.2","Line Spacing")
        if gens == None : quit()
        try :
            lineSpread = float(gens)
            if lineSpread < 0.8 : lineSpread = 0.8
            break
        except :
            Alert("The line spread has to be a floating point number.",\
            "Try again by entering a number.")

# paper type
if paperType == None :
    # "US Letter" or "A4"
    bookType = GetOption("Select physical page size for your printer and/or "+\
    "your LaTeX configuration.",None,["US Letter","Cancel","A4"])
    if bookType == "Cancel" : quit()

# book size
if bookSize == None :
    # final book style "Hardcover Novel", "Large Textbook" or "Full Page"
    options = ["Full Page","Large Textbook","Hardcover Novel"]
    msg = "When not using 'Full Page' the typeset output will need to be "+\
    "printed (or copied) 1 to 2 sided and then trimmed to final book size."
    bookSize = GetOption("Select final page size for the printed book.",msg,options)

# create portraits directory
try :
    portraitFldr = rootFldr+"/portraits"
    os.mkdir(portraitFldr)
except :
    if overwrite == False :
        Alert("Error trying to create the portraits folder at the selected location")
        quit()
    
# copy the defs file
if styleSheet == "Ruled Sections" :
    defName = "BookLaTeXDefs2.tex"
else :
    defName = "BookLaTeXDefs.tex"
defFile = CurrentScriptFolder(__file__)+"/"+defName
defDestFile = rootFldr+"/"+defName
try :
    shutil.copyfile(defFile,defDestFile)
except :
    Alert("Error trying to copy BookLatexDefs.tex file to output folder")
    quit()

# prepare to save tex file
rpt = ScriptOutput(scriptName,"monospace",rootFldr+"/BookLaTeXBody.tex")

# ancestor
gdoc.notifyProgressFraction_message_(-1.,"Finding ancestors of root individuals")
ancestors = PersonSet()
ancestors.ancestorSet(source,True,ancestGen)

# if desired, add descendants from tops
if descendGen > -ancestGen :
    gdoc.notifyProgressFraction_message_(-1.,"Finding descendants of tree-top individuals")
    theTops = RecordsSet()
    last = -1
    for (n,rfs) in enumerate(ancestors.recs) :
        if rfs.value <= last :
            last = rfs.value
            continue
        treeTop = False
        if n == len(ancestors.recs)-1 :
            treeTop = True
        elif rfs.value >= ancestors.recs[n+1].value :
            treeTop = True
        if treeTop :
            theTops.addObjectWithKey(rfs,rfs.key)
    descendants = PersonSet()
    descendants.descendantSet(theTops,False,descendGen)
    for pfs in descendants.recs :
        if pfs.value < 0 :
            pfs.value = -float(pfs.value)/1000.
    ancestors.union(descendants)
    
if ancestors.len() < 1 :
    Alert("No ancestors or descendants were found")
    quit()

# sort by generation number
ancestors.valueNameSort()
ancestors.GetXrefs()

# Get sizes
if paperType == "A4" :
    physicalPaperWidth = 8.25
    physicalPaperHeight = 11.5
    paperType = "papera4,"
else :
    # US Letter
    physicalPaperWidth = 8.5
    physicalPaperHeight = 11
    paperType = ""

# physical paper width and paper for printing
# LaTeX defaults
# physicalPaperWidth=612pt, bindMargin=89pt, rightMargin=88pt,
#     finalPaperWidth=567pt (7 7/8 in), textwidth=390pt (5.416in)
#
# Hardcover novel
# physicalPaperWidth=8.5in, finalPaperWidth 6.5in
#     rightMargin=0.94in textwidth=4.5in, bindMargin=1.06in
if bookSize == "Hardcover Novel" :
    finalPaperWidth = 6.25
    finalPaperHeight = 9.125
    bindMargin = 1.0
    rightMargin = 0.75
    topMargin = 1.0
    bottomMargin = 1.0
elif bookSize == "Large Textbook" :
    finalPaperWidth = 7.5
    finalPaperHeight = 9.5
    bindMargin = 1.0
    rightMargin = 0.75
    topMargin = 1.0
    bottomMargin = 1.0
else :
	# Full Page
    finalPaperWidth = physicalPaperWidth
    finalPaperHeight = physicalPaperHeight 
    bindMargin = 1.0
    rightMargin = 1.0
    topMargin = 1.0
    bottomMargin = 1.0

# bindMargin = 1+\oddsideMargin
# finalPaperWidth = bindMargin + \textwidth + rightMargin
# physicalPaperWidth = 1 + \evensideMargin + \textwidth + rightMargin
#                    = finalPaperWidth + \evensideargin - \oddsidemargin
oddSideMargin = bindMargin - 1.0
textWidth = finalPaperWidth - bindMargin - rightMargin
evenSideMargin = physicalPaperWidth - 1 - textWidth - rightMargin
voffset = topMargin - 1.80
textHeight = finalPaperHeight - topMargin - bottomMargin

# Tree calculations
if maxTreeGens > 0 :
    # adjust tree height
    thgt = TreeHeight()
    troom = 72*textHeight
    if troom-thgt < 50 :
        maxTreeGens -= 1
        th = TreeHeight()
        if troom - thgt < 50 : maxTreeGens -= 1
    
    # find descendants
    childes = []
    for i in range(len(ancestors.recs)) :
        rfs = ancestors.recs[i]
        if rfs.value == 0 :
            continue;
        elif rfs.value < 1 :
            childes.append(rfs)
        else :
            break;
    
    # append sources
    for i in range(len(ancestors.recs)) :
        rfs = ancestors.recs[i]
        if rfs.value == 0 :
            if source.xrefID(rfs.key) != "" :
                childes.append(rfs)
        else :
            break;
            
    # descendant trees
    numdes = len(childes)
    if numdes > 0 :
        for i in range(numdes) :
            rfs = childes[numdes-1-i]
            MakeTree(rfs)
            
    # rest of the trees
    for (n,rfs) in enumerate(ancestors.recs) :
        gen = rfs.value
        if gen==0 or gen >=1 :
            MakeTree(rfs)

# preamble
if fontSize == 9 :
    docSize = 10
elif fontSize == 14 :
    docSize = 12
else :
    docSize = fontSize
rpt.out("%&pdflatex\n\n")
rpt.out("% Main LaTeX source file for a genealogy book\n")
rpt.out("% File automatically generated by running '"+scriptName+"' version "+str(scriptVersion)+"\n")
rpt.out("% Script run in "+AppVersion()+"\n\n")

rpt.out("\\documentclass["+paperType+str(docSize)+"pt]{book}\n")
rpt.out("\\input{"+defName+"}\n\n")

rpt.out("\\textwidth"+str(textWidth)+"in\n")
rpt.out("\\oddsidemargin"+str(oddSideMargin)+"in\n")
rpt.out("\\evensidemargin"+str(evenSideMargin)+"in\n")
rpt.out("\\textheight"+str(textHeight)+"in\n")
rpt.out("\\voffset"+str(voffset)+"in\n")

# font settings
rpt.out("\n\\usepackage[T1]{fontenc}\n")
if fontFamily == "Times" :
    rpt.out("\\usepackage{mathptmx}\n")
elif fontFamily == "Palatino" :
    rpt.out("\\usepackage{mathpazo}\n")
elif fontFamily == "Bookman" :
    rpt.out("\\usepackage{bookman}\n")
elif fontFamily == "New Century Schoolbook" :
    rpt.out("\\usepackage{newcent}\n")
elif fontFamily == "Charter" :
    rpt.out("\\usepackage{charter}\n")
elif fontFamily == "Helvetica" :
    rpt.out("\\usepackage{helvet}\n\\renewcommand{\\familydefault}{\\sfdefault}\n")
elif fontFamily == "Avant-Garde" :
    rpt.out("\\usepackage{avant}\n\\renewcommand{\\familydefault}{\\sfdefault}\n")
elif fontFamily == "Zapf Chancery" :
    rpt.out("\\usepackage{chancery}\n")
elif fontFamily == "Courier" :
    rpt.out("\\usepackage{courier}\n\\renewcommand{\\familydefault}{\\ttdefault}\n")
rpt.out("\\linespread{"+str(lineSpread)+"}\n\n")

# translation defs
vers = str(int(10*gedit.versionNumber())/10.)+", build "+str(gedit.buildNumber())
toyear = gdoc.dateYearFullDate_(today)
rpt.out("% For some translations\n\n")
rpt.out("\\def\\tocName{Table of Contents}\n")
rpt.out("\\def\\bibName{Sources}\n")
rpt.out("\\def\\authorIntro{Book Prepared by}     % followed by author's name\n")
rpt.out("\\def\\geditcomII{Prepared using GEDitCOM II version "+vers+"}\n")
rpt.out("\\def\\printDate{"+today+"}\n")
rpt.out("\\def\\generation{Generation}\n")
rpt.out("\\def\\ancestor{Ancestor}\n")
rpt.out("\\def\\descendant{Descendant}\n")
rpt.out("\\def\\rootgen{Root \generation}\n\n")

rpt.out("\\graphicspath{{./portraits/}}\n\n")

# start document
rpt.out("\\begin{document}\n\n")
rpt.out("% Title Page and Copyright Notice\n")

# title page
subtitle=""
if descendGen <= -ancestGen:
    btitle = "THE ANCESTORS OF"
elif ancestGen == 0 :
    btitle = "THE DESCENDANTS OF"
else :
    btitle = "THE ANCESTORS OF"
    subtitle = "AND THEIR DESCENDANTS"
if cOwner != None :
    if len(cOwner) == 0 : cOwner = author
    cRight = "\\copyright\\ "+toyear+", "+cOwner+", All Rights Reserved\\\\ "
    if len(cGrantees) > 0 :
        cRight = cRight + cGrantees + " and their heirs are hereby granted"
        cRight = cRight + " a non-exclusive worldwide, perpetual license to"
        cRight = cRight + " make unlimited copies of this work, in whole or in part,"
        cRight = cRight + " without fee or accounting obligations."
else :
    cRight = ""

rpt.out("\\booktitlepage{"+btitle+"}{"+rootsFlat+"}{"+author+"}{"+email+"}{"+subtitle+"}{"+cRight+"}\n\n")
rpt.out("% Generations\n\n")

if fontSize == 9 :
    rpt.out("\\small\n\n")
elif fontSize == 14 :
    rpt.out("\\large\n\n")

# output
gdoc.notifyProgressFraction_message_(0,"Preparing LaTeX source file")
fraction = nextFraction = 0.1
nmax = len(ancestors.recs)+1
last = None
for (n,rfs) in enumerate(ancestors.recs) :
    gen = rfs.value
    
    # on new generation, start a new chapter
    if gen != last :
        DequeuePortraits(True)
        if gen == 0 :
            ctitle = "\\rootgen"
        elif gen < 1 :
            # decendant generations -1, -2, etc. number .001,.002, etc.
            ctitle = "\\descendant\\ \\generation\\ "+str(int(1000*gen+0.1))
        else :
            ctitle = "\\ancestor\\ \\generation\\ "+str(gen)
        rpt.out("\\startGeneration{"+ctitle+"}\n")
        if gen == 0 :
            # Generation 1 gets an introduction
            rpt.out("\\setcounter{page}{1}\n")
            rpt.out("\\pagestyle{myheadings}\n")
            rpt.out("\\pagenumbering{arabic}\n\n")
            rpt.out("\\theintroduction\n\n")
            if ancestGen > 0 :
                if ancestGen > 999 :
                    thegens = "all the"
                else :
                    thegens = Cardinal(ancestGen)+" generation"
                    if ancestGen != 1 : thegens += "s"
                    thegens += " of"
                rpt.out("This book describes "+thegens+" ancestors of "+rootsFlat)
                contains = "ancestors"
                if descendGen < -ancestGen or descendGen < -999 :
                    if numRoots == 1 :
                        rpt.out(", who is")
                    else :
                        rpt.out(", who are")
                    rpt.out(" listed in this first chapter. ")
                elif descendGen > -1000 :
                    rpt.out(". For each ancestor, this book also describes ")
                    if descendGen > 999 :
                        rpt.out("all their descendants. ")
                    elif descendGen == 0 :
                        rpt.out("their descendants back to the root generation. ")
                    elif descendGen < 0 :
                        rpt.out("their descendants to "+Cardinal(-descendGen)+" generation")
                        if descendGen != -1 : rpt.out("s")
                        rpt.out(" above the root generation. ")
                    else :
                        rpt.out("their descendants up to "+Cardinal(descendGen)+" generation")
                        if descendGen != 1 : rpt.out("s")
                        rpt.out(" beyond the root generation. ")
                    if numRoots == 1 :
                        rpt.out(rootsFlat+" is listed within this first chapter. ")
                    else :
                        rpt.out("The root individuals are listed within this first chapter. ")
                    contains += " or descendants"
            else :
                if descendGen > 999 :
                    thegens = "all the"
                else :
                    thegens = Cardinal(descendGen)+" generation"
                    if descendGen != 1 : thegens += "s"
                    thegens += " of"
                rpt.out("This book describes "+thegens+" descendants of "+rootsFlat+", who ")
                if numRoots == 1 :
                    rpt.out("is")
                else :
                    rpt.out("are")
                rpt.out(" listed in this first chapter. ")
                contains = "descendants"
            rpt.out("Within each generation, the "+contains+" are")
            rpt.out(" listed in alphabetical order. When individuals are referenced who are")
            rpt.out(" listed elsewhere in the book, their names are followed by their number")
            rpt.out(" in this book. You can also locate all references to each individual")
            rpt.out(" by referring to the index at the end of the book.\n\n")
            
            if introduction != None :
                if introTeX == "Y" :
                    rpt.out(introduction)
                else :
                    rpt.out(SafeTex(introduction))
                rpt.out("\n\n")
        else :
            rpt.out("\n")
        last = gen
        conj = "From"
    
    # check portraits
    DequeuePortraits(False)
    
    # start person section
    rpt.out("\\person{"+str(n+1)+"}{"+rfs.altname+"}{"+rfs.indexTag()+"}{"+conj+"}\n\n")
    conj = ""
    
    # Output the section
    OutputPerson(rfs,n+1)
    
    # Queue portrate
    QueuePortrait(rfs)
    
    # progress
    fraction = float(n+1)/float(nmax)
    if fraction>nextFraction :
        gdoc.notifyProgressFraction_message_(fraction,None)

# finish up
DequeuePortraits(True)

# about the author
if aboutAuthor != None :
    rpt.out("\n\\startGeneration{About the Author}\n\n")
    if aboutTeX == "Y" :
        rpt.out(aboutAuthor)
    else :
        rpt.out(SafeTex(aboutAuthor))
    rpt.out("\n")

rpt.out("\n\\bibliography{book}\n\n")
rpt.out("\\printindex\n\n")
rpt.out("\\end{document}")

#
rpt.write()

# create bibliography
bib = []
bib.append("%% This BibTeX bibliography file was created using GEDitCOM II.")
bib.append("%% http://www.geditcom.com\n")
bib.append("%% Created for "+author+" on "+today+"\n")
bib.append("%% Saved with string encoding Unicode (UTF-8)\n")

biblio = GetBiblio()
for sour in biblio.recs :
    type = sour.rec.sourceType().lower()
    date = sour.rec.sourceDate()
    year = "????"
    if date :
        dmy = gdoc.dateNumbersFullDate_(date)
        if len(dmy) >= 3 : year = str(dmy[2])
    auth = SafeTex(', '.join(CompactLines(sour.rec.sourceAuthors())))
    if not(auth) : auth = "(no author)"
    publ = SafeTex(', '.join(CompactLines(sour.rec.sourceDetails())))
    titl = SafeTex(', '.join(CompactLines(sour.rec.sourceTitle())))
    if not(titl) : titl = "(no title)"
    
    if type == "article" :
        bib.append("@article{B"+sour.key[1:-1]+",")
        bib.append("    Author = {{"+auth+"}},")
        bib.append("    Title = {{"+titl+"}},")
        if not(publ) : publ = "(no journal)"
        bib.append("    Journal = {{"+publ+"}},")
        bib.append("    Year = {"+year+"}}\n")
    elif type == "web page" :
        bib.append("@misc{B"+sour.key[1:-1]+",")
        bib.append("    Author = {{"+auth+"}},")
        bib.append("    Title = {{"+titl+"}},")
        if not(publ) : publ = "(no publisher)"
        bib.append("    Publisher = {{"+publ+"}},")
        bib.append("    Howpublished = {"+SafeTex(sour.rec.sourceUrl())+"},")
        bib.append("    Year = {"+year+"}}\n")
    elif type == "unpublished" :
        bib.append("@unpublished{B"+sour.key[1:-1]+",")
        bib.append("    Author = {{"+auth+"}},")
        bib.append("    Title = {{"+titl+"}},")
        if not(publ) : publ = "(no note)"
        bib.append("    Note = {{"+publ+"}},")
        bib.append("    Year = {"+year+"}}\n")
    elif type == "vital records" :
        bib.append("@book{B"+sour.key[1:-1]+",")
        if auth == "(no author)" : auth = "(no location)"
        bib.append("    Author = {{"+auth+"}},")
        bib.append("    Title = {{"+titl+"}},")
        if not(publ) : publ = "(no storage/publisher)"
        bib.append("    Publisher = {{"+publ+"}},")
        bib.append("    Year = {"+year+"}}\n")
    else :
        # book, in book, general
        bib.append("@book{B"+sour.key[1:-1]+",")
        bib.append("    Author = {{"+auth+"}},")
        bib.append("    Title = {{"+titl+"}},")
        if not(publ) : publ = "(no publisher)"
        bib.append("    Publisher = {{"+publ+"}},")
        bib.append("    Year = {"+year+"}}\n")

# write the file
WriteUTF8File(rootFldr+"/book.bib",'\n'.join(bib))

# typeset here
if commandLineTypeset == True :
    gdoc.notifyProgressFraction_message_(1,"\n-------- Typesetting book: First Pass --------")
    
    # first pass
    cdFldr = "cd '"+rootFldr+"'; "
    makeTex = "/usr/texbin/pdflatex -halt-on-error -shell-escape BookLaTeXBody.tex"
    retcode = subprocess.call(cdFldr+makeTex,shell=True)
    if retcode != 0 :
        msg = "You can trying typesetting the output file in another application instead, such as TeXShop, to get better results."
        GetOption("An error ocurred when trying to typeset the book.",msg,["OK"])
        quit()
    
    # make index
    gdoc.notifyProgressFraction_message_(1,"\n-------- Typesetting book: Creating Index --------")
    makeidx = "/usr/texbin/makeindex BookLaTeXBody.idx"
    subprocess.call(cdFldr+ makeidx,shell=True)
    
    # make bibliography
    gdoc.notifyProgressFraction_message_(1,"\n-------- Typesetting book: Creating Bibliography --------")
    makebib = "/usr/texbin/bibtex BookLaTeXBody.aux"
    subprocess.call(cdFldr+makebib,shell=True)
    
    # second pass
    gdoc.notifyProgressFraction_message_(1,"\n-------- Typesetting book: Second Pass --------")
    subprocess.call(cdFldr+makeTex,shell=True)
    
    # final pass
    gdoc.notifyProgressFraction_message_(1,"\n-------- Typesetting book: Final Pass --------")
    subprocess.call(cdFldr+makeTex,shell=True)
    
    # open in Preview
    astring = NSString.stringWithString_(rootFldr+"/BookLaTeXBody.pdf")
    fileURL = NSURL.fileURLWithPath_(astring)
    NSWorkspace.sharedWorkspace().openFile_(astring)

else :
    # message to user
    if bookSize != "Full Page" :
        msg = "After printing or copying typeset version 1 to 2 side, the final pages will need to be trimmed to "+\
        str(finalPaperWidth)+"in by "+str(finalPaperHeight)+"in."
    else :
        msg = None
    GetOption("The LaTeX Book files are done and ready for typesetting in an application like TeXShop.",msg,["OK"])

