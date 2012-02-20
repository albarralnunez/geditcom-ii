(*	Change Place Name script
	GEDitCOM II Apple Script
	23 DEC 2008, by John A. Nairn

	This script will replace all occurences of "original text" in place
	names with "replacement text." The change can be made throughout the 
	entire file or only on selected recrods.
	
	When the script starts, you will be asked to enter the "original text"
	and the "replace" text in separate dialog boxes, and to select if you
	want on all records of just the currently selected records.
*)

-- variables
property oldName : "old place"
property oldLength : 9
property newName : "new place"
property scriptName : "Change Place Name Script"
global changes

-- if no document is open then quit
if CheckAvailable(scriptName, 1.5) is false then return

-- get the old place name
tell application "GEDitCOM II"
	set r to user input prompt "Enter place name to change" initial text oldName buttons {"OK", "Cancel"} title scriptName
	if item 1 of r is "Cancel" then return
	set oldName to item 2 of r
	set oldLength to count of characters in oldName
	
	-- get the new place name
	set r to user input prompt "Enter new place name" initial text newName buttons {"OK", "Cancel"} title scriptName
	if item 1 of r is "Cancel" then return
	if item 1 of r is "Cancel" then return
	set newName to item 2 of r
	
	-- choose all records or selected records (with option to cancel)
	set r to user option title "Change all records or just selected records" buttons {"All", "Cancel", "Selected"}
	if item 1 of r is "Cancel" then return
	set whichOnes to item 2 of r
end tell

-- loop through all relevant reocrds or selected one
set changes to 0
tell application "GEDitCOM II"
	if whichOnes is "All" then
		tell front document
			begin undo
			-- do individuals
			my checkPlaces(every individual whose gedcom contains oldName)
			
			-- do families
			my checkPlaces(every family whose gedcom contains oldName)
			end undo action "Change Place Names"
		end tell
		
	else
		tell front document
			begin undo
			my checkPlaces(selected records)
			end undo action "Change Place Names"
		end tell
	end if
end tell

-- alert when done
if changes is 1 then
	set doneText to "1 place name change was made."
else if changes is 0 then
	set doneText to "No place name changes were made."
else
	set doneText to changes & " place name changes were made."
end if
return doneText

(* Check all PLAC tags in records with id recID. If any contain oldName
	replace by newName and change contents of that structure.
*)
on checkPlaces(recRefs)
	local numRecs
	set numRecs to number of items in recRefs
	repeat with i from 1 to numRecs
		tell application "GEDitCOM II"
			tell item i of recRefs
				set places to find structures tag "PLAC"
				set np to number of items in places
				repeat with j from 1 to np
					set place to item j of places
					
					-- check place name
					set value to item 1 of place
					set ibegin to offset of oldName in value
					if ibegin > 0 then
						-- in contains the string, build new string
						if ibegin > 1 then
							set prefix to (characters 1 thru (ibegin - 1) of value) as string
						else
							set prefix to ""
						end if
						set iend to ibegin + oldLength
						set endLength to count of characters in value
						if endLength ³ iend then
							set suffix to (characters iend thru endLength of value) as string
						else
							set suffix to ""
						end if
						set repName to prefix & newName & suffix
						
						-- trace reference to the actual structure and replace contents
						set sref to (a reference to structure (item 2 of place))
						repeat with k from 3 to number of items in place
							set sref to (a reference to structure (item k of place) of sref)
						end repeat
						set contents of sref to repName
						set changes to changes + 1
					end if
					
				end repeat
			end tell
		end tell
	end repeat
end checkPlaces

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
