tell application "GEDitCOM II"
	set message visible to false
end tell

property INDIEventList : {"ADOP", "BAPL", "BAPM", "BARM", "BASM", "BIRT", "BLES", "BURI", "CAST", "CENS", "CHR", "CHRA", "CONF", "CONL", "CREM", "DEAT", "DSCR", "EDUC", "EMIG", "ENDL", "EVEN", "FCOM", "GRAD", "IDNO", "IMMI", "NATI", "NATU", "NCHI", "NMR", "OCCU", "ORDN", "PROB", "PROP", "REFN", "RELI", "RESI", "RETI", "SLGC", "SSN", "TITL", "WAC", "WILL"}
property FAMEventList : {"ANUL", "CENS", "DIV", "DIVF", "ENGA", "MARB", "MARC", "MARL", "MARR", "MARS", "NCHI", "REFN"}



tell application "Finder"
	set PasteData to (the clipboard)
end tell


tell application "GEDitCOM II"
	tell front document
		
		set props to properties
		set keyRec to (key record of props)
		set keytype to (class of key record) as string
		set keyRecRef to (id of keyRec)
		set keyDoc to (name of props)
		--Sometimes we get the wrong class so correct if necessary
		if keytype is "«class gcFa»" then
			set keytype to "Family"
		end if
		if keytype is "«class gcIn»" then
			set keytype to "Individual"
		end if
		if keytype is "«class gcSo»" then
			set keytype to "Source"
		end if
		if keytype is "«class gcHe»" then
			set keytype to "Header"
		end if
		if keytype is "«class gcSu»" then
			set keytype to "Submitter"
		end if
		if keytype is "«class gcRe»" then
			set keytype to "Repository"
		end if
		if keytype is "«class gcNo»" then
			set keytype to "Note"
		end if
		if keytype is "«class gcOb»" then
			set keytype to "Multimedia Object"
		end if
		if keytype is "«class gcLg»" then
			set keytype to "Research Log"
		end if
		
		try
			set word1 to first word of PasteData
			set word2 to second word of PasteData
		on error
			set word1 to ""
			set word2 to ""
		end try
		
		if word2 is not "SOUR" then
			
			if word1 is not 1 then
				if word2 is not in INDIEventList and word2 is not in FAMEventList then
					display dialog "You have not copied an event to the clipboard" buttons {"OK"} default button 1
					return
				end if
			end if
			
			if keytype is not in {"Individual", "Family"} then
				display dialog "You cannot paste an event into a " & keytype & " record." buttons {"OK"} default button 1
				return
			end if
			
			if keytype is "Family" and word2 is not in FAMEventList and word2 is in INDIEventList then
				display dialog "You have copied an individual event which cannot be pasted into a " & keytype & " record." buttons {"OK"} default button 1
				return
			end if
			
			if keytype is "Individual" and word2 is not in INDIEventList and word2 is in FAMEventList then
				display dialog "You have copied an family event which cannot be pasted into a " & keytype & " record." buttons {"OK"} default button 1
				return
			end if
			
			
			if word2 is not "CENS" then
				set newdate to user input prompt "Enter date for the event" title "Date" buttons {"OK"}
			end if
			if keytype is "Individual" then
				set newage to user input prompt "Enter age at event" title "Age" buttons {"OK"}
			else
				set husbnewage to user input prompt "Enter husband's age at event" title "Husband's Age" buttons {"OK"}
				set wifenewage to user input prompt "Enter wife's age at event" title "Wife's Age" buttons {"OK"}
			end if
			
			tell keyRec
				set existingged to gedcom of keyRec
				set gedcom of keyRec to existingged & return & PasteData
				--make new structure with properties {name:"CENS", gedcom:PasteData}
				set newstruct to last structure of keyRec
				tell newstruct
					set curdate to find structures tag "DATE" output "References"
					set curage to find structures tag "AGE" output "References"
					
					if name of newstruct is not "CENS" then
						--Enter date for the event unless it is a census where all dates are the same in a given year
						
						if curdate is not {} then
							set contents of item 1 of curdate to item 2 of newdate
						else
							if item 2 of newdate is not "" then
								make new structure with properties {name:"DATE"}
								set curdate to find structures tag "DATE" output "References"
								set contents of item 1 of curdate to item 2 of newdate
							end if
						end if
					end if
					
					if keytype is "Individual" then
						if curage is not {} then
							set contents of item 1 of curage to item 2 of newage
						else
							if item 2 of newage is not "" then
								make new structure with properties {name:"AGE"}
								set curage to find structures tag "AGE" output "References"
								set contents of item 1 of curage to item 2 of newage
							end if
						end if
					else
						set husbcurage to {}
						set wifecurage to {}
						repeat with a from 1 to number of items in curage
							if name of parent structure of item a of curage is "HUSB" then
								set husbcurage to parent structure of item a of curage
							else if name of parent structure of item a of curage is "WIFE" then
								set wifecurage to parent structure of item a of curage
							end if
						end repeat
						if husbcurage is not {} then
							if item 2 of husbnewage is not "" then
								set contents of item 1 of structure 1 of husbcurage to item 2 of husbnewage
							else
								delete husbcurage
							end if
						else
							if item 2 of husbnewage is not "" then
								set newhusbstruct to make new structure with properties {name:"HUSB"}
								tell newhusbstruct
									make new structure with properties {name:"AGE"}
									set husbcurage to find structures tag "AGE" output "References"
									set contents of item 1 of husbcurage to item 2 of husbnewage
								end tell
							end if
						end if
						if wifecurage is not {} then
							if item 2 of wifenewage is not "" then
								set contents of item 1 of structure 1 of wifecurage to item 2 of wifenewage
							else
								delete wifecurage
							end if
						else
							if item 2 of wifenewage is not "" then
								set newwifestruct to make new structure with properties {name:"WIFE"}
								tell newwifestruct
									make new structure with properties {name:"AGE"}
									set wifecurage to find structures tag "AGE" output "References"
									set contents of item 1 of wifecurage to item 2 of wifenewage
								end tell
							end if
						end if
					end if
				end tell
				
				set newstructged to gedcom of newstruct
				tell keyRec
					sort data (the events)
					set numstruct to number of items in structures
					repeat with s from 1 to numstruct
						if gedcom of structure s of keyRec is newstructged then
							set newstruct to (a reference to structure s of keyRec)
						end if
					end repeat
				end tell
				
				delay 0.1
				
				--Need to handle the sources now
				set sourdeletions to {}
				tell newstruct
					set sours to find structures tag "SOUR" output "References"
					set numsour to number of items in sours
					repeat with s from 1 to numsour
						repeat 1 times
							set cursourtitle to evaluate expression "SOUR.i." & s & ".TITL"
							tell item s of sours
								set cursourpage to evaluate expression "PAGE"
								set cursourdate to evaluate expression "DATA.DATE"
								set cursourtext to evaluate expression "DATA.TEXT"
								set cursourrole to evaluate expression "EVEN.ROLE"
								
								if "Census" is not in cursourtitle then
									set newsourpage to user input prompt "Enter source page reference" initial text cursourpage title cursourtitle buttons {"OK", "Delete Source"}
									
									if item 1 of newsourpage is "Delete Source" then
										--delete item s of sours
										set end of sourdeletions to item s of sours
										exit repeat
									end if
									
									set newsourdate to user input prompt "Enter source date" initial text cursourdate title cursourtitle buttons {"OK"}
									
									if item 2 of newsourpage is not "" then
										set cursourpagestruc to find structures tag "PAGE" output "references"
										if cursourpagestruc is {} then
											set cursourpagestruc to make new structure with properties {name:"PAGE"}
										end if
										set contents of item 1 of cursourpagestruc to item 2 of newsourpage
									end if
									
									if item 2 of newsourdate is not "" then
										set sourdatastruc to find structures tag "DATA" output "references"
										if sourdatastruc is {} then
											set sourdatastruc to make new structure with properties {name:"DATA"}
										end if
										tell item 1 of sourdatastruc
											set cursourdatestruc to find structures tag "DATE" output "references"
											if cursourdatestruc is {} then
												set cursourdatestruc to make new structure with properties {name:"DATE"}
											end if
											set contents of item 1 of cursourdatestruc to item 2 of newsourdate
										end tell
									end if
								end if
								
								
								if "Census" is in cursourtitle then
									set newsourtext to user input prompt "Enter source text" initial text cursourtext title cursourtitle buttons {"OK", "Delete Source"}
									if item 1 of newsourtext is "Delete Source" then
										--delete item s of sours
										set end of sourdeletions to item s of sours
										exit repeat
									end if
								else
									set newsourtext to user input prompt "Enter source text" initial text cursourtext title cursourtitle buttons {"OK"}
								end if
								set newsourrole to user input prompt "Enter role in event" initial text cursourrole title cursourtitle buttons {"OK"}
								
								
								if item 2 of newsourtext is not "" then
									set sourdatastruc to find structures tag "DATA" output "references"
									if sourdatastruc is {} then
										set sourdatastruc to make new structure with properties {name:"DATA"}
									end if
									tell item 1 of sourdatastruc
										set cursourtextstruc to find structures tag "TEXT" output "references"
										if cursourtextstruc is {} then
											set cursourtextstruc to make new structure with properties {name:"TEXT"}
										end if
										set contents of item 1 of cursourtextstruc to item 2 of newsourtext
									end tell
								end if
								
								if item 2 of newsourrole is not "" then
									set sourevenstruc to find structures tag "EVEN" output "references"
									if sourevenstruc is {} then
										set sourevenstruc to make new structure with properties {name:"EVEN"}
									end if
									tell item 1 of sourevenstruc
										set cursourrolestruc to find structures tag "ROLE" output "references"
										if cursourrolestruc is {} then
											set cursourrolestruc to make new structure with properties {name:"ROLE"}
										end if
										set contents of item 1 of cursourrolestruc to item 2 of newsourrole
									end tell
								end if
								
								
							end tell
						end repeat
					end repeat
					
					set deletenum to number of items in sourdeletions
					repeat with d from 0 to deletenum - 1
						delete item (deletenum - d) of sourdeletions
					end repeat
					
				end tell
			end tell
		else
			
			--if the tag of the paste data is SOUR then work out where to paste the source
			
			
		end if
	end tell
end tell
