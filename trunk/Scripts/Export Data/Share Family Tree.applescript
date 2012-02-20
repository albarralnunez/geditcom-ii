(*	Share Family Tree Script
	GEDitCOM II Apple Script
	13 DEC 2009, by John A. Nairn
	
	If individual or family selected, prompt for ancestors
	or decendants and for number of generations. Compile
	tree and export GEDCOM file.
	
	If family tree window in front, export all to a GEDCOM file.
	
	If the file has multimedia, reopen the file, create a new
	folder, consolidate multimedia in the new folder,di
	move the file into that folder too.
	
	-- when compress, take original name, -.ged, +.zip, check unique
	-- compress in entire file GEDCOM script too
*)

property scriptName : "Share Family Tree"
property compressResults : true

global GEDFilePath -- string path user-supplied save location
global GEDFileName -- name of just the file
global GEDFolder -- string path to the folder being used
global ExportMethod -- user selected export style
global KeepPaths -- setting that depends on ExportMethod

-- if no document is open then quit
if CheckAvailable(scriptName, 1.5) is false then return

-- loop through all families 
tell application "GEDitCOM II"
	tell front document
		set wt to window type
		set indiRef to ""
		set savePrompt to "Select location to save the GEDCOM file (with extension .ged)"
		set GEDName to ""
		
		-- if not a family tree, see if individual is available
		if wt is not "AncestorController" and wt is not "DescendantController" then
			set indiRef to my SelectedIndividual()
			
			-- if no individual, exit with an error
			if indiRef is "" then
				beep
				user option title "You have to select an individual record or display a family tree to use this script." message "Make that selection and try again" buttons {"OK"}
				return
			end if
			set iname to alternate name of indiRef
			
			-- decide what kind of tree
			set thePrompt to "Would you like to export ancestors or descendants of " & iname & "?"
			set treeType to user option title thePrompt buttons {"Ancestors", "Cancel", "Descendants"}
			if treeType is "Cancel" then return
			
			-- get the number of generations
			set thePrompt to "Enter maximum number of generations of " & treeType & " of " & iname & " to include in the exported GEDCOM file:"
			set r to user input prompt thePrompt initial text "4" buttons {"Next", "Cancel"}
			if item 1 of r is "Cancel" then return
			set MaxGen to item 2 of r
			try
				set generations to MaxGen as integer
				if MaxGen < 1 then error
			on error
				beep
				user option title "The number of generations must be a number and be greater than zero." message "Please try again and enter a number" buttons {"OK"}
				return
			end try
			
			-- get file name for saving
			set expStyle to my GetExportStyle()
			if expStyle is false then return
			my GetFileName(savePrompt, iname & " " & treeType)
			if GEDFilePath is "" then return
			
			-- open the family tree window
			notify progress message "Collecting the family tree"
			my GetFamilyTree(indiRef, treeType, generations)
			
		else
			-- get file name for saving
			set fguess to alternate name of key record
			if wt is "AncestorController" then
				set fguess to fguess & "Ancestors"
			else
				set fguess to fguess & " Descendants"
			end if
			set expStyle to my GetExportStyle()
			if expStyle is false then return
			my GetFileName(savePrompt, fguess)
			if GEDFilePath is "" then return
		end if
		
		-- populate a new album, export, and delete it
		notify progress message "Exporting the GEDCOM data"
		populate
		set exportPath to POSIX path of GEDFilePath
		tell last album to export gedcom file path exportPath with options ExportMethod
		delete last album
		
	end tell
	
	-- close tree if generated here
	if indiRef is not "" then
		close front window
	end if
end tell

-- test if file was saved
try
	tell application "Finder"
		if (exists of file GEDFilePath) is false then
			error "could not be exported"
		end if
	end tell
on error
	return "The file '" & GEDFileName & "' could not be exported due to insufficient permission to create files " & Â
		"at the selected location (or possibly due to a disk error). Please try saving to a different location in your home directory."
end try

