(* Preflight script to remove application support items
	that should no longer be there
*)

-- mute and restore later
set currentVol to output volume of (get volume settings)
set volume output volume 0

-- new style has all scripts in subfolders
-- latter will put path to all scripts in default install
set newScpts to {}

tell application "Finder"
	set appSup to path to application support folder
	try
		set scptFldr to folder "Scripts" in folder "GEDitCOMII" in appSup
	on error
		-- exit if cannot find the Scripts folder
		return
	end try
	
	-- make or use "Archived" folder
	try
		set archFldr to folder "Archived" in scptFldr
	on error
		try
			set archFldr to (make new folder at scptFldr with properties {name:"Archived"})
		on error
			-- can't find or create the archived folder so give up
			return
		end try
	end try
	
	-- read files and compare to new list
	-- moving any not in new list to the "Archived Folder"
	set i to 1
	repeat
		if i > number of files in scptFldr then exit repeat
		set nextFile to file i of scptFldr
		
		-- get name and extenions
		set oldScpt to (name of nextFile) as string
		set oldExt to (name extension of nextFile) as string
		
		-- get name without extension
		set numext to number of characters in oldExt
		if numext > 0 then
			set numext to -(numext + 2)
			set oldScptName to (characters 1 thru numext of oldScpt) as string
		else
			set oldScptName to oldScpt
		end if
		
		-- if old script is not in the subsequent install, then move it out
		if (oldScptName is not in newScpts) or (oldExt is not "scpt") then
			set moved to my MoveFile(oldScpt, scptFldr, archFldr)
			if moved is false then
				set i to i + 1
			end if
		else
			set i to i + 1
		end if
		
	end repeat
	
end tell

-- restore user volume
set volume output volume currentVol

return

-- move file named fname in fromFldr to toFldr
on MoveFile(fname, fromFldr, toFldr)
	tell application "Finder"
		try
			set mfile to file fname in fromFldr
			move mfile to toFldr with replacing
			return true
		end try
	end tell
	return false
end MoveFile