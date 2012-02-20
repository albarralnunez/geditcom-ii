tell application "GEDitCOM II"
	set message visible to false
	set sm to scriptMessage
	set resiNum to word 1 of sm
	set typeTag to word 2 of sm
	if typeTag = "URL" then
		set theTag to "OBJE"
	else
		set theTag to typeTag
	end if
	set locNone to local string for key "This individual does not have any data of that type to remove"
	set locOK to local string for key "OK"
	set locCancel to local string for key "Cancel"
	tell front document
		set recRef to key record
		tell recRef
			set currentResis to find structures tag "RESI" output "references"
			set resiRef to item resiNum of currentResis
			
			-- read potential tags
			tell resiRef
				set currentTags to find structures tag theTag
			end tell
		end tell
		
		-- check for none
		set numTags to (count of currentTags)
		if numTags = 0 then
			user option title locNone buttons {locOK}
			return
		end if
		
		-- list for selection
		set listTags to {}
		set numLocs to {}
		repeat with i from 1 to numTags
			set details to item i of currentTags
			
			if number of items in details is 2 then
				set snum to item 2 of item i of currentTags
				set recID to item 1 of details
				if theTag = "OBJE" then
					tell multimedia id recID
						set theForm to evaluate expression "FORM"
					end tell
					if theForm = "url" and typeTag = "URL" then
						set end of listTags to name of multimedia id recID
						set end of numLocs to snum
					else if theForm is not "url" and typeTag = "OBJE" then
						set end of listTags to name of multimedia id recID
						set end of numLocs to snum
					end if
				else
					set end of listTags to name of gedcomRecord id recID
					set end of numLocs to snum
				end if
			end if
		end repeat
		
		-- check for none
		set numTags to (count of listTags)
		if numTags = 0 then
			user option title locNone buttons {locOK}
			return
		end if
		
		if typeTag = "URL" then
			set prmpt to local string for key "Select URL or Email address to remove"
			set undact to "Remove URL or Email"
		else if typeTag = "OBJE" then
			set prmpt to local string for key "Select multimedia object to remove"
			set undact to "Remove a multimedia object"
		else
			set prmpt to local string for key "Select notes to remove"
			set undact to "Remove notes"
		end if
		
		-- pick one
		set rem to user choice prompt prmpt list items listTags buttons {locOK, locCancel}
		if item 1 of rem is locCancel then return
		set whichOne to item 1 of item 2 of rem
		repeat with i from 1 to numTags
			if item i of listTags is whichOne then
				set remNum to item i of numLocs
				exit repeat
			end if
		end repeat
		
		-- delete it
		begin undo
		delete structure remNum of resiRef
		end undo action undact
	end tell
end tell
