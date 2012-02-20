(*	Address Book script
	GEDitCOM II Apple Script
	8 AUG 2010, by John A. Nairn

	This script goes through all or selected individuals and each one that
	has residence information (RESI) event is added to an 'Address Book'
	report.
	
	If using selected records, it is best if they are sorted
	alphabetically before running this script
*)

property scriptName : "Address Book Script"
global rpt, placeTag, dateTag, aletter, letIndex

-- if no document is open then quit
if CheckAvailable(scriptName, 1.5) is false then return

tell application "GEDitCOM II"
	-- choose all records or selected records (with option to cancel)
	set whichOnes to user option title Â
		"Which individuals searched for residences?" message Â
		"Search 'All' individuals in the file or just the currently 'selected' individuals." buttons {"All", "Cancel", "Selected"}
	if whichOnes is "Cancel" then return
	
	-- looking for residence events
	set theTag to "RESI"
	
	-- loop through all individuals or selected one
	if whichOnes is "All" then
		-- do all individuals
		tell front document
			display byType "INDI" sorting "view"
			set recs to every individual
		end tell
	else
		-- do just the selected records
		tell front document
			if window type is "IndexController" then
				display sorting "view"
			end if
			set recs to selected records
		end tell
	end if
	
	-- start report
	set rpt to {}
	set placeTag to local string for key "PLAC"
	set dateTag to local string for key "DATE"
	set aletter to ""
	set letIndex to "|"
	
	set {fractionStepSize, nextFraction} to {0.01, 0.01} -- progress reporting interval
	set numRecs to number of items in recs
	
	tell front document
		set found to 0
		repeat with i from 1 to numRecs
			set theRec to item i of recs
			tell theRec
				set resis to find structures tag theTag output "references"
				if (count of resis) > 0 then
					my AddAddresses(theRec, resis)
				end if
			end tell
			
			-- time for progress
			set fractionDone to i / numRecs
			if fractionDone > nextFraction then
				notify progress fraction fractionDone
				set nextFraction to nextFraction + fractionStepSize
			end if
		end repeat
	end tell
	
	-- end rpt
	set end of rpt to "</div>" & return
	
	-- preamble, title, and contents
	set preamble to "<div>" & return
	set preamble to preamble & "<head><style type='text/css'>" & return
	set preamble to preamble & "* { font-size: 9pt; line-height: 1.4;" & return
	set preamble to preamble & "font-family: 'Lucida Grande', Helvetica, Arial;}" & return
	set preamble to preamble & "table {border: none; margin-left: 0pt;}" & return
	set preamble to preamble & "table tbody td {vertical-align: top; border: none;}" & return
	set preamble to preamble & "h1 { font-size: 14pt; color: #000; " & return
	set preamble to preamble & "border: none; text-align:center;}" & return
	set preamble to preamble & "h2 { font-size: 12pt; color: #600; margin-left: 0pt;" & return
	set preamble to preamble & " border: none; padding-top: 12pt;}" & return
	set preamble to preamble & "</style></head>" & return
	
	set abook to local string for key "Address Book"
	set preamble to preamble & "<h1>" & abook & "</h1>" & return
	set preamble to preamble & "<center><p>" & letIndex & "</p></center>" & return
	
	-- full report
	set rptbody to preamble & (rpt as string)
	
	tell front document
		set newreport to make new report with properties {name:"Address Book", body:rptbody}
		show browser of newreport
	end tell
end tell

