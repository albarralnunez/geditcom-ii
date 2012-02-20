(*	Find Disconnected Records
	GEDitCOM II Apple Script
	12 OCT 2009, by John A. Nairn

	This script will check various types of records (or all records)
	and move those not connected to other records to an album.
		
	These moved records may be records you would like to delete
	from the file
*)

property scriptName : "Find Disconnected Records Script"
global found

-- if no document is open then quit
if CheckAvailable(scriptName, 1.5) is false then return

-- what to find
set findOptions to {"Disconnected Records (Any Type)", "Disconnected Families", "Disconnected Individuals", Â
	"Unlinked Notes", "Unlinked Sources", "Unlinked Multimedia", Â
	"Unlinked Research Logs", "Unlinked Repositories", "Unused Places"}
tell application "GEDitCOM II"
	set r to user choice prompt "What do you want to find?" list items findOptions title scriptName
end tell
if item 1 of r is "Cancel" then return
set lookFor to item 1 of item 2 of r

-- loop through all families
set checkAsso to false
tell application "GEDitCOM II"
	tell front document
		
		-- make the album
		set newAlbum to (make new album with properties {name:lookFor})
		
		-- Disconnected Families (any family with 1 or 0 members)
		if lookFor is "Disconnected Families" then
			set lookRec to "Family"
			move (every family whose connected is false) to newAlbum
			set checkAsso to true
			
			-- Disconnected Individuals (any individual with no spouses or parents)
		else if lookFor is "Disconnected Individuals" then
			set lookRec to "Individual"
			move (every individual whose connected is false) to newAlbum
			set checkAsso to true
			
			-- Unlinked Notes (note not referenced by any record)
		else if lookFor is "Unlinked Notes" then
			set lookRec to "Note"
			move (every note whose connected is false) to newAlbum
			
			-- Unlinked Sources (source not referenced by any record)
		else if lookFor is "Unlinked Sources" then
			set lookRec to "Source"
			move (every source whose connected is false) to newAlbum
			
			-- Unlinked Research Logs (log not referenced by any record)
		else if lookFor is "Unlinked Research Logs" then
			set lookRec to "Research Logs"
			move (every research log whose connected is false) to newAlbum
			
			-- Unlinked Multimedia (object not referenced by any record)
		else if lookFor is "Unlinked Multimedia" then
			set lookRec to "Multimedia Object"
			move (every multimedia whose connected is false) to newAlbum
			
			-- Unlinked Repositories (object not referenced by any record)
		else if lookFor is "Unlinked Repositories" then
			set lookRec to "Repository"
			move (every repository whose connected is false) to newAlbum
			
			-- Unused places (object not referenced by any record)
		else if lookFor is "Unused Places" then
			set lookRec to "Place"
			move (every place whose connected is false) to newAlbum
			
			-- Unlinked Repositories (object not referenced by any record)
		else
			set lookFor to "Disconnected Records"
			set lookRec to "Record"
			move (every gedcomRecord whose connected is false) to newAlbum
			set checkAsso to true
		end if
		
		-- remove those associated with other records
		if checkAsso is true then
			my LookForAsso(newAlbum)
		end if
		
		-- how many were found?
		set found to (count of records of newAlbum)
	end tell
end tell

-- alert when done
if found = 0 then
	set res to "No " & lookFor & " were found."
	tell application "GEDitCOM II" to delete newAlbum
else if found = 1 then
	set res to "One " & lookRec & " was moved to a new '" & lookFor & "' album."
else
	set lookRecs to word 2 of lookFor
	if number of words in lookFor > 2 then
		set lookRecs to lookRecs & " " & (word 3 of lookFor)
	end if
	set res to (found & " " & lookRecs & " were moved to a new '" & lookFor & "' album.") as string
end if
return res


(* If record is associated with another record, remove from the album
*)
on LookForAsso(newAlbum)
	tell application "GEDitCOM II"
		tell front document
			set found to (count of records of newAlbum)
			repeat with i from found to 1 by -1
				set onerec to gedcomRecord i of newAlbum
				try
					tell onerec
						set assoLink to structure named "ASSO"
					end tell
					delete gedcomRecord i of newAlbum
				end try
			end repeat
		end tell
	end tell
end LookForAsso

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
