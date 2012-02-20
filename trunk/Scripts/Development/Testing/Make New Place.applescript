(*	Place Tools
	GEDitCOM II Apple Script
	6 DEC 2009, by John A. Nairn
*)

property scriptName : "Place Tools"

-- if no document is open then quit
if CheckAvailable(scriptName) is false then return

MakeNewPlace()

return

-- Make new place with provided name
on MakeNewPlace()
	-- get new place name
	set r to display dialog Â
		"Enter new place name" default answer "" buttons {"Cancel", "OK"} Â
		default button "OK" cancel button "Cancel" with title scriptName
	if button returned of r is "Cancel" then return
	set newName to text returned of r
	
	-- make the record
	tell application "GEDitCOM II"
		tell front document
			set gnum to (count of gedcomRecords)
			make new gedcomRecord with properties {record type:"_PLACE"}
			tell gedcomRecord (gnum + 1)
				make new structure with properties {name:"_PLAC", contents:newName}
				show browser
			end tell
		end tell
	end tell
end MakeNewPlace

(* Start GEDitCOM II (if needed) and verify that a documenbt is open
	return true or false if at least one document is open
*)
on CheckAvailable(sName)
	tell application "GEDitCOM II"
		if versionNumber < 1.39 then
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
