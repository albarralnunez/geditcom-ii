(*	Ancestors To Album Script
	GEDitCOM II Apple Script
	2 May 2010, by John A. Nairn

	Find any number of generations of ancestors of the currently
	selected individual (or spouse in a family) and send them to
	an album. The individuals sent to the album can optionally
	be limited to a single paternal or material line.
	
	To focus on a single paternal or maternal line, a good solution is
	to move the entire line to a new file. One simple route to this goal is:
	
	1. Create a new file (command-N keyboard command)
	2. Open the single-line album in the original file and select all
	     (Command-A keyboard command)
	3. Click and drag all records in that album to the "Record Albums" column
	     of the index window in the new file
	4. Open the original individual in the new file and request an ancestor tree
*)

property scriptName : "Ancestors To Album"

-- if no document is open then quit
if CheckAvailable(scriptName, 1.5) is false then return

-- get selected record
set indvRef to SelectedIndividual()
if indvRef is "" then
	beep
	tell application "GEDitCOM II"
		user option title "You have to select an individual in GEDitCOM II to use this script" message "Select an individual and try again" buttons {"OK"}
	end tell
	return
end if

-- Get user input for number of generations (1 or higher)
tell application "GEDitCOM II"
	set iname to alternate name of indvRef
	set aprompt to "Enter maximum number of generations of " & iname & Â
		" to move to a new album"
	set r to user input prompt aprompt initial text "4" title scriptName
end tell
if item 1 of r is "Cancel" then return
set MaxGen to item 2 of r
try
	set generations to MaxGen as integer
	if MaxGen < 1 then error
on error
	beep
	tell application "GEDitCOM II"
		user option title "The number of generations must be a number and be greater than zero." buttons {"OK"}
	end tell
	return
end try

-- get sex to include
tell application "GEDitCOM II"
	set ancestorSex to user option title "Include all ancestors or just single paternal or material line" buttons {"All", "Maternal", "Paternal"}
end tell

-- get album name
if ancestorSex = "Paternal" then
	set albumName to "Paternal Ancestors of " & iname
	set ancestorSex to "FAMC.HUSB"
else if ancestorSex = "Maternal" then
	set albumName to "Maternal Ancestors of " & iname
	set ancestorSex to "FAMC.WIFE"
else
	set albumName to "Ancestors of " & iname
end if
set albumName to albumName & " (" & MaxGen & " gen)"

-- compile list of descendants
tell application "GEDitCOM II"
	notify progress message "Finding Ancestors"
	tell front document
		
		if ancestorSex is "All" then
			show ancestors indvRef generations MaxGen tree style outline
			populate
			set newAlbum to last album
			set name of newAlbum to albumName
			
		else
			set newAlbum to (make new album with properties {name:albumName})
			
			-- source individual
			move indvRef to newAlbum
			
			repeat
				-- get ID of selected parent type, and exit if not more in this line
				tell indvRef
					set parID to evaluate expression ancestorSex
				end tell
				if parID = "" then
					exit repeat
				end if
				
				-- move parent to the album
				set indvRef to a reference to individual id parID
				move indvRef to newAlbum
				
				-- exit if done with request number of generatinos
				set MaxGen to MaxGen - 1
				if MaxGen ² 0 then
					exit repeat
				end if
			end repeat
		end if
		
	end tell
	
	if ancestorSex is "All" then
		close front window
	end if
end tell

return

(* Find the selected record. If it is a family record, switch to
     the first spouse found. Finally, return "" if the selected record
     is not an indivdual record or if no record is selected
*)
on SelectedIndividual()
	tell application "GEDitCOM II"
		set indvRef to ""
		set recSet to selected records of front document
		if number of items in recSet is not 0 then
			set indvRef to item 1 of recSet
			if record type of indvRef is "FAM" then
				set husbRef to husband of indvRef
				if husbRef is not "" then
					set indvRef to husbRef
				else
					set indvRef to wife of IndvRec
				end if
			end if
			if record type of indvRef is not "INDI" then
				set indvRef to ""
			end if
		end if
	end tell
	return indvRef
end SelectedIndividual

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