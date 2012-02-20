(*	Find Disconnected Records
	GEDitCOM II Apple Script
	12 OCT 2009, by John A. Nairn

	This script will check all family records and move all reords that
	have zero or one members to a new album.
	
	These family records are not linking any people and may not be needed
	in your file
*)

property scriptName : "Find Merging Candidates Script"
global found, newAlbum

-- if no document is open then quit
if CheckAvailable(scriptName) is false then return

-- what to find

-- loop through all families 
tell application "GEDitCOM II"
	tell front document
		--my findMergers(selected records)
		my findMergers(every individual)
	end tell
end tell

return

on findMergers(theRecs)
	
	set fractionStepSize to 0.05 -- progress reporting interval
	set nextFraction to fractionStepSize -- progress reporting interval
	set found to 0
	
	tell application "GEDitCOM II"
		
		set firstMatch to 1
		set lastMatch to 1
		set hasMerged to false
		set hasUnmerged to false
		set indiRef to item 1 of theRecs
		set fullName to name of indiRef
		tell indiRef
			set gname to evaluate expression "NAME"
			set nparts to name parts gedcom name gname
			set prename to item 1 of nparts
			set psurname to item 2 of nparts
			set pfName to ""
			set pmName to ""
			try
				set pfName to word 1 of prename
				set pmName to word 2 of prename
			end try
			set mnote to evaluate expression "NOTE.view"
			if mnote is "Marion McCloud" then
				set hasMerged to true
			else
				set hasUnmerged to true
			end if
		end tell
		
		set numRecs to count of theRecs
		repeat with i from 2 to numRecs
			
			set indiRef to item i of theRecs
			set newName to name of indiRef
			tell indiRef
				set gname to evaluate expression "NAME"
				set nparts to name parts gedcom name gname
				set prename to item 1 of nparts
				set surname to item 2 of nparts
				set fName to ""
				set mName to ""
				try
					set fName to word 1 of prename
					set mName to word 2 of prename
				end try
				set mnote to evaluate expression "NOTE.view"
			end tell
			
			set match to false
			if newName is fullName then
				set match to true
			else if surname is psurname then
				set fName to ""
				set mName to ""
				try
					set fName to word 1 of prename
					set mName to word 2 of prename
				end try
				if my partName(pfName, fName) and my partName(pmName, mName) then
					set match to true
				end if
			end if
			
			-- when no match see if need to add any record
			if match is false then
				if lastMatch > firstMatch and hasMerged is true and hasUnmerged is true then
					--if lastMatch > firstMatch then
					repeat with j from firstMatch to lastMatch
						my MoveToAlbum(item j of theRecs)
					end repeat
				end if
				set firstMatch to i
				set lastMatch to i
				set hasMerged to false
				set hasUnmerged to false
			else
				set lastMatch to i
			end if
			if mnote is "Marion McCloud" then
				set hasMerged to true
			else
				set hasUnmerged to true
			end if
			
			-- remember previous ones
			set fullName to newName
			set pfName to fName
			set pmName to mName
			set psurname to surname
			
			set fractionDone to i / numRecs
			if fractionDone > nextFraction then
				notify progress fraction fractionDone
				set nextFraction to nextFraction + fractionStepSize
			end if
		end repeat
		
		-- if end in true, see if has match
		if match is true then
			if lastMatch > firstMatch and hasMerged is true and hasUnmerged is true then
				--if lastMatch > firstMatch then
				repeat with j from firstMatch to lastMatch
					my MoveToAlbum(item j of theRecs)
				end repeat
			end if
		end if
		
	end tell
	
end findMergers

on partName(n1, n2)
	
	-- match if same or one is empty
	if n1 is n2 then
		return true
	else if n1 is "" or n2 is "" then
		return true
	end if
	
	-- see if either an initial
	set l1 to ""
	if length of n1 is 2 then
		if character 2 of n1 is "." then
			set l1 to character 1 of n1
		end if
	else if length of n1 is 1 then
		set l1 to character 1 of n1
	end if
	
	set l2 to ""
	if length of n2 is 2 then
		if character 2 of n2 is "." then
			set l2 to character 1 of n2
		end if
	else if length of n2 is 1 then
		set l2 to character 1 of n2
	end if
	
	-- neither are a letter then fails
	if l1 = "" and l2 = "" then
		return false
	end if
	
	if l1 = l2 then
		return true
	else if l1 = "" then
		if l2 is character 1 of n1 then
			return true
		end if
	else if l2 = "" then
		if l1 is character 1 of n2 then
			return true
		end if
	end if
	return false
	
end partName

-- Move a record to an album (create album if first one)
on MoveToAlbum(recRef)
	tell application "GEDitCOM II"
		tell front document
			if found is 0 then
				set newAlbum to (make new album with properties {name:"Merge Candidates"})
			end if
			move recRef to newAlbum
			set found to found + 1
		end tell
	end tell
end MoveToAlbum

(* Start GEDitCOM II (if needed) and verify that a documenbt is open
	return true or false if at least one document is open
*)
on CheckAvailable(sName)
	tell application "GEDitCOM II"
		if versionNumber < 1.09 then
			display dialog "This script requires GEDitCOM II, Version 1.1 or newer. Please upgrade and try again" buttons {"OK"} default button "OK" with title sName
			return false
		end if
		if number of documents is 0 then
			display dialog "You have to open a document in GEDitCOM II to use this script" buttons {"OK"} default button "OK" with title sName
			return false
		end if
	end tell
	return true
end CheckAvailable
