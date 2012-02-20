(*	Check Sources quality script
	GEDitCOM II Apple Script
	After 'Check Has Died, 6 July 2009, by John A. Nairn'
	26 May 2010, Lindsay Crawford

	It is essential to have good quality sources for your information.
	This script looks at all sources for birth, death, marriage, baptism,
	christening, burial, and cremation. If that event is in the file, it
	checks the source for the event and output the following options:
	
	1. Event Name - no source
	     This means the event is documented but it has no source
	2. Event Name - undefined quality
	     This means the event is sourced, the "Source" quality  was not documented
	3. Event Name - poor quality
	     This means the event is sources, but you indicated the source has poor quality
	
	This script assumes the family historian has identified the quality of each source,
	otherwise the report will return a lot of "undefined quality" results, even though
	source are present.
	
	To set source quality in GEDitCOM II when using the "Default Format"
	     a. Click the "i" icon in fron of the source
		 b. Choose the quality from the popup men
	
	A setting of "Unknown" will trigger "undefined quality" result while a setting
	of "Unreliable" will trigger a "poor quality" result.
*)

-- globals
property scriptName : "Check Sources Quality"
property QUALlist : {"no source", "undefined quality", "poor quality"}
global numChecked, numUncertain, unRpt

on run
	(*	Selection of the range of individuals to process
	processing the records
	assembling the report
*)
	-- if no document is open then quit
	if CheckAvailable(scriptName) is false then return
	
	-- choose all records or selected records (with option to cancel)
	set r to display dialog Â
		"Check source quality for births, deaths, and marriages for selected individuals or for all individuals" buttons {"Cancel", "Selected", "All"} Â
		default button "All" with title scriptName
	set whichOnes to button returned of r
	if whichOnes is "Cancel" then return
	
	
	-- start the report (list of uncertain individuals)
	set unRpt to {}
	
	-- loop through all individuals or selected ones
	set numChecked to 0
	set numUncertain to 0
	tell application "GEDitCOM II"
		if whichOnes is "All" then
			-- do all individuals
			set recs to every individual of front document
		else
			-- do just the selected records
			set recs to selected records of front document
		end if
	end tell
	
	-- call method to process the records
	tell application "GEDitCOM II"
		set fname to name of front document
		tell front document
			my ProcessRecords(recs)
		end tell
	end tell
	
	-- prepare report
	set rpt to "<div>" & return
	
	set rpt to rpt & "<h1>Checking Source Quality in " & fname & "</h1>" & return
	set rpt to rpt & "<p>"
	
	if numChecked = 0 then
		set rpt to rpt & "No BDM (<i>etc.</i>) sources were found. "
	else if numChecked = 1 then
		set rpt to rpt & "One BDM (<i>etc.</i>) source was found. "
	else
		set rpt to rpt & numChecked & " BDM (<i>etc.</i>) sources were found. "
	end if
	
	if numUncertain = 0 then
		set rpt to rpt & "There were no records found with poor quality sources.</p>" & return
	else
		set rpt to rpt & "The following " & numUncertain & " event"
		if numUncertain > 1 then
			set rpt to rpt & "s"
		end if
		set rpt to rpt & " need source work as follows:</p>" & return
		set rpt to rpt & "<ul><li>For &quot;no source&quot; find a source for that event</li>"
		set rpt to rpt & "<li>For &quot;undefined quality&quot, open the event details and enter a source quality rating</li>"
		set rpt to rpt & "<li>For &quot;poor quality&quot; find a better source for that event</li></ul>" & return
		
		set rpt to rpt & "<p>Individual records needing source work:</p>"&return
		
		-- add list of unknown individuals
		set rpt to rpt & "<ol>" & return & (unRpt as string) & "</ol>" & return
	end if
	
	-- end the report
	set rpt to rpt & "</div>"
	
	-- add report to document and open it
	tell application "GEDitCOM II"
		tell front document
			set newreport to make new report with properties {name:"BDM Source Quality Results", body:rpt}
			show browser of newreport
		end tell
	end tell
	
	return
end run

(*	Loop through the selected records. Skip if not an individual.
	Process, and add the outcome to the report
*)
on ProcessRecords(recSet)
	tell application "GEDitCOM II"
		
		set fractionStepSize to 0.01 -- progress reporting interval
		set nextFraction to fractionStepSize -- progress reporting interval
		
		set num to number of items in recSet
		repeat with i from 1 to num
			set recRef to item i of recSet
			if record type of recRef is "INDI" then
				
				-- next returns a list of 2 item lists eg { {BIRT,no source}, {MARR, poor quality},...}
				copy (my checkSourceQuality(recRef)) to statlst -- B M D bap chris bur crem eg {"BIRT","no source"}
				copy number of items in statlst to n
				set bdRpt to {}
				repeat with j from 1 to n
					set numChecked to numChecked + 1
					set statpair to item j of statlst
					copy (count of items of statpair) to ci
					if ci is 2 then
						copy statpair to {bdm, stat}
						if stat is in QUALlist then
							-- uncertain source, add to report
							set numUncertain to numUncertain + 1
							set end of bdRpt to bdm & ", " & stat & "; " & return
						end if
					end if
				end repeat
				if number of items in bdRpt > 0 then
					set end of unRpt to "<li><a href='" & (id of recRef) & "'>" & (name of recRef) & "</a>: "
					set end of unRpt to (bdRpt as string) & "</li>" & return
				end if
			end if
			
			-- time for progress
			set fractionDone to i / num
			if fractionDone > nextFraction then
				notify progress fraction fractionDone
				set nextFraction to nextFraction + fractionStepSize
			end if
		end repeat
	end tell
