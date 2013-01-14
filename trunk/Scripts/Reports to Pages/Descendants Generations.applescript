(*	Descendants Generations To Pages Script
	GEDitCOM II Apple Script
	26 Dec 2009, by John A. Nairn

	Find any number of generations of descendants of the currently
	selected individual (or spouse in a family) and output them grouped
	by generation number.
	
	The report is output to an Pages document For other options
	with the same report see "Descendants Generations Report" in the
	"Reports" section or in the "Reports to Word" section
	   
	Customization
	1. To include extra events in the report, add three items to extraEvents property
	    below. The first item should be the GEDCOM tag for the event, the
	    second should be an event verb, third item true or false to include address).
           The verb should be choosen to make a phrase like:
	       "He was buried 1943 in New Hampshire"
	    where "was buried" is the entered verb. If address is true it will append
          "at address" after the place.
	2. For each direct descendant in this report, it lists all their spouse name along
	   with marriage date and place. You can customize to include more details on each
	   spouse as follows:
	   a. Find the comment "-- if desired, collect details on the spouse in spouseDes"
	   b. Using any scripting methods to load report details for the spouse
	   c. The simplest is to uncomment the line beginning in "set spouseDes to description"
	      adn select output options for the "description" scripting command.
	   d. You are not limite to the "description" method. You can use any scripting
	      method to load report details in the spoueDes container
*)

-- script name
property scriptName : "Descendants Generations Report"
property extraEvents : {}
-- Example: include burial events with address
--property extraEvents : {"BURI", "was buried", true}

-- set these strings for preferred style or a new language
global MaxGen

-- if no document is open then quit
if CheckAvailable(scriptName, 1.75) is false then return

-- get selected record
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
tell application "GEDitCOM II"
	set DList to my TraceDescendants(indvRef)
end tell

-- format the list into a report
WriteToReport(indvRef, DList)

return