-- exit on simple export, with option to open now
tell application "GEDitCOM II"
	if expStyle is 3 then
		-- decide what kind of tree
		set thePrompt to "Would you like to open the new '" & GEDFileName & "' GEDCOM file in GEDitCOM II now?"
		set r to user option title thePrompt buttons {"Yes", "No"}
		set openType to item 1 of r
		if openType is "No" then return
		open file GEDFilePath
		return
	end if
	
	-- open the new ged file
	notify progress message "Reopening GEDCOM data to process multimedia"
	try
		set oldnum to number of documents
		-- open the new ged file to get multimedia too
		notify progress message "Reopening GEDCOM data to process multimedia"
		try
			open file GEDFilePath
		on error number -1712
			repeat
				if number of documents is oldnum then
					notify progress message "Éopening"
					delay 1
				else
					exit repeat
				end if
			end repeat
		end try
		if number of documents is oldnum then
			error "could not be reopened"
		end if
	on error
		beep
		display alert "The exported file '" & GEDFileName & "' could not be reopened in GEDitCOM II"
		return
	end try
	
	-- if no multimedia, then done
	tell front document
		set numMM to count of multimedia
		if numMM is 0 then
			close saving no
			return "The file '" & GEDFileName & "' is ready to be emailed to a friend, transfered to another computer, " & Â
				"or uploaded to a GEDCOM web site."
		end if
	end tell
end tell

-- create new folder at same location as the saved file
set nc to number of characters in GEDFilePath
set rootName to (characters 1 thru (nc - 4) of GEDFilePath) as string
set rootName to rootName & " Folder"
set gedSaveFolder to GetUniqueFolderName(rootName)
if gedSaveFolder is "" then return
set msg to ""
tell application "Finder"
	try
		set savedDelims to AppleScript's text item delimiters
		set AppleScript's text item delimiters to {":"}
		set fname to last text item of gedSaveFolder
		set AppleScript's text item delimiters to savedDelims
		set gedFldr to (make new folder at folder GEDFolder with properties {name:fname})
	on error errText number errNum
		set msg to "Unable to create folder to copy multimedia files along with file '" & GEDFileName & ". " & Â
			errText & " (" & errNum & ")"
		-- exit repeat here and will abort script in GEDitCOM II tell block below
	end try
end tell

-- the folder and file are not at new paths
if expStyle is 2 then
	set gedMMFolder to gedSaveFolder & ":multimedia"
else
	set gedMMFolder to gedSaveFolder
end if

tell application "GEDitCOM II"
	-- if could not create folder, give msg and exit
	if msg is not "" then
		beep
		display alert msg
		return
	end if
	
	if expStyle is 4 then
		set ExportMethod to {lines_CRLF, mm_PhpGedView}
	end if
	tell front document
		-- consolidate multimedia
		notify progress message "Copying the multimedia objects"
		set gedMMPath to POSIX path of gedMMFolder
		consolidate multimedia to folder gedMMPath preserve paths KeepPaths
		notify progress message "Exporting the GEDCOM data a final time"
		set gedPathName to POSIX path of (gedSaveFolder & ":" & GEDFileName)
		export gedcom file path gedPathName with options ExportMethod
		
		-- need message here for some reason
		if compressResults is true and expStyle is not 4 then
			notify progress message "Compressing folder (may take a while)"
		end if
		
		-- close it
		close saving no
	end tell
end tell

-- last delete the first file
tell application "Finder"
	delete file GEDFilePath
end tell

if compressResults is true and expStyle is not 4 then
	-- compress the folder
	set itemPath to quote & (POSIX path of gedSaveFolder) & quote
	set destPath to GetUniqueFileName(gedSaveFolder & ".zip")
	if destPath = "" then return
	set qDestPath to quote & (POSIX path of destPath) & quote
	set zipcmd to "ditto -c -k --sequesterRsrc " & itemPath & " " & qDestPath
	do shell script zipcmd
	
	-- delete the uncompressed file
	tell application "Finder"
		delete gedFldr
	end tell
	
	set AppleScript's text item delimiters to {":"}
	set zipName to (last text item of destPath)
	set AppleScript's text item delimiters to {}
	return "The file '" & zipName & "' is compressed and ready to email" & Â
		" to a friend or to transfer to another computer."
	
else
	if expStyle is 4 then
		return "The file '" & GEDFileName & "' was moved to a new folder called '" & fname & "' (at the same location) " & Â
			" to package it along with its multimedia objects. The contents of that folder are ready to be uploaded to a PhpGedView web site."
	else
		return "The file '" & GEDFileName & "' was moved to a new folder called '" & fname & "' (at the same location) " & Â
			" to package it along with its multimedia objects. Compress that entire folder to email to a friend or to transfer to another computer."
	end if
