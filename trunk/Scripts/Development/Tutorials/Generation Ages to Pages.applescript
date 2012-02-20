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
	set fname to name of front document of application "GEDitCOM II"
	
	tell application "Pages"
		activate
		make document
		set titleStyle to {alignment:center, bold:true, italic:false, font size:14, font name:"Helvetica"}
		set captionStyle to {alignment:center, bold:false, italic:true, font size:12}
	end tell
	
	-- title
	TextToPages("Generational Age Analysis in " & fname, titleStyle)
	TextToPages(return & return, "")
	
	-- caption
	TextToPages("Summary of spouse ages when married and when children were born", captionStyle)
	TextToPages(return & return, "")
	
	-- build table into list of lists. Each item of list is row of the table
	
	-- first row is column labels
	set rpt to {{"Age Item", "Husband", "Wife"}}
	
	-- rows for ages when married and when children were borm
	set end of rpt to InsertRowList("Avg. Age at Marriage", numHusbAge, sumHusbAge, numWifeAge, sumWifeAge)
	set end of rpt to InsertRowList("Avg. Age at Childbirth", numFathAge, sumFathAge, numMothAge, sumMothAge)
	
	tell application "Pages"
		tell front document
			add table data rpt with header row
			set pageRec to paper size of page attributes
			set pwidth to ((width of pageRec) / 72)
			tell table 1
				set vertical position to 2 * 72
				set width to 6.25 * 72
				set leftEdge to (pwidth - 6.25) * 36
				set horizontal position to leftEdge
			end tell
		end tell
	end tell
	
end WriteToReport

(* Insert table row with husband and wife results in a list element
*)
on InsertRowList(rowLabel, numHusb, sumHusb, numWife, sumWife)
	set tr to {rowLabel}
	if numHusb > 0 then
		set end of tr to RoundNum(sumHusb / numHusb, 2)
	else
		set end of tr to "-"
	end if
	if numWife > 0 then
		set end of tr to RoundNum(sumWife / numWife, 2)
	else
		set end of tr to "-"
	end if
	return tr
end InsertRowList

(* Change current selection to theText using paragraph properties in pstyle
      When done, move the selection point to the end of the inserted text.
*)
on TextToPages(theText, textStyle)
	tell application "Pages"
		tell front document
			set nc to count of characters
			set selection to theText & " "
			set endnc to count of characters
			if textStyle is not "" then
				set nc to nc + 1
				tell characters nc thru endnc
					set properties to textStyle
				end tell
			end if
			select character endnc
			set selection to ""
		end tell
	end tell
end TextToPages

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
