(*	Check Has Died script
	GEDitCOM II Apple Script
	6 July 2009, by John A. Nairn

	To improve your data, it is useful to check the "Has Died" check box in all
	individuals who are known to be deceased, but for which no additional death
	information is known. This script will go through all (or selected) individuals
	and try to deterimine if those with no death information are likely to be
	deceased. It determines if someone is deceased by checking their birth date,
	birth dates of children, siblings, parents, looking for certain events
	(e.g., baptism, burial, cremation), and checking marriage dates. If any
	information is found that confirms the person is deceased, the box will be
	checked.
	
	If the information indicates the person could be alive, or if no information is
	found, the person is added to a report. When the script is done, the report will
	list all individuals for which it could not determine if they are living or
	deceased. To complete the process, go through the report list and check the
	"Has Died" check box for those known to be deceased.
	
	Notes:
	
	GEDitCOM II may build in a feature with even more checking. This script
	provides a similar function until that is ready
*)

-- globals
property scriptName : "Check Has Died"
global numChecked, numUncertain, todaySDN, unRpt
global maxAge, maxMotherAge, maxFatherAge, minParentAge

-- if no document is open then quit
if CheckAvailable(scriptName, 1.5) is false then return

-- get today's serial day number
tell application "GEDitCOM II"
	set todayRange to sdn range full date (date today)
	set todaySDN to item 1 of todayRange
	activate
	set whichOnes to user option title "Check for 'Has Died' for selected individuals or for all individuals" buttons {"All", "Cancel", "Selected"}
end tell

-- choose all records or selected records (with option to cancel)
if whichOnes is "Cancel" then return

-- get age limits to use when deciding if died
set maxAge to 105
set maxMotherAge to 55
set maxFatherAge to 75
set minParentAge to 15

-- start the report (list of uncertain individuals)
set unRpt to ""

-- loop through all individuals or selected ones
set numChecked to 0
set numUncertain to 0
tell application "GEDitCOM II"
	if whichOnes is "All" then
		-- do all individuals
		set recs to every individual of front document
	else
		-- do just the selected records
		set recs to selected records of front document
	end if
end tell

-- call method to process the records
tell application "GEDitCOM II"
	set fname to name of front document
	tell front document
		begin undo
		my ProcessRecords(recs)
		end undo action "Check Has Died"
	end tell
end tell

-- prepare report
set rpt to "<div>" & return

set rpt to rpt & "<h1>Checking 'Has Died' boxes in " & fname & "</h1>" & return
set rpt to rpt & "<p>"

if numChecked = 0 then
	set rpt to rpt & "No additional 'Has Died' boxes were checked. "
else if numChecked = 1 then
	set rpt to rpt & "One 'Has Died' box was checked. "
else
	set rpt to rpt & numChecked & " 'Has Died' boxes were checked. "
end if

if numUncertain = 0 then
	set rpt to rpt & "There were no record found with uncertain deceased status.</p>" & return
else
	set rpt to rpt & "For the following " & numUncertain & " individual"
	if numUncertain > 1 then
		set rpt to rpt & "s"
	end if
	set rpt to rpt & ", it could not be determined if they are deceased "
	set rpt to rpt & "(birth dates are listed if they are known). "
	set rpt to rpt & "If you know any of the listed individuals are deceased, you should "
	set rpt to rpt & "open their records in check the 'Has Died' box.</p>" & return
	
	-- add list of unknown individuals
	set rpt to rpt & "<ol>" & return & unRpt & "</ol>" & return
end if

-- end the report
set rpt to rpt & "</div>"

-- add report to document and open it
tell application "GEDitCOM II"
	tell front document
		set newreport to make new report with properties {name:"Check 'Has Died' Results", body:rpt}
		show browser of newreport
	end tell
end tell

return

