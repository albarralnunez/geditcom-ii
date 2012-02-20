(*	Find Disconnected Records
	GEDitCOM II Apple Script
	12 OCT 2009, by John A. Nairn

	This script will check all family records and move all reords that
	have zero or one members to a new album.
	
	These family records are not linking any people and may not be needed
	in your file
*)

property scriptName : "Find Disconnected Records Script"
global found, lookFor, lookRec, lookRecs, newAlbum
global fractionStepSize, nextFraction, num

-- if no document is open then quit
if CheckAvailable(scriptName) is false then return

-- what to find
set findOptions to {"Disconnected Families", "Disconnected Individuals", "Unlinked Notes", Â
	"Unlinked Sources", "Unlinked Multimedia", "Unlinked Research Logs"}
set r to choose from list findOptions with prompt "What do you want to find?" default items {"Disconnected Families"}
set lookFor to item 1 of r

-- loop through all families 
tell application "GEDitCOM II"
	tell front document
		
		-- make the album
		set found to 0
		set fractionStepSize to 0.05 -- progress reporting interval
		set nextFraction to fractionStepSize -- progress reporting interval
		
		-- Disconnected Families (any family with 1 or 0 members)
		if lookFor is "Disconnected Families" then
			set lookRec to "Family"
			set lookRecs to "Families"
			set num to number of families
			repeat with i from 1 to num
				tell family i
					set members to 0
					if husband is not "" then
						set members to members + 1
					end if
					if wife is not "" then
						set members to members + 1
					end if
					set ch to children
					set members to members + (number of items in ch)
				end tell
				if members ² 1 then my MoveToAlbum(family i)
				my DoProgress(i)
			end repeat
			
			-- Disconnected Individuals (any individual with no spouses or parents)
		else if lookFor is "Disconnected Individuals" then
			set lookRec to "Individual"
			set lookRecs to "Individuals"
			set num to number of individuals
			repeat with i from 1 to num
				tell individual i
					set related to 1
					set famc to (find structures tag "FAMC")
					if number of items in famc is 0 then
						set fams to (find structures tag "FAMS")
						if number of items in fams is 0 then
							set related to 0
						end if
					end if
				end tell
				if related is 0 then my MoveToAlbum(individual i)
				my DoProgress(i)
			end repeat
			
			-- Unlinked Notes (note not referenced by any record)
		else if lookFor is "Unlinked Notes" then
			set lookRec to "Note"
			set lookRecs to "Notes"
			set num to number of notes
			repeat with i from 1 to num
				set rb to referenced by of note i
				if number of items in rb is 0 then
					my MoveToAlbum(note i)
				end if
				my DoProgress(i)
			end repeat
			
			-- Unlinked Sources (source not referenced by any record)
		else if lookFor is "Unlinked Sources" then
			set lookRec to "Source"
			set lookRecs to "Sources"
			set num to number of sources
			repeat with i from 1 to num
				set rb to referenced by of source i
				if number of items in rb is 0 then
					my MoveToAlbum(source i)
				end if
				my DoProgress(i)
			end repeat
			
			-- Unlinked Research Logs (log not referenced by any record)
		else if lookFor is "Unlinked Research Logs" then
			set lookRec to "Research Logs"
			set lookRecs to "Research Logs"
			set num to number of research logs
			repeat with i from 1 to num
				set rb to referenced by of research log i
				if number of items in rb is 0 then
					my MoveToAlbum(research log i)
				end if
				my DoProgress(i)
			end repeat
			
			-- Unlinked Multimedia (object not referenced by any record)
		else if lookFor is "Unlinked Multimedia" then
			set lookRec to "Multimedia Object"
			set lookRecs to "Multimedia Objects"
			set num to number of multimedia
			repeat with i from 1 to num
				set rb to referenced by of multimedia i
				if number of items in rb is 0 then
					my MoveToAlbum(multimedia i)
				end if
				my DoProgress(i)
			end repeat
		end if
		
	end tell
	
end tell

-- alert when done
if found = 0 then
	set res to "No " & lookFor & " were found."
else if found = 1 then
	set res to "One " & lookRec & " was moved to a new '" & lookFor & "' album."
else
	set res to (found & " " & lookRecs & " were moved to a new '" & lookFor & "' album.") as string
end if
return res

-- Move a record to an album (create album if first one)
on MoveToAlbum(recRef)
	tell application "GEDitCOM II"
		tell front document
			if found is 0 then
				set newAlbum to (make new album with properties {name:lookFor})
			end if
			move recRef to newAlbum
			set found to found + 1
		end tell
	end tell
end MoveToAlbum

-- update progress if needed
on DoProgress(reci)
	set fractionDone to reci / num
	if fractionDone > nextFraction then
		tell application "GEDitCOM II"
			notify progress fraction fractionDone
		end tell
		set nextFraction to nextFraction + fractionStepSize
	end if
end DoProgress


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
