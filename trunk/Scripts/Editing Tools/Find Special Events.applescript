(*	Find Special Events script
	GEDitCOM II Apple Script
	30 JUL 2010, by John A. Nairn

	This script goes though all or selected individuals  and move all those
	that have a certain eveant to a new album. The event to locate
	is selected from a list.
	
	To add additional types of events for finding, follow the
	intruction below after the "-- decide events to locate" comment
	line below
*)

property scriptName : "Find Special Events Script"

-- if no document is open then quit
if CheckAvailable(scriptName, 1.5) is false then return

tell application "GEDitCOM II"
	-- choose all records or selected records (with option to cancel)
	set whichOnes to user option title Â
		"Which individuals and families should be searched?" message Â
		"Search 'All' individuals and families in the file or just the currently 'selected' individuals and families." buttons {"All", "Cancel", "Selected"}
	if whichOnes is "Cancel" then return
	
	-- decide events to locate
	-- to add more add the name to the eventNames list and the GEDCOM tag
	-- in the corresponding position of the eventTags list
	set eventNames to {"Residences (RESI)", "Census Details (CENS)", "Naturalization (NATU)", "Emmigration (EMIG)", "Immigration (IMMI)", "Adoptions (ADOP)", "Burials (BURI)", "Divorces (DIV)", "Generic Events (EVEN)"}
	set thePrompt to "Select the type of event to locate"
	set btnClick to user choice prompt thePrompt list items eventNames buttons {"OK", "Cancel"}
	if item 1 of btnClick is "Cancel" then return
	set eventName to item 1 of item 2 of btnClick
	-- this removes the () for us
	set theTag to last word of eventName
	
	-- loop through all individuals or selected one
	if whichOnes is "All" then
		-- do all individuals
		set recs1 to every individual of front document
		set recs2 to every family of front document
		set recs to recs1 & recs2
	else
		-- do just the selected records
		set recs to selected records of front document
	end if
	
	set {fractionStepSize, nextFraction} to {0.01, 0.01} -- progress reporting interval
	set numRecs to number of items in recs
	
	tell front document
		set newAlbum to (make new album with properties {name:eventName})
		
		set found to 0
		repeat with i from 1 to numRecs
			set theRec to item i of recs
			tell theRec
				try
					set theEvent to structure named theTag
					set found to found + 1
					move theRec to newAlbum
				end try
			end tell
			
			-- time for progress
			set fractionDone to i / numRecs
			if fractionDone > nextFraction then
				notify progress fraction fractionDone
				set nextFraction to nextFraction + fractionStepSize
			end if
		end repeat
	end tell
	
end tell

-- alert when done
if found = 0 then
	set res to "No " & eventName & " events were found."
	tell application "GEDitCOM II" to delete newAlbum
else if found = 1 then
	set res to "One record with one or more " & eventName & " events was moved to a new '" & eventName & "' album."
else
	set res to found & " records with one or more " & eventName & " events were moved to a new '" & eventName & "' album."
end if
return res

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
