tell application "GEDitCOM II"
	set sm to scriptMessage
	set resiNum to word 1 of sm
	set phoneNum to word 2 of sm
	tell front document
		begin undo
		set recRef to key record
		tell recRef
			set resis to find structures tag "RESI" output "references"
			set theResi to item resiNum of resis
			tell theResi
				set phones to find structures tag "PHON"
				set pnum to (count of phones)
				if pnum = 0 then
					-- zero phones means nothing to remove
				else
					-- add one after current one
					set snum to item 2 of item phoneNum of phones
					delete structure snum
				end if
			end tell
		end tell
		end undo action "Remove Phone Number"
	end tell
end tell
