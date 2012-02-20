#!/usr/bin/python
#
# Ahnentafel Report (Python Script for GEDitCOM II)
# 6 DEC 2010
#
# This script reproduces the built-in Ahnentafel report in GEDitCOM II.
# If that built-in report does all you need, then there is no need to
# to use this script. But, if you wished the built-in report could
# output different information for each ancestor, this script can solve
# the problem. You can edit this script and customize in a few places
# to create any style Ahnentafel report you would like or to translate
# the report into any language.
#
# Customization
#
# Normally all customization will be confied to the few subroutines at
# the begining of the script in the section labeled "Customization Subroutines."
# The functions of each subroutine are:
#
# reportTitle(indiRef): return title for the report
# reportIntroduction(indiRef): return text to appear at the top of the report
# reportSection(gen): return label for each group of ancestors
# individualDetails(indiRef) : return content for one individual
# 
# See each subrountine comments for additional details. One way to customize is to
# translate the report. All text in the report comes from these customization routines
# and therefore by translating their output, you can translate the report
# into any language. Any template can check the global variable "lang"
# to check the currently selected language (or you can translate to any
# fixed language)
#
# Note: when the ancestors include cross links to avoid duplicates, this
# script report may find the cross links in a different order than the
# built-in report. As a result, the numbering of those that are duplicates
# or ancestors of the duplicates may differ, but both reports will have 
# complete ancestor information.

# Load Apple's Scripting Bridge for Python
from GEDitCOMII import *
from Foundation import *
from ScriptingBridge import *

################### Customization Subroutines

# Return text for the report title. The text will be enclosed in an <h1>
# element but can contain other html that works well in that element. It
# should not contain the beginning and ending <h1> elements.
# The variable indiRef is reference to the individual for the report.
def reportTitle(indiRef) :
    return "Ahenentafel Report for " + indiRef.alternateName()

# Return report introduction. This should return the entire html content for the introduction.
# For example, if it is a paragraph of text, the block should be enclosed in a <p>...</p> element.
# It can contain any valid html content.
# The variable indiRef is reference to the individual for the report.
def reportIntroduction(indiRef) :
    intro = "<p>The ancestors in this report are listed such that each person's father's" + \
    " number is double the person's number. Each person's mother's number" + \
    " in one higher than their father's number." + \
    " The following links jump to any generation starting with '0' for the individual.</p>\n"
    return intro

# Return section name for generation number in variable gen (starting with 0 for individual).
# The method should return just the text. That text will be enclosed in an <h2> element
def reportSection(gen) :
    if gen == 0 :
        return "Individual"
    elif gen == 1 :
        return "Parents"
    elif gen == 2 :
        return "Grandparents"
    elif gen == 3 :
        return "Great Grandparents"
    else :
        return "Great(" + str(gen-2) + ") Grandparents"

# Return all the information you want to appear in the report for the individual
# referenced by the variable indiRef.
# The returned text can contain any html content for formatting. The returned result
# will be placed within a list item (between <li>...</li>) and start on a new line
# below the name. You do not need to include the name, the Ahnentafel number,
# cross references, or the bounding <li> and </li> elements because those
# are automatically included by the main script.
def individualDetails(indiRef) :
    # The following two commands are a place holder that use a built-in function
    # to do the work of finding  details. Normally you will want to remove these
    # lines and replace them with custom lines to extract data and reformulate
    # in the desired language. See code below for an example.
    options = ["PRON","LINKS","BD","BP","DD","DP"]
    indiDetails = indiRef.objectDescriptionOutputOptions_(options)
    
    # The follow commented-out code is an example of extracting birth date and
    # place and formulating for output. This same model can be extended to any
    # other data you can find in a script (and you should be able to find 
    # anything you need)
    #isex = indiRef.sex()
    #if isex == "M" :
    #    pron = "He"
    #elif isex == "F" :
    #    pron = "She"
    #else :
    #    pron = "He or she"
    #bd = indiRef.birthDateUser()
    #bp = indiRef.birthPlace()
    #if bd != "" and bp != "" :
    #    indiDetails = pron+" was born on "+bd+" in "+bp+"."
    #elif bd != "" :
    #    indiDetails = pron+" was born on "+bd+"."
    #elif bp != "" :
    #    indiDetails = pron+" was born in "+bp+"."
    #else :
    #    indiDetails = ""
    
    return indiDetails

