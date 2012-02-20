(*	Generational Ages Report Script
	14 NOV 2009, by John A. Nairn
	
	This script generates a report of average ages of all spouses when
	they got married and when their children were born.
	
	The report can be for all spouses in the file or just for spouses
	in the currently selected family records.
*)

-- key properties and variables
property scriptName : "Generation Ages Report"
global numHusbAge, numWifeAge, numFathAge, numMothAge
global sumHusbAge, sumWifeAge, sumFathAge, sumMothAge

(* EXTRA *)
global minHusbAge, maxHusbAge, minWifeAge, maxWifeAge
global minHusbRef, maxHusbRef, minWifeRef, maxWifeRef
global numMinHusb, numMaxHusb, numMinWife, numMaxWife
global minFathAge, maxFathAge, minMothAge, maxMothAge
global minFathRef, maxFathRef, minMothRef, maxMothRef
global numMinFath, numMaxFath, numMinMoth, numMaxMoth
(* ENDEXTRA *)

-- if no document is open then quit
if CheckAvailable(scriptName, 1.5) is false then return

-- choose all family or all family records in the currently selected records
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
--SendToTextEdit()
--SendToPages()
--SendToWord()
return

(* Write the results now in the global variables to a
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
	(* EXTRA *)
	set end of rpt to InsertRecordsRow("Youngest Spouse", minHusbRef, minWifeRef)
	set end of rpt to InsertRow("Youngest Spouse's Age", numMinHusb, minHusbAge, numMinWife, minWifeAge)
	set end of rpt to InsertRecordsRow("Oldest Spouse", maxHusbRef, maxWifeRef)
	set end of rpt to InsertRow("Oldest Spouse's Age", numMaxHusb, maxHusbAge, numMaxHusb, maxWifeAge)
	(* ENDEXTRA *)
	set end of rpt to InsertRow("Avg. Age at Childbirth", numFathAge, sumFathAge, numMothAge, sumMothAge)
	(* EXTRA *)
	set end of rpt to InsertRecordsRow("Youngest Parent", minFathRef, minMothRef)
	set end of rpt to InsertRow("Youngest Parent's Age", numMinFath, minFathAge, numMinMoth, minMothAge)
	set end of rpt to InsertRecordsRow("Oldest Parent", maxFathRef, maxMothRef)
	set end of rpt to InsertRow("Oldest Parent's Age", numMaxFath, maxFathAge, numMaxMoth, maxMothAge)
	(* ENDEXTRA *)
	
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

(* Write the results not in the global variables to a
     TextEdit document *)
on SendToTextEdit()
	set fname to name of front document of application "GEDitCOM II"
	
	-- title
	set rpt to {"Generational Age Analysis in " & fname & return & return}
	
	-- caption
	set end of rpt to "Summary of spouse ages when married and when children were born" & return & return
	
	-- column labels
	set end of rpt to "Age Item" & tab & "Husband" & tab & "Wife" & return
	
	-- rows for ages when married and when children were borm
	set end of rpt to InsertRowSep("Avg. Age at Marriage", numHusbAge, sumHusbAge, numWifeAge, sumWifeAge)
	(* EXTRA *)
	set end of rpt to InsertRecordsRowSep("Youngest Spouse", minHusbRef, minWifeRef)
	set end of rpt to InsertRowSep("Youngest Spouse's Age", numMinHusb, minHusbAge, numMinWife, minWifeAge)
	set end of rpt to InsertRecordsRowSep("Oldest Spouse", maxHusbRef, maxWifeRef)
	set end of rpt to InsertRowSep("Oldest Spouse's Age", numMaxHusb, maxHusbAge, numMaxHusb, maxWifeAge)
	(* ENDEXTRA *)
	set end of rpt to InsertRowSep("Avg. Age at Childbirth", numFathAge, sumFathAge, numMothAge, sumMothAge)
	(* EXTRA *)
	set end of rpt to InsertRecordsRowSep("Youngest Parent", minFathRef, minMothRef)
	set end of rpt to InsertRowSep("Youngest Parent's Age", numMinFath, minFathAge, numMinMoth, minMothAge)
	set end of rpt to InsertRecordsRowSep("Oldest Parent", maxFathRef, maxMothRef)
	set end of rpt to InsertRowSep("Oldest Parent's Age", numMaxFath, maxFathAge, numMaxMoth, maxMothAge)
	(* ENDEXTRA *)
	
	set rptText to rpt as text
	tell application "TextEdit"
		activate
		make new document with properties {name:"Generational Ages", text:rptText}
		tell text of front document
			set size of every paragraph to 12
			set font of every paragraph to "Helvetica"
			set size of first paragraph to 14
			set font of paragraph 3 to "Helvetica Oblique"
			set font of paragraph 5 to "Helvetica Bold"
		end tell
	end tell
end SendToTextEdit

(* Write the results not in the global variables to a
     Pages document *)
on SendToPages()
	set fname to name of front document of application "GEDitCOM II"
	
	tell application "Pages"
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
	(* EXTRA *)
	set end of rpt to InsertRecordsRowList("Youngest Spouse", minHusbRef, minWifeRef)
	set end of rpt to InsertRowList("Youngest Spouse's Age", numMinHusb, minHusbAge, numMinWife, minWifeAge)
	set end of rpt to InsertRecordsRowList("Oldest Spouse", maxHusbRef, maxWifeRef)
	set end of rpt to InsertRowList("Oldest Spouse's Age", numMaxHusb, maxHusbAge, numMaxHusb, maxWifeAge)
	(* ENDEXTRA *)
	set end of rpt to InsertRowList("Avg. Age at Childbirth", numFathAge, sumFathAge, numMothAge, sumMothAge)
	(* EXTRA *)
	set end of rpt to InsertRecordsRowList("Youngest Parent", minFathRef, minMothRef)
	set end of rpt to InsertRowList("Youngest Parent's Age", numMinFath, minFathAge, numMinMoth, minMothAge)
	set end of rpt to InsertRecordsRowList("Oldest Parent", maxFathRef, maxMothRef)
	set end of rpt to InsertRowList("Oldest Parent's Age", numMaxFath, maxFathAge, numMaxMoth, maxMothAge)
	(* ENDEXTRA *)
	
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
	
end SendToPages

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

(* Write the results not in the global variables to an
     MS Word document *)
on SendToWord()
	set fname to name of front document of application "GEDitCOM II"
	
	tell application "Microsoft Word"
		make document
		set titleFont to {name:"Times New Roman", font size:14, bold:true, italic:false}
		set titlePara to {alignment:align paragraph center}
		set captionFont to {font size:12, bold:false, italic:true}
		set captionPara to ""
		set headerFont to {bold:true, italic:false}
		set tablePara to {alignment:align paragraph left}
		set rowFont to {bold:false}
	end tell
	
	-- title
	TextToWord("Generational Age Analysis in " & fname, titleFont, titlePara)
	TextToWord(return & return, "", "")
	
	-- caption
	TextToWord("Summary of spouse ages when married and when children were born", captionFont, captionPara)
	TextToWord(return & return, "", "")
	
	-- first row is column labels
	tell selection of application "Microsoft Word"
		set tableStart to selection end
	end tell
	TextToWord("Age Item" & tab & "Husband" & tab & "Wife" & return, headerFont, tablePara)
	
	-- rows for ages when married and when children were borm
	TextToWord(InsertRowSep("Avg. Age at Marriage", numHusbAge, sumHusbAge, numWifeAge, sumWifeAge), rowFont, "")
	(* EXTRA *)
	TextToWord(InsertRecordsRowSep("Youngest Spouse", minHusbRef, minWifeRef), "", "")
	TextToWord(InsertRowSep("Youngest Spouse's Age", numMinHusb, minHusbAge, numMinWife, minWifeAge), "", "")
	TextToWord(InsertRecordsRowSep("Oldest Spouse", maxHusbRef, maxWifeRef), "", "")
	TextToWord(InsertRowSep("Oldest Spouse's Age", numMaxHusb, maxHusbAge, numMaxHusb, maxWifeAge), "", "")
	(* ENDEXTRA *)
	TextToWord(InsertRowSep("Avg. Age at Childbirth", numFathAge, sumFathAge, numMothAge, sumMothAge), "", "")
	(* EXTRA *)
	TextToWord(InsertRecordsRowSep("Youngest Parent", minFathRef, minMothRef), "", "")
	TextToWord(InsertRowSep("Youngest Parent's Age", numMinFath, minFathAge, numMinMoth, minMothAge), "", "")
	TextToWord(InsertRecordsRowSep("Oldest Parent", maxFathRef, maxMothRef), "", "")
	TextToWord(InsertRowSep("Oldest Parent's Age", numMaxFath, maxFathAge, numMaxMoth, maxMothAge), "", "")
	(* ENDEXTRA *)
	
	tell application "Microsoft Word"
		-- select the table text and convert to MS word table
		tell selection
			set tableEnd to selection end
		end tell
		-- need this approach since separator option in convert to table broken
		set default table separator to tab
		set aDoc to the active document
		set myRange to set range text object of aDoc start tableStart end tableEnd
		set myTable to convert to table myRange table format table format grid3
		
		-- do some table formatting (avoiding methods that don't work)
		set alignment of paragraph format of text object of first row of myTable to align paragraph center
		repeat with i from 2 to 11
			repeat with j from 2 to 3
				set acell to get cell from table myTable row i column j
				set alignment of paragraph format of text object of acell to align paragraph center
			end repeat
		end repeat
	end tell
end SendToWord

(* Insert the text uses changes in font in fontStyle and change in
     paragraph style in paraStyle. Either can be "" to ignore
*)
on TextToWord(theText, fontStyle, paraStyle)
	tell application "Microsoft Word"
		tell selection
			if fontStyle is not "" then
				set properties of font object to fontStyle
			end if
			if paraStyle is not "" then
				set properties of paragraph format of text object to paraStyle
			end if
			type text text theText
		end tell
	end tell
end TextToWord

(* Collect data for the generational report
*)
on CollectAges(famList)
	
	-- initialize counters
	set {numHusbAge, sumHusbAge, numFathAge, sumFathAge} to {0, 0, 0, 0}
	set {numWifeAge, sumWifeAge, numMothAge, sumMothAge} to {0, 0, 0, 0}
	
	(* EXTRA *)
	-- extrema
	set {minHusbAge, minHusbRef, numMinHusb} to {200, "", 0}
	set {maxHusbAge, maxHusbRef, numMaxHusb} to {0, "", 0}
	set {minWifeAge, minWifeRef, numMinWife} to {200, "", 0}
	set {maxWifeAge, maxWifeRef, numMaxWife} to {0, "", 0}
	set {minFathAge, minFathRef, numMinFath} to {200, "", 0}
	set {maxFathAge, maxFathRef, numMaxFath} to {0, "", 0}
	set {minMothAge, minMothRef, numMinMoth} to {200, "", 0}
	set {maxMothAge, maxMothRef, numMaxMoth} to {0, "", 0}
	(* ENDEXTRA *)
	
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
			if mdate > 0 then
				if hbdate > 0 then
					set husbAge to my GetAgeSpan(hbdate, mdate)
					set {numHusbAge, sumHusbAge} to {numHusbAge + 1, sumHusbAge + husbAge}
					(* EXTRA *)
					if husbAge < minHusbAge then
						set {minHusbAge, minHusbRef, numMinHusb} to {husbAge, husbRef, 1}
					end if
					if husbAge > maxHusbAge then
						set {maxHusbAge, maxHusbRef, numMaxHusb} to {husbAge, husbRef, 1}
					end if
					(* ENDEXTRA *)
				end if
				if wbdate > 0 then
					set wifeAge to my GetAgeSpan(wbdate, mdate)
					set {numWifeAge, sumWifeAge} to {numWifeAge + 1, sumWifeAge + wifeAge}
					(* EXTRA *)
					if wifeAge < minWifeAge then
						set {minWifeAge, minWifeRef, numMinWife} to {wifeAge, wifeRef, 1}
					end if
					if wifeAge > maxWifeAge then
						set {maxWifeAge, maxWifeRef, numMaxWife} to {wifeAge, wifeRef, 1}
					end if
					(* ENDEXTRA *)
				end if
			end if
			
			-- spouse ages when children were born
			if hbdate > 0 or wbdate > 0 then
				repeat with chilRef in chilList
					set cbdate to birth SDN of chilRef
					if cbdate > 0 then
						if hbdate > 0 then
							set fathAge to my GetAgeSpan(hbdate, cbdate)
							set {numFathAge, sumFathAge} to {numFathAge + 1, sumFathAge + fathAge}
							(* EXTRA *)
							if fathAge < minFathAge then
								set {minFathAge, minFathRef, numMinFath} to {fathAge, husbRef, 1}
							end if
							if fathAge > maxFathAge then
								set {maxFathAge, maxFathRef, numMaxFath} to {fathAge, husbRef, 1}
							end if
							(* ENDEXTRA *)
						end if
						if wbdate > 0 then
							set mothAge to my GetAgeSpan(wbdate, cbdate)
							set {numMothAge, sumMothAge} to {numMothAge + 1, sumMothAge + mothAge}
							(* EXTRA *)
							if mothAge < minMothAge then
								set {minMothAge, minMothRef, numMinMoth} to {mothAge, wifeRef, 1}
							end if
							if mothAge > maxMothAge then
								set {maxMothAge, maxMothRef, numMaxMoth} to {mothAge, wifeRef, 1}
							end if
							(* ENDEXTRA *)
						end if
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

(* Convert two date SDNs to years from first date to second date
*)
on GetAgeSpan(beginDate, endDate)
	return (endDate - beginDate) / 365.25
end GetAgeSpan

(* Insert table row with husband and wife results
*)
on InsertRow(rowLabel, numHusb, sumHusb, numWife, sumWife)
	set tr to "<tr><td>" & rowLabel & "</td><td align='"
	if numHusb > 0 then
		set tr to tr & "center'>" & RoundNum(sumHusb / numHusb, 2)
	else
		set tr to tr & "center'>-"
	end if
	set tr to tr & "</td><td align='"
	if numWife > 0 then
		set tr to tr & "center'>" & RoundNum(sumWife / numWife, 2)
	else
		set tr to tr & "center'>-"
	end if
	set tr to tr & "</td></tr>" & return
	return tr
end InsertRow

(* Insert table row with husband and wife results in plain text
*)
on InsertRowSep(rowLabel, numHusb, sumHusb, numWife, sumWife)
	set tr to rowLabel & tab
	if numHusb > 0 then
		set tr to tr & RoundNum(sumHusb / numHusb, 2) & tab
	else
		set tr to tr & "-" & tab
	end if
	if numWife > 0 then
		set tr to tr & RoundNum(sumWife / numWife, 2)
	else
		set tr to tr & "-"
	end if
	return tr & return
end InsertRowSep

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


(* EXTRA *)
(* Insert table row with husband and wife results into <tr> element for the row
*)
on InsertRecordsRow(rowLabel, husbRef, wifeRef)
	set tr to "<tr><td>" & rowLabel & "</td><td align='center'>"
	tell application "GEDitCOM II"
		if husbRef is not "" then
			tell husbRef
				set tr to tr & "<a href='" & (id) & "'>" & (name) & "</a>"
			end tell
		else
			set tr to tr & "-"
		end if
		set tr to tr & "</td><td align='center'>"
		if wifeRef is not "" then
			tell wifeRef
				set tr to tr & "<a href='" & (id) & "'>" & (name) & "</a>"
			end tell
		else
			set tr to tr & "-"
		end if
	end tell
	set tr to tr & "</td></tr>" & return
	return tr
end InsertRecordsRow

(* Insert table row with husband and wife results into plain text
*)
on InsertRecordsRowSep(rowLabel, husbRef, wifeRef)
	set tr to rowLabel & tab
	tell application "GEDitCOM II"
		if husbRef is not "" then
			set tr to tr & name of husbRef & tab
		else
			set tr to tr & "-" & tab
		end if
		if wifeRef is not "" then
			set tr to tr & name of wifeRef
		else
			set tr to tr & "-"
		end if
	end tell
	return tr & return
end InsertRecordsRowSep

(* Insert table row with husband and wife results into list
*)
on InsertRecordsRowList(rowLabel, husbRef, wifeRef)
	set tr to {rowLabel}
	tell application "GEDitCOM II"
		if husbRef is not "" then
			tell husbRef
				set end of tr to name
			end tell
		else
			set end of tr to "-"
		end if
		if wifeRef is not "" then
			tell wifeRef
				set end of tr to name
			end tell
		else
			set end of tr to "-"
		end if
	end tell
	return tr
end InsertRecordsRowList
(* ENDEXTRA *)

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
