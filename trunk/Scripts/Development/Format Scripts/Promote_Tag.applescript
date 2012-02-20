tell application "GEDitCOM II"
	set message visible to false
	
	-- line 1 is the tag, 2 is text for missing text on line 1
	-- 3 is prompt, 4 is undo mssage
	--set sm to scriptMessage
	set sm to "_URL" & return & "(unnamed map)" & return & "Select web site to promote" & return & "Remove a map"
	set theTag to paragraph 1 of sm
	set noName to paragraph 2 of sm
	set inPrmpt to paragraph 3 of sm
	set inUndo to paragraph 4 of sm
	
	set locNoName to local string for key noName
	set locOK to local string for key "OK"
	set locCancel to local string for key "Cancel"
	tell front document
		set recRef to key record
		tell recRef
			set currentTags to every structure whose name is theTag
			-- check for none
			set numTags to (count of currentTags)
			if numTags = 0 then return
		end tell
		
		-- list for selection
		set listTags to {}
		repeat with i from 1 to numTags
			set oneTag to item i of currentTags
			set tcontents to contents of oneTag
			if tcontents is not "" then
				set end of listTags to tcontents
			else
				set end of listTags to locNoName
			end if
		end repeat
		
		-- pick one
		set prmpt to local string for key inPrmpt
		set undact to local string for key inUndo
		set rem to user choice prompt prmpt list items listTags buttons {locOK, locCancel}
		if item 1 of rem is locCancel then return
		set whichOne to item 1 of item 3 of rem
		if whichOne = 1 then return
		set theRef to item whichOne of currentTags
		
		-- delete it
		begin undo
		tell recRef
			move theRef to before structure named theTag
		end tell
		end undo action undact
	end tell
end tell
