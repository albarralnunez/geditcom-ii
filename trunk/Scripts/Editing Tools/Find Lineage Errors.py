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
    newCache = Person(grec,recordCache,rectype)
    recordCache[key] = newCache
    return newCache

# Cache individual record
class Person :
    def __init__(self,grec,recordCache,rectype) :
        global prefix,branch,badRec,lastRec
        thename = grec.name()
        self.key = grec.id()
        self.check = thename +" ("+grec.evaluateExpression_("span")+")"
        if rectype=="error" :
            branch.append("<li>"+prefix+"<a href='"+self.key+"'>"+self.check+"</a></li>\n")
            if self.key in branchIDs :
                badRec = [self.key,self.check]
                raise Exception()
            else :
                branchIDs[self.key] = ""
            prefix += ".."
            lastRec = [self.key,self.check]

        # look up all parents
        parfam = grec.parentFamilies()
        if parfam :
            for famc in parfam :
                f = famc.husband().get()
                if f :
                    father = lookup(recordCache,f,rectype)
                m = famc.wife().get()
                if m :
                    mother = lookup(recordCache,m,rectype)
                    
        if rectype == "error" :
            prefix = prefix[:-2]
        
################### Main Script

# fetch document
gedit = CheckVersionAndDocument("Find Lineage Errors",1.6,2)
if not(gedit) : quit()
gdoc = FrontDocument()
merging="INDI"

# to store data for speed
cache = {}
branchIDs = {}
prefix = "  "
branch = []
badRec = ["",""]
lastRec = ["",""]
lastVerify = ["",""]
firstVerify = None

# collect the records
recs = gdoc.individuals()

# display records and sort by view name
gdoc.displayByName_byType_sorting_(None,merging,"view")

# get starting record
gdoc.userSelectByType_fromList_prompt_(merging,None,"Select starting record lineage error searching")
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
    try :
        # lookup new ancestors
        rec = lookup(cache,recs[index],merging)
    except RuntimeError:
        print "\n**** Found error (see report for details) ****"
        try :
            rec = lookup(cache,recs[index],"error")
        except Exception:
            rec = None
        break
    
    # say person is done
    gdoc.notifyProgressFraction_message_(float(index)/float(len(recs)),"Verified: "+rec.check)
    lastVerify = [rec.key,rec.check]
    if firstVerify == None :
	    firstVerify = [rec.key,rec.check]
	    
    # on to next record
    index += 1

# summarize the results
rpt = ["<div>\n<h1>Lineage Errors in File "+gdoc.name()+"</h1>\n\n"]

if len(branch) == 0 :
    rpt.append("<p>No lineage errors were found in checked records from ")
    rpt.append("<a href='"+ firstVerify[0]+"'>"+ firstVerify[1]+"</a>")
    rpt.append(" to the end of the individuals.</p>")

else :
    rpt.append("<p>The following ancestral line lists ")
    rpt.append("<a href='"+ badRec[0]+"'>"+badRec[1]+"</a>")
    rpt.append(" with himself (or herself) as their own ancestor.</p>\n")    
    rpt.append("<ul>\n")
    rpt.append(''.join(branch))
    rpt.append("</ul>\n")
    rpt.append("<p>The two most likely errors are that  ")
    rpt.append("<a href='"+ badRec[0]+"'>"+badRec[1]+"</a>")
    rpt.append(" is incorrectly listed as a parent of ")
    rpt.append("<a href='"+ lastRec[0]+"'>"+ lastRec[1]+"</a>")
    rpt.append(" or that ")
    rpt.append("<a href='"+ badRec[0]+"'>"+badRec[1]+"</a>")
    rpt.append(" is incorrectly listed the child of the individual that")
    rpt.append(" appears after his or her first appearance in the above list. To fix, open ")
    rpt.append("<a href='"+ badRec[0]+"'>"+badRec[1]+"</a>")
    rpt.append(" and look for invalid parents or children of that individual.</p>")
    rpt.append("<p><b>Note</b>: This script stops when it finds the first error. After fixing ")
    rpt.append("the above error, you should therefore run the script again. ")
    rpt.append("To save time, the next run can restart from the last verified individual (")
    rpt.append("<a href='"+ lastVerify[0]+"'>"+ lastVerify[1]+"</a>). ")
    rpt.append("Keep running this script until no errors are found.</p>")

# finish up
rpt.append("</div>")

# show the report
p = {"name":"Merging Records", "body":''.join(rpt)}
newReport = gedit.classForScriptingClass_("report").alloc().initWithProperties_(p)
gdoc.reports().addObject_(newReport)
newReport.showBrowser()

