(*	Ancestors Outline Report Script
	GEDitCOM II Apple Script
	9 Dec 2009, by John A. Nairn

	Find any number of generations of ancestors of the currently
	selected individual (or spouse in a family) and output them in a
	concise outline. The outline will list birth, death, and marriage
	dates if known and will show each person's sex.
		
	The report is output to a GEDitCOM II report, which can
	be saved as an html file. For other options with the same
	report see:
	   Ancestors Outline to Pages
	   Ancestors Outline to Word
	   
	TO customize the output, edit the AddIndividualDetails()
	method and add any details you want for the report.
*)

property scriptName : "Ancestors Outline Report"

-- set these strings for preferred style or a new language
global titleKey, dateKey, maxgenKey, foundKey, unkSpouse
global marrKey, birthKey, deathKey, femaleKey, maleKey
global duplicateKey, dupLinkKey, MaxGen

-- if no document is open then quit
if CheckAvailable(scriptName, 1.5) is false then return

-- get selected record
set indvRef to SelectedIndividual()
if indvRef is "" then
	beep
	tell application "GEDitCOM II"
		user option title "You have to select an individual in GEDitCOM II to use this script" message "Select an individual and try again" buttons {"OK"}
	end tell
	return
end if

-- Get user input for number of generations (1 or higher)
tell application "GEDitCOM II"
	set iname to alternate name of indvRef
	set aprompt to "Enter maximum number of generations of ancestors of " & iname & ¬
		" to include in the report"
	set r to user input prompt aprompt initial text "4" title scriptName
end tell
if item 1 of r is "Cancel" then return
set MaxGen to item 2 of r
try
	set generations to MaxGen as integer
	if MaxGen < 1 then error
on error
	beep
	tell application "GEDitCOM II"
		user option title "The number of generations must be a number and be greater than zero." buttons {"OK"}
	end tell
	return
end try

-- compile list of descendants
SetLanguageKeys()
tell application "GEDitCOM II"
	notify progress message "Finding Ancestors"
	set DList to my TraceAncestors(indvRef)
	notify progress message "Preparing Report"
end tell

-- format the list into a report
WriteToReport(indvRef, DList)

return

