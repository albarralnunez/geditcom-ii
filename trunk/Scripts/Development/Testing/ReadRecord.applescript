(*	Tell Me About the Record
	GEDitCOM II Apple Script
	12 DEC 2009, by John A. Nairn
	
	Simple use of Apple Script's "say" command
*)
-- these needs volume
set currentVol to output volume of (get volume settings)
if currentVol < 10 then
	set volume output volume 60
end if

-- loop through all families 
tell application "GEDitCOM II"
	tell front document
		set selrecs to selected records
		if (count of selrecs) is 0 then
			say "I can't read you anything because no record is selected." without waiting until completion
			return
		end if
		
		tell item 1 of selrecs
			set rt to record type
			if rt is "INDI" then
				set des to description output options {"BD", "BP", "DD", "DP", "SN", "MD", "MP", "CN", "SEX", "SAY"}
			else if rt is "FAM" then
				set des to description output options {"BD", "BP", "DD", "DP", "MD", "MP", "CN", "SEX", "SAY"}
			else if rt is "HEAD" then
				set vers to evaluate expression "SOUR.VERS"
				if vers is not "" then
					set vers to ", version " & vers
				end if
				set des to "This is the header record for this genealogy file. " & Â
					"It was created by jed it com two" & vers & ". "
				set hnote to evaluate expression "NOTE"
				set begnote to offset of "This GEDCOM file was originally" in hnote
				if begnote is not 0 then
					set nn to number of characters in hnote
					set hnote to ((characters (begnote + 11) thru nn) of hnote)
					set hnote to hnote as string
					set endnote to offset of ")." in hnote
					if endnote is not 0 then
						set hnote to ((characters 1 thru endnote) of hnote)
						set des to des & "This jed com" & (hnote as string)
					end if
				end if
			else if rt is "OBJE" then
				set des to description output options {"SAY", "BD", "BP"}
			else if rt is "SUBN" then
				set des to "This is the submission record for the file. It is used by members of the LDS Church for Temple Ready submissions of genealogy records."
			else
				-- SUBM, SUBM, NOTE,REPO
				set des to description output options {"SAY"}
			end if
		end tell
		if des is not "" then
			say des without waiting until completion
		else
			say "I don't know anything about this type of custom record." without waiting until completion
		end if
	end tell
end tell

return