(*	Fix Reunion GEDCOM File script
	GEDitCOM II AppleScript
	31 JAN 2009, John A. Nairn
	
	The genealogy program Reunion exports GEDCOM files with many Reunion customizations
	and with some GEDCOM errors. If you get a file from Reunion, this script may repair
	many of these issues and give a better genealogy file having better compatibility
	with GEDitCOM II or with other GEDCOM software.
	
	To determine if the file is from Reunion, check the header record. If you open
	the file in GEDitCOM II, the information on the originating software will be
	in the header record notes.
	
	You can also run a "Validate GEDCOM Data" report. If you see errors like INDI._UID,
	INDI.ELEC, INDI.HEAL, INDI>ENGA, SOUR.TYPE, SOUR.DATE, OBJE._TYPE, OBJE._PRIM, etc.,
	if is probably a Reunion file.
	
	This script was based on an export of the Kennedy's example file that comes with
	Reunion. If fix all issues in that file, but may miss unknown issues of other files.
	After running this script, you should run another "Validate GEDCOM Data" report. If
	you find any new types of errors, please send the original GEDCOM file to
	john@geditcom.com and this script will be updated to handle the new issues, if
	possible.
*)

-- key properties and variables
property scriptName : "Fix Reunion GEDCOM File"
global changes

-- if no document is open then quit
if CheckAvailable(scriptName, 1.5) is false then return

