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
		my doRemove(selected records)
	end tell
end tell

-- alert when done
if found = 0 then
	set res to "No duplicates were found."
else if found = 1 then
	set res to "One duplicate line was removed."
else
	set res to (found & " duplicate data values were removed") as string
end if
return res

return

on doRemove(theRecs)
	
	set fractionStepSize to 0.05 -- progress reporting interval
	set nextFraction to fractionStepSize -- progress reporting interval
	set found to 0
	set numRecs to count of theRecs
	if numRecs is 0 then return
	
	repeat with i from 1 to numRecs
		set recRef to item i of theRecs
		removeDuplicates(recRef, "FAMS")
		removeDuplicates(recRef, "FAMC")
		
		set fractionDone to i / numRecs
		if fractionDone > nextFraction then
			tell application "GEDitCOM II"
				notify progress fraction fractionDone
			end tell
			set nextFraction to nextFraction + fractionStepSize
		end if
	end repeat
	
end doRemove

-- Move a record to an album (create album if first one)
on removeDuplicates(recRef, theTag)
	tell application "GEDitCOM II"
		tell recRef
			
			-- find {{val,@},{val,3},...}
			set sts to find structures tag theTag
			set theVals to {}
			
			repeat with j from (count of sts) to 1 by -1
				set nextFnd to item j of sts
				if number of items in nextFnd is 2 then
					-- levet 1 data
					set foundVal to item 1 of nextFnd
					if theVals contains foundVal then
						delete structure (item 2 of nextFnd)
						set found to found + 1
					else
						set end of theVals to foundVal
					end if
				end if
			end repeat
		end tell
	end tell
end removeDuplicates

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
