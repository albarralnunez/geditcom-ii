(*	Descendants Script
	GEDitCOM II Apple Script
	29 Nov 2009, by John A. Nairn

	Find any number of generations of descendants of the currently
	selected individual (or spouse in a family) and output them in a
	concise outline. The outline will list birth, death, and marriage
	dates if known and will show each person's sex. Spouses are
	included with a "+" sign in front.
	
	TO customize the output, edit the AddIndividualDetails()
	method and add any details you want for the report.
	
	To Do:
	   Pages, Word, LaTeX options
*)

property scriptName : "Find Descendants Script"

-- set these strings for preferred style or a new language
global titleKey, dateKey, maxgenKey, foundKey, unkSpouse
global marrKey, birthKey, deathKey, femaleKey, maleKey
global duplicateKey, dupLinkKey, MaxGen

-- if no document is open then quit
if CheckAvailable(scriptName) is false then return

-- First find the selected individual. If a family is selected, transfer to
-- the husband or wife if they are attached
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
				set indvRef to wife of IndvRec
			end if
		end if
	end if
end tell

-- exit if did not find a selected individual
if CheckType(indvRef) is false then return

-- Get user input for number of generations (1 or higher)
tell application "GEDitCOM II"
	set iname to alternate name of indvRef
end tell
set r to display dialog Â
	"Enter maximum number of generations of " & iname & Â
	" to include in the report" default answer "4" buttons {"Cancel", "OK"} Â
	default button "OK" cancel button "Cancel" with title scriptName
if button returned of r is "Cancel" then return
set MaxGen to text returned of r
try
	set generations to MaxGen as integer
	if MaxGen < 1 then error
on error
	beep
	display dialog "The number of generations must be a number and be greater than zero." buttons {"OK"} default button "OK" with title scriptName
	return
end try

-- compile list of descendants
SetLanguageKeys()
tell application "GEDitCOM II"
	notify progress message "Finding Descendants"
	tell front document
		set contextInfo of every individual to ""
	end tell
	set NumXRefs to 0
	set NumUnknownSpouses to 0
	set DList to my TraceDescendants(indvRef, 0)
	notify progress message "Preparing Report"
end tell

-- format the list into a report
WriteToReport(indvRef, DList)

return

