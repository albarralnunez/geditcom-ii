#!/usr/bin/ruby
#
# Generational Ages Report Script
# 20 JUN 2010, by John A. Nairn
#	
# This script generates a report of average ages of all spouses when
# they got married and when their children were born.
#	
# The report can be for all spouses in the file or just for spouses
# in the currently selected family records.

# Prepare to use Apple's Scripting Bridge for Python
require "osx/cocoa"
include OSX
OSX.require_framework 'ScriptingBridge'

# Define the script name in a global variable
scriptName="Generation Ages"

################### Subroutines

# Verify acceptable version of GEDitCOM II is running and a document is open.
# Return 1 or 0 if script can run or not.
def CheckAvailable(gedit,sName,vNeed)
    if gedit.versionNumber()<vNeed
        errMsg = "The script '" + sName + "' requires GEDitCOM II, Version "\
        + vNeed.to_s + " or newer.\nPlease upgrade and try again."
        puts errMsg
        return 0
    end

    if gedit.documents().count()<1
        errMsg = "The script '" + sName + "' requires requires a document to be open\n"\
        + "Please open a document and try again."
        puts errMsg
        return 0
    end

    return 1
end

# Collect data for the generation ages report
def CollectAges(gdoc,famList)
    # initialize global counters
    $numHusbAge=$sumHusbAge=$numFathAge=$sumFathAge=0
    $numWifeAge=$sumWifeAge=$numMothAge=$sumMothAge=0
    
    # progress reporting interval
    fractionStepSize=nextFraction=0.01
    numFams=famList.length
    i=0

    famList.each do |fam|
        # read family record information
        husbRef = fam.husband()
        wifeRef = fam.wife()
        chilList = fam.children()
        mdate = fam.marriageSDN()
        
        # read parent birthdates
        hbdate = wbdate = 0
        if husbRef != ""
            hbdate = husbRef.birthSDN()
        end
        if wifeRef != ""
            wbdate = wifeRef.birthSDN()
        end
        
        # spouse ages at marriage
        if mdate>0
            if hbdate>0
                $sumHusbAge = $sumHusbAge + GetAgeSpan(hbdate,mdate)
                $numHusbAge = $numHusbAge+1
            end
           
            if wbdate>0
                $sumWifeAge = $sumWifeAge + GetAgeSpan(wbdate,mdate)
                $numWifeAge = $numWifeAge+1
            end
        end
                
        # spouse ages when children were born
        if hbdate > 0 or wbdate > 0
            chilList.each do |chilRef|
                cbdate = chilRef.birthSDN()
                if cbdate > 0 and hbdate > 0
                    $sumFathAge = $sumFathAge + GetAgeSpan(hbdate,cbdate)
                    $numFathAge = $numFathAge + 1
                end
                if cbdate > 0 and wbdate > 0
                    $sumMothAge = $sumMothAge + GetAgeSpan(wbdate,cbdate)
                    $numMothAge = $numMothAge + 1
                end
            end
        end
                    
        # time for progress
        i = i+1
        fractionDone = Float(i)/Float(numFams)
        if fractionDone > nextFraction
            gdoc.notifyProgressFraction_message_(fractionDone,nil)
            nextFraction = nextFraction+fractionStepSize
        end
    end
end

# Write the results now in the global variables to a
# GEDitCOM II report
def WriteToReport(gdoc,gedit)
    # build report using <html> elements beginning with <div>
    rpt = ["<div>\n"]
    
    # begin report with <h1> for title
    fname = gdoc.name()
    rpt.push("<h1>Generational Age Analysis in " + fname + "</h1>\n")

    # start <table> and give it a <caption>
    rpt.push("<table>\n<caption>\n")
    rpt.push("Summary of spouse ages when married and when children were born\n")
    rpt.push("</caption>\n")
    
    # column labels in the <thead> section
    rpt.push("<thead><tr>\n")
    rpt.push("<th>Age Item</th><th>Husband</th><th>Wife</th>\n")
    rpt.push("</tr></thead>\n")
    
    # the rows are in the <tbody> element
    rpt.push("<tbody>\n")
    
    # rows for ages when married and when children were borm
    rpt.push(InsertRow("Avg. Age at Marriage", $numHusbAge, $sumHusbAge, $numWifeAge, $sumWifeAge))
    rpt.push(InsertRow("Avg. Age at Childbirth", $numFathAge, $sumFathAge, $numMothAge, $sumMothAge))

    # end the <tbody> and <table> elements
    rpt.push("</tbody>\n</table>\n")
    rpt.push("</div>")
    
    # display the report
    theReport = rpt.join
    p = {"name"=>"Generational Ages","body"=>theReport}
    newReport = gedit.classForScriptingClass_("report").alloc().initWithProperties_(p)
    gdoc.reports.addObject_(newReport)
    newReport.showBrowser()
end

# Insert table row with husband and wife results
def InsertRow(rowLabel, numHusb, sumHusb, numWife, sumWife)
    tr = "<tr><td>" + rowLabel + "</td><td align='"
    if numHusb > 0
        tr = tr + "right'>%.2f" % (sumHusb / numHusb)
    else
        tr = tr + "center'>-"
    end
    tr = tr + "</td><td align='"
    if numWife > 0
        tr = tr + "right'>%.2f" % (sumWife / numWife)
    else
        tr = tr + "center'>-"
    end
    tr = tr + "</td></tr>\n"
    return tr
end

# Convert two date SDNs to years from first date to second date
def GetAgeSpan(beginDate, endDate)
    return (endDate - beginDate) / 365.25
end

################### Main Script

# fetch application object
gedit = OSX::SBApplication.applicationWithBundleIdentifier_("com.geditcom.GEDitCOMII")

# verify document is open and version is acceptable
if CheckAvailable(gedit,scriptName,1.5)==0
	exit
end

# reference to the front document
gdoc=gedit.documents[0]

# choose all or currently selected family records
whichOnes = gdoc.userOptionTitle_buttons_message_("Get report for All or just Selected family records",\
["All", "Cancel", "Selected"],nil)
if whichOnes=="Cancel"
    exit
end

# Get of list of the choosen family records
if whichOnes=="All"
    fams = gdoc.families()

else
    selRecs = gdoc.selectedRecords()
    fams = []
    selRecs.each do |fam|
        if fam.recordType()=="FAM"
            fams.push(fam)
        end
    end
end

# No report if no family records were found
if fams.length==0
    puts "No family records were selected"
    exit
end

# Collect all report data in a subroutine
CollectAges(gdoc,fams)

# write to report and then done
WriteToReport(gdoc,gedit)
