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

property scriptName : "Rearrange Names Script"
global numChanged, recs

-- if no document is open then quit
if CheckAvailable(scriptName, 1.5) is false then return

tell application "GEDitCOM II"
	-- choose all records or selected records (with option to cancel)
	set whichOnes to user option title "Which names should be changed?" message "Change 'All' individuals in the file or just the currently 'selected' individuals." buttons {"All", "Cancel", "Selected"}
	if whichOnes is "Cancel" then return
	
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
	set msg to "No names were changed."
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
					set nparts to name parts gedcom name oldName
					if item 3 of nparts is not "" then
						set newName to my wordsof(item 1 of nparts) & " " & my wordsof(item 3 of nparts) & " /" & (item 2 of nparts) & "/"
						set name to newName
						set numChanged to numChanged + 1
					end if
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

(* Strip leading and trailing blanks
*)
on wordsof(ntext)
	set cbeg to 1
	set nc to number of characters in ntext
	repeat while cbeg ² nc
		if character cbeg of ntext is not " " then
			exit repeat
		end if
		set cbeg to cbeg + 1
	end repeat
	if cbeg > nc then return ""
	set cend to nc
	repeat while cend > 0
		if character cend of ntext is not " " then
			exit repeat
		end if
		set cend to cend - 1
	end repeat
	if cend < 1 then return ""
	if cbeg is 1 and cend is nc then return ntext
	return (characters cbeg thru cend of ntext) as string
end wordsof

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
