(*	Add or Remove Keywords
	GEDitCOM II AppleScript
	20 AUG 2009, by John A. Nairn

	This script lets you add or remove keywords to or from the currently
	selected records and/or all records and each type that can accept
	keywords. Multiple keywords can be done and they should be separated
	by semicolons. The script is smart enough to not add a keyword to
	a record if that record already has that keyword.
	
	When the script starts, enter the keywords (separated by semicolons).
	Then in the list of record type options, select one of of items or hold
	the shift or command key down to make multiple selestions. Finally,
	click "Add" or "Remove" to finish the task.
	
	To add keywords to records in an album, select the album, select one
	or more records in the album, run this script, and choose the
	"Currenlty Selected Records" option.
*)

-- global variable
property scriptName : "Add or Remove Keyword Script"
property maxLength : 80
property validRecs : {"INDI", "FAM", "OBJE", "SOUR", "NOTE", "REPO", "_LOG"}
global proc, theKeys, numChanged, numKeys

-- if no document is open then quit
if CheckAvailable(scriptName, 1.5) is false then return

-- get the keywords
tell application "GEDitCOM II"
	set r to user input prompt "Enter Keyword(s) to add or remove (separated by semicolons)" buttons {"Add", "Cancel", "Remove"} title scriptName
	set proc to item 1 of r
	if proc is "Cancel" then return
	set userKeys to item 2 of r
end tell
if userKeys is "" then
	return "The script was stopped because no keyword was entered."
end if

-- decode the keywords
set oldDelims to AppleScript's text item delimiters
set theKeys to DecodeKeyString(userKeys)
set AppleScript's text item delimiters to oldDelims
set numKeys to number of items in theKeys
if numKeys is 0 then
	return "The script was stopped because no keywords were entered."
end if

tell application "GEDitCOM II"
	
	-- find which records
	set which to {}
	tell front document
		-- add to possible types
		-- cannot add REFN to to HEAD, SUBN, or SUBM
		set selRecords to selected records
		set numSelRecords to count of selRecords
		if numSelRecords > 0 then
			set end of which to "Currently Selected Records"
		end if
		if (count of individuals) > 0 then
			set end of which to "All Individual Records"
		end if
		if (count of families) > 0 then
			set end of which to "All Family Records"
		end if
		if (count of multimedia) > 0 then
			set end of which to "All Multimedia Object Records"
		end if
		if (count of sources) > 0 then
			set end of which to "All Source Records"
		end if
		if (count of research logs) > 0 then
			set end of which to "All Research Log Records"
		end if
		if (count of repositories) > 0 then
			set end of which to "All Repository Records"
		end if
		if (count of notes) > 0 then
			set end of which to "All Notes Records"
		end if
		
		set numRecords to number of items in which
		set numAlbums to number of albums
		repeat with i from 1 to numAlbums
			set end of which to ("Album: " & name of album i)
		end repeat
		
	end tell
	
	-- chose record types for a list
	if proc is "Add" then
		set thePrompt to "Choose records for adding the keyword(s)"
	else
		set thePrompt to "Choose records for keyword(s) removal"
	end if
	set mySet to user choice prompt thePrompt list items which buttons {proc, "Cancel"} with multiple
	if item 1 of mySet is "Cancel" then
		return
	end if
	set mySet to item 2 of mySet
	
	-- process each type
	set numChanged to 0
	tell front document
		set selRecs to {}
		if mySet contains "Currently Selected Records" then
			set selRecs to selRecs & selRecords
		end if
		if mySet contains "All Individual Records" then
			set selRecs to selRecs & every individual
		end if
		if mySet contains "All Family Records" then
			set selRecs to selRecs & every family
		end if
		if mySet contains "All Multimedia Object Records" then
			set selRecs to selRecs & every multimedia
		end if
		if mySet contains "All Source Records" then
			set selRecs to selRecs & every source
		end if
		if mySet contains "All Notes Records" then
			set selRecs to selRecs & every note
		end if
		if mySet contains "All Repository Records" then
			set selRecs to selRecs & every repository
		end if
		if mySet contains "All Research Log Records" then
			set selRecs to selRecs & every research log
		end if
		set numWhich to number of items in which
		repeat with i from numRecords + 1 to numWhich
			if mySet contains item i of which then
				set selRecs to selRecs & records of album (i - numRecords)
			end if
		end repeat
		
		-- process the chosen records
		begin undo
		set selRecsRef to a reference to selRecs
		my ProcessRecords(selRecsRef)
		end undo action proc & " Keywords"
	end tell
end tell

-- summary
if numChanged = 0 then
	set msg to "No keywords were " & proc
else if numChanged = 1 then
	set msg to "One keyword was " & proc
else
	set msg to (numChanged as string) & " keywords were " & proc
end if
if last character of proc is not "e" then
	set msg to msg & "ed."
else
	set msg to msg & "d."
end if
return msg

(* Process each record verifying it can accept keywords and special
	case for the keyword tag for OBJE records
*)
on ProcessRecords(recRefs)
	tell application "GEDitCOM II"
		set fractionStepSize to 0.01 -- progress reporting interval
		set nextFraction to fractionStepSize -- progress reporting interval
		set numRecs to number of items in recRefs
		repeat with i from 1 to numRecs
			-- if can add keyword to this record, do so
			set theRec to item i of recRefs
			tell theRec
				set recType to record type
				if recType is in validRecs then
					
					-- read current keywords
					set recKeys to keywords
					set needToSet to false
					
					if proc is "Add" then
						-- add any that are new
						repeat with aKey in theKeys
							if recKeys does not contain aKey then
								set end of recKeys to aKey
								set needToSet to true
								set numChanged to numChanged + 1
							end if
						end repeat
						
						-- if needed, add them
						if needToSet is true then
							set keywords to recKeys
						end if
						
					else
						-- remove any that are there
						set newKeys to {}
						repeat with aKey in recKeys
							if theKeys does not contain aKey then
								set end of newKeys to (aKey as string)
							else
								set needToSet to true
								set numChanged to numChanged + 1
							end if
						end repeat
						
						-- if needed, remove them
						if needToSet is true then
							set keywords to newKeys
						end if
						
					end if
					
				end if
			end tell
			
			-- if time, notify GEDitCOM II of the amount done
			set fractionDone to i / numRecs
			if fractionDone > nextFraction then
				notify progress fraction fractionDone
				set nextFraction to nextFraction + fractionStepSize
			end if
		end repeat
	end tell
end ProcessRecords

(* Turn semicolon delimited string of keywords into a list of
	keywords with leading and trailing space removed
	*)
on DecodeKeyString(someKeys)
	set AppleScript's text item delimiters to {";"}
	set keylist to every text item in someKeys
	set AppleScript's text item delimiters to {" "}
	set i to 1
	set num to number of items in keylist
	set outlist to {}
	repeat
		if i > num then exit repeat
		set keyword to item i of keylist
		set nwrds to number of words in keyword
		if nwrds > 0 then
			set end of outlist to (words 1 thru nwrds of keyword) as string
		end if
		set i to i + 1
	end repeat
	return outlist
end DecodeKeyString

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