set changes to 0
tell application "GEDitCOM II"
	
	-- INDI Records
	tell front document
		begin undo
		if (count of individuals) is not 0 then
			set indis to every individual
		else
			set indis to {}
		end if
		set {numFAM, numNOTE, numSOUR, numobje} to Â
			{count of families, count of notes, count of source, count of multimedia}
		set cstas to every gedcomRecord whose record type is "CSTA"
	end tell
	
	notify progress message "Fixing Individual Records"
	set numIndis to number of items in indis
	repeat with i from 1 to numIndis
		set indiRef to item i of indis
		my FixHealth(indiRef)
		my FixElection(indiRef)
		my FixEngagement(indiRef)
		
		-- Reunion has custom _UID tag that has no information useful to others
		my DeleteTag("_UID", indiRef)
	end repeat
	
	-- FAM Records
	if numFAM > 0 then
		notify progress message "Fixing Family Records"
		set fams to every family in front document
		set numFams to number of items in fams
		repeat with i from 1 to numFams
			-- Reunion has custom _UID tag that has no information useful to others
			my DeleteTag("_UID", item i of fams)
			my FixCSTA(item i of fams)
		end repeat
	end if
	
	-- SOUR Records
	if numSOUR > 0 then
		notify progress message "Fixing Source Records"
		set sours to every source in front document
		set numSours to number of items in sours
		repeat with i from 1 to numSours
			tell item i of sours
				-- Invalid TYPE tag changed to _TYPE
				try
					set name of structure named "TYPE" to "_TYPE"
					set changes to changes + 1
					if source type is "Web Site" then
						set source type to "web page"
					else if source type is "Periodical" then
						set source type to "article"
					else if source type is "Vital Record" then
						set source type to "vital records"
					end if
				end try
				-- Invalid DATE tag changed to _DATE
				try
					set name of structure named "DATE" to "_DATE"
					set changes to changes + 1
				end try
				-- Invalid URL tag changed to _URL
				try
					set name of structure named "URL" to "_URL"
					set changes to changes + 1
				end try
				
				-- fudge title if missing
				if source title is "" then
					if structure named "PERI" exists then
						set source title to contents of structure named "PERI"
						delete structure named "PERI"
						set changes to changes + 1
					else if structure named "_URL" exists then
						set source title to contents of structure named "_URL"
					else if structure named "PLAC" exists then
						set source title to contents of structure named "PLAC"
						delete structure named "PLAC"
						if source type is "vital records" then
							set sttl to source title
							set source title to sttl & " Vital Records"
							if source authors is not "" then
								set sttl to source authors & " " & sttl
							end if
							set source authors to sttl
						end if
						set changes to changes + 1
					else
						set source title to "Unknown source title"
					end if
				end if
				
				-- Invalid PERI, PAGE, and PLAC put into PUBL
				-- Not great solution, but at least valid GEDCOM
				set publish to source details
				if publish is not "" then
					set publish to publish & linefeed
				end if
				set prevChanges to changes
				try
					set journal to contents of structure named "PERI"
					delete structure named "PERI"
					set publish to publish & "Periodical: " & journal
					set sep to linefeed
					set changes to changes + 1
				on error
					set sep to ""
				end try
				try
					set pgnum to contents of structure named "PAGE"
					delete structure named "PAGE"
					set publish to publish & sep & "Page: " & pgnum
					set sep to linefeed
					set changes to changes + 1
				on error
					set sep to ""
				end try
				try
					set pname to contents of structure named "PLAC"
					delete structure named "PLAC"
					set publish to publish & sep & "Place: " & pname
					set changes to changes + 1
				end try
				if changes is not prevChanges then
					set source details to publish
				end if
				
			end tell
			
			-- Reunion name puts REPO name in REPO tag instead of
			-- creating a REPO record
			try
				set sourceRef to item i of sours
				tell sourceRef
					set repoName to contents of structure named "REPO"
				end tell
				if character 1 of repoName is not "@" then
					tell sourceRef
						delete structure named "REPO"
					end tell
					tell front document
						set rref to make new repository with properties {name:repoName}
						move rref to sourceRef
					end tell
					set changes to changes + 1
				end if
			end try
		end repeat
	end if
	
	-- OBJE Records
	if numobje > 0 then
		notify progress message "Fixing Multimedia Object Records"
		set objes to every multimedia in front document
		set numObjes to number of items in objes
		repeat with i from 1 to numObjes
			-- Reunion has custom _TYPE, _PRIM, _CROP, _SIZE
			-- Not used by GEDitCOM, so just delete them
			my DeleteTag("_TYPE", item i of objes)
			my DeleteTag("_PRIM", item i of objes)
			my DeleteTag("_CROP", item i of objes)
			my DeleteTag("_SIZE", item i of objes)
		end repeat
	end if
	
	-- NOTE Records
	if numNOTE > 0 then
		notify progress message "Fixing Note Records"
		set nts to every note in front document
		set numNts to number of items in nts
		repeat with i from 1 to numNts
			-- Reunion SOUR links subordinate to CONC with the notes text
			tell item i of nts
				set sublinks to find structures tag "SOUR" output "references"
				set ns to number of items in sublinks
				repeat with j from 1 to ns
					set sref to item j of sublinks
					if level of sref > 1 then
						move (item j of sublinks) to after last structure
						set changes to changes + 1
					end if
				end repeat
			end tell
		end repeat
	end if
	
	-- CSTA records
	if (count of cstas) > 0 then
		notify progress message "Deleting CSTA Records"
		repeat with i from 1 to count of cstas
			set cstaRecord to item i of cstas
			tell front document
				-- delete CSTA record after grab the text
				tell (last gedcomRecord whose record type is "CSTA")
					set cstaID to id
					set cstaText to evaluate expression "TEXT"
					delete
				end tell
				
				-- make new note record using its id
				make new note with properties {id:cstaID, notes text:cstaText}
				set changes to changes + 1
			end tell
		end repeat
	end if
	
	tell front document
		end undo action "Fix Reunion GEDCOM"
	end tell
	
	notify progress message "Done"
	
	-- alert when done
	if changes is 0 then
		set doneText to "No changes were made."
		user option title doneText buttons {"OK"}
		set doneMsg to "You should run a 'Validate GEDCOM Data' report to see "
		set doneMsg to doneMsg & "if all issues were fixed."
	else
		if changes is 1 then
			set doneText to "One change was made."
		else
			set doneText to (changes & " changes were made.") as string
		end if
		set doneMsg to "You should run a 'Validate GEDCOM Data' report to see "
		set doneMsg to doneMsg & "if all issues were fixed."
		user option title doneText message doneMsg buttons {"OK"}
	end if
	
