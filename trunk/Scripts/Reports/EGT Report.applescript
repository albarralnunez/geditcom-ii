(*	 Report 'à la brother Éloi-Gérard Talbot' Script
	GEDitCOM II Apple Script
	11 Dec 2009, by John A. Nairn, adapted March 2011 by Stéphane Lelaure to make it a "Talbot" report.

	Find any number of generations of descendants of the currently
	selected individual (or spouse in a family) and output them grouped
	by generation number. Read the output to understand how the Talbot number system works.
	
	Blue links link to the record. Green links show duplicate individuals.
	
	The report is output to GEDitCOM II report. This report also exists with output to LaTeX.
	
	Version 1.6 20110308
	*)

-- script name
property scriptName : "EGT Descendants Generations Report"

-- set these strings for preferred style or a new language
global MaxGen

-- if no document is open then quit
if CheckAvailable(scriptName, 1.6) is false then return

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
	set thePrompt to "Enter maximum number of generations of descendants of " & iname & ¬
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
	
	set leftColNb to "" -- left-hand column family number as text
	set numFamc to 0 -- left-hand column family counter
	set prevFamcID to ""
	set rightColNb to "" -- right-hand column family number as text
	set numFams to 0 -- right-hand column family counter
	
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
	-- finish hrpt once number of descendants are known
	
	-- loop over each generation
	set irpt to {"<center>|"} -- the index
	set rpt to {} -- body of report
	set dNum to 1 -- descendant number
	set numDups to 0 -- number that are duplicates
	set thisRow to {}
	set thisPerson to ""
	set thisFams to {}
	
	repeat with i from 1 to numDList
		tell application "GEDitCOM II" to notify progress message "Writing Generation No. " & (i - 1)
		
		-- start the generation by adding to index and inserting a header
		set end of irpt to " <a href='#g" & (i - 1) & "'>" & (i - 1) & "</a> |"
		set end of rpt to "<h2><a name='g" & (i - 1) & "'></a>Generation No. " & (i - 1) & "</h2>" & return
		
		set end of rpt to "<table width='95%' border='0' cellpadding ='0' cellspacing='0'>" & return
		set end of rpt to "<col width='10%' align='right' /><col width='55%'/><col width='20%' align='center'/><col width='10%' align='right'/>" & return
		set end of rpt to "<tbody>" & return
		
		set dGen to item i of DList -- list for this generation
		set numGen to number of items in dGen
		set j to 1
		repeat while j ≤ numGen
			set dIndi to item j of dGen
			set dType to GetDescendantType(dIndi)
			set thisIndi to item 2 of dIndi
			
			-- must be a direct decendant (spouses, if any, will follow)
			tell application "GEDitCOM II"
				tell thisIndi
					
					-- get left-column number
					if i > 1 then
						set FamcID to evaluate expression "FAMC"
						if FamcID = prevFamcID then
							set leftColNb to ""
						else
							set prevFamcID to FamcID
							set numFamc to numFamc + 1
							set leftColNb to numFamc as text
						end if
					else
						set leftColNb to ""
					end if
					
					-- see if a duplicate and set linkNum to previous appearance (left number) if yes
					set {linkNum, fetchFamilies, skipFamilies} to {"", false, false}
					if dType is "named direct" then
						set linkID to item 3 of dIndi
						set linkNum to contextInfo
						if linkNum is "" then
							-- first appearance in the report, if linkID is 0 will need to get families here
							set contextInfo to numFamc
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
						set des to "<a href='" & id & "'>" & alternate name & "</a>"
						set binfo to my eventDate("", birth date user, birth place)
						set dinfo to my eventDate("", death date user, death place)
						if dinfo is not "" then
							if binfo is not "" then
								set theEvents to " (" & binfo & " – " & dinfo & ") "
							else
								set theEvents to " (d. " & dinfo & ")"
							end if
						else
							if binfo is not "" then
								set theEvents to " (" & binfo & ")"
							else
								set theEvents to ""
							end if
						end if
						
						set thisRow to "<tr><td><a name='" & aname & "'></a><p class='fams'><b>" & leftColNb & "</b></p></td>"
						set thisPerson to "<td>" & des & theEvents
					else
						-- for duplicates, provide link back to original appearance (and no description)
						set thisRow to "<tr><td><p class='fams'><b>" & leftColNb & "</b></p></td>"
						set end of thisPerson to "<td>" & alternate name & " (<a class='here' href='#" & aname & "'>see #" & linkNum & "</a>)"
						set numDups to numDups + 1
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
				repeat while j ≤ numGen
					set dIndi to item j of dGen
					set dType to GetDescendantType(dIndi)
					if dType is not "spouse" then exit repeat
					if skipFamilies is false then set end of fams to dIndi
					set j to j + 1
				end repeat
			end if
			
			-- Any subsequent items that are spouses are spouse for previous individual
			-- process all that are found
			if fams is {} then
				set thisPerson to thisPerson & "</td><td>&nbsp;</td><td>&nbsp;</td></tr>" & return
				set end of rpt to thisRow
				set end of rpt to thisPerson
				set thisRow to {}
				set thisPerson to ""
			else
				repeat with jj from 1 to (count of fams)
					-- if not a spouse, exit this loop and continue to next direct descendant
					set thisFams to {}
					set dIndi to item jj of fams
					
					-- process this spouse
					set spouse to item 2 of dIndi
					set fam to item 3 of dIndi
					
					-- spouse's name
					if spouse is "" then
						set end of thisFams to " x unknown spouse "
					else
						tell application "GEDitCOM II"
							tell spouse
								set end of thisFams to " x <a href='" & id & "'>" & alternate name & "</a>"
								
								-- parents' name
								try
									set spfather to {id of father, alternate name of father}
								on error
									set spfather to {}
								end try
								try
									set spmother to {id of mother, alternate name of mother}
								on error
									set spmother to {}
								end try
								if spmother is not {} then
									if spfather is not {} then
										set spParents to " (Parents: <a href='" & item 1 of spfather & "'>" & item 2 of spfather & "</a> and <a href='" & item 1 of spmother & "'>" & item 2 of spmother & "</a>)"
									else
										set spParents to " (Mother: <a href='" & item 1 of spmother & "'>" & item 2 of spmother & "</a>)"
									end if
								else
									if spfather is not {} then
										set spParents to " (Father: <a href='" & item 1 of spfather & "'>" & item 2 of spfather & "</a>)"
									else
										set spParents to " (Unknown parents)"
									end if
								end if
								set end of thisFams to spParents
							end tell
						end tell
					end if
					
					-- marriage date and place
					tell application "GEDitCOM II"
						tell fam to set md to my eventDate("", marriage date user, marriage place)
						if md is not "" then
							set end of thisFams to "<td> " & md & "</td> "
						else
							set end of thisFams to "<td>&nbsp;</td>"
						end if
					end tell
					
					-- right-handside column number (unless in the final generation)
					if i < numDList then
						tell application "GEDitCOM II"
							tell fam
								set numChil to count of children
								if numChil > 0 then
									set numFams to numFams + 1
									set rightColNb to numFams as text
								else
									set rightColNb to "" & return
								end if
								set end of thisFams to "<td><p class='fams'><b>" & rightColNb & "</b></p></td>" & return
							end tell
						end tell
					else
						-- no right-handside number for the final generation
						if i = numDList then
							set end of thisFams to "<td></td>"
						end if
					end if -- end of right column number block
					
					if jj > 1 then
						-- do not repeat number on the left if indi is spouse in more than 1 family
						set thisRow to "<tr><td></td>"
						-- set descendant in italics (to show it is the same individual as previously displayed)
						tell application "GEDitCOM II"
							tell thisIndi
								set thisPerson to "<td><a class='here' href='" & id & "'>" & alternate name & "</a>"
							end tell
						end tell
					end if
					
					-- build each row with both spouses
					set end of rpt to thisRow & thisPerson & thisFams & "</tr>" & return
				end repeat -- end of spouses
			end if
			
			-- individual and spouse done
			set thisPerson to {}
			
		end repeat -- end of one generation
		
		set end of rpt to "</tbody></table>"
		
	end repeat -- end of all generations
	
	-- end the report by ending <div> element
	set end of rpt to "</div>"
	
	-- add number found to the header along with the index
	set end of hrpt to "Number of unique descendants: " & (dNum - numDups - 2) & "</p>" & return
	set end of hrpt to "<p style='margin-left:9pt;text-indent:0pt;'>This report is based on the clever system of cross-reference numbers invented by an experienced genealogist, very famous in Canada especially in Quebec, marist brother Éloi-Gérard Talbot (1899-1976). He used this original and different method to classify and publish the result of his religious and civil record listings during his research on the history of eight Canadian families.<br>" & return
	set end of hrpt to "Contrary to the Quebecois genealogist’s works however, this report shows all descendants, including people who have not founded a family (children who died at an early age, religious people, single people without descendancy). Similarly, lineage through women, which the genealogies Mr Talbot reconstituted do not present, is included here, which implies systematic printing of the family names. This report also gives the name of the spouse’s parents and can print generation headers.<br>" & return
	set end of hrpt to "For further information on brother Talbot, you can read this book by Laurent Potvin: \"Eloi-Gérard Talbot. Un généalogiste chevronné\", published in 2008 and available for free in French on this website: <a href=\"http://classiques.uqac.ca/contemporains/potvin_laurent/eloi_gerard_talbot/eloi_gerard_talbot.html\">http://classiques.uqac.ca/contemporains/potvin_laurent/eloi_gerard_talbot/eloi_gerard_talbot.html</a>.</p>" & return
	set end of hrpt to "<h3>How this report works:</h3>" & return
	set end of hrpt to "<p style='margin-left:9pt;text-indent:0pt;'>The numbers on each side of the list always refer to a family (whether the spouses are married or not).<br>" & return
	set end of hrpt to "The number on the right refers to the family a person made with his/her spouse, thus to his/her children. It allows to find his/her descendancy by looking at the same number on the left further down the report. No number will be printed on the right of someone without (known) children.<br>" & return
	set end of hrpt to "The number on the left refers to the family a person was the child in, thus to the couple his/her parents made. It allows to find his/her ascendancy.  The number is printed on the left of the first child in a family only. His siblings are printed below him/her, without a number. You can find a person’s parents by finding the first number on the left up the list.<br>" & return
	set end of hrpt to "The first person in a couple is always a descendant of the first couple in the report.<br>" & return
	set end of hrpt to "If a descendant had more than one spouse, he/she is printed in green for his/her subsequent unions and all his/her families are printed with a different number in the right hand-side column.</p>" & return
	set end of hrpt to "<h3>How to use this report:</h3>" & return
	set end of hrpt to "<ol><li>Choose a couple at random in your report.</li>" & return
	set end of hrpt to "<li>Locate the number on the left of the couple. If there is no number, locate the closest number up the column. You have just gone through the elder siblings of the main spouse in the chosen couple.</li>" & return
	set end of hrpt to "<li>Take this number and find the same in the right-handside column further up the report. You will thus get to the parents of the main spouse.</li>" & return
	set end of hrpt to "<li>Repeat step 2: from left-handside number to right-handside number, you will find the main spouse’s grandparents, great grandsparents, etc in this lineage and finally reach his/her topmost ancestors, the first couple in this report.</li>" & return
	set end of hrpt to "<li>Get back to the chosen couple in step 1. If there is no number on the right, it means this couple did not have children.</li>" & return
	set end of hrpt to "<li>If there is one, locate the same number in the left-handside column further down the list. You will get the first child in the couple. If he has any, his/her siblings share the same number: they are mentioned below without a number on the left.</li>" & return
	set end of hrpt to "<li>Choose one of the children and repeat the previous step. That way you will go along the lineage down to the most recent generations.</li></ol><br>" & return
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
		set ed to eKey & "" & theDate
	else
		set ed to ""
	end if
	if thePlace is not "" then
		if ed is "" then
			set ed to eKey
		end if
		set ed to ed & ", " & thePlace
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
