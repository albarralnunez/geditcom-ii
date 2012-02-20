(*	AGE Analysis REPORT Script
	An AppleScript for GEDitCOM II
	21 JAN 2009, by John A. Nairn
	
	This script will check all individuals in the file and compile a report on ages
	at death for all individuals with known birth and death dates. The results
	will by displayed in a table and plotted in a bar chart.
*)

-- key properties and variables
property scriptName : "Age Analysis Report"
global rpt

-- if no document is open then quit
if CheckAvailable(scriptName,1.5) is false then return

-- results
set numBdays to 0
set minBday to 10000000
set minBdayRef to null
set maxSpan to 0
set minSpan to 10000000
set numSpans to 0
set maxSpanRef to null
set minSpanRef to null
set avgSpan to 0
set bars to {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}

tell application "GEDitCOM II"
	
	set fractionStepSize to 0.01 -- progress reporting interval
	set nextFraction to fractionStepSize -- progress reporting interval
	set indis to every individual in front document
	set numIndis to number of items in indis
	set indisRef to a reference to indis
	
	repeat with i from 1 to numIndis
		tell item i of indisRef
			set bday to birth SDN
			if bday > 0 then
				set numBdays to numBdays + 1
				if bday < minBday then
					set minBday to bday
					set minBdayRef to item i of indisRef
				end if
			end if
			
			set dday to death SDN
			if bday > 0 and dday > 0 then
				set numSpans to numSpans + 1
				set lifespan to dday - bday
				set avgSpan to avgSpan + lifespan
				if lifespan > maxSpan then
					set maxSpan to lifespan
					set maxSpanRef to item i of indisRef
				end if
				if lifespan < minSpan then
					set minSpan to lifespan
					set minSpanRef to item i of indisRef
				end if
				set ageIndex to (lifespan - 913.125) / 365.25 / 5 as integer
				if ageIndex < 0 then
					set ageIndex to 0
				else if ageIndex > 20 then
					set ageIndex to 20
				end if
				set ageIndex to ageIndex + 1
				set barTotal to (item ageIndex of bars) + 1
				set item ageIndex of bars to barTotal
			end if
		end tell
		
		-- time for progress
		set fractionDone to i / numIndis
		if fractionDone > nextFraction then
			notify progress fraction fractionDone
			set nextFraction to nextFraction + fractionStepSize
		end if
	end repeat
	
	set fname to name of front document
	
	set rpt to "<div>" & return
	set rpt to rpt & "<h1>Lifespan Analysis for Individuals in " & fname & "</h1>" & return
	set rpt to rpt & "<table>" & return
	
	set rpt to rpt & "<caption>" & return
	set rpt to rpt & "Summary of life spans of all individuals" & return
	set rpt to rpt & "</caption>" & return
	
	set rpt to rpt & "<thead><tr>" & return
	set rpt to rpt & "<th>Age Item</th>" & return
	set rpt to rpt & "<th>Ages in File</th>" & return
	set rpt to rpt & "</tr></thead>" & return
	
	set rpt to rpt & "<tbody>" & return
	set rpt to rpt & "<tr>" & return
	set rpt to rpt & "<td>Number of individiuals</td>" & return
	set rpt to rpt & "<td align='center'>" & numIndis & "</td>" & return
	set rpt to rpt & "</tr>" & return
	
	set rpt to rpt & "<tr>" & return
	set rpt to rpt & "<td>Number with birth dates</td>" & return
	set rpt to rpt & "<td align='center'>" & numBdays & "</td>" & return
	set rpt to rpt & "</tr>" & return
	
	if numBdays > 0 then
		my writeExtreme("Earliest birth date", minBdayRef, birth date of minBdayRef)
	end if
	
	set rpt to rpt & "<tr>" & return
	set rpt to rpt & "<td>Number with life spans</td>" & return
	set rpt to rpt & "<td align='center'>" & numSpans & "</td>" & return
	set rpt to rpt & "</tr>" & return
	
	if numSpans > 0 then
		set rpt to rpt & "<tr>" & return
		set rpt to rpt & "<td>Average age at death</td>" & return
		set avgage to my roundThis((avgSpan / numSpans) / 365.25, 2)
		set rpt to rpt & "<td align='center'>" & avgage & " years</td>" & return
		set rpt to rpt & "</tr>" & return
		
		set theSpan to my roundThis((minSpan / 365.25), 2) & " years"
		my writeExtreme("Shortest life span", minSpanRef, theSpan)
		
		set theSpan to my roundThis((maxSpan / 365.25), 2) & " years"
		my writeExtreme("Longest life span", maxSpanRef, theSpan)
	end if
	set rpt to rpt & "</tbody>" & return
	
	set rpt to rpt & "</table>" & return
	
	-- age bar chart
	set rpt to rpt & "<p>&nbsp;</p>" & return
	set rpt to rpt & "<table width='90%' class='graph'>" & return
	set rpt to rpt & "<thead>" & return
	set rpt to rpt & "<tr><th colspan='3'>"
	set rpt to rpt & "Distribution of ages for individuals with birth and death dates"
	set rpt to rpt & "</th></tr>" & return
	set rpt to rpt & "</thead>" & return
	set rpt to rpt & "<tbody>" & return
	
	set maxBar to item 1 of bars
	repeat with i from 2 to 21
		if item i of bars > maxBar then
			set maxBar to item i of bars
		end if
	end repeat
	
	repeat with i from 1 to 21
		set rpt to rpt & "<tr><td width='80'>"
		if i < 21 then
			set ageRange to (i - 1) * 5 & " to " & (5 * i - 1)
		else
			set ageRange to "100+"
		end if
		set rpt to rpt & ageRange & "</td>"
		set agePercent to 100 * (item i of bars) / maxBar
		set rpt to rpt & "<td class='bar'><div style='width: " & agePercent & "%'></div></td>"
		set agePercent to 1000 * (item i of bars) / numSpans as integer
		set agePercent to (agePercent as real) / 10
		set rpt to rpt & "<td width='35'>" & agePercent & "%</td>" & return
		set rpt to rpt & "</tr>" & return
	end repeat
	
	set rpt to rpt & "</tbody>" & return
	set rpt to rpt & "<tfoot>" & return
	set rpt to rpt & "<tr><td colspan='3'></td>" & return
	set rpt to rpt & "</tfoot>" & return
	set rpt to rpt & "</table>" & return
	
	set rpt to rpt & "</div>"
	
	tell front document
		set newreport to make new report with properties {name:"Lifespan Analysis", body:rpt}
		show browser of newreport
	end tell
	
end tell

return

(* output row of extreme name and date
*)
on writeExtreme(exTitle, exRef, exText)
	set rpt to rpt & "<tr>" & return
	set rpt to rpt & "<td>" & exTitle & "</td>" & return
	set rpt to rpt & "<td align='center'>" & exText & "</td>" & return
	set rpt to rpt & "</tr>" & return
	
	set rpt to rpt & "<tr>" & return
	set rpt to rpt & "<td>...for individual</td>" & return
	set minId to id of exRef
	set minName to name of exRef
	set rpt to rpt & "<td align='center'><a href='" & minId & "'>" & minName & "</a></td>" & return
	set rpt to rpt & "</tr>" & return
end writeExtreme

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

on roundThis(n, numDecimals)
	set x to 10 ^ numDecimals
	(((n * x) + 0.5) div 1) / x
end roundThis