(*	Fix Reunion GEDCOM File script
	GEDitCOM II AppleScript
	1 AUG 2009, Stéphane LeLaure
	
	Put a copy of this script in your system scripts
	folder and in your user scripts folder. Selecting
	the script will open that folder in the Finder and
	you can double click any script to edit in Apple's
	Script Editor
*)

tell application "Finder"
	set ScriptsWindow to container of (path to me) as string
	open ScriptsWindow
	activate
	select front window
end tell