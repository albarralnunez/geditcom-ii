#!/usr/bin/python
#
# BookPreparation (Python Script for GEDitCOM II)

# Load GEDitCOM II Module
from GEDitCOMII import *

#---------------------- BookEvent Class

# Subclass of event for custom descriptions and safe Tex characters
class BookEvent(Event) :
    def __init__(self,evnt,verb=None,atAge=False,noun=None,freq=[.33,.67],withAddr=True) :
        Event.__init__(self,evnt)
        if withAddr==True :
            attAddr = evnt.evaluateExpression_("ADDR")
            if len(attAddr) > 0 :
                if verb == "graduated" :
                    # use "from" and start with address
                    newplace = "from "+ ', '.join(CompactLines(attAddr))
                    if len(self.place) > 0 : newplace += " "
                    self.place = newplace + self.place
                else :
                    if len(self.place) > 0 : self.place += " "
                    self.place += "at "+ ', '.join(CompactLines(attAddr))
        if verb == "immigrated" :
            # use "to"
            if len(self.place) > 0 : self.place = "to " + self.place
        elif verb == "emigrated" :
            # use "from"
            if len(self.place) > 0 : self.place = "to " + self.place
        self.place = SafeTex(self.place)
        if verb != None :
            if noun != None :
                self.randomDescribe(noun,verb,atAge,freq)
            else :
                self.describe(verb,atAge)
        self.sources = None            
                        
    # special phrase for burial (note, pass None for verb when create the event)
    # was buried (in addr) (in place)
    def FormatBurial(self) :
        if self.phrase != None : return self.phrase
        addr = self.event.evaluateExpression_("ADDR")
        self.phrase = ""
        if addr :
            addr = SafeTex(', '.join(CompactLines(addr)))
            self.phrase = "was buried in "+addr
            if self.place :
                self.phrase += " in "+self.place
        elif self.place :
            self.phrase = "was buried in "+self.place
        return self.phrase
    
    # special phrase for census
    # In (the date or one) census for (place), person is listed (with age xx) (and) (living at addr)
    # If no age or addr
    # Person is listed in (the date or one) census (for place)
    def FormatCensus(self,person) :
        if self.phrase != None : return self.phrase
        age = self.event.evaluateExpression_("AGE")
        detail = ""
        if age :
            detail = person+" is listed with age "+age
        if detail :
            start = "In "
        else :
            start = CapitalOne(person)+" is listed in "
        if self.date :
            start = start+"the "+self.date+" census"
        else :
            start = start+"one census"
        if self.place :
            start = start+" for "+self.place
        if detail:
            self.phrase = start+", "+detail
        else :
            self.phrase = start
        return self.phrase

    # phrase for cause of this event
    def FormatCause(self,verb,term="") :
        cause = SafeTex(self.event.evaluateExpression_("CAUS"))
        if not(cause) : return ""
        return SafeTex(verb+" "+cause+term)

#---------------------- BookAttribute Class

# Subclass of event for custom descriptions and safe Tex characters
# verb should be "religion was", None should be "His"
class BookAttribute(Attribute) :
    def __init__(self,evnt,verb=None,atAge=False,noun=None,freq=[.33,.67],withAddr=True) :
        Attribute.__init__(self,evnt)
        self.attribute = SafeTex(self.attribute)
        # if verb ends in " a" drop it if attribute begins in "a ", "an " or "the "
        if len(verb) > 2 :
            if verb[-2:] == " a" :
                if len(self.attribute) > 4 :
                    if self.attribute[:2] == "a " or self.attribute[:3] == "an " or self.attribute[:4] == "the " :
                        verb = verb[:-2]
        if withAddr==True :
            attAddr = evnt.evaluateExpression_("ADDR")
            if len(attAddr) > 0 :
                if len(self.place) > 0 : self.place += " "
                self.place += "at "+ ', '.join(CompactLines(attAddr))
        self.place = SafeTex(self.place)
        if verb != None :
            if noun != None :
                self.randomDescribe(noun,verb,atAge,freq)
            else :
                self.describe(verb,atAge)
        self.sources = None            

#---------------------- TeX Utilities