(* Let GEDitCOM II find the Descendants. First get listed records, but those
	are in outline order (see GEDitCOM II documentation). They need to be
	rearranged into generations. When done each item of the returnd list will
	have a list for that generation with elements as follows:
	
	For Direct Descendants:
		Unique name: {gen #, indi ref}
		Duplicate name: {gen #,indi ref,integer}
	For spouses:
		Known: { gen #, indi ref, fam ref}
		Unknown: { gen #, "", fam ref}
	Where
		gen # = generation number (0 for source, 1, 2, ...) (not needed here)
		indi ref = reference to individual record or "" if unknown spouse
		fam ref = those that are spouses include link to the family record
	                		(spouses will follow associated direct decendant)
*)
on TraceDescendants(indvRef)
	-- tell GEDitCOM II to compile outline of descendants
	tell application "GEDitCOM II"
		notify progress message "Finding Descendants"
		tell front document
			show descendants indvRef generations MaxGen tree style outline
			set DList to listed records
		end tell
		close front window
		notify progress message "Arranging Descendants by Generation"
	end tell
	
	-- rearrange into generations as described above
	set numDList to count of DList
	set DGList to {}
	repeat with i from 1 to numDList
		-- read item for outline list and its gen number
		set ditem to item i of DList
		set iGen to (item 1 of ditem) + 1
		
		-- convert duplicates from {gen #, link #}  to {iGen, indi ref, 0)
		if number of items in ditem is 2 and class of item 2 of ditem is integer then
			set oldnum to item 2 of ditem
			set orig to item 2 of item oldnum of DList -- find indi ref in DList
			set ditem to {iGen - 1, orig, 0} -- actual number does not matter here
		end if
		
		-- create new generation or add to end of existing one
		if iGen > (count of DGList) then
			set end of DGList to {ditem}
		else
			set end of item iGen of DGList to ditem
		end if
	end repeat
	return DGList
end TraceDescendants

(* Get type of descendent. The style are
	Direct Descendent is {gen #,rec ref} or {gen #,rec ref,link num} if needs name link
	Spouses are {gen #,rec ref,fam ref} or {gen #,"",fam ref} for unknown spouse
	Duplicate Direct have {gen #,prev num} where prev num is number in the list
*)
on GetDescendantType(oneIndi)
	if number of items in oneIndi is 2 then
		return "direct"
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
	set numExtraEvents to number of items in extraEvents
	
	-- begin report with <h1> for name of source indiviual and number found
	tell application "GEDitCOM II"
		set contextInfo of every individual of front document to ""
		set fname to alternate name of indvRef
	end tell
	
	tell application "Pages"
		make document
		activate
		set titleStyle to {capitalization type:all caps, alignment:center, bold:true, italic:false, font size:14, font name:"Times New Roman"}
		set subTitleStyle to {capitalization type:none, bold:false, font size:12}
		
		-- genStyle may follow subTitleStyle, indiStyle of childStyle
		-- inidStyle may follow genStyle, or childStyle
		-- parentStlye may follow indiStyle or childStyle
		-- childStyle only follows parentStlye
		set genStyle to {first line indent:0, left indent:0, alignment:center, italic:true, space before:12, space after:3, font size:14}
		set indiNum to {bold:true, italic:false, font size:12}
		set indiStyle to {first line indent:0, left indent:0.2, alignment:justify, bold:false, italic:false, space before:9, space after:0, font size:12}
		set parentStyle to {first line indent:0.2, left indent:0.2, italic:false, space before:4, space after:2, font size:12}
		set childStyle to {first line indent:0.6, left indent:0.8, italic:true, space before:0, space after:1, font size:10}
		
		set hfStyle to {alignment:center, font name:"Times New Roman", font size:10, italic:true}
		tell first section of front document
			set different first page to true
			set odd header to "Descendants of " & fname
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
		end tell
	end tell
	
	set numDList to number of items in DList
	TextToPages("Descendants of " & fname & return & return, titleStyle)
	TextToPages("Report prepared: " & (current date) & return, subTitleStyle)
	TextToPages("Number of generations found: " & (numDList - 1) & return, "")
	
	-- loop over each generation
	set dNum to 1 -- descendant number
	set numDups to 0 -- number that are duplicates
	repeat with i from 1 to numDList
		tell application "GEDitCOM II" to notify progress message "Writing Generation No. " & (i - 1)
		
		TextToPages("Generation No. " & (i - 1) & return, genStyle)
		
		set dGen to item i of DList -- list for this generation
		set numGen to number of items in dGen
		set j to 1
		repeat while j ² numGen
			set dIndi to item j of dGen
			set dType to GetDescendantType(dIndi)
			set thisIndi to item 2 of dIndi
			
			-- must be a direct decendant (spouses, if any, will follow)
			tell application "GEDitCOM II"
				tell thisIndi
					-- see if a duplicate and set linkNum to previous appearance if yes
					set {linkNum, fetchFamilies, skipFamilies} to {"", false, false}
					if dType is "named direct" then
						set linkID to item 3 of dIndi
						set linkNum to contextInfo
						if linkNum is "" then
							-- first appearance in the report, if linkID is 0 will need to get families here
							set contextInfo to dNum
							if linkID = 0 then set fetchFamilies to true
						else
							-- subsequent appearance, if linkID>0 then should skip families now
							if linkID > 0 then set skipFamilies to true
						end if
					end if
					
					my TextToPages((dNum as string), indiNum)
					my TextToPages(". ", indiStyle)
					if linkNum is "" then
						-- for unique individuals, output GEDitCOM II description with options
						set des to description output options {"BD", "BP", "DD", "DP", "FM", "SEX"}
						my TextToPages(des, "")
						
						-- add extra events
						set i to 1
						if sex is "F" then
							set pronoun to "She "
						else
							set pronoun to "He "
						end if
						repeat while i < numExtraEvents
							set gtag to item i of extraEvents
							try
								set evnt to structure named gtag
								if item (i + 2) of extraEvents is true then
									set ePlace to event place plus address of evnt
								else
									set ePlace to event place of evnt
								end if
								set etext to my eventDate(item (i + 1) of extraEvents, event date user of evnt, ePlace)
								if etext is not "" then
									my TextToPages(pronoun & etext & ". ", "", "")
								end if
							end try
							set i to i + 3
						end repeat
					else
						my TextToPages(alternate name & " (see #" & linkNum & ")", "")
						-- for duplicates, provide link back to original appearance (and no description)
						set numDups to numDups + 1
					end if
					
					-- get pronoun in case needed in spouses
					set iSex to sex
					if iSex is "M" then
						set HeShe to "He"
					else
						set HeShe to "She"
					end if
					if fetchFamilies is true then set famRefs to spouse families
				end tell
				set dNum to dNum + 1 -- increment number
			end tell
			
			-- on to next descendant
			set j to j + 1
			
			-- collect families
			set fams to {}
			if fetchFamilies is true then
				-- collect families when person was a duplicate, but appeared first
				repeat with jj from 1 to count of famRefs
					set fam to item jj of famRefs
					tell application "GEDitCOM II"
						tell fam
							set spse to husband
							if spse is not "" and spse is thisIndi then
								set spse to wife
							end if
						end tell
					end tell
					set end of fams to {0, spse, fam}
				end repeat
			else
				-- collect from those that follow the individual
				repeat while j ² numGen
					set dIndi to item j of dGen
					set dType to GetDescendantType(dIndi)
					if dType is not "spouse" then exit repeat
					if skipFamilies is false then set end of fams to dIndi
					set j to j + 1
				end repeat
			end if
			
			-- Any subsequent items that are spouses are spouse for previous individual
			-- process all that are found
			set cpt to {} -- save children to after spouses are done
			repeat with jj from 1 to (count of fams)
				-- if not a spouse, exit this loop and continue to next direct descendant
				set dIndi to item jj of fams
				
				-- process this spouse
				set spouse to item 2 of dIndi
				set fam to item 3 of dIndi
				
				-- spouse's name
				-- optionally collect spouse description in spouseDes
				set spouseDes to ""
				if spouse is "" then
					my TextToPages(HeShe & " married an unknown spouse", "")
				else
					tell application "GEDitCOM II"
						tell spouse
							my TextToPages(HeShe & " married " & alternate name, "")
							-- if desired, collect details on the spouse in spouseDes
							--set spouseDes to description output options {"PRON", "BD", "BP", "DD", "DP"}
						end tell
					end tell
				end if
				
				-- marriage date and place
				tell application "GEDitCOM II"
					tell fam to set md to my eventDate("", marriage date user, marriage place)
					if md is not "" then
						my TextToPages(md & ". ", "")
					else
						my TextToPages(". ", "")
					end if
				end tell
				
				-- add optionally spouse details if collected above
				if spouseDes is not "" then
					my TextToPages(spouseDes, "")
				end if
				
				-- and box with children (unless in the final generation)
				if i < numDList then
					tell application "GEDitCOM II"
						-- family link for the children
						tell fam
							set chil to children
							set numChil to count of chil
							if numChil > 0 then
								set end of cpt to "Children of " & alternate name & " are:" & return
								set end of cpt to parentStyle
							end if
						end tell
						
						-- block for the children
						if numChil > 0 then
							repeat with ic from 1 to numChil
								set ichil to item ic of chil
								tell ichil
									-- begin "+" or space if child has children or not
									set chilID to evaluate expression "FAMS.CHIL"
									if chilID = "" then
										set cline to ""
									else
										set cline to "+"
									end if
									
									-- output name sex
									set csex to sex
									if csex is "M" then
										set csex to " (son)"
									else if csex is "F" then
										set csex to " (daughter)"
									else
										set csex to "(?)"
									end if
									set cline to cline & ic & ". " & alternate name & csex
									
									-- birth date and place
									set bd to my eventDate("b:", birth date, birth place)
									if bd is not "" then
										set end of cpt to cline & ", " & bd & "." & return
									else
										set end of cpt to cline & return
									end if
									
									-- style
									if ic is 1 then
										set end of cpt to childStyle
									else
										set end of cpt to ""
									end if
								end tell
							end repeat
							
						end if
					end tell
				end if -- end of children block
				
			end repeat -- end of spouses
			my TextToPages(return, "")
			
			-- output children blocks now
			repeat with ic from 1 to count of cpt by 2
				my TextToPages(item ic of cpt, item (ic + 1) of cpt)
			end repeat
			
			
		end repeat -- end of one generation
		
	end repeat -- end of all generations
	
	
end WriteToReport

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
		set ed to eKey & " " & theDate
	else
		set ed to ""
	end if
	if thePlace is not "" then
		if ed is "" then
			set ed to eKey
		end if
		set ed to ed & " in " & thePlace
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