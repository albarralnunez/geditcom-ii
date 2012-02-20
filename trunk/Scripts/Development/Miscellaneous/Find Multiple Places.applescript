(*	GEDitCOM II Test Apple Script
	6 DEC 2009, by John A. Nairn
*)

property scriptName : "Find Multiple Places"

-- if no document is open then quit
if CheckAvailable(scriptName) is false then return

set fname to name of front document
set rpt to {"<div>" & return}
set end of rpt to "<h1>Check for Multple Places in " & fname & "</h1>" & return
set intro to "<p>Open each record, use Command-option-E to view GEDCOM data "
set intro to intro & "in the index window, and then remove unwanted places "
set intro to intro & "in the listed events.</p>" & return
set intro to intro & "<ol>" & return
set end of rpt to intro
set numIntro to number of items in rpt

tell application "GEDitCOM II"
	tell front document
		repeat with pass from 1 to 2
			if pass is 1 then
				set recs to (every individual whose gedcom contains "2 PLAC ")
			else
				set recs to (every family whose gedcom contains "2 PLAC ")
			end if
			set nc to number of items in recs
			repeat with i from 1 to nc
				set rec to item i of recs
				tell rec
					set hasName to false
					set plist to find structures tag "PLAC"
					set np to number of items in plist
					set lastp to -1
					repeat with p from 1 to np
						set plc to item p of plist
						if number of items in plc is 3 then
							set pnum to item 2 of plc
							if pnum is lastp then
								if hasName is false then
									set anchor to "<a href='" & id & "'>" & name & "</a>"
									set end of rpt to "<li>" & anchor & return & "<ul>"
									set hasName to true
									
									set evnt to name of structure pnum
									set evnt to local string for key evnt
									set end of rpt to "<li>" & evnt & "</li>" & return
								end if
							end if
							set lastp to pnum
						else
							set lastp to -1
						end if
					end repeat
					if hasName is true then
						set end of rpt to "</ul></li>" & return
					end if
				end tell
			end repeat
		end repeat
		
		-- output report
		if number of items in rpt is numIntro then
			set last item of rpt to "<p>No records with multiple places in the same event were found.</p>" & return
		else
			set end of rpt to "<ul>" & return
		end if
		set end of rpt to "</div>"
		set rpt to (rpt as string)
		set newreport to make new report with properties {name:"Multiple Places Report", body:rpt}
		show browser of newreport
	end tell
end tell

(* Start GEDitCOM II (if needed) and verify that a documenbt is open
	return true or false if at least one document is open
*)
on CheckAvailable(sName)
	tell application "GEDitCOM II"
		if versionNumber < 1.7 then
			display dialog "This script requires GEDitCOM II, Version 1.7 or newer. Please upgrade and try again" buttons {"OK"} default button "OK" with title sName
			return false
		end if
		if number of documents is 0 then
			display dialog "You have to open a document in GEDitCOM II to use this script" buttons {"OK"} default button "OK" with title sName
			return false
		end if
	end tell
	return true
end CheckAvailable
