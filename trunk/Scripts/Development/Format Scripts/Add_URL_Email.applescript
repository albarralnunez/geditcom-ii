tell application "GEDitCOM II"
	set snum to scriptMessage
	tell front document
		set thePrompt to "Enter an URL (beginning in 'http') or an Email address (containing '@'):"
		set urlData to user input prompt thePrompt title "Add URL or Email" buttons {"Add", "Cancel"} initial text "http://"
		if item 1 of urlData is "Cancel" then return
		
		-- URL or email
		set newURL to item 2 of urlData
		set prot to ""
		if number of characters in newURL > 0 then
			set prot to (characters 1 thru 4 of newURL) as string
		end if
		if prot is not "http" then
			set atLoc to offset of "@" in newURL
			if atLoc ² 0 then
				set theTitle to "The entered text does no tappear to be an email address or an web URL."
				set theMsg to "URLs must begin in 'http' and email addresses must contain '@'"
				user option title theTitle message theMsg buttons {"OK"}
				return
			end if
		end if
		
		if prot is "http" then
			set theFile to prot
		else
			set theFile to "mailto:" & newURL
		end if
		
		begin undo
		
		-- create OBJE record
		set newOBJE to make new multimedia with properties {name:newURL}
		tell newOBJE
			set fileTag to structure named "_FILE"
			set contents of fileTag to theFile
			make new structure with properties {name:"FORM", contents:"url"}
		end tell
		
		set recRef to key record
		if snum < 1 then
			move newOBJE to recRef
		else
			set mmID to id of newOBJE
			tell recRef
				set resis to find structures tag "RESI" output "references"
				set oneresi to item snum of resis
				tell oneresi
					make new structure with properties {name:"OBJE", contents:mmID}
				end tell
			end tell
		end if
		
		end undo action "Add new URL or Email"
	end tell
end tell
