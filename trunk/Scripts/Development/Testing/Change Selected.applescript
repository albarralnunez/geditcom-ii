(*	Generic Script to make change on selected records
	GEDitCOM II Apple Script
*)

property scriptName : "Change Selected Records"
global numChanged

-- if no document is open then quit
if CheckAvailable(scriptName, 1.5) is false then return

tell application "GEDitCOM II"
	-- loop through all individuals or selected one
	set numChanged to 0
	set recs to selected records of front document
	
	begin undo
	my recordChange(recs)
	end undo action "Selected Record Changes"
end tell

-- alert when done
if numChanged = 0 then
	set msg to "No records were changed."
else if numChanged = 1 then
	set msg to "One record was changed."
else
	set msg to "" & numChanged & " records were changed."
end if
return msg

(* Insert change here
*)
on recordChange(recSet)
	tell application "GEDitCOM II"
		set fractionStepSize to 0.05 -- progress reporting interval
		set nextFraction to fractionStepSize -- progress reporting interval
		set num to number of items in recSet
		repeat with i from 1 to num
			set recRef to item i of recSet
			
			-- change recRef
			set changed to false
			tell recRef
				set birts to find structures tag "BIRT"
				set nb to number of items in birts
				if nb > 1 then
					repeat with j from (number of items in birts) to 2 by -1
						set bd to item j of birts
						set bdnum to item 2 of bd
						delete structure bdnum
						set changed to true
					end repeat
				end if
				
				set cens to find structures tag "CENS"
				set nc to number of items in cens
				if nc > 1 then
					repeat with j from (number of items in cens) to 2 by -1
						set bd to item j of cens
						set bdnum to item 2 of bd
						delete structure bdnum
						set changed to true
					end repeat
				end if
			end tell
			
			if changed is true then
				set numChanged to numChanged + 1
			end if
			
			-- if time, notify GEDitCOM II of the amount done
			set fractionDone to i / num
			if fractionDone > nextFraction then
				notify progress fraction fractionDone
				set nextFraction to nextFraction + fractionStepSize
			end if
		end repeat
	end tell
end recordChange

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