end tell


(* Reunion use HEAL to link to a NOTE record about the person's health
	These tags should be changed to NOTE and here a comment will be
	added to the NOTE record that it is notes about the persons
	Health
*)
on FixHealth(indiRef)
	tell application "GEDitCOM II"
		tell indiRef
			set health to find structures tag "HEAL" output "references"
		end tell
		set nh to number of items in health
		if nh = 0 then return
		repeat with j from 1 to nh
			set sref to item j of health
			set noteID to contents of sref
			delete sref
			
			set inidName to alternate name of indiRef
			set nprefix to "<!--name " & inidName & " Health Information -->"
			tell front document
				tell note id noteID
					set newnotes to notes text
					set notes text to nprefix & return & newnotes
				end tell
				move note id noteID to indiRef
			end tell
			set changes to changes + 1
		end repeat
	end tell
end FixHealth

(* Reunion use ELEC for an election event. This event is in their sample
	file, but it is porbably not common in other files. It should
	be a generic EVEN with subordinate TYPE line for Election
*)
on FixElection(indiRef)
	tell application "GEDitCOM II"
		tell indiRef
			set elections to find structures tag "ELEC" output "references"
		end tell
		set ne to number of items in elections
		if ne = 0 then return
		repeat with j from 1 to ne
			set sref to item j of elections
			set name of sref to "EVEN"
			tell sref
				make new structure at before structure 1 with properties {name:"TYPE", contents:"Election"}
			end tell
			set changes to changes + 1
		end repeat
	end tell
end FixElection

(* Reunion attach child status (e.g., a note) to child links in the family
     when they should be NOTE attached in the individual FAMC link. Here will delete
     the CSTA and attach NOTE with that ID in the individual's record
*)
on FixCSTA(famRef)
	tell application "GEDitCOM II"
		tell famRef
			set chilStats to find structures tag "CSTA"
			if (count of chilStats) is 0 then return
			set famID to id
		end tell
		
		repeat with i from 1 to count of chilStats
			set ct to item i of chilStats
			set noteID to item 1 of ct
			set famLink to structure (item 2 of ct) of famRef
			
			-- delete the CSTA strcuture
			tell famLink
				set indiID to contents
				delete structure (item 3 of ct)
			end tell
			
			-- attach note to the individual
			tell individual id indiID of front document
				set famcLinks to find structures tag "FAMC" value famID output "references"
				if (count of famcLinks) > 0 then
					set famc to item 1 of famcLinks
					tell famc
						make new structure with properties {name:"NOTE", contents:noteID}
					end tell
				end if
			end tell
			
			set changes to changes + 1
		end repeat
	end tell
end FixCSTA

(* Reunion puts engament event incorrectly in the individual
	move to first family (could be error if person as multiple spouses)
*)
on FixEngagement(indiRef)
	tell application "GEDitCOM II"
		tell indiRef
			set engas to find structures tag "ENGA" output "references"
		end tell
		set ne to number of items in engas
		if ne = 0 then return
		repeat with j from 1 to ne
			set sref to item j of engas
			try
				tell indiRef
					set famID to contents of structure named "FAMS"
				end tell
				set fref to (a reference to family id famID of front document)
				move sref to after last structure of fref
				set changes to changes + 1
			end try
		end repeat
	end tell
end FixEngagement

(* Delete a tag from the current record
*)
on DeleteTag(tagName, recRef)
	tell application "GEDitCOM II"
		tell recRef
			try
				delete structure named tagName
				set changes to changes + 1
			end try
		end tell
	end tell
end DeleteTag

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

(* Give one item in a list returned by find structures in record
	recRef, return a refernce the the structure for that item
*)
on DeRef(refList, recRef)
	tell application "GEDitCOM II"
		tell recRef
			-- trace reference to the actual structure
			set snum to item 2 of refList
			set sref to (a reference to structure snum)
			repeat with k from 3 to number of items in refList
				set sref to (a reference to structure (item k of refList) of sref)
			end repeat
		end tell
		return sref
	end tell
end DeRef

