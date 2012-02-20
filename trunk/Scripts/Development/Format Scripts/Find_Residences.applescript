tell application "GEDitCOM II"
	set eventName to "Known Residences"
	set theTag to "RESI"
	set recs to every individual of front document
	
	set {fractionStepSize, nextFraction} to {0.01, 0.01}
	set numRecs to number of items in recs
	
	tell front document
		try
			set resiAlbum to album named eventName
		on error
			set resiAlbum to (make new album with properties {name:eventName})
		end try
		
		set found to 0
		repeat with i from 1 to numRecs
			set theRec to item i of recs
			tell theRec
				try
					set theEvent to structure named theTag
					set found to found + 1
					move theRec to resiAlbum
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
	
	-- alert when done
	if found = 0 then
		set res to "No individual with known residences were found."
	else
		if found = 1 then
			set res to "One record"
			set wverb to "was"
			set msg to "It is now in the 'Known Residences' album."
		else
			set res to "" & found & " individuals"
			set wverb to "were"
			set msg to "They are now all in the 'Known Residences' album."
		end if
		set res to res & " with one or more known residences " & wverb & " found."
	end if
	
	set message visible to false
	user option title res message msg buttons {"OK"}
end tell
