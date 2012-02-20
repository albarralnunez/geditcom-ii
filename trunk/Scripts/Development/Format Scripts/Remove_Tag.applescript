tell application "GEDitCOM II"
	set message visible to false
	set typeTag to scriptMessage
	if typeTag = "URL" then
		set theTag to "OBJE"
	else
		set theTag to typeTag
	end if
	set locNone to local string for key "This individual does not have any data of that type to remove"
	set locOK to local string for key "OK"
	set locDate to local string for key "DATE"
	set locPlace to local string for key "PLAC"
	tell front document
		set recRef to key record
		tell recRef
			set currentTags to find structures tag theTag
			
			-- check for none
			set numTags to (count of currentTags)
			if numTags = 0 then
				user option title locNone buttons {locOK}
				return
			end if
		end tell
		
		-- list for selection
		set listTags to {}
		set numLocs to {}
		repeat with i from 1 to numTags
			set details to item i of currentTags
			
			if number of items in details is 2 then
				set resiNum to item 2 of details
				if theTag = "RESI" then
					set resiRef to structure resiNum of recRef
					tell resiRef
						set addr to evaluate expression "ADDR"
						if addr is "" then
							set addr to event place
							if addr is "" then
								set addr to event date user
								if addr is "" then
									set addr to "(residence with no place or address)"
								else
									set addr to locDate & ": " & addr
								end if
							else
								set addr to locPlace & ": " & addr
							end if
						else
							set addr to (first paragraph of addr)
							set addr to "Starting in: " & addr
						end if
					end tell
					set end of listTags to addr
					set end of numLocs to resiNum
				else if theTag = "NOTE" then
					set recID to item 1 of details
					set end of listTags to name of note id recID
					set end of numLocs to resiNum
				else
					set recID to item 1 of details
					tell multimedia id recID
						set theForm to evaluate expression "FORM"
					end tell
					if theForm = "url" and typeTag = "URL" then
						set end of listTags to name of multimedia id recID
						set end of numLocs to resiNum
					else if theForm is not "url" and typeTag = "OBJE" then
						set end of listTags to name of multimedia id recID
						set end of numLocs to resiNum
					end if
				end if
			end if
		end repeat
		
		-- check for none
		set numTags to (count of listTags)
		if numTags = 0 then
			user option title "This individual does not have any data of that type to remove." buttons {"OK"}
			return
		end if
		
		if typeTag = "RESI" then
			set prmpt to "Select residence to remove"
			set undact to "Remove a Residence"
		else if typeTag = "OBJE" then
			set prmpt to "Select multimedia object to remove"
			set undact to "Remove a multimedia object"
		else if typeTag = "URL" then
			set prmpt to "Select URL or Email address to remove"
			set undact to "Remove URL or Email"
		else
			set prmpt to "Select set of notes to remove"
			set undact to "Remove notes"
		end if
		
		-- pick one
		set rem to user choice prompt prmpt list items listTags
		if item 1 of rem is "Cancel" then return
		set whichOne to item 1 of item 2 of rem
		repeat with i from 1 to numTags
			if item i of listTags is whichOne then
				set remNum to item i of numLocs
				exit repeat
			end if
		end repeat
		
		-- delete it
		begin undo
		delete structure remNum of recRef
		end undo action undact
	end tell
end tell
