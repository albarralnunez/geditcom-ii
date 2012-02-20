(*	Descendants Outline to Word
	GEDitCOM II Apple Script
	26 Dec 2009, by John A. Nairn

	Find any number of generations of descendants of the currently
	selected individual (or spouse in a family) and output them in a
	concise outline. The outline will list birth, death, and marriage
	dates if known and will show each person's sex. Spouses are
	included with a "+" sign in front.
	
	The report is output to a Pages document. For other options
	with the same report see:
	   Descendants Outline Report
	   Descendants Outline to Word
		
	To customize the output, edit the AddIndividualDetails()
	method and add any details you want for the report.
*)

property scriptName : "Descendants Outline to Word"

-- set these strings for preferred style or a new language
global titleKey, dateKey, maxgenKey, foundKey, unkSpouse
global marrKey, birthKey, deathKey, femaleKey, maleKey
global duplicateKey, dupLinkKey, MaxGen, pscale

-- if no document is open then quit
if CheckAvailable(scriptName, 1.5) is false then return

-- First find the selected individual
set indvRef to SelectedIndividual()
if indvRef is "" then
	beep
	tell application "GEDitCOM II"
		user option title "You have to select an individual or a family in GEDitCOM II to use this script" message "Select an individual and try again" buttons {"OK"}
	end tell
	return
end if

-- Get user input for number of generations (1 or higher)
tell application "GEDitCOM II"
	set iname to alternate name of indvRef
	set thePrompt to "Enter maximum number of generations of descendants of " & iname & Â
		" to include in the report"
	set r to user input prompt thePrompt initial text "4" buttons {"OK", "Cancel"}
	if item 1 of r is "Cancel" then return
	set MaxGen to item 2 of r
end tell
try
	set generations to MaxGen as integer
	if MaxGen < 1 then error
on error
	beep
	tell application "GEDitCOM II"
		user option title "The number of generations must be a number and be greater than zero." message "Try again and enter of number" buttons {"OK"}
	end tell
	return
end try

-- compile list of descendants
SetLanguageKeys()
tell application "GEDitCOM II"
	notify progress message "Finding Descendants"
	set DList to my TraceDescendants(indvRef)
	notify progress message "Preparing Report"
end tell

-- format the list into a report
WriteToReport(indvRef, DList)

return