# convert string to safe TeX string
# Special characters are # $ % & ~ _ ^ \ { }
# Characters only in math are < > |
# Perhaps move to modulue
def SafeTex(ptext) :
    ntext = []
    lastIndex = 0
    index = 0
    last = len(ptext)
    while index < last :
        pchar = ptext[index]
        
        # special characters, put '\' before and after (if followed by space)
        if pchar in _Tspecial :
            if lastIndex < index : ntext.append(ptext[lastIndex:index])
            ntext.append('\\'+pchar)
            if index+1 < last :
                if ptext[index+1] == ' ' :
                    ntext.append('\\')
            lastIndex = index+1
        
        # special characers needed in verbatim mode
        elif pchar in _Tverbatim :
            if lastIndex < index : ntext.append(ptext[lastIndex:index])
            ntext.append('\\verb+'+pchar+'+')
            lastIndex = index+1
            
        # math characters
        elif pchar in _Ttomath :
            if lastIndex < index : ntext.append(ptext[lastIndex:index])
            ntext.append('$'+pchar+'$')
            lastIndex = index+1
        
        # replace characters
        elif pchar in _Treps :
            if lastIndex < index : ntext.append(ptext[lastIndex:index])
            ntext.append(_Trepsto[_Treps.index(pchar)])
            lastIndex = index+1   
        
        # qt characters
        elif pchar == _Tqt :
            if lastIndex < index : ntext.append(ptext[lastIndex:index])
            # First check if at end or the beginning,
            #    than check preceding or following characters
            if index+1 >= last :
                ntext.append("''")
            elif index == 0 :
                ntext.append("``")
            elif ptext[index-1] == " " :
                ntext.append("``")
            else :
                nchar = ptext[index+1]
                if nchar in _TqtTerm :
                    ntext.append("''")
                else :
                    ntext.append("``")
            lastIndex = index+1
        
        # on to next character
        index += 1
    
    # return string in no changes
    if lastIndex == 0 : return ptext
    if lastIndex < last : ntext.append(ptext[lastIndex:])
    return ''.join(ntext)

#----------------- Utilities

# Take string with multiple lines, remove empy lines and return list
def CompactLines(ntext) :
    if len(ntext) == 0 : return []
    alllines = []
    nlines = ntext.split("\n")
    for line in nlines :
        line = line.strip()
        if len(line) > 0 :
            alllines.append(line)
    return alllines

# set notes optoin to have other than default hideNone
#can be ("hideOwner","hideFamily","hideAll","hideNone")
def SetNotesOption(param) :
    global _notesOption
    _notesOption = param
    
# collect all plain text note lines for this event
# single line will be plain text. Multiple lines will
# will be sparated and trailed by double line feeds
def GetNotes(obj) :
    if _notesOption == "hideAll" : return ""
    notes = obj.notations()
    if len(notes) == 0 : return ""
    totlines = []
    texlines = []
    gdoc = FrontDocument()
    for nid in notes :
        note = gdoc.notes().objectWithID_(nid)
        if note :
            if _notesOption != "hideNone" :
                # setting is hideOwner or hideFamily
                # Owner - always hide
                # Family - hide if setting is hideFamily
                dist = note.evaluateExpression_("_DIST")
                if dist == "Owner" :
                    continue
                elif dist == "Family" and _notesOption == "hideFamily" :
                    continue
            ntext = note.notesText().strip()
            if not(ntext) : continue
            [cmnt,ctext] = GetHTMLComment(ntext,("TeX","alt"))
            if ctext != None :
                if cmnt == "TeX" :
                    texlines.append(ctext)
                elif cmnt == "alt" :
                    totlines.extend(CompactLines(ctext.strip()))
            else :
                totlines.extend(CompactLines(ntext))
    if len(totlines) > 1 :
        allText = SafeTex('\n\n'.join(totlines)+"\n\n")
    elif len(totlines) == 1 :
        allText = SafeTex(totlines[0]+" ")
    else :
        allText = ""
    if len(texlines) == 0 : return allText
    return allText + ''.join(texlines)

# return bibliogrpahy when needed
def GetBiblio() :
    return _biblio
    
# get sources and return citations
# space before, but not after
def GetSources(obj) :
    global _biblio
    sources = obj.citations()
    if len(sources) == 0 : return ""
    cites = []
    gdoc = FrontDocument()
    for source in sources :
        # if new source, add if need, or skip if not found
        if source not in _biblio.table :
            sour = gdoc.sources().objectWithID_(source)
            if not(sour) : continue
            sfs = RecordForSet(sour,0)
            _biblio.addObjectWithKey(sfs,source)
        cites.append("B"+source[1:-1])
    if len(cites) == 0 : return ""
    return " \\cite{"+','.join(cites)+"}"

# when using XeTeX can remove _Treps
def SetUnireps(reps,repsto) :
    global _Treps,_Trepsto
    _Treps = reps
    _Trepsto = repsto

#----------------- Globals

# TeX special characters
_Tspecial = ('$','%','&','_','{','}','#')
# TeX verbatim characters
_Tverbatim = ('~','^','\\')
# TeX need to be in math mode
_Ttomath = ('<','|','>')
# Tex replace characters with strings
_Treps = [u'\xa0',unichr(8220),unichr(8221),unichr(0x2028),unichr(0x25e6),unichr(0x200e),unichr(0x200f)]
_Trepsto = [" ","``","''","\n",unichr(0x2022),"",""]
# TeX special handling of quotes
_Tqt = "\""
_TqtTerm = (' ','.',',',';',':',')',']','?','}','!',u'\x0a')

# Default settings and variables
_notesOption = "hideNone"
_biblio = RecordsSet()

# handle attempt to run the modulus
if __name__ == "__main__" :
     print "This BookPreparation.py module cannot be run as a script."
     print "You should run scripts that use this module instead."

