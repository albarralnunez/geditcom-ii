(*	Delete Living Dates script
	GEDitCOM II Apple Script
	19 JUL 2009, by John A. Nairn
	
	This script goes thrrough individual records and for all living records,
	it deletes their birth dates, baptism dates, and christening dates, if
	those dates are present.
	
	The main use for this script is to prepare a file that hides birth information
	for living individuals. Since it deletes dates, it should only be run on a
	copy of your genealogy file. Once done, you can export to a GEDCOM file if the
	goal was to transmit a GEDCOM file with those dates removed.
	
	This script assumes anyone with no death information is living. It is common
	to have deceased individuals in files that have no death information. For this
	script to correctly recognize them as deceased, you must check the "Has Died"
	check box for all such individuals.
	
	Hint: The "Check Has Died" script provided with GEDitCOM II will help you
	get the "Has Died" check box checked for all deceased individuals.
*)

property scriptName : "Delete Living Dates"
global numChanged

-- if no document is open then quit
if CheckAvailable(scriptName, 1.5) is false then return

-- choose all records or selected records (with option to cancel)
tell application "GEDitCOM II"
	set whichOnes to user option title " Change currently selected individuals or all individuals" buttons {"All", "Cancel", "Selected"}
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
	
	tell front document
		begin undo
		my deleteDates(recs)
		end undo action "Delete living dates"
	end tell
end tell

-- alert when done
if numChanged = 0 then
	set msg to "No dates were deleted."
else if numChanged = 1 then
	set msg to "One date was deleted."
else
	set msg to " " & numChanged & " dates were deleted."
end if
if numChanged > 0 then
	set msg to msg & " Because some dates were deleted, you should only save"
	set msg to msg & " the file now as a copy using the 'Save As...' menu command."
end if
return {msg}

(* Reformat names for all records in the list in recSet
*)
on deleteDates(recSet)
	tell application "GEDitCOM II"
		set num to number of items in recSet
		repeat with i from 1 to num
			set recRef to item i of recSet
			if record type of recRef is "INDI" then
				tell recRef
					try
						set deat to structure named "DEAT"
						--set fams to {}
					on error
						my deleteOneDate(recRef, "BIRT")
						my deleteOneDate(recRef, "BAPM")
						my deleteOneDate(recRef, "CHR")
						--set fams to spouse families
					end try
				end tell
				
				-- to delete marriage dates, uncomment following loop
				-- as well as to lines to "set fams" above
				--repeat with fam in fams
				--	tell fam
				--		my deleteOneDate(fam, "MARR")
				--	end tell
				--end repeat
			end if
		end repeat
	end tell
end deleteDates

(* Delete date in one event type
*)
on deleteOneDate(recRef, tag)
	tell application "GEDitCOM II"
		tell recRef
			try
				set etag to structure named tag
				tell etag
					delete structure named "DATE"
				end tell
				set numChanged to numChanged + 1
			end try
		end tell
	end tell
end deleteOneDate

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