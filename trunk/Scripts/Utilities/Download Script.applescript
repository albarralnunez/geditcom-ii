(*	GEDitCOM II Download Interface Format
	24 Jun 2010, by John A. Nairn
	
	Download list of available formats at
	
	     http://www.geditcom.com/scripts/FileList2.txt
	
	and let user pick one to download.
	
	Once selected, download zip file to target folder and expand it
	
	Update 18 Oct 2010 to look for script folders and save to
	the appropraite folder in either library. It uses new FileList2.txt
	file in place of old FileList.txt file.
*)

property scriptName : "Download Interface"

-- if no document is open then quit
if CheckAvailable(scriptName, 1.5) is false then return

-- read the list of available scripts
-- Each script has two lines. First is zip file name, second is save
-- file name (with its extension)
set intFiles to (do shell script "curl http://www.geditcom.com/scripts/FileList2.txt")

-- quit if fails
if character 1 of intFiles is not "#" then
	tell application "GEDitCOM II"
		activate
		user option title Â
			"The list of available scripts could not be read" message Â
			"Check your Internet connection and try again" buttons {"OK"}
	end tell
	return
end if

-- break list into zip file names and .scpt file names (without the .gfrmt)
set fileNames to {}
set fileDescrip to {}
repeat with i from 2 to (number of paragraphs in intFiles) by 2
	set end of fileNames to paragraph i of intFiles
	set end of fileDescrip to paragraph (i + 1) of intFiles
end repeat

-- let user pick one of the file
tell application "GEDitCOM II"
	activate
	set newForm to user choice list items fileDescrip Â
		prompt Â
		"Select Script to download from following cateogries:" buttons {"To System Scripts", "To User Scripts", "Cancel"} title scriptName
end tell

-- exit if canceled
set btn to item 1 of newForm
if btn is "Cancel" then
	return
end if

-- find which one was selected
set downName to item 1 of item 2 of newForm
set downIndex to item 1 of item 3 of newForm
set zipFile to item downIndex of fileNames
set scriptFile to item downIndex of fileDescrip

-- get path to appropriate folder
set appSupport to path to application support from user domain as string
if btn = "To User Scripts" then
	set appSupport to appSupport & "GEDitCOM II:"
else
	set appSupport to appSupport & "GEDitCOM II:System:"
end if
set srcPath to "http://www.geditcom.com/scripts/" & zipFile

-- convert _ to space in zipFile
set soff to offset of "/" in zipFile
set fldr to characters 1 thru (soff - 1) of zipFile as string
set numf to count of characters in fldr
repeat
	set uoff to offset of "_" in fldr
	if uoff is 0 then exit repeat
	set word1 to characters 1 through (uoff - 1) of fldr as string
	set word2 to characters (uoff + 1) through numf of fldr as string
	set fldr to word1 & " " & word2
end repeat

-- save zip file in the script folder
set nz to count of characters in zipFile
set zipFile to characters (soff + 1) thru nz of zipFile as string
set destPath to appSupport & "Scripts:" & fldr & ":" & zipFile

-- get script name only and then final path for saved script
set coff to offset of ":" in scriptFile
set ns to count of characters in scriptFile
if coff > 0 then
	set scriptFile to characters (coff + 2) thru ns of scriptFile as string
else
	repeat with i from 1 to ns
		if (character i of scriptFile) is not " " then
			set scriptFile to characters i thru ns of scriptFile as string
			exit repeat
		end if
	end repeat
end if
set destFile to appSupport & "Scripts:" & fldr & ":" & scriptFile

-- confirm replace if destFile exists
set oldFile to "no"
tell application "Finder"
	if exists file destFile then
		set oldFile to "yes"
	end if
end tell

if oldFile is "yes" then
	tell application "GEDitCOM II"
		set repOption to user option title Â
			"The script '" & scriptFile & "' already exists" message Â
			"Would you like to replace it with a downloaded script?" buttons {"Replace", "Cancel"}
	end tell
	if repOption is "Cancel" then
		return
	end if
	
else
	-- make sure the folder exisit
	set sfolder to appSupport & "Scripts:" & fldr & ":"
	try
		tell application "Finder"
			if not (exists folder sfolder) then
				set baseFolder to appSupport & "Scripts:"
				make new folder at alias baseFolder with properties {name:fldr}
			end if
		end tell
	on error
		tell application "GEDitCOM II"
			user option title Â
				"A folder to save the downloaded script could not be created" message Â
				"You may not have permission to create folders at that location" buttons {"OK"}
		end tell
		return
	end try
end if

-- download zip file
try
	-- Using URL Access
	--tell application "URL Access Scripting"
	--	activate
	--	download srcPath to file destPath replacing yes
	--	quit
	--end tell
	-- Using curl
	set myFile to POSIX path of file destPath
	do shell script "curl -L " & srcPath & " -o '" & myFile & "'"
on error
	tell application "GEDitCOM II"
		user option title Â
			"The script file could not be downloaded" message Â
			"You can try downloading and/or expanding manually." buttons {"OK"}
	end tell
	return
end try

-- delete prior file if it was there
if oldFile is "yes" then
	try
		tell application "Finder"
			delete file destFile
		end tell
	on error
		tell application "GEDitCOM II"
			user option title Â
				"The previous script file could not be replaced" message Â
				"You may not have permission to delete files to that folder" buttons {"OK"}
		end tell
		return
	end try
end if

-- example the zip file
set zipPath to POSIX path of file destPath
set zipFolder to POSIX path of file (appSupport & "Scripts:" & fldr & ":")
set zipcmd to "ditto -x -k '" & zipPath & "' '" & zipFolder & "'"
try
	do shell script zipcmd
on error
	tell application "GEDitCOM II"
		user option title Â
			"The downloaded file could not be expanded" message Â
			"You can try downloading and/or expanding manually." buttons {"OK"}
	end tell
	return
end try

-- delete the downloaded zip file
tell application "Finder"
	delete file destPath
end tell

-- refresh scripts menu
tell application "GEDitCOM II"
	refresh scripts
end tell

(* Activate GEDitCOM II (if needed) and verify acceptable
     version is running. Return true or false if script can run.
*)
on CheckAvailable(sName, vNeed)
	tell application "GEDitCOM II"
		activate
		if versionNumber < vNeed then
			user option title "The script '" & sName & Â
				"' requires GEDitCOM II, Version " & vNeed & " or newer" message "Please upgrade and try again." buttons {"OK"}
			return false
		end if
	end tell
	return true
end CheckAvailable