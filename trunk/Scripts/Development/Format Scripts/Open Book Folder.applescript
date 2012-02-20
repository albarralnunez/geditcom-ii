(*	Open book file in finder
*)
tell application "GEDitCOM II"
	set bookRef to ""
	set recSet to selected records of front document
	if number of items in recSet is not 0 then
		set bookRef to item 1 of recSet
		if record type of bookRef is not "_BOK" then
			set bookRef to ""
		end if
	end if
	if bookRef = "" then
		set opt to user option title "You have to select a book style record to use this script."
		return
	end if
	
	-- get folder name
	tell bookRef
		set fldr to evaluate expression "_FLDR"
	end tell
	if fldr = "" then
		set opt to user option title "The folder field for this book style record is empty."
		return
	end if
	set fldr to fldr & "/BookLaTeXBody.pdf"
end tell

-- open the folder
try
	set the_file to (POSIX file fldr) as alias
	tell application "Preview"
		open the_file
	end tell
on error
	tell application "GEDitCOM II"
		set opt to user option title "The output file could not be found. Run the script to create it."
	end tell
end try