################### Classes

# Class to hold one ancestor, their Ahnentafel number, and a cross reference
# number. The Ahnentafel number is stored in a Python long which, unlike other
# language longs, is actually an arbitrary precision integer
class Billions:
    # initialize with given number of digits
    def __init__(self,value) :
        self.value = long(value)
        self.crossRefNumber = 0
        self.person = None
    
    # make a copy of this number and return the new numnber
    def copyNumber(self) :
    	bcopy = Billions(self.value)
    	return bcopy
    
    # return copy that is twice as large as the original
    def multiplyByTwo(self) :
        timesTwo = self.copyNumber()
        timesTwo.addSelf()
        return timesTwo
    
    # double this object by adding to itself
    def addSelf(self) :
        self.value = self.value + self.value
    
    # add one to the number
    def increment(self) :
        self.value += 1
    
    # string value - reverse the digits in joint into string
    def stringValue(self) :
        return str(self.value)
    
    # comparison for sorting
    def __cmp__(self,other) :
        if self.value > other.value :
            return 1
        elif self.value < other.value :
            return -1
        return 0

################### Internal Subroutines

# Rescursive add ancestors to list with ahnentafel numbers
def AddAncestor(ahnen) :
    global index,ancestors,aList,refNumber,maxGenFound
    
    # add to the list and get person details
    ancestors.append(ahnen)
    nextPerson = aList[index]
    
    # track maximum number of generations
    if nextPerson[0] > maxGenFound :
        maxGenFound = nextPerson[0]
    
	# If this person is a cross reference to a previous individual
	# set to the previous person and crossRefNumber to -refNumber
    if isinstance(nextPerson[1], int) :
        prevPerson = aList[nextPerson[1]-1]
        ahnen.person = prevPerson[1]
        ahnen.crossRefNumber = -prevPerson[2]
        return
      
    # new ancestor
    ahnen.person = nextPerson[1]
    
    # if original appearance of a duplicate, set cross reference number
    if len(nextPerson)>2 :
        ahnen.crossRefNumber = nextPerson[2]
    
    # look for father and mother
    index+=1
    if index >= len(aList) :
        return
    parentPerson = aList[index]
    
    # if next person generation is lower, then exit becuase no parents
    if parentPerson[0] <= nextPerson[0] :
        index-=1
        return
    
    # get sex of individual
    if isinstance(parentPerson[1], int) :
        parent = aList[parentPerson[1]-1][1]
    else :
        parent = parentPerson[1]
    parentSex = parent.sex()
    
    # multiply individual number by two
    parentAhnen = ahnen.multiplyByTwo()
    
    if parentSex == "M" :
        # add father at current index
        AddAncestor(parentAhnen)
        
        # look for mother too
        index+=1
        if index >= len(aList) :
            return
        motherPerson = aList[index]
        
        # if next person generation differs, then exit because not mother
        if motherPerson[0] != parentPerson[0] :
            index-=1
            return
        
        # add mother to the report with number 1 higher than father
        motherAhnen = parentAhnen.copyNumber()
        motherAhnen.increment()
        AddAncestor(motherAhnen)
    
    else :
        # add only a mother at current index and 1 higher number
        parentAhnen.increment()
        AddAncestor(parentAhnen)
          

# Let GEDitCOM II find the Ancestors. The resulting list will
# have the following
#
# For Direct Ancestors:
#    Unique name: [gen #, indi ref]
#    First appearance of duplicate name: [gen #,indi ref,link #]
#    Subsequent appearances of duplicate name: [gen #,xref #]
# Where
#    gen # = generation number (0 for source, 1, 2, ...)
#    indi ref = reference to individual record or "" if unknown spouse
#    link # = means link number to use for subsequent duplicates
#    xref # = a duplicate direct ancestor and first appearance
#             was in that # element of DList (1 based). Also 3rd item of
#             previous appearance is the link numberdef TraceAncestors(indvRef,gens) :
    outline = 0x74724F55
    indvRef.showAncestorsGenerations_treeStyle_(gens, outline)
    DList = gdoc.listedRecords()    gedit.windows()[0].closeSaving_savingIn_(0,None)    return DList# Find current selected individual. If family record is seleted, look