(* Let GEDitCOM II find the Ancestors. The resulting list will
	have the following
	
	For Direct Ancestors:
		Unique name: {gen #, indi ref}
		First appearance duplicate name: {gen #,indi ref,link #}
		Subsequent appearances: {gen #,xref #}
	Where
		gen # = generation number (0 for source, 1, 2, ...)
		indi ref = reference to individual record or "" if unknown spouse
		link # = means link number to use for subsequent duplicates
		xref # = a duplicate direct descendant and first appearance
	                was in that # element of DList (1 based). Also 3rd item of
			  previous appearance is the link number
*)
on TraceAncestors(indvRef)
	tell application "GEDitCOM II"
		tell front document
			show ancestors indvRef generations MaxGen tree style outline
			set DList to listed records
		end tell
		close front window
	end tell
	return DList
end TraceAncestors

(* Get type of ancestor. The style are
	Direct ancestor is {gen #,rec ref} or {gen #,rec ref,link num} if needs name link
	Duplicate Direct have {gen #,prev num} where prev num is number in the list
	Spouses don't appear in ancestors
*)
on GetAncestorType(oneIndi)
	if number of items in oneIndi is 2 then
		if class of item 2 of oneIndi is integer then
			return "duplicate"
		else
			return "direct"
		end if
	else
		return "named direct"
	end if
end GetAncestorType

(* Write the results now in the global variables to a
     GEDitCOM II report *)
on WriteToReport(indvRef, DList)
	-- progess settings
	set {fractionStepSize, nextFraction} to {0.01, 0.01}
	
	-- build report using <html> elements beginning with <div>
	set rpt to {"<div>" & return}
	
	set end of rpt to "<head><style type='text/css'>" & return
	set end of rpt to ".chil {margin-left:-12pt;margin-top:3pt;}" & return
	set end of rpt to "</style></head>" & return
	
	-- begin report with <h1> for name of source indiviual and number found
	tell application "GEDitCOM II"
		set fname to alternate name of indvRef
	end tell
	set end of rpt to "<h1>" & titleKey & fname & "</h1>" & return
	set end of rpt to "<p>" & dateKey & (current date) & "<br>" & return
	set end of rpt to maxgenKey & MaxGen & "<br>" & return
	set numDList to number of items in DList
	set end of rpt to foundKey & numDList & "</p>" & return
	
	-- loop over all descendants
	set genNum to -1
	repeat with i from 1 to numDList
		
		-- get descendant and decode the type
		set oneIndi to item i of DList
		set dType to GetAncestorType(oneIndi)
		
		set iGen to item 1 of oneIndi
		if dType is "named direct" then
			set linkNum to item 3 of oneIndi
		else
			set linkNum to 0
		end if
		set firstParent to false
		if iGen > genNum then
			-- if next generation, start an <ol> element
			if genNum < 0 then
				-- first person in the list (different margin)
				set end of rpt to return & "<ol style='margin-left:-6pt;'>" & return
			else
				set end of rpt to return & "<ol class='chil'>" & return
			end if
			set genNum to iGen
			set firstParent to true
		else if iGen < genNum then
			-- if generation is done, close finished lists back to iGen
			repeat with gen from genNum to iGen + 1 by -1
				set end of rpt to return & "</ol></li>" & return
			end repeat
			set genNum to iGen
		else
			-- for same level, close previous direct
			set end of rpt to "</li>" & return
		end if
		
		-- Preamble - start <li>
		set end of rpt to "<li>"
		
		set iPerson to item 2 of oneIndi
		if dType is "duplicate" then
			-- for duplicate person, just link back to original appearance
			set xref to item iPerson of DList
			set linkNum to item 3 of xref
			set iPerson to item 2 of xref
			tell application "GEDitCOM II"
				tell iPerson
					set end of rpt to "<a href='" & (id) & "'>"
					set end of rpt to (alternate name) & "</a>"
				end tell
			end tell
			set end of rpt to " " & duplicateKey & " (<a href='#x" & linkNum & "'>" & dupLinkKey & linkNum & "</a>)"
		else
			-- name
			tell application "GEDitCOM II"
				-- put name (as link to record) and sex
				tell iPerson
					set end of rpt to "<a href='" & (id) & "'>"
					set end of rpt to (alternate name) & "</a>"
					if linkNum > 0 then
						set end of rpt to " <a name='x" & linkNum & "'></a>(#" & linkNum & ")"
					end if
					
					set sc to sex
					if sc is "M" then
						set end of rpt to " " & maleKey & return
					else if sc is "F" then
						set end of rpt to " " & femaleKey & return
					else
						set end of rpt to " (?)" & return
					end if
				end tell
			end tell
			AddIndividualDetails(rpt, iPerson, firstParent)
			
		end if
		
		-- time for progress
		set fractionDone to i / numDList
		if fractionDone > nextFraction then
			tell application "GEDitCOM II" to ¬
				notify progress fraction fractionDone
			set nextFraction to nextFraction + fractionStepSize
		end if
	end repeat
	
	-- close the list, be sure to catch all open lists
	set end of rpt to "</li>" & return
	if genNum > 0 then
		repeat with i from genNum to 1 by -1
			set end of rpt to "</ol></li>" & return
		end repeat
	end if
	set end of rpt to "</ol>" & return
	
	-- end the report by ending <div> element
	set end of rpt to "</div>"
	
	-- create a report and open it in a browser window
	tell front document of application "GEDitCOM II"
		set newreport to make new report with properties {name:titleKey & fname, body:rpt as string}
		show browser of newreport
	end tell
	
end WriteToReport

(* This subroutine can be customized to change the content of the report. It will output
	all desired information for the individual in iPerson. firstPerson will be true
	for first parent (of each couple), which can option be used to output
	details about the marriage
		
	This text will be placed within a parent <li> element but can include other
	html for formatting.
*)
on AddIndividualDetails(rpt, iPerson, firstParent)
	tell application "GEDitCOM II"
		-- output birth and death dates/places if known
		set conj to " "
		tell iPerson
			set bd to my eventDate(birthKey, birth date, birth place)
			if bd is not "" then
				set end of rpt to conj & bd
				set conj to ", "
			end if
			
			set dd to my eventDate(deathKey, death date, death place)
			if dd is not "" then
				set end of rpt to conj & dd
			end if
			
			-- add marriage details to first parent
			if firstParent is true then
				set res to description output options {"SN", "MD", "MP", "PRON", "LINKS"}
				if res is not "" then
					set end of rpt to " (" & res & ")"
				end if
			end if
			
		end tell
	end tell
end AddIndividualDetails

(* Given date and place (either of which might be empty) return string to
     include in the report. If neither there, return "". If either, start with
     eKey and add each (separated by comma if has both)

    Be sure to get safe html in case text has special characters
*)
on eventDate(eKey, theDate, thePlace)
	tell front document of application "GEDitCOM II"
		set theDate to safe html raw text theDate
		set thePlace to safe html raw text thePlace
	end tell
	if theDate is not "" then
		set ed to eKey & theDate
	else
		set ed to ""
	end if
	if thePlace is not "" then
		if ed is "" then
			set ed to eKey
		else
			set ed to ed & ", "
		end if
		set ed to ed & thePlace
	end if
	return ed
end eventDate

(* Find the selected record. If it is a family record, switch to
     the first spouse found. Finally, return "" if the selected record
     is not an indivdual record or if no record is selected
*)
on SelectedIndividual()
	tell application "GEDitCOM II"
		set indvRef to ""
		set recSet to selected records of front document
		if number of items in recSet is not 0 then
			set indvRef to item 1 of recSet
			if record type of indvRef is "FAM" then
				set husbRef to husband of indvRef
				if husbRef is not "" then
					set indvRef to husbRef
				else
					set indvRef to wife of indvRef
				end if
			end if
			if record type of indvRef is not "INDI" then
				set indvRef to ""
			end if
		end if
	end tell
	return indvRef
end SelectedIndividual

(* Set language keys - use English if current one is not supported.
     Add more langauges by adding a new section in the conditional
*)
on SetLanguageKeys()
	tell application "GEDitCOM II" to set lang to format language
	if lang = "French" then
		set titleKey to "Ancêtres de "
		set dateKey to "Rapport préparé : "
		set maxgenKey to "Nombre de générations : "
		set foundKey to "Nombre d'ancêtres :  "
		set {marrKey, birthKey, deathKey} to {"ma: ", "n: ", "m: "}
		set {maleKey, femaleKey} to {"(M)", "(F)"}
		set duplicateKey to "duplicata ancêtre"
		set dupLinkKey to "voir #"
	else
		set titleKey to "Ancestors of "
		set dateKey to "Report prepared: "
		set maxgenKey to "Number of generations: "
		set foundKey to "Number of ancestors:  "
		set {marrKey, birthKey, deathKey} to {"m: ", "b: ", "d: "}
		set {maleKey, femaleKey} to {"(M)", "(F)"}
		set duplicateKey to "duplicate descendant"
		set dupLinkKey to "see #"
	end if
end SetLanguageKeys

(* Activate GEDitCOM II (if needed) and verify acceptable
     version is running and a document is open. Return true
     or false if script can run.
*)
on CheckAvailable(sName, vNeed)
	tell application "GEDitCOM II"
		activate
		if versionNumber < vNeed then
			user option title "The script '" & sName & ¬
				"' requires GEDitCOM II, Version " & vNeed & " or newer" message "Please upgrade and try again." buttons {"OK"}
			return false
		end if
		if number of documents is 0 then
			user option title "The script '" & sName & ¬
				"' requires a document to be open" message "Please open a document and try again." buttons {"OK"}
			return false
		end if
	end tell
	return true
end CheckAvailable
