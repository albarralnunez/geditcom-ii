(*	GEDitCOM II Test Apple Script
	6 DEC 2009, by John A. Nairn
*)

property scriptName : "Test Script"
property cmds : {"pwd", "who -a", "whoami"}

-- if no document is open then quit
if CheckAvailable(scriptName) is false then return

tell application "GEDitCOM II"
	set dn to date numbers full date "INT 1208 (or 1209)"
end tell

return dn

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
