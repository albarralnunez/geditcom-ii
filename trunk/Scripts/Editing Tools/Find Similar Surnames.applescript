(*	Find Similar Surnames
	GEDitCOM II Apple Script
	6 SEP 2010, by John A. Nairn

	This script will check load all records with surnames have soundex
	the same as the front record to an album
*)

property scriptName : "Find Disconnected Records Script"
global found

-- if no document is open then quit
if CheckAvailable(scriptName, 1.5) is false then return

-- get selected record
set indvRef to SelectedIndividual()
if indvRef is "" then
	beep
	tell application "GEDitCOM II"
		user option title "You have to select an individual or a family in GEDitCOM II to use this script" message "Select an individual and try again" buttons {"OK"}
	end tell
	return
end if

tell application "GEDitCOM II"
	-- get the name and soundex
	tell indvRef
		set thename to surname
		set thesound to surname soundex
		set lookFor to "Surname " & thename
	end tell
	
	-- move all to an album
	tell front document
		-- make the album
		set newAlbum to (make new album with properties {name:lookFor})
		move (every individual whose surname soundex is thesound) to newAlbum
		
		-- how many were found?
		set found to (count of records of newAlbum)
	end tell
end tell

-- alert when done
if found = 0 then
	set res to "No individuals with " & lookFor & " were found."
	tell application "GEDitCOM II" to delete newAlbum
else if found = 1 then
	set res to "One individual was moved to a new '" & lookFor & "' album."
else
	set res to (found & " individuals were moved to a new '" & lookFor & "' album.") as string
end if
return res

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