(* This recurive subroutine will compile all descendants of
      indvRef up to MaxGen generations. The output will be
      a single list using the global DList.
   
   Each element of the list will have an individual.
   For direct descendants the list element will be
        {gen #, indi ref} or {gen #,indi ref,link #} or {gen #,xref #}
   For spouses of direct descendnants, the list element will be
        { gen #, indi ref, fam ref}
   Here
      gen # = generation number (0 for source, 1, 2, ...)
      indi ref = reference to individual record or "" if unknown spouse
      fam ref = those that are spouses include link to the family record
	                (spouses will be at same gen # as direct spouse)
      link # = means link number connected with subsequent duplicates
      xref # = a duplicate direct descendant and first appearance
	                was in that # element of DList. Also 3rd item of
			  previous appearance in the link number
			  
     Needs globals NumXRefs and NumUnknownSpouses. When done these
	 are the number of duplicates and the number of unknown spouses
*)
on TraceDescendants(indvRef, genNum)
	tell application "GEDitCOM II"
		tell front document
			show descendants indvRef generations MaxGen tree style outline
			set DList to listed records
		end tell
		close front window
	end tell
	return DList
	
	(*tell application "GEDitCOM II"
		-- the indvRef is a direct descendant, add to list now
		set end of DList to {genNum, indvRef}
		
		-- is this a duplicate?
		set ci to contextInfo of indvRef
		if ci is not "" then
			-- if a duplicate, then add link number for original (if needed)
			if number of items in (item ci of DList) < 3 then
				set NumXRefs to NumXRefs + 1
				set end of (item ci of DList) to NumXRefs
			end if
			
			-- change indcRef to number of previous indvRef and exit
			set item 2 of last item of DList to ci
			return
		else
			-- for first appearance, set contextInfo to is location
			set contextInfo of indvRef to (count of DList)
		end if
		
		-- to continue tree, find all families with this direct
		-- descendant as a spouse
		set fams to spouse families of indvRef
		set numFams to count of fams
		if numFams is 0 then return
		
		-- loop over each family
		repeat with i from 1 to numFams
			-- retrieve the family
			set fam to item i of fams
			
			-- add spouse and family record
			-- if unknown spouse, add "" and family record
			set husbRef to husband of fam
			if husbRef is "" then
				set end of DList to {genNum, "", fam}
				set NumUnknownSpouses to NumUnknownSpouses + 1
			else if husbRef is not indvRef then
				set end of DList to {genNum, husbRef, fam}
			else
				set wifeRef to wife of fam
				if wifeRef is "" then
					set NumUnknownSpouses to NumUnknownSpouses + 1
				end if
				set end of DList to {genNum, wifeRef, fam}
			end if
			
			-- recursively call this method for all children in this family
			-- unless already reached maximum generation
			if genNum < MaxGen then
				set chils to children of fam
				repeat with c from 1 to (count of chils)
					my TraceDescendants(item c of chils, genNum + 1)
				end repeat
			end if
		end repeat
	end tell
	*)
end TraceDescendants

(* Get type of descendent. The style are
	Direct Descendent is {gen #,rec ref} or {gen #,rec ref,link num} if needs name link
	Spouses are {gen #,rec ref,fam ref} or {gen #,"",fam ref} for unknown spouse
	Duplicate Direct have {gen #,prev num} where prev num is number in the list
*)
on GetDescendantType(oneIndi)
	if number of items in oneIndi is 2 then
		if class of item 2 of oneIndi is integer then
			return "duplicate"
		else
			return "direct"
		end if
	else
		if class of item 3 of oneIndi is integer then
			return "named direct"
		else
			return "spouse" -- may be unknown spouse
		end if
	end if
end GetDescendantType

(* Write the results now in the global variables to a
     GEDitCOM II report *)
on WriteToReport(indvRef, DList)
	-- progess settings
	set {fractionStepSize, nextFraction} to {0.01, 0.01}
	
	-- build report using <html> elements beginning with <div>
	set rpt to {"<div>" & return}
	
	set end of rpt to "<head><style type='text/css'>" & return
	set end of rpt to ".chil {margin-left:-12pt;margin-top:3pt;}" & return
	set end of rpt to ".spse {text-indent:-15pt;margin-top:3pt;margin-bottom:0pt;}" & return
	set end of rpt to "</style></head>" & return
	
	-- begin report with <h1> for name of source indiviual and number found
	tell application "GEDitCOM II"
		set fName to alternate name of indvRef
	end tell
	set end of rpt to "<h1>" & titleKey & fName & "</h1>" & return
	set end of rpt to "<p>" & dateKey & (current date) & "<br>" & return
	set end of rpt to maxgenKey & MaxGen & "<br>" & return
	set numDList to number of items in DList
	set end of rpt to foundKey & (numDList - NumXRefs - NumUnknownSpouses) & "</p>" & return
	
	-- loop over all descendants
	set genNum to -1
	repeat with i from 1 to numDList
		
		-- get descendant and decode the type
		set oneIndi to item i of DList
		set dType to GetDescendantType(oneIndi)
		
		set iGen to item 1 of oneIndi
		set fam to ""
		if dType is "named direct" then
			set linkNum to item 3 of oneIndi
		else
			set linkNum to 0
		end if
		if iGen > genNum then
			-- if next generation, start an <ol> element
			if genNum < 0 then
				-- first person in the list (different margin)
				set end of rpt to return & "<ol style='margin-left:-6pt;'>" & return
			else
				set end of rpt to return & "<ol class='chil'>" & return
			end if
			set genNum to iGen
		else if iGen < genNum then
			-- if generation is done, close finished lists back to iGen
			repeat with gen from genNum to iGen + 1 by -1
				set end of rpt to return & "</ol></li>" & return
			end repeat
			set genNum to iGen
		else
			-- if same generation, see if new direct or a spouse
			if dType is "spouse" then
				-- for spouse, get family and add a return
				set fam to item 3 of oneIndi
				set end of rpt to return
			else
				-- for new direct, close previous direct
				set end of rpt to "</li>" & return
			end if
		end if
		
		-- Preamble - start <li> for direct or custom <div> for spouses
		if fam is "" then
			set end of rpt to "<li>"
		else
			set end of rpt to "<div class='spse'>+&nbsp;&nbsp;"
		end if
		
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
		else if iPerson is "" then
			-- an unknown spouse
			set end of rpt to unkSpouse
			AddIndividualDetails(rpt, "", fam)
		else
			-- name or an unknown spouse
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
			AddIndividualDetails(rpt, iPerson, fam)
		end if
		
		-- spouse (because has fam) is closed with </div> element
		if fam is not "" then
			set end of rpt to "</div>"
		end if
		
		-- time for progress
		set fractionDone to i / numDList
		if fractionDone > nextFraction then
			tell application "GEDitCOM II" to Â
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
		set newreport to make new report with properties {name:"Generation Ages", body:rpt as string}
		show browser of newreport
	end tell
	
end WriteToReport

(* This subrountine can be customized to change the content of the report. It will output
	all desired information for the individual in iPerson. If fam is no "", than that
	individual is a spouse and you can optionally include information from the family
	reocrd too.
	
	This text will be placed within a parent <li> element or <div> element for spouses
	but can include othe html for formatting.
*)
on AddIndividualDetails(rpt, iPerson, fam)
	(*tell application "GEDitCOM II"
		tell iPerson
			set res to description output options {"BD", "BP", "DD", "DP", "MD", "MP", "HESHE"}
			set end of rpt to "- " & res
		end tell
	end tell
	return
	*)
	
	tell application "GEDitCOM II"
		
		-- for spouses output marriage date/place if known
		set conj to " "
		if fam is not "" then
			tell fam
				set md to my eventDate(marrKey, marriage date, marriage place)
			end tell
			if md is not "" then
				set end of rpt to conj & md
				set conj to ", "
			end if
		end if
		
		-- exit on unknown spouse
		if iPerson is "" then return
		
		-- output birth and death dates/places if known
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
			
		end tell
	end tell
end AddIndividualDetails

(* Fiven date and place (either of which might be empty) return string to
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
		if ed is not "" then
			set ed to ed & ", "
		end if
		set ed to ed & thePlace
	end if
	return ed
end eventDate

(* Error message if selected record is not an individual
*)
on CheckType(indvRef)
	if indvRef is not "" then
		tell application "GEDitCOM II"
			if record type of indvRef is "INDI" then return true
		end tell
	end if
	beep
	display dialog "You have to select an individual in GEDitCOM II to use this script" buttons {"OK"} default button "OK" with title scriptName
	return false
end CheckType

(* Set language keys - use English if current one is not supported.
     Add more langauges by adding a new section in the conditional
*)
on SetLanguageKeys()
	tell application "GEDitCOM II" to set lang to format language
	if lang = "French" then
		set titleKey to "Descendants de "
		set dateKey to "Rapport prŽparŽ : "
		set maxgenKey to "Nombre de gŽnŽrations : "
		set foundKey to "Nombre de descendants :  "
		set unkSpouse to "Conjoint Inconnu"
		set {marrKey, birthKey, deathKey} to {"ma: ", "n: ", "m: "}
		set {maleKey, femaleKey} to {"(M)", "(F)"}
		set duplicateKey to "double descendant"
		set dupLinkKey to "voir #"
	else
		set titleKey to "Descendants of "
		set dateKey to "Report prepared: "
		set maxgenKey to "Number of generations: "
		set foundKey to "Number of descendants:  "
		set unkSpouse to "Unknown Spouse"
		set {marrKey, birthKey, deathKey} to {"m: ", "b: ", "d: "}
		set {maleKey, femaleKey} to {"(M)", "(F)"}
		set duplicateKey to "duplicate descendant"
		set dupLinkKey to "see #"
	end if
end SetLanguageKeys

(* Start GEDitCOM II (if needed) and verify that a documenbt is open
	return true or false if at least one document is open
*)
on CheckAvailable(sName)
	tell application "GEDitCOM II"
		if versionNumber < 1.29 then
			beep
			display dialog "This script requires GEDitCOM II, Version 1.3 or newer. Please upgrade and try again" buttons {"OK"} default button "OK" with title sName
			return false
		end if
		if number of documents is 0 then
			beep
			display dialog "You have to open a document in GEDitCOM II to use this script" buttons {"OK"} default button "OK" with title sName
			return false
		end if
	end tell
	return true
end CheckAvailable
