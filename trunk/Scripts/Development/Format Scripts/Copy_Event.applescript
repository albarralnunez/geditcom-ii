property INDIEventList : {"ADOP", "BAPL", "BAPM", "BARM", "BASM", "BIRT", "BLES", "BURI", "CAST", "CENS", "CHR", "CHRA", "CONF", "CONL", "CREM", "DEAT", "DSCR", "EDUC", "EMIG", "ENDL", "EVEN", "FCOM", "GRAD", "IDNO", "IMMI", "NATI", "NATU", "OCCU", "ORDN", "PROB", "PROP", "REFN", "RELI", "RESI", "RETI", "SLGC", "SSN", "TITL", "WAC", "WILL"}
property FAMEventList : {"ANUL", "CENS", "DIV", "DIVF", "ENGA", "EVEN", "MARB", "MARC", "MARL", "MARR", "MARS", "SLGS"}

tell application "GEDitCOM II"
	set message visible to false
	tell front document
		set eventstruc to ""
		set props to properties
		try
			set keyref to item 3 of (editing details of props)
		on error
			set msg to "You need to select a non-blank editing field in the event to be copied."
			user option title "No event was selected" message msg buttons {"OK"}
			return
		end try
		
		set keylevel to level of keyref
		if keylevel is 1 then
			set eventstruc to keyref
		end if
		if keylevel is 2 then
			set eventstruc to parent structure of keyref
		end if
		if keylevel is 3 then
			set eventstruc to parent structure of parent structure of keyref
		end if
		if keylevel is 4 then
			set eventstruc to parent structure of parent structure of parent structure of keyref
		end if
		if keylevel is 5 then
			set eventstruc to parent structure of parent structure of parent structure of keyref
		end if
	end tell
	
	if eventstruc is "" or (name of eventstruc is not in INDIEventList and name of eventstruc is not in FAMEventList) then
		set msg to "You need to select a non-blank editing field in the event to be copied."
		user option title "The selected text is not part of an event" message msg buttons {"OK"}
		return
	else
		set copydata to (gedcom of eventstruc) as string
	end if
	
	try
		set the clipboard to copydata
	on error
		user option title "Unable to put the data on the system clipboard" buttons {"OK"}
	end try
	
end tell