end ProcessRecords

(*	Check this individual's BIRT DEAT and FAMS.MARR are present.
	Also,look for baptism, christening, burial, cremation.
	Make sure they have a SOURce and if so that the best quality
	QUAY is Primary or Secondary
*)
on checkSourceQuality(INDI)
	copy {} to csq
	
	-- check birth
	copy SourQ("BIRT", INDI) to the end of csq
	
	-- check death
	copy SourQ("DEAT", INDI) to the end of csq
	
	-- check marriages
	copy getMarriages(INDI) to the end of csq
	
	-- more options
	
	-- baptism
	copy SourQ("BAPM", INDI) to the end of csq
	
	-- christening
	copy SourQ("CHR", INDI) to the end of csq
	
	--  burial
	copy SourQ("BURI", INDI) to the end of csq
	
	-- cremation
	copy SourQ("CREM", INDI) to the end of csq
	
	return delist(csq)
end checkSourceQuality

(* Check the source for the element given, eg BIRT, and return:
	1. "no source", if no SOUR
	2. "undefined quality", if SOUR but no QUAY
	3. "poor quality", if SOUR and QUAY < 2 (Secondary)
*)
on SourQ(theTag, INDI)
	
	set theItemQ to {"", ""}
	
	--	try
	tell application "GEDitCOM II"
		
		-- Get all of the TAG (eg BIRT, MARR) for the individual
		
		tell INDI to set theTAGlist to find structures tag theTag output "references"
		copy number of items in theTAGlist to n
		if n is 0 then return theItemQ -- no records of type theTag (eg BIRT)
		
		-- for each TAG record (usually only 1!) get the citations
		repeat with i from 1 to n
			set theTagRec to item i of theTAGlist
			
			-- -- Get all of the SOURces
			tell theTagRec to set citlist to find structures tag "SOUR" output "references"
			
			copy the number of items in citlist to nS
			if nS is 0 then return {theTag, item 1 of QUALlist} -- no records of type SOUR
			
			-- check the quality of each source and only note if worse than secondary
			
			copy 0 to maxQ
			
			repeat with j from 1 to nS -- for each SOUR
				set theSRC to item j of citlist
				
				-- Check the Source has a quality rating
				tell theSRC to set theQlist to find structures tag "QUAY" output "list"
				copy number of items in theQlist to nQ
				if nQ > 0 then
					repeat with k from 1 to nQ
						copy item 1 of item k of theQlist to theQuality
						-- Check the quality rating
						if theQuality > 1 then
							copy theQuality to maxQ
						end if
					end repeat
				else
					if j = 1 then
						copy theTag & ".SOUR" to item 1 of theItemQ
					else
						copy theTag & ".SOUR" & j to item 1 of theItemQ
					end if
					copy item 2 of QUALlist to item 2 of theItemQ
				end if
				if maxQ > 1 then copy {"", ""} to theItemQ
			end repeat
		end repeat
	end tell
	--	end try
	return theItemQ
end SourQ

(*	Get output for marriages, return empty if none, otherwise return 
	references eg {"MARR.SOUR","poor quality"}
*)
on getMarriages(INDI)
	
	tell application "GEDitCOM II"
		-- read marriage info
		tell INDI
			set famses to spouse families
			set nmr to number of items in famses
			if nmr is 0 then return {"", ""}
		end tell
	end tell
	
	-- for each marriage get source and quality
	set mq to {}
	repeat with m from 1 to nmr
		
		-- get details from the family record
		copy (item m of famses) to famRec
		copy SourQ("MARR", famRec) to lFam
		if lFam is not {"", ""} then
			if m is 1 then
				copy "MARR" to item 1 of lFam
			else
				copy "MARR" & m to item 1 of lFam
			end if
			copy lFam to the end of mq
		end if
	end repeat
	if mq is {} then copy {"", ""} to mq
	return mq
end getMarriages

(*	Flatten the list into a list of 2 item lists eg 
	{ {BIRT,no source},{DEAT,poor quality},..}
	Assumes that the list is at worst like this:
	{ {BIRT,no source},{DEAT,poor quality},{{MARR1,no source},{MARR2,no source}..}..}
	  *)
on delist(aList)
	
	copy {} to nulist
	copy the number of items in aList to ni
	repeat with i from 1 to ni
		copy item i of aList to lPair -- eg. {BIRT,no source} OR {{MARR1,no source},{MARR2,no source}}
		if the class of item 1 of lPair is list then
			copy the number of items in lPair to nn
			repeat with j from 1 to nn
				copy item j of lPair to the end of nulist
			end repeat
			
		else
			copy lPair to the end of nulist
		end if
	end repeat
	return nulist
end delist

(*	Start GEDitCOM II (if needed) and verify that a document is open
	return true or false if at least one document is open
*)
on CheckAvailable(sName)
	tell application "GEDitCOM II"
		if versionNumber < 1.09 then
			display dialog "This script requires GEDitCOM II, Version 1.1 or newer. Please upgrade and try again" buttons {"OK"} default button "OK" with title sName
			return false
		end if
		if number of documents is 0 then
			display dialog "You have to open a document in GEDitCOM II to use this script" buttons {"OK"} default button "OK" with title sName
			return false
		end if
	end tell
	return true
end CheckAvailable