(* Loop through selected records. Skip if not an individual. For individual,
	look foe DEAT structure. If already there, assume OK. If not see if
	should check "Has Died" or record as an uncertain record
*)
on ProcessRecords(recSet)
	tell application "GEDitCOM II"
		set fractionStepSize to 0.01 -- progress reporting interval
		set nextFraction to fractionStepSize -- progress reporting interval
		set num to number of items in recSet
		repeat with i from 1 to num
			set recRef to item i of recSet
			if record type of recRef is "INDI" then
				set stat to my checkLikelyDead(recRef)
				if stat is "likely" then
					-- check the Has Died box
					set numChecked to numChecked + 1
					tell recRef
						make new structure with properties {name:"DEAT", contents:"Y"}
					end tell
				else if stat is "unknown" then
					-- uncertain, add to report
					set numUncertain to numUncertain + 1
					set unRpt to unRpt & "<li><a href='" & (id of recRef) & "'>" & (name of recRef) & "</a>"
					set bd to (evaluate expression "BIRT.DATE") of recRef
					if bd is not "" then
						set unRpt to unRpt & ": born " & bd
					end if
					set unRpt to unRpt & "</li>" & return
				end if
			end if
			
			-- time for progress
			set fractionDone to i / num
			if fractionDone > nextFraction then
				notify progress fraction fractionDone
				set nextFraction to nextFraction + fractionStepSize
			end if
		end repeat
	end tell
end ProcessRecords

(* See if can determine if this person has died.
	Return "dead" is already known dead, "likely" is dead by age settings,
	"unknown" if cannot determine if dead
*)
on checkLikelyDead(INDI)
	tell application "GEDitCOM II"
		tell INDI
			try
				set deat to structure named "DEAT"
				-- Uncomment following if/end if block to check all people with
				-- any death data too, but this is discouraged by the GEDCOM standard
				--if contents of deat is not "Y" then
				--	set contents of deat to "Y"
				--end if
				return "dead"
			end try
			
			-- check birth date
			if my canVerifyDeath(evaluate expression "BIRT.DATE.sdn", maxAge) is true then
				return "likely"
			end if
			
			-- check mother's birth date
			if my canVerifyDeath(evaluate expression "FAMC.WIFE.BIRT.DATE.sdn", maxAge + maxMotherAge) is true then
				return "likely"
			end if
			
			-- check father's birth date
			if my canVerifyDeath(evaluate expression "FAMC.HUSB.BIRT.DATE.sdn", maxAge + maxFatherAge) is true then
				return "likely"
			end if
			
			-- check first marriage date
			if my canVerifyDeath(evaluate expression "FAMS.MARR.DATE.sdn", maxAge - minParentAge) is true then
				return "likely"
			end if
			
			-- read children
			set chil to children
			
		end tell
		
		-- check each child
		set nc to number of chil
		repeat with i from 1 to nc
			set chilRef to item i of chil
			tell chilRef
				if my canVerifyDeath(evaluate expression "BIRT.DATE.sdn", maxAge - minParentAge) is true then
					return "likely"
				end if
			end tell
		end repeat
		
		-- more options
		tell INDI
			-- check baptism date
			if my canVerifyDeath(evaluate expression "BAPM.DATE.sdn", maxAge) is true then
				return "likely"
			end if
			
			-- check christening date
			if my canVerifyDeath(evaluate expression "CHR.DATE.sdn", maxAge) is true then
				return "likely"
			end if
			
			-- is there a burial
			try
				set buri to structure named "BURI"
				return "likely"
			end try
			
			-- is there a cremation
			try
				set crem to structure named "CREM"
				return "likely"
			end try
			
			-- check siblings
			try
				set famc to structure named "FAMC"
			on error
				set famc to ""
			end try
			
		end tell
		
		-- check siblings
		if famc is not "" then
			set famID to (contents of famc)
			tell front document
				set chil to children of family id famID
			end tell
			set nc to number of chil
			repeat with i from 1 to nc
				set chilRef to item i of chil
				tell chilRef
					if my canVerifyDeath(evaluate expression "BIRT.DATE.sdn", maxAge + maxMotherAge - minParentAge) is true then
						return "likely"
					end if
				end tell
			end repeat
		end if
		
	end tell
	return "unknown"
end checkLikelyDead

(* Check SDN to see if more than minYears from today;
	return true if yes or false if no
*)
on canVerifyDeath(birthSDN, minYears)
	if birthSDN is "" then return false
	if birthSDN ² 0 then return false
	if my YearsBetweenSDNS(todaySDN, birthSDN) > minYears then
		return true
	end if
	return false
end canVerifyDeath

(* Find years between two SDNs
*)
on YearsBetweenSDNS(sdn1, sdn2)
	return (sdn1 - sdn2) / 356.25
end YearsBetweenSDNS

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
