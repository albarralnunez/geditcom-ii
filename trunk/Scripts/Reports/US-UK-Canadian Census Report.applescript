(*  Census Report Script
     Written by Simon Robbins
     Some changes by John Nairn
     3 SEP 2010
	 
     This script cycles through each of the census events listed in CensusDates for
     every individual in the current database or for selected individuals.

     For each event found it puts the place in a table and the cell is coloured green.
     Pale green if the event is recorded but not place stated.

     Where an individual was definitely alive but no data is held the cell is coloured amber.

     Where an individual was definitely (or probably) dead or not yet born the
     cell is coloured grey.

     Where an individual was probably alive the cell is coloured red. (The intensity of the
     colour decreases as the probability decreases. When running the script the user is
     prompted to enter a maximum age. This is the age after which individuals are
     assumed to be probably dead.

     The dates are set up to search for UK, Canadian, os US census

     John Nairn Changes:
       - accepts census event within 120 days of the dates in CensusDates
       - calculates census SDNs once at the start in a new list
       - dereferences all global lists to help speed (but small effect since lists are small)
       - screen records before calling processRecords
          note: finds a few more to to use of SND min and max rather than always the min
       - use GEDitCOM 1.3 attributes (birth date, birth SDN, birth SDN max, birth place, and same for death and event)
       - tried to set "end of list" in some loops rather then setting an item
       - unRpt to a list rather than a string (converted to string at output)
           note: this was most important changed for speed
       - changed name to "British Census Report"
       - changed some properties to globals when they are always initialized anyway
       - added check for no records found
       - added option for Canada and US
	- added key

     Hint:
        You probably only want to report on individual known to be in the country relevant
		to the selected census information. A good way to do this is
	 1. Open search window and search for "Any Place" "contains" the country name
	 2. When found, save all search hits in a new album
	 3. Select all records in that album, run this script, and chose "Selected" individuals

*)

-- globals
property scriptName : "US-UK-Canadian Census Report"
property BritCensusDates : {"6 JUN 1841", "30 MAR 1851", "7 APR 1861", "2 APR 1871", "3 APR 1881", "5 APR 1891", "31 MAR 1901", "2 APR 1911"}
property BritCensusNames : {"1841", "1851", "1861", "1871", "1881", "1891", "1901", "1911"}
property CanCensusDates : {"1 JUL 1851", "1 JUL 1871", "1 JUL 1881", "1 MAY 1891", "29 APR 1901", "1 JUN 1906", "1 JUN 1911"}
property CanCensusNames : {"1851 (Partial)", "1871", "1881", "1891", "1901", "1906 (NW)", "1911"}
property USCensusDates : {"2 AUG 1790", "4 AUG 1800", "6 AUG 1810", "7 AUG 1820", "1 JUN 1830", "1 JUN 1840", "1 JUN 1850", "1 JUN 1860", "1 JUN 1870", "1 JUN 1880", "2 JUN 1890", "1 JUN 1900", "15 APR 1910", "5 JAN 1920", "1 APR 1930", "1 APR 1940"}
property USCensusNames : {"1790", "1800", "1810", "1820", "1830", "1840", "1850", "1860", "1870", "1880", "1890", "1900", "1910", "1920", "1930","1940"}
property speculative : {"ff1919", "ff3333", "ff4d4d", "ff6666", "ff8080", "ff9999", "ffb2b2", "ffcccc"}
global unRpt, minbdtesdn, maxbdtesdn, minddtesdn, maxddtesdn, MaxAge
global NumCENS, CensusSDNsRef, CensusSDNs, colnum, CensusDates, CensusNames
global ColData, ColDataRef, ColWithData, ColWithDataRef, colour, colourRef, speculativeRef

-- pick census dates and names by country
set CensusDates to BritCensusDates
set CensusNames to BritCensusNames

-- if no document is open then quit
if CheckAvailable(scriptName, 1.5) is false then return

tell application "GEDitCOM II"
	-- which census years?
	set cenOptions to {"US Censuses 1790 to 1940", "UK Censuses 1841 to 1911", "Canadian Census 1851 to 1911"}
	set thePrompt to "Select census group and then click button for which individual to include in the report:"
	set r to user choice prompt thePrompt list items cenOptions buttons {"All", "Selected", "Cancel"} title scriptName
	set whichOnes to item 1 of r
	if whichOnes is "Cancel" then return
	set cenGroup to item 1 of item 2 of r
	if cenGroup is "US Censuses 1790 to 1940" then
		set CensusDates to USCensusDates
		set CensusNames to USCensusNames
	else if cenGroup is "UK Censuses 1841 to 1911" then
		set CensusDates to BritCensusDates
		set CensusNames to BritCensusNames
	else
		set CensusDates to CanCensusDates
		set CensusNames to CanCensusNames
	end if
	
	-- Max Age option (must be integer 1 or higher)
	set thePrompt to "Enter maximum age after which persons with no death date are assumed dead"
	set r to user input prompt thePrompt initial text "80" title scriptName buttons {"OK", "Cancel"}
	if item 1 of r is "Cancel" then return
	set MaxAge to item 2 of r
	try
		set MaxAge to MaxAge as integer
		if MaxAge < 1 or MaxAge > 110 then error
	on error
		user option title "The maximum age must be a number and be between 1 and 110." buttons {"OK"} message "Please try the script again"
		return
	end try
	
	--calculate date ranges required in report and select records
	set colnum to (count of CensusDates)
	set CensusSDNs to {}
	repeat with i from 1 to colnum
		set end of CensusSDNs to item 1 of (sdn range full date (item i of CensusDates))
	end repeat
	set CensusSDNsRef to a reference to CensusSDNs
	set ColDataRef to a reference to ColData
	set ColWithDataRef to a reference to ColWithData
	set colourRef to a reference to colour
	set speculativeRef to a reference to speculative
	
	-- find date ranges from exact census dates
	set minbdtesdn to (item 1 of CensusSDNsRef) - (365 * MaxAge)
	set maxbdtesdn to item colnum of CensusSDNsRef
	set minddtesdn to item 1 of CensusSDNsRef
	set maxddtesdn to (item colnum of CensusSDNsRef) + (365 * MaxAge)
	
	if whichOnes is "All" then
		-- do all individuals
		tell front document
			set recs to every individual whose (birth SDN is not 0 or death SDN is not 0) and Â
				((birth SDN max > minbdtesdn and birth SDN < maxbdtesdn) or birth SDN = 0) and Â
				((death SDN max > minddtesdn and death SDN < maxddtesdn) or death SDN = 0)
		end tell
		--return (count of recs) as string
	else
		-- do just the selected records
		set selRecs to selected records of front document
		set numSel to count of selRecs
		set recs to {}
		repeat with x from 1 to numSel
			set oneRec to item x of selRecs
			if record type of oneRec is "INDI" then
				tell oneRec
					if (birth SDN is not 0 or death SDN is not 0) and Â
						((birth SDN max > minbdtesdn and birth SDN < maxbdtesdn) or birth SDN = 0) and Â
						((death SDN max > minddtesdn and death SDN < maxddtesdn) or death SDN = 0) then
						set end of recs to oneRec
					end if
				end tell
			end if
		end repeat
	end if
end tell

-- call method to process the records
tell application "GEDitCOM II"
	if (count of recs) is 0 then
		user option title "No selected records were found that could have census events for the selected censuses" buttons {"OK"}
		return
	end if
	
	set fName to name of front document
	tell front document
		
		my processRecords(recs)
		
	end tell
end tell

-- prepare report
set rpt to "<div>" & return

set rpt to rpt & "<h1>Census Events in " & cenGroup & " for " & fName & "</h1>" & return

set rpt to rpt & "<p>&nbsp;&nbsp;&nbsp;(<a href='#tablekey'>See Colour Key</a>)</p>" & return

set rpt to rpt & "<table width=1375 border=1 cellspacing=0 cellpadding=2>" & return

set rpt to rpt & "<tr><td width= 25>No.</td><td width= 325>Name</td><td width= 125>Birth</td><td width= 125>Death</td>"
set colnum to (count of CensusDates)
repeat with i from 1 to colnum
	set rpt to rpt & "<td width= 110>" & item i of CensusNames & "</td>"
end repeat
set rpt to rpt & "</tr>" & return

--set rpt to rpt & "<ol>" & return & (unRpt as string) & "</ol>" & return
set rpt to rpt & (unRpt as string) & return & "</table>" & return

-- key
set keytab to {"<br><a name='tablekey'></a>" & return & "<table>" & return}
set end of keytab to "<tr><th>Table Key</th></tr>" & return
set end of keytab to "<tr><td bgcolor=#009900>Census done, place entered</td></tr>" & return
set end of keytab to "<tr><td bgcolor=#33ff33>Census done, place not entered</td></tr>" & return
set end of keytab to "<tr><td bgcolor=#ff9900>Alive, not done</td></tr>" & return
set snum to number of items in speculative
repeat with i from 1 to snum
	set end of keytab to "<tr><td bgcolor=#" & item i of speculative & ">Alive likelihood = " & (snum + 1 - i) & ", not done</td></tr>" & return
end repeat
set end of keytab to "<tr><td bgcolor=#606060>Not Alive</td></tr>" & return
set end of keytab to "</table>" & return

-- end the report
set rpt to rpt & (keytab as string) & "</div>"

-- add report to document and open it
tell application "GEDitCOM II"
	tell front document
		set newreport to make new report with properties {name:"Census Report", body:rpt}
		show browser of newreport
	end tell
	tell application "Finder"
		set screen_size to bounds of window of desktop
		set screen_width to item 3 of screen_size
		set screen_height to item 4 of screen_size
	end tell
	tell application "GEDitCOM II"
		set br to bounds of front window
		if screen_width > 1450 then
			set item 1 of br to (screen_width - 1450) / 2
			set item 3 of br to screen_width - ((screen_width - 1450) / 2)
		else
			set item 1 of br to 22
			set item 3 of br to screen_width - 22
		end if
		set item 2 of br to 50
		set item 4 of br to screen_height - 50
		set bounds of front window to br
	end tell
	
end tell

return



on processRecords(recSet)
	tell application "GEDitCOM II"
		set fractionStepSize to 0.01 -- progress reporting interval
		set nextFraction to fractionStepSize -- progress reporting interval
		set unRpt to {}
		set linenum to 0
		set num to number of items in recSet
		repeat with r from 1 to num
			set IndiRec to item r of recSet
			
			
			tell IndiRec
				set bdate to birth SDN
				set ddate to death SDN
				
				set ColDataRef to {}
				repeat with x from 1 to colnum
					set end of ColDataRef to ""
				end repeat
				set cens to find structures tag "CENS" output "references"
				set cnum to number of items in cens
				
				
				repeat with c from 1 to cnum
					set crec to item c of cens
					tell crec
						set cdate to (event SDN + event SDN max) / 2
						set cplac to event place
						
						repeat with x from 1 to colnum
							set cdiff to cdate - (item x of CensusSDNsRef)
							if cdiff > -120 and cdiff < 120 then
								if cplac is not "" then
									set item x of ColDataRef to cplac
								else
									set item x of ColDataRef to "Not entered"
								end if
							end if
						end repeat
						
					end tell
				end repeat
				
				-- Work out which columns have data
				set ColWithDataRef to {}
				repeat with x from 1 to colnum
					if item x of ColDataRef is not "" then
						set end of ColWithDataRef to x
					else
						set end of ColWithDataRef to ""
					end if
				end repeat
				
				
				--Calculate cell colour
				
				set colourRef to {}
				repeat with x from 1 to colnum
					set thisColour to "ffffff"
					-- If person not yet born or already died at time of census colour cell grey
					if (bdate > item x of CensusSDNsRef) or (ddate < item x of CensusSDNsRef) then
						set thisColour to "606060"
					end if
					
					--If census record exists but no place entered colour cell light green
					if item x of ColDataRef is "Not Entered" then
						set thisColour to "33ff33"
					end if
					
					--If census record exists and place entered colour cell dark green
					if item x of ColDataRef is not "Not Entered" and item x of ColDataRef is not "" then
						set thisColour to "009900"
					end if
					
					--If census record does not exist but we know it must do colour cell amber
					if (bdate is not 0 or ddate is not 0) then
						if item x of ColDataRef is "" and (x - 1 is in ColWithDataRef or x - 2 is in ColWithDataRef or x - 3 is in ColWithDataRef or x - 4 is in ColWithDataRef or x - 5 is in ColWithDataRef or x - 6 is in ColWithDataRef or x - 7 is in ColWithDataRef or bdate < item x of CensusSDNsRef) and (x + 1 is in ColWithDataRef or x + 2 is in ColWithDataRef or x + 3 is in ColWithDataRef or x + 4 is in ColWithDataRef or x + 5 is in ColWithDataRef or x + 6 is in ColWithDataRef or x + 7 is in ColWithDataRef or ddate > item x of CensusSDNsRef) then
							set thisColour to "ff9900"
						end if
					end if
					
					if item x of ColDataRef is "" and bdate is 0 and (x - 1 is not in ColWithDataRef and x - 2 is not in ColWithDataRef and x - 3 is not in ColWithDataRef and x - 4 is not in ColWithDataRef and x - 5 is not in ColWithDataRef and x - 6 is not in ColWithDataRef and x - 7 is not in ColWithDataRef) then
						set y to round (((ddate) - (item x of CensusSDNsRef)) / 3652.5)
						if y > MaxAge / 10 or y < 1 then
							set thisColour to "606060"
						else
							set thisColour to item y of speculativeRef
						end if
					end if
					
					if item x of ColDataRef is "" and ddate is 0 and (x + 1 is not in ColWithDataRef and x + 2 is not in ColWithDataRef and x + 3 is not in ColWithDataRef and x + 4 is not in ColWithDataRef and x + 5 is not in ColWithDataRef and x + 6 is not in ColWithDataRef and x + 7 is not in ColWithDataRef) then
						set y to round (((item x of CensusSDNsRef) - (bdate)) / 3652.5)
						if y > MaxAge / 10 or y < 1 then
							set thisColour to "606060"
						else
							set thisColour to item y of speculativeRef
						end if
					end if
					
					set end of colourRef to thisColour
				end repeat
				
				
				
				set linenum to linenum + 1
				set end of unRpt to "<tr><td>" & linenum & ".</td><td><a href='" & (id of IndiRec) & "'>" & (name of IndiRec) & "</a></td>" & return
				
				set end of unRpt to "<td>" & birth date & "</td>" & "<td>" & death date & "</td>"
				
				repeat with x from 1 to colnum
					set end of unRpt to "<td bgcolor=#" & item x of colourRef & ">" & item x of ColDataRef & "</td>"
				end repeat
				
				set end of unRpt to "</tr>" & return
				
			end tell
			
			
			
			-- time for progress
			set fractionDone to r / num
			if fractionDone > nextFraction then
				notify progress fraction fractionDone
				set nextFraction to nextFraction + fractionStepSize
			end if
		end repeat
	end tell
end processRecords


(* Activate GEDitCOM II (if needed) and verify acceptable
     version is running and a document is open. Return true
     or false if script can run.
*)
on CheckAvailable(sName, vNeed)
	tell application "GEDitCOM II"
		activate
		if versionNumber < vNeed then
			user option title "The script '" & sName & Â
				"' requires GEDitCOM II, Version " & vNeed & Â
				" or newer" message "Please upgrade and try again." buttons {"OK"}
			return false
		end if
		if number of documents is 0 then
			user option title "The script '" & sName & Â
				Â
					"' requires a document to be open" message Â
				"Please open a document and try again." buttons {"OK"}
			return false
		end if
	end tell
	return true
end CheckAvailable