(*	Name Case script
	GEDitCOM II Apple Script
	19 DEC 2008, by John A. Nairn

	This script changes names of all or selected individuals to be
	all UPPERCASE, to be Uppercase SURNAMES, or to be Title Case
	Names.
	
	The Uppercaase SURNAMES options does not change non-surname parts of the name.
	To change names in all upper case to upper case surnames only, first change
	to Title Case Names and then do a second pass for Uppercase SURNAMES.
*)

property scriptName : "Name Case Script"
global numChanged, nameCase, recs

tell application "GEDitCOM II"
	if number of documents is 0 then
		user option title "The script '" & scriptName & Â
			"' requires a document to be open" message "Please open a document and try again." buttons {"OK"}
		return false
	end if
	
	-- choose all records or selected records (with option to cancel)
	set whichOnes to user option title Â
		"Which names should be changed?" message Â
		"Change 'All' individuals in the file or just the currently 'selected' individuals." buttons {"All", "Cancel", "Selected"}
	if whichOnes is "Cancel" then return
	
	-- decide how to change the names
	set btnClick to user option title Â
		"How should the name case be changed?" message Â
		"Make names ALL UPPERCASE, just the surname UPPERCASE, or use Title Case." buttons {"UPPERCASE", "Uppercase SURNAMES", "Title Case"}
	if btnClick is "Uppercase SURNAMES" then
		set nameCase to "uppersurname"
	else if btnClick is "UPPERCASE" then
		set nameCase to "upper"
	else
		set nameCase to "title"
	end if
	
	-- loop through all individuals or selected one
	set numChanged to 0
	if whichOnes is "All" then
		-- do all individuals
		set recs to every individual of front document
	else
		-- do just the selected records
		set recs to selected records of front document
	end if
end tell

tell front document of application "GEDitCOM II" to begin undo
my nameChange(recs)
tell front document of application "GEDitCOM II" to end undo action "Name Case Changes"

-- alert when done
if numChanged = 0 then
	set msg to "No names were changed, probably because no individual records were selected."
else if numChanged = 1 then
	set msg to "One name was changed."
else
	set msg to "Name changes done and " & numChanged & " names were changed."
end if
return msg

(* Reformat names for all records in the list in recSet
*)
on nameChange(recSet)
	tell application "GEDitCOM II"
		set fractionStepSize to 0.05 -- progress reporting interval
		set nextFraction to fractionStepSize -- progress reporting interval
		set num to number of items in recSet
		repeat with i from 1 to num
			set recRef to item i of recSet
			if record type of recRef is "INDI" then
				tell recRef
					set oldName to evaluate expression "NAME"
					set name to format name value oldName case nameCase
					set numChanged to numChanged + 1
				end tell
			end if
			
			-- if time, notify GEDitCOM II of the amount done
			set fractionDone to i / num
			if fractionDone > nextFraction then
				notify progress fraction fractionDone
				set nextFraction to nextFraction + fractionStepSize
			end if
		end repeat
	end tell
end nameChange

