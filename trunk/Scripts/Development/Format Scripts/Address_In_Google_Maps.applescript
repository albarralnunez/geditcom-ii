tell application "GEDitCOM II"
	set message visible to false
	tell front document
		set details to editing details
		
		-- exit if empty structure (but should never happen when in format)
		if number of items in details < 3 then
			return
		end if
		
		-- build request
		set addrStruct to item 3 of details
		set addr to contents of addrStruct
		set addrWords to every word of addr
		set AppleScript's text item delimiters to "+"
		set query to addrWords as string
		set request to "http://maps.google.com/maps?hl=en&client=safari&rls=en&q=" & query
	end tell
end tell

open location request
