(*	Generational Ages Report Script - a GEDitCOM II Tutorial Script
	14 NOV 2009, by John A. Nairn
	
	This script generates a report of average ages of all spouses when
	they got married and when their children were born. The report can
	be for all spouses in the file or just for spouses in the currently
	selected family records.
	
	The output is to a GEDitCOM II report window
*)

-- key properties and variables
property scriptName : "Generation Ages"
global numHusbAge, numWifeAge, numFathAge, numMothAge
global sumHusbAge, sumWifeAge, sumFathAge, sumMothAge

-- if no document is open then quit
if CheckAvailable(scriptName, 1.5) is false then return

-- choose all family or all family records in the current selected records
tell application "GEDitCOM II"
	set whichOnes to user option title "Get report for All or just Selected family records" buttons {"All", "Cancel", "Selected"}
	if whichOnes is "Cancel" then return
	
	-- Get of list of the choosen family records
	if whichOnes is "All" then
		set fams to every family of front document
	else
		set selRecs to selected records of front document
		set fams to {}
		repeat with selRec in selRecs
			if record type of selRec is "FAM" then
				set end of fams to selRec
			end if
		end repeat
	end if
end tell

-- No report if no family records were found
if (count of fams) is 0 then
	return "No family records were selected"
end if

-- Collect all report data in a subroutine
CollectAges(fams)

-- write to report and then done
WriteToReport()
return

(* Collect data for the generational report
*)
on CollectAges(famList)
	
	-- initialize counters
	set {numHusbAge, sumHusbAge, numFathAge, sumFathAge} to {0, 0, 0, 0}
	set {numWifeAge, sumWifeAge, numMothAge, sumMothAge} to {0, 0, 0, 0}
	
	set {fractionStepSize, nextFraction} to {0.01, 0.01} -- progress reporting interval
	set numFams to number of items in famList
	
	tell application "GEDitCOM II"
		repeat with i from 1 to numFams
			-- read family record information
			tell item i of famList
				set {husbRef, wifeRef, chilList} to {husband, wife, children}
				set mdate to marriage SDN
			end tell
			
			-- read parent birthdates
			set {hbdate, wbdate} to {0, 0}
			if husbRef is not "" then
				set hbdate to birth SDN of husbRef
			end if
			if wifeRef is not "" then
				set wbdate to birth SDN of wifeRef
			end if
			
			-- spouse ages at marriage
			if mdate > 0 and hbdate > 0 then
				set husbAge to my GetAgeSpan(hbdate, mdate)
				set {numHusbAge, sumHusbAge} to {numHusbAge + 1, sumHusbAge + husbAge}
			end if
			if mdate > 0 and wbdate > 0 then
				set wifeAge to my GetAgeSpan(wbdate, mdate)
				set {numWifeAge, sumWifeAge} to {numWifeAge + 1, sumWifeAge + wifeAge}
			end if
			
			-- spouse ages when children were born
			if hbdate > 0 or wbdate > 0 then
				repeat with chilRef in chilList
					set cbdate to birth SDN of chilRef
					if cbdate > 0 and hbdate > 0 then
						set fathAge to my GetAgeSpan(hbdate, cbdate)
						set {numFathAge, sumFathAge} to {numFathAge + 1, sumFathAge + fathAge}
					end if
					if cbdate > 0 and wbdate > 0 then
						set mothAge to my GetAgeSpan(wbdate, cbdate)
						set {numMothAge, sumMothAge} to {numMothAge + 1, sumMothAge + mothAge}
					end if
				end repeat
			end if
			
			-- time for progress
			set fractionDone to i / numFams
			if fractionDone > nextFraction then
				notify progress fraction fractionDone
				set nextFraction to nextFraction + fractionStepSize
			end if
		end repeat
	end tell
	
end CollectAges

(* Write the results not in the global variables to a
     GEDitCOM II report *)
on WriteToReport()
	
	-- build report using <html> elements beginning with <div>
	set rpt to {"<div>" & return}
	
	-- begin report with <h1> for title
	set fname to name of front document of application "GEDitCOM II"
	set end of rpt to "<h1>Generational Age Analysis in " & fname & "</h1>" & return
	
	-- start <table> and give it a caption
	set end of rpt to "<table>" & return
	set end of rpt to "<caption>" & return
	set end of rpt to "Summary of spouse ages when married and when children were born" & return
	set end of rpt to "</caption>" & return
	
	-- column labels in the <thead> section
	set end of rpt to "<thead><tr>" & return
	set end of rpt to "<th>Age Item</th><th>Husband</th><th>Wife</th>" & return
	set end of rpt to "</tr></thead>" & return
	
	-- the rows are in the <tbody> element
	set end of rpt to "<tbody>" & return
	
	-- rows for ages when married and when children were borm
	set end of rpt to InsertRow("Avg. Age at Marriage", numHusbAge, sumHusbAge, numWifeAge, sumWifeAge)
	set end of rpt to InsertRow("Avg. Age at Childbirth", numFathAge, sumFathAge, numMothAge, sumMothAge)
	
	-- end the <tbody> and <table> elements
	set end of rpt to "</tbody>" & return
	set end of rpt to "</table>" & return
	
	-- end the report by ending <div> element
	set end of rpt to "</div>"
	
	-- create a report and open it in a browser window
	tell front document of application "GEDitCOM II"
		set newreport to make new report with properties {name:"Generation Ages", body:rpt as string}
		show browser of newreport
	end tell
	
end WriteToReport

(* Insert table row with husband and wife results
*)
on InsertRow(rowLabel, numHusb, sumHusb, numWife, sumWife)
	set tr to "<tr><td>" & rowLabel & "</td><td align='"
	if numHusb > 0 then
		set tr to tr & "right'>" & RoundNum(sumHusb / numHusb, 2)
	else
		set tr to tr & "center'>-"
	end if
	set tr to tr & "</td><td align='"
	if numWife > 0 then
		set tr to tr & "right'>" & RoundNum(sumWife / numWife, 2)
	else
		set tr to tr & "center'>-"
	end if
	set tr to tr & "</td></tr>" & return
	return tr
end InsertRow

(* Convert two date SDNs to years from first date to second date
*)
on GetAgeSpan(beginDate, endDate)
	return (endDate - beginDate) / 365.25
end GetAgeSpan

(* Round the number in n to the number of decimal places in numDecimals
*)
on RoundNum(n, numDecimals)
	if numDecimals = 0 then
		return round n as string
	end if
	set x to 10 ^ numDecimals
	set nstr to ((((n * x) + 0.5) div 1) / x) as string
	set decPt to offset of "." in nstr
	if decPt = 0 then
		set nstr to nstr & "."
		set extra to numDecimals
	else
		set extra to numDecimals - (number of characters in nstr) + decPt
	end if
	repeat with i from 1 to extra
		set nstr to nstr & "0"
	end repeat
	return nstr
end RoundNum

(* Activate GEDitCOM II (if needed) and verify acceptable
     version is running and a document is open. Return true
     or false if script can run.
*)
on CheckAvailable(sName, vNeed)
	tell application "GEDitCOM II"
		activate
		if versionNumber < vNeed then
			user option title "The script '" & sName & Â
				"' requires GEDitCOM II, Version " & vNeed & " or newer" message "Please upgrade and try again." buttons {"OK"}
			return false
		end if
		if number of documents is 0 then
			user option title "The script '" & sName & Â
				"' requires a document to be open" message "Please open a document and try again." buttons {"OK"}
			return false
		end if
	end tell
	return true
end CheckAvailable