(* Let GEDitCOM II find the Descendants. The resulting list will
	have the following
	
	For Direct Descendants:
		Unique name: {gen #, indi ref}
		First appearance duplicate name: {gen #,indi ref,link #}
		Subsequent appearances: {gen #,xref #}
	For spouses:
		Known: { gen #, indi ref, fam ref}
		Unknown: { gen #, "", fam ref}
	Where
		gen # = generation number (0 for source, 1, 2, ...)
		indi ref = reference to individual record or "" if unknown spouse
		fam ref = those that are spouses include link to the family record
	                		(spouses will be at same gen # as direct spouse)
		link # = means link number connected with subsequent duplicates
		xref # = a duplicate direct descendant and first appearance
	                was in that # element of DList. Also 3rd item of
			  previous appearance in the link number
*)
on TraceDescendants(indvRef)
	tell application "GEDitCOM II"
		tell front document
			show descendants indvRef generations MaxGen tree style outline
			set DList to listed records
		end tell
		close front window
	end tell
	return DList
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
	
	tell application "GEDitCOM II"
		set fname to alternate name of indvRef
	end tell
	
	tell application "Pages"
		make document
		activate
		set titleStyle to {alignment:center, font name:"Times New Roman", font size:14, bold:true, italic:false}
		set normalStyle to {alignment:left, font size:11, bold:false}
		
		set hfStyle to {alignment:center, font name:"Times New Roman", font size:10, italic:true}
		tell first section of front document
			set different first page to true
			set odd header to titleKey & fname
			tell paragraph 1 of odd header
				set properties to hfStyle
			end tell
			set first page footer to " " & (current date)
			tell paragraph 1 of first page footer
				set properties to hfStyle
			end tell
			set odd footer to " " & (current date)
			tell paragraph 1 of odd footer
				set properties to hfStyle
			end tell
			try
				set pheight to (height of page 1)
				if pheight < 20 then
					set pscale to 1.0 / 72
				else
					set pscale to 1.0
				end if
			on error
				set pscale to 1.0 / 72
			end try
		end tell
	end tell
	
	-- begin report with name of source indiviual and number found
	TextToPages(titleKey & fname, titleStyle)
	TextToPages(return & return, "")
	
	TextToPages(dateKey & (current date) & return, normalStyle)
	TextToPages(maxgenKey & MaxGen & return, "")
	set numDList to number of items in DList
	TextToPages(foundKey & (numDList) & return & return, "")
	
	-- loop over all descendants
	set dNum to {}
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
			if genNum ³ 0 then
				if iGen > (count of dNum) then
					set end of dNum to 0
				end if
			end if
			set genNum to iGen
		else if iGen < genNum then
			repeat with gen from genNum to iGen + 1 by -1
				set item gen of dNum to 0
			end repeat
			set genNum to iGen
			-- see if spouse in previous generation
			if dType is "spouse" then
				-- for spouse, get family
				set fam to item 3 of oneIndi
			end if
		else
			-- if same generation, see if new direct or a spouse
			if dType is "spouse" then
				-- for spouse, get family
				set fam to item 3 of oneIndi
			end if
		end if
		
		-- Preamble - indent according to generation number
		tell application "Pages"
			set listPara to {left indent:((12 * genNum + 15) * pscale), first line indent:((12 * genNum) * pscale)}
		end tell
		if fam is "" then
			if iGen = 0 then
				set num to 1
			else
				set num to (item iGen of dNum) + 1
				set item iGen of dNum to num
			end if
			my TextToPages((num as string) & ". ", listPara)
		else
			my TextToPages("+  ", listPara)
		end if
		
		set iPerson to item 2 of oneIndi
		if dType is "duplicate" then
			-- for duplicate person, just link back to original appearance
			set xref to item iPerson of DList
			set linkNum to item 3 of xref
			set iPerson to item 2 of xref
			tell application "GEDitCOM II"
				tell iPerson
					my TextToPages(alternate name, "")
				end tell
			end tell
			my TextToPages(" " & duplicateKey & " (" & dupLinkKey & linkNum & ")", "")
		else if iPerson is "" then
			-- an unknown spouse
			my TextToPages(unkSpouse, "")
			AddIndividualDetails("", fam)
		else
			-- name or an unknown spouse
			tell application "GEDitCOM II"
				-- put name (as link to record) and sex
				tell iPerson
					my TextToPages(alternate name, "")
					if linkNum > 0 then
						my TextToPages(" (#" & linkNum & ")", "")
					end if
					
					set sc to sex
					if sc is "M" then
						my TextToPages(" " & maleKey, "")
					else if sc is "F" then
						my TextToPages(" " & femaleKey, "")
					else
						my TextToPages(" (?)", "")
					end if
				end tell
			end tell
			AddIndividualDetails(iPerson, fam)
		end if
		
		my TextToPages(return, "")
		
		-- time for progress
		set fractionDone to i / numDList
		if fractionDone > nextFraction then
			tell application "GEDitCOM II" to Â
				notify progress fraction fractionDone
			set nextFraction to nextFraction + fractionStepSize
		end if
	end repeat
	
end WriteToReport

(* This subroutine can be customized to change the content of the report. It will output
	all desired information for the individual in iPerson. If fam is no "", than that
	individual is a spouse and you can optionally include information from the family
	reocrd too.
	
	This text will be placed within a parent <li> element or <div> element for spouses
	but can include othe html for formatting.
*)
on AddIndividualDetails(iPerson, fam)
	tell application "GEDitCOM II"
		
		-- for spouses output marriage date/place if known
		set conj to " "
		if fam is not "" then
			tell fam
				set md to my eventDate(marrKey, marriage date, marriage place)
			end tell
			if md is not "" then
				my TextToPages(conj & md, "")
				set conj to ", "
			end if
		end if
		
		-- exit on unknown spouse
		if iPerson is "" then return
		
		-- output birth and death dates/places if known
		tell iPerson
			set bd to my eventDate(birthKey, birth date, birth place)
			if bd is not "" then
				my TextToPages(conj & bd, "")
				set conj to ", "
			end if
			
			set dd to my eventDate(deathKey, death date, death place)
			if dd is not "" then
				my TextToPages(conj & dd, "")
			end if
			
		end tell
	end tell
end AddIndividualDetails

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
					set indvRef to wife of IndvRec
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
	tell application "GEDitCOM II"
		set lang to format language
	end tell
	if lang = "French" then
		set titleKey to "Descendants de "
		set dateKey to "Rapport prŽparŽ : "
		set maxgenKey to "Nombre maximal de gŽnŽrations : "
		set foundKey to "Nombre de descendants :  "
		set unkSpouse to "Conjoint Inconnu"
		set {marrKey, birthKey, deathKey} to {"ma: ", "n: ", "m: "}
		set {maleKey, femaleKey} to {"(M)", "(F)"}
		set duplicateKey to "double descendant"
		set dupLinkKey to "voir #"
	else
		set titleKey to "Descendants of "
		set dateKey to "Report prepared: "
		set maxgenKey to "Maximum number of generations: "
		set foundKey to "Number of descendants:  "
		set unkSpouse to "Unknown Spouse"
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