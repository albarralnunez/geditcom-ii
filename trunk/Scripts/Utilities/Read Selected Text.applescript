(*	Read Field Script
	GEDitCOM II Apple Script
	12 DEC 2009, by John A. Nairn
	
	Simple use of Apple Script's "say" command to read selected field
	in the front window
*)

property scriptName : "Read Field Script"

-- these needs volume
set currentVol to output volume of (get volume settings)
if currentVol < 15 then
	set volume output volume 60
end if

-- if no document is open then quit
if CheckAvailable(scriptName,1.5) is false then return

-- loop through all families 
tell application "GEDitCOM II"
	tell front document
		set swrds to selected text
		if swrds is not "" then
			say swrds
		else
			say "No text is selected for reading"
		end if
	end tell
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
