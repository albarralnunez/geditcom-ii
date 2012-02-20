(*	Copy Special Script
	GEDitCOM II Apple Script
	2 JAN 2010, by John A. Nairn
	
	Support Copy special command
	Assumes a document is open and record is selected
	This setting is verified by enabling of the menu command
*)

-- copy text for each record
set copyData to {}
tell application "GEDitCOM II"
	set recs to selected records of front document
	set num to number of items in recs
	repeat with i from 1 to num
		set recRef to item i of recs
		set recData to my copyRecord(recRef, record type of recRef)
		set end of copyData to recData
	end repeat
end tell

set the clipboard to (copyData as string)
return

(* Copy specific data for each type of record. You can customize
       this method to determine what gets copied
*)
on copyRecord(recRef, recType)
	-- call method depending on record stype
	tell application "GEDitCOM II"
		tell recRef
			if recType is "INDI" then
				set recData to description output options {"BD", "BP", "DD", "DP", "SN", "MD", "MP", "CN", "SEX", "LIST", "FM"}
			else if recType is "FAM" then
				set recData to description output options {"BD", "BP", "DD", "DP", "MD", "MP", "CN", "SEX", "LIST"}
			else if recType is "OBJE" then
				set recData to description output options {"BD", "BP", "LIST"}
			else
				-- SUBM, HEAD, SUBN, SOUR, NOTE, REPO, and custom
				set recData to description output options {"LIST"}
			end if
		end tell
	end tell
	
	-- convert to string
	set AppleScript's text item delimiters to {return}
	set recData to recData as string
	set AppleScript's text item delimiters to {}
	
	-- return result and a return character
	return recData & return & return
end copyRecord
