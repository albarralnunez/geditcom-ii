property scriptName : "Find Lat, Lon"
tell application "GEDitCOM II"
	tell front document
		set details to editing details
		
		-- exit if empty structure
		if number of items in details < 3 then
			my ErrorExit("This field does not have a latitude and longitude.")
			return
		end if
		
		-- read latitude and longitude
		set gpsRef to item 3 of details
		set latlon to contents of gpsRef
		set AppleScript's text item delimiters to {","}
		if number of text items in latlon is not 2 then
			my ErrorExit("The field must contain latitude and longitude separated by a comma.")
			return
		end if
		
		-- find each
		set lat to text item 1 of latlon
		set lon to text item 2 of latlon
		set AppleScript's text item delimiters to {}
		
		-- latitide to signed number
		set latnum to my DecodeCoordinate(lat, "N", "S")
		if latnum is "error" then
			my ErrorExit("The latitude is neither a valid number nor a number with 'N' or 'S'")
			return
		end if
		
		-- longitude to signed number
		set lonnum to my DecodeCoordinate(lon, "E", "W")
		if latnum is "error" then
			my ErrorExit("The longitude is neither a valid number nor a number with 'W' or 'E'")
			return
		end if
		
		-- break into degrees
		set latdeg to my ConvertToDegrees(latnum, "N", "S")
		set londeg to my ConvertToDegrees(lonnum, "E", "W")
	end tell
end tell

-- form url
set ghurl to "http://toolserver.org/~geohack/geohack.php?params="
set ghurl2 to (item 2 of latdeg) & "_" & (item 3 of latdeg) & "_" & (item 4 of latdeg) & "_"
set ghurl3 to (item 1 of latdeg) & "_" & (item 2 of londeg) & "_" & (item 3 of londeg) & "_"
set ghurl4 to (item 4 of londeg) & "_" & (item 1 of londeg)
set ghurl to ghurl&ghurl2&ghurl3&ghurl4

open location ghurl

-- decode number and letter into signed number
on DecodeCoordinate(coord, posDir, negDir)
	try
		-- if number then done
		set cnum to coord as number
		return cnum
	on error
		-- see if sign character is present
		set soffset to offset of posDir in coord
		if soffset > 0 then
			set csign to 1
		else
			set soffset to offset of negDir in coord
			if soffset > 0 then
				set csign to -1
			else
				return "error"
			end if
		end if
	end try
	
	-- look at text before sign character
	if soffset > 1 then
		set pretext to (characters 1 thru (soffset - 1) of coord) as string
		try
			set cnum to pretext as number
			return cnum * csign
		end try
	end if
	
	-- look at text after the sign
	set clen to number of characters in coord
	if soffset < (clen - 1) then
		set posttext to (characters (soffset + 1) thru clen of coord) as string
		try
			set cnum to posttext as number
			return cnum * csign
		end try
	end if
	
	return "error"
end DecodeCoordinate

-- decode number into degrees, minutes, and seconds
on ConvertToDegrees(cnum, posDir, negDir)
	if cnum > 0 then
		set degs to {posDir}
	else
		set degs to {negDir}
		set cnum to -cnum
	end if
	
	-- degrees
	set deg to cnum as integer
	if deg > cnum then
		set deg to deg - 1
	end if
	set end of degs to deg
	set cnum to (cnum - deg) * 60
	
	-- minutes
	set mins to cnum as integer
	if mins > cnum then
		set mins to mins - 1
	end if
	set end of degs to mins
	
	set end of degs to RoundNum(((cnum - mins) * 60), 3)
	
	return degs
end ConvertToDegrees

(* Round number n to numDecimal digits *)
on RoundNum(n, numDecimals)
	if numDecimals = 0 then
		return round n as string
	end if
	set x to 10 ^ numDecimals
	set nstr to ((((n * x) + 0.5) div 1) / x) as string
	set decPt to offset of "." in nstr
	if decPt = 0 then
		set nstr to nstr & "."
		set extra to numDecimals
	else
		set extra to numDecimals - (number of characters in nstr) + decPt
	end if
	repeat with i from 1 to extra
		set nstr to nstr & "0"
	end repeat
	return nstr
end RoundNum

-- display message and then quit
on ErrorExit(msg)
	beep
    tell application "GEDitCOM II"
        set err to user option title msg
    end tell
end ErrorExit