end if

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

-- get export style
on GetExportStyle()
	tell application "GEDitCOM II"
		-- what to find
		set expOptions to {"Will share with someone using a different computer and different software", Â
			"Will open with GEDitCOM II on a different computer", "Will open in GEDitCOM II on this computer", Â
			"Will upload to a PhpGedView web site"}
		set r to user choice prompt "How will share the exported family tree GEDCOM file?" list items expOptions buttons {"Next", "Cancel"} title scriptName
		if item 1 of r is "Cancel" then return false
		set theStyle to item 1 of item 2 of r
		if theStyle is item 1 of expOptions then
			set ExportMethod to {lines_CRLF}
			set KeepPaths to false
			return 1
		else if theStyle is item 2 of expOptions then
			set ExportMethod to {mm_GEDitCOM, logs_Include, places_Include, books_Include}
			set KeepPaths to true
			return 2
		else if theStyle is item 3 of expOptions then
			set ExportMethod to {mm_GEDitCOM, logs_Include, places_Include, books_Include}
			set KeepPaths to true
			return 3
		else if theStyle is item 4 of expOptions then
			set ExportMethod to {lines_CRLF, mm_GEDitCOM}
			set KeepPaths to false
			return 4
		end if
		return false
	end tell
end GetExportStyle

-- get file path for saving
on GetFileName(savePrompt, gedpkgName)
	tell application "GEDitCOM II"
		try
			set fileRef to choose file name with prompt savePrompt default name gedpkgName & ".ged"
		on error
			set GEDFilePath to ""
			return
		end try
	end tell
	
	-- if does not end in .ged, then add it and make sure unique
	set GEDFilePath to (fileRef as string)
	log GEDFilePath
	set oldDelim to AppleScript's text item delimiters
	set AppleScript's text item delimiters to {"."}
	if (count of text items in GEDFilePath) > 1 then
		set fext to last text item of GEDFilePath
	else
		set fext to ""
	end if
	log {fext}
	if fext is not "ged" then
		set GEDFilePath to GetUniqueFileName(GEDFilePath & ".ged")
		if GEDFilePath is "" then return
	end if
	
	-- extract folder and file names extracted
	set AppleScript's text item delimiters to {":"}
	set GEDFileName to last text item of GEDFilePath
	set GEDFolder to (text items 1 thru -2 of GEDFilePath) as string
	set AppleScript's text item delimiters to oldDelim
end GetFileName

-- open family tree window
on GetFamilyTree(indvRef, treeType, genNum)
	tell application "GEDitCOM II"
		tell front document
			if treeType is "Ancestors" then
				show ancestors indvRef generations genNum
			else
				show descendants indvRef generations genNum
			end if
		end tell
	end tell
end GetFamilyTree

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

(* Get unique file name by inserting numbers (if needed) between base name
	and its extension. baseName is colon separate mac path
*)
on GetUniqueFileName(basePath)
	-- extract the extension
	set savedDelims to AppleScript's text item delimiters
	set AppleScript's text item delimiters to {"."}
	set theTextItems to text items of basePath
	if ((count of theTextItems) > 1) then
		set baseName to (items 1 thru -2 of theTextItems) as text
		set theExt to "." & (item -1 of theTextItems)
	else
		set baseName to basePath
		set theExt to ""
	end if
	set AppleScript's text item delimiters to savedDelims
	
	-- check with Finder for file that does not exist
	tell application "Finder"
		set tempName to baseName & theExt
		set i to 0
		repeat while ((file tempName exists) and (i < 1000))
			set i to i + 1
			set tempName to baseName & " " & i & theExt
		end repeat
	end tell
	
	-- return results or an error
	if (i < 1000) then
		return tempName
	else
		return ""
	end if
end GetUniqueFileName

(* Get unique folder name by inserting numbers (if needed) after base path where
	base path is colon separated path
*)
on GetUniqueFolderName(basePath)
	-- check with Finder for file that does not exist
	tell application "Finder"
		set tempName to basePath
		set i to 0
		repeat while ((folder tempName exists) and (i < 1000))
			set i to i + 1
			set tempName to basePath & " " & i
		end repeat
	end tell
	
	-- return results or an error
	if (i < 1000) then
		return tempName
	else
		return ""
	end if
end GetUniqueFolderName