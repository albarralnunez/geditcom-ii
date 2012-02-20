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
		my findMergers(every family)
	end tell
end tell

return

on findMergers(theRecs)
	
	set fractionStepSize to 0.05 -- progress reporting interval
	set nextFraction to fractionStepSize -- progress reporting interval
	set found to 0
	
	tell application "GEDitCOM II"
		
		set famRef to item 1 of theRecs
		set ph to husband of famRef
		set pw to wife of famRef
		
		set numRecs to count of theRecs
		repeat with i from 2 to numRecs
			
			set famRef to item i of theRecs
			set h to husband of famRef
			set w to wife of famRef
			
			if h = ph and w = pw then
				my MoveToAlbum(item (i - 1) of the theRecs)
				my MoveToAlbum(famRef)
			end if
			
			-- remember previous ones
			set ph to h
			set pw to w
			
			set fractionDone to i / numRecs
			if fractionDone > nextFraction then
				notify progress fraction fractionDone
				set nextFraction to nextFraction + fractionStepSize
			end if
		end repeat
		
	end tell
	
end findMergers

-- Move a record to an album (create album if first one)
on MoveToAlbum(recRef)
	tell application "GEDitCOM II"
		tell front document
			if found is 0 then
				set newAlbum to (make new album with properties {name:"Merge Families"})
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