# for husband or wife (if husband not found). Return the individual
# or return "" is no individual is selected
def SelectedIndividual() :
    recSet = gdoc.selectedRecords()
    indvRef = ""
    if len(recSet) > 0:
        indvRef = recSet[0];
        if indvRef.recordType() == "FAM" :
            husbRef = indvRef.husband().get()
            if husbRef != "" :
                indvRef = husbRef
            else :
                indvRef = indvRef.wife().get()
        elif indvRef.recordType() != "INDI" :
            indvRef = ""
    return indvRef
            

# Verify acceptable version of GEDitCOM II is running and a document is open.
# Return 1 or 0 if script can run or not.
def CheckAvailable(gedit,sName,vNeed) :
    vnum = gedit.versionNumber()
    if vnum<vNeed:
        errMsg = "The script '" + sName + "' requires GEDitCOM II, Version "\
        + str(vNeed) + " or newer.\nPlease upgrade and try again."
        print errMsg
        return 0

    if gedit.documents().count()<1 :
        errMsg = "The script '" + sName + \
        "' requires requires a document to be open\n"\
        + "Please open a document and try again."
        print errMsg
        return 0

    return 1

################### Main Script

# Preamble
scriptName = "Ahnentafel Report"
gedit = CheckVersionAndDocument(scriptName,1.6,2)
gdoc = FrontDocument()

# current language
lang = gedit.formatLanguage()

# get selected individual
indi = GetIndividual(gdoc,"Select individual for the Ahnentafel Report")
if indi == None : quit()

# get number of ancestor generations to include in the report
iname = indi.alternateName()
aprompt = "Enter maximum number of generations of ancestors of " + iname + " to include in the report"
MaxGen = GetInteger(aprompt,None,4,1)
if MaxGen == None : quit()

# get list of ancestors
ProgressMessage(-1.,"Finding ancestors")
aList = TraceAncestors(indi,MaxGen)

# convert to list with ahnentafel numbers in a recursive function
ProgressMessage(-1.,"Calculating and sorting by Ahnentafel numbers")
firstAhnen=Billions(1);
ancestors = []
index = 0
maxGenFound = 0
AddAncestor(firstAhnen)

# Sort the ancestors list by ahnentafel number
ancestors.sort()

# create the report
ProgressMessage(-1.,"Preparing the report")
rpt = ScriptOutput(CurrentScript(),"html")
rpt.out("<h1>"+reportTitle(indi)+"</h1>\n\n")

# introduction
rpt.out(reportIntroduction(indi))

# link index
sectionLinks = ["\n<center>"]
for i in range(maxGenFound+1) :
    link = str(i)
    sectionLinks.append("<a href='#g"+link+"'>"+link+"</a> ")
sectionLinks.append("</center>\n")
theLinks=''.join(sectionLinks)
rpt.out(theLinks)

# the names by section
startSection = Billions(1)
genNumber = 0
for i in range(len(ancestors)) :
    # next ancestor
    ahnen = ancestors[i]
    
    # is this a new section
    if ahnen >= startSection :
        if genNumber>0 :
            rpt.out("</ul>\n\n")
        rpt.out("<h2><a name='g"+str(genNumber)+"'></a>")
        rpt.out(reportSection(genNumber))
        rpt.out("</h2>\n\n")
        rpt.out("<ul class='ahnen'>\n")
        startSection.addSelf()
        genNumber+=1
     
    # add ahnentafel number
    rpt.out("<li>"+ahnen.stringValue()+". ")
    
    # add name and link to the record
    rpt.out("<a href='"+ahnen.person.id()+"'>")
    rpt.out(ahnen.person.name())
    
    # add cross reference name
    if ahnen.crossRefNumber > 0 :
        linkStr=str(ahnen.crossRefNumber)
        rpt.out("<sup><font color='red'>"+linkStr+"</font></sup>")
        rpt.out("<a name='x"+ linkStr +"'></a>")
    
    # finish name link
    rpt.out("</a>\n")
    
    # add details or a cross references
    if ahnen.crossRefNumber >= 0 :
        details=individualDetails(ahnen.person)
        if len(details) > 0:
            rpt.out("<br>\n")
            rpt.out(details)
    else :
        linkStr = str(-ahnen.crossRefNumber)
        rpt.out(" (continue from <a href='#x"+linkStr+"'>link "+linkStr+"</a>)")
    
    # finish the item
    rpt.out("</li>\n")

# finish up
rpt.out("</ul>\n\n"+theLinks)

# show the report
rpt.write()
