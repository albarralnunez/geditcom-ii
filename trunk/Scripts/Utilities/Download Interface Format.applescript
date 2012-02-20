(*	GEDitCOM II Download Interface Format
	24 Jun 2010, by John A. Nairn
	
	Download list of available formats at
	
	     http://www.geditcom.com/interfaces/FileList.txt
	
	and let user pick one to download.
	
	Once selected, download zip file to target folder, expandma and switches to
	that format
*)

property scriptName : "Download Interface"

-- if no document is open then quit
if CheckAvailable(scriptName, 1.5) is false then return

-- read the list of available formats
-- Each format has two lines. First is zip file name, second is save
-- file name (without the ".gfrmt")
set intFiles to (do shell script "curl http://www.geditcom.com/interfaces/FileList.txt")

-- quit if fails
if character 1 of intFiles is not "#" then
	tell application "GEDitCOM II"
		user option title Â
			"The list of available formats could not be read" message Â
			"Check your Internet connection and try again" buttons {"OK"}
	end tell
	return
end if

-- break list into zip file names and .gfrmt file names (without the .gfrmt)
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
		"Select User Interface to Download" buttons {"To System Formats", "To User Formats", "Cancel"} title scriptName
end tell

-- exit if canceled
set btn to item 1 of newForm
if btn is "Cancel" then
	return
end if

-- find which one was selected
set downName to item 1 of item 2 of newForm
set downIndex to 0
repeat with i from 1 to number of items in fileDescrip
	if downName is item i of fileDescrip then
		set downIndex to i
		exit repeat
	end if
end repeat
if downIndex = 0 then
	return
end if
set zipFile to item downIndex of fileNames
set formatFile to item downIndex of fileDescrip

-- get path to appropriate folder
if btn = "To User Formats" then
	set zipFldr to "GEDitCOM II:Formats:"
	set relPath to "$USER/"
else
	set zipFldr to "GEDitCOM II:System:Formats:"
	set relPath to "$SYSTEM/"
end if
set appSupport to path to application support from user domain as string
set destPath to appSupport & zipFldr & zipFile
set destFile to appSupport & zipFldr & formatFile & ".gfrmt"
set srcPath to "http://www.geditcom.com/interfaces/" & zipFile

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
			"The inteface format '" & formatFile & "' already exists" message Â
			"Would you like to replace it with a downloaded format?" buttons {"Replace", "Cancel"}
	end tell
	if repOption is "Cancel" then
		return
	end if
end if

-- download zip file with URL Access
--tell application "URL Access Scripting"
--	activate
--	download srcPath to file destPath replacing yes
--	quit
--end tell

-- Using curl
set myFile to POSIX path of file destPath
do shell script "curl -L " & srcPath & " -o '" & myFile & "'"

-- delete prior file if it was there
if oldFile is "yes" then
	try
		tell application "Finder"
			delete file destFile
		end tell
	on error
		tell application "GEDitCOM II"
			user option title Â
				"The previous interface format file could not be replaced" message Â
				"You may mot have permission to write files to that folder" buttons {"OK"}
		end tell
		return
	end try
end if

-- expand the zip file
set zipPath to POSIX path of file destPath
set zipFolder to POSIX path of file (appSupport & zipFldr)
set zipcmd to "ditto -x -k '" & zipPath & "' '" & zipFolder & "'"
try
	do shell script zipcmd
on error
	tell application "GEDitCOM II"
		user option title Â
			"The download file could not be expanded" message Â
			"You can try downloading and/or expanding manually." buttons {"OK"}
	end tell
	return
end try

-- delete the downloaded zip file
tell application "Finder"
	delete file destPath
end tell

-- switch to the new format
tell application "GEDitCOM II"
	refresh formats
	set current format to (relPath & formatFile)
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