(* Add residences for one individual to the address report
*)
on AddAddresses(indiRec, resis)
	tell application "GEDitCOM II"
		-- name and letter
		set aname to name of indiRec
		if number of characters in aname > 0 then
			set newLetter to (first character of aname) as string
			if newLetter is not aletter then
				set aletter to newLetter
				set end of rpt to "<h2><a name='" & aletter & "'></a>" & aletter & "</h2>" & return
				set end of rpt to "<hr>" & return
				set letIndex to letIndex & "<a href='#" & aletter & "'>" & aletter & "</a>|"
			end if
		end if
		
		-- begin table with name in first column
		set end of rpt to "<table width='97%'>" & return
		
		set nr to number of items in resis
		repeat with i from 1 to nr
			-- get next RESI structure
			set resi to item i of resis
			
			-- Name or empty in column 1
			if i = 1 then
				set ilnk to "<a href='" & (id of indiRec) & "'>" & (name of indiRec) & "</a>"
				set end of rpt to "<tr><td width='25%'>" & ilnk & "</td>" & return
			else
				set end of rpt to "<tr><td width='25%'>&nbsp;</td>" & return
			end if
			
			-- RESI number if more than 1
			if nr > 1 then
				set end of rpt to "<td width='3%'>#" & i & "</td>" & return
			end if
			
			-- central column for address and multimedia
			if nr > 1 then
				set end of rpt to "<td width='52%'>"
			else
				set end of rpt to "<td width='55%' colspan='2'>"
			end if
			set rbreak to ""
			
			-- address (possible more than on ADDR)
			tell resi
				-- date and place
				set pdate to evaluate expression "DATE"
				if pdate is not "" then
					set end of rpt to "<font color='gray'>" & dateTag & ": </font>" & pdate
					set rbreak to "<br><br>" & return
				end if
				
				set pplace to evaluate expression "PLAC"
				if pplace is not "" then
					set pplace to safe html raw text pplace
					if rbreak is not "" then
						set end of rpt to "<br>" & return
					end if
					set end of rpt to "<font color='gray'>" & placeTag & ": </font>" & pplace
					set rbreak to "<br><br>" & return
				end if
				
				set addrs to find structures tag "ADDR" output "references"
				set na to number of items in addrs
				repeat with j from 1 to na
					set addr to item j of addrs
					
					-- main address (but break into lines
					set oneaddr to contents of addr
					if oneaddr is not "" then
						set oneaddr to safe html raw text oneaddr
						set alines to every paragraph of oneaddr
						set AppleScript's text item delimiters to "<br>" & return
						set end of rpt to rbreak & (alines as string)
						set AppleScript's text item delimiters to {""}
						set rbreak to "<br><br>" & return
					end if
					
					-- specific lines
					tell addr
						set adr1 to evaluate expression "ADR1"
						set adr1 to safe html raw text adr1
						set adr2 to evaluate expression "ADR2"
						set adr2 to safe html raw text adr2
						set city to evaluate expression "CITY"
						set city to safe html raw text city
						set stae to evaluate expression "STAE"
						set stae to safe html raw text stae
						set post to evaluate expression "POST"
						set post to safe html raw text post
						set ctry to evaluate expression "CTRY"
						set ctry to safe html raw text ctry
					end tell
					
					-- address line 1
					if adr1 is not "" then
						set slines to adr1
						set br to "<br>" & return
					else
						set slines to ""
						set br to ""
					end if
					
					-- address line 2
					if adr2 is not "" then
						set slines to slines & br & adr1
						set br to "<br>" & return
					end if
					
					-- city, state post
					if city is not "" then
						if stae is not "" then
							set csp to city & ", " & stae
						else
							set csp to city
						end if
					else if stae is not "" then
						set csp to stae
					else
						set csp to ""
					end if
					if post is not "" then
						if csp is not "" then
							set csp to csp & " "
						end if
						set csp to csp & post
					end if
					if csp is not "" then
						set slines to slines & br & csp
						set br to "<br>" & return
					end if
					
					-- country
					if ctry is not "" then
						set slines to slines & br & ctry
					end if
					
					if slines is not "" then
						set end of rpt to rbreak & slines
						set rbreak to "<br><br>" & return
					end if
					
				end repeat
				
				-- Get multimedia objects before end this tell
				set objes to find structures tag "OBJE" output "references"
			end tell
			
			-- Process OBJEs
			set urls to ""
			set nob to number of items in objes
			repeat with j from 1 to nob
				set obje to item j of objes
				set mid to contents of obje
				set mmrec to (a reference to multimedia id mid of front document)
				try
					set mmform to contents of structure named "FORM" of mmrec
				on error
					set mmform to "jpeg"
				end try
				if mmform is "url" or mmform is "URL" then
					-- url or email
					try
						set mmUrl to contents of structure named "_FILE" of mmrec
						if mmUrl is not "" then
							if urls is not "" then
								set urls to urls & "<br>" & return
							end if
							set urls to urls & "<a href='" & mmUrl & "'>" & mmUrl & "</a>"
						end if
					end try
				else
					set mpath to object path of mmrec
					if mpath is not "" then
						set mname to name of mmrec
						set end of rpt to rbreak & mname & "<br>" & return
						set end of rpt to "<img src='" & mpath & "' width='128'>" & return
						set rbreak to "<br><br>" & return
					end if
				end if
			end repeat
			
			set end of rpt to "</td>" & return
			
			-- phone numbers, email, URLS
			set end of rpt to "<td width='20%'>"
			
			tell resi
				-- phone numbers
				set phones to find structures tag "PHON" output "references"
				set np to number of items in phones
				set pbreak to ""
				repeat with j from 1 to np
					set phone to item j of phones
					set pnum to contents of phone
					if pnum is not "" then
						set end of rpt to pbreak & pnum
						set pbreak to "<br>" & return
					end if
				end repeat
				
				-- add urls
				if urls is not "" then
					set end of rpt to pbreak & urls
				end if
				
				set end of rpt to "</td>" & return
			end tell
			
			-- end row
			set end of rpt to "</tr>" & return
		end repeat
		set end of rpt to "</table>" & return
		
		set end of rpt to "<hr>" & return
	end tell
end AddAddresses

(* Activate GEDitCOM II (if needed) and verify acceptable
     version is running and a document is open. Return true
     or false if script can run.
*)
on CheckAvailable(sName, vNeed)
	tell application "GEDitCOM II"
		activate
		if versionNumber < vNeed then
			user option title "The script '" & sName & Â
				"' requires GEDitCOM II, Version " & vNeed & " or newer" message "Please upgrade and try again." buttons {"OK"}
			return false
		end if
		if number of documents is 0 then
			user option title "The script '" & sName & Â
				"' requires a document to be open" message "Please open a document and try again." buttons {"OK"}
			return false
		end if
	end tell
	return true
end CheckAvailable
