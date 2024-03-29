(*	Descendants Generations Report Script
	GEDitCOM II Apple Script
	11 Dec 2009, by John A. Nairn

	Find any number of generations of descendants of the currently
	selected individual (or spouse in a family) and output them grouped
	by generation number.
	
	Blue links link to the record. Green links link to location within
	the report. Duplicates appear once. The second time links back to
	the first appearance (by # and by link)
	
	The report is output to GEDitCOM II report. For other options
	with the same report see "Descendants Generations Report" in the
	"Reports to Word" section or in the "Reports to Pages" section
	
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
	set thePrompt to "Enter maximum number of generations of descendants of " & iname & �
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
	-- extra events
	set numExtraEvents to number of items in extraEvents
	
	-- build report using <html> elements beginning with <div>
	set hrpt to {"<div>" & return}
	
	set end of hrpt to "<head><style type='text/css'>" & return
	set end of hrpt to "p { margin-left: 19pt;" & return
	set end of hrpt to "text-indent: -13pt; }" & return
	set end of hrpt to "blockquote { margin-left: 36pt; }" & return
	set end of hrpt to "blockquote p { margin-top: 1pt;" & return
	set end of hrpt to "margin-bottom: 1pt; }" & return
	set end of hrpt to ".fams { text-indent: 0pt; }" & return
	set end of hrpt to "a.here { color:green; }" & return
	set end of hrpt to "</style></head>" & return
	
	-- begin report with <h1> for name of source indiviual and number found
	tell application "GEDitCOM II"
		set contextInfo of every individual of front document to ""
		set fname to alternate name of indvRef
	end tell
	set numDList to number of items in DList
	set end of hrpt to "<h1>Descendants of " & fname & "</h1>" & return
	set end of hrpt to "<p style='margin-left:9pt;text-indent:0pt;'>Report prepared: " & (current date) & "<br>" & return
	set end of hrpt to "Number of generations found: " & (numDList - 1) & "<br>" & return
	-- finish hrpt one number of descendants are known
	
	-- loop over each generation
	set irpt to {"<center>|"} -- the index
	set rpt to {} -- body of report
	set dNum to 1 -- descendant number
	set numDups to 0 -- number that are duplicates
	repeat with i from 1 to numDList
		tell application "GEDitCOM II" to notify progress message "Writing Generation No. " & (i - 1)
		
		-- start the generation by adding to index and inserting a header
		set end of irpt to " <a href='#g" & (i - 1) & "'>" & (i - 1) & "</a> |"
		set end of rpt to "<h2><a name='g" & (i - 1) & "'></a>Generation No. " & (i - 1) & "</h2>" & return
		
		set dGen to item i of DList -- list for this generation
		set numGen to number of items in dGen
		set j to 1
		repeat while j � numGen
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
					
					-- retrieve anchor (ID minus the @ signs)
					set aname to my makeAnchor(id)
					
					if linkNum is "" then
						-- for unique individuals, output GEDitCOM II description with options
						set des to description output options {"BD", "BP", "DD", "DP", "LINKS", "MAINLINK", "FM", "SEX"}
						set end of rpt to "<p><a name='" & aname & "'></a><b>" & dNum & ".</b> " & des
						
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
									set end of rpt to pronoun & etext & ". "
								end if
							end try
							set i to i + 3
						end repeat
					else
						-- for duplicates, provide link back to original appearance (and no description)
						set end of rpt to "<p><b>" & dNum & ".</b> " & alternate name & " (<a class='here' href='#" & aname & "'>see #" & linkNum & "</a>)"
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
				repeat while j � numGen
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
					set end of rpt to HeShe & " married an unknown spouse"
				else
					tell application "GEDitCOM II"
						tell spouse
							set end of rpt to HeShe & " married <a href='" & id & "'>" & alternate name & "</a>"
							
							-- if desired, collect details on the spouse in spouseDes
							--set spouseDes to description output options {"PRON", "BD", "BP", "DD", "DP"}
						end tell
					end tell
				end if
				
				-- marriage date and place
				tell application "GEDitCOM II"
					tell fam to set md to my eventDate("", marriage date user, marriage place)
					if md is not "" then
						set end of rpt to md & ". "
					else
						set end of rpt to ". "
					end if
				end tell
				
				-- add optionally spouse details if collected above
				if spouseDes is not "" then
					set end of rpt to spouseDes
				end if
				
				-- and box with children (unless in the final generation)
				if i < numDList then
					tell application "GEDitCOM II"
						-- family link for the children
						tell fam
							set chil to children
							set numChil to count of chil
							if numChil > 0 then
								set end of cpt to "<p class='fams'>Children of <a href='" & id & "'>" & alternate name & "</a> are:</p>" & return
							end if
						end tell
						
						-- block for the children
						if numChil > 0 then
							set end of cpt to "<blockquote>" & return
							repeat with ic from 1 to numChil
								set ichil to item ic of chil
								tell ichil
									-- begin "+" or space if child has children or not
									set chilID to evaluate expression "FAMS.CHIL"
									if chilID = "" then
										set end of cpt to "<p><i>&nbsp;&nbsp;"
									else
										set end of cpt to "<p><i>+"
									end if
									
									-- anchor to link child to subsequent appearance in this report
									set link to my makeAnchor(id)
									
									-- output name sex
									set csex to sex
									if csex is "M" then
										set csex to " (son)"
									else if csex is "F" then
										set csex to " (daughter)"
									else
										set csex to "(?)"
									end if
									set end of cpt to "<b>" & ic & ".</b> <a class='here' href='#" & link & "'>" & alternate name & "</a> " & csex
									
									-- birth date and place
									set bd to my eventDate("b:", birth date, birth place)
									if bd is not "" then
										set end of cpt to ", " & bd & ".</i>" & return
									else
										set end of cpt to "</i>" & return
									end if
								end tell
							end repeat
							set end of cpt to "</blockquote>" & return
							
						end if
					end tell
				end if -- end of children block
				
			end repeat -- end of spouses
			
			-- individual and spouse done, add children blocks
			set end of rpt to "</p>" & return & (cpt as string)
			
		end repeat -- end of one generation
		
	end repeat -- end of all generations
	
	-- end the report by ending <div> element
	set end of rpt to "</div>"
	
	-- add number found to the header along with the index
	set end of hrpt to "Number of unique descendants: " & (dNum - numDups - 2) & "</p>" & return
	set rpt to (hrpt as string) & (irpt as string) & "</center>" & return & (rpt as string)
	
	-- create a report and open it in a browser window
	tell front document of application "GEDitCOM II"
		set newreport to make new report with properties {name:"Descendant Generations of " & fname, body:rpt}
		show browser of newreport
	end tell
	
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

(* convert ID to anchor without the at signs
*)
on makeAnchor(indiID)
	set alen to number of characters in indiID
	if alen < 2 then
		return "a" & indiID
	end if
	set subset to (characters 2 thru (alen - 1) of indiID as string)
	return "a" & subset
end makeAnchor

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

(* Activate GEDitCOM II (if needed) and verify acceptable
     version is running and a document is open. Return true
     or false if script can run.
*)
on CheckAvailable(sName, vNeed)
	tell application "GEDitCOM II"
		activate
		if versionNumber < vNeed then
			user option title "The script '" & sName & �
				"' requires GEDitCOM II, Version " & vNeed & " or newer" message "Please upgrade and try again." buttons {"OK"}
			return false
		end if
		if number of documents is 0 then
			user option title "The script '" & sName & �
				"' requires a document to be open" message "Please open a document and try again." buttons {"OK"}
			return false
		end if
	end tell
	return true
end CheckAvailable
