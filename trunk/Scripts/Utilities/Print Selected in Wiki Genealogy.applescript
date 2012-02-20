(*	GEDitCOM II Apple Script
	5 June 2010, by John A. Nairn
	
	Print Selected Records using the Wiki Genealogy Format
	
	The print dialog box prints before each one. To avoid that dialog, change
	"with print dialog" to "without print dialog"
	
	To print using a different format, change the format name that is set to
	the current format at the beginning.
*)

property scriptName : "Print Selected in Book Format"

-- if no document is open then quit
if CheckAvailable(scriptName,1.5) is false then return

tell application "GEDitCOM II"
	
	-- save current current and save previous one
	activate
	set oldFormat to current format
	set current format to "$SYSTEM/Wiki Genealogy"
	
	-- get selected records
	set recs to selected records of front document
	
	-- and print each one
	repeat with i from 1 to count of recs
		tell front document
			-- show browser and print
			set recRef to item i of recs
			show browser recRef
			print with print dialog
			
			-- wait until browser has printed
			repeat
				if printing is false then
					exit repeat
				end if
			end repeat
		end tell
		
		-- close browser
		close front window
	end repeat
	
	-- restore original format
	set current format to oldFormat
end tell

return

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
