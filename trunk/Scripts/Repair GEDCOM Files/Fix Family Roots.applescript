(*	Fix Family Roots script
	AppleScript for GEDitCOM II
	1 Aug 2009, John A. Nairn
	
	An old genealogy program called Family Roots (FR) exports very poor GEDCOM files that are either a long-outdate
	GEDCOM style or just involve many non-standard methods choosen by FR (I am not sure which). These files
	include all family link information (links to father, mother, spouses, and children) in the individual
	records instead of in family records where they belong in GEDCOM 5.5. Some of these files have the family
	records, but others have none and therefore and hard to use with any genealogy software.
	
	You can recognize such files by looking in the header record and seeing the originating software called
	"FAMROOTS". If you open the file in GEDitCOM, this information will be found in the notes of the
	header record. You can also recognize such files by either having no family records or by having numerous
	unknown tags that will appear in the "Additional Data" section of GEDitCOM II. Some typical tags
	present will be ID, FATH, MOTH, MARR, NMAR, NCHI, and CHIL.
	
	If you find such a file, you can try this script. It may take a while (on a large file), but will finish
	and the AppleScript panel will show the progress. When done, you will possible have a reasonable good
	genealogy file.
	
	This script was tested with one large sample FR file and worked well, but may not handle all FR problems. When
	done, you should run GEDitCOM II's "Validate GEDCOM Data..." report. The sample file I used had numerous
	invalid dates. Most are easy to fix, but need to be fixed to have a valid GEDCOM data. Any other errors
	found, might be examples of other problems in FR files that were not in the one large test file. If you find
	such errors, please email a copy of the FR file and the validation report to john@geditcom.com and maybe
	fixing those problems can be added to this script.
*)

property scriptName : "Fix Family Roots"
global newAlbum
global missingParents, sexError

-- if no document is open then quit
if CheckAvailable(scriptName, 1.5) is false then return

-- choose all records or selected records (with option to cancel)
set whichOnes to "All"

-- loop through all individuals or selected one
set missingParents to 0
set sexError to 0
tell application "GEDitCOM II"
	if whichOnes is "All" then
		-- do all individuals
		set recs to every individual of front document
	else
		-- do just the selected records
		set recs to selected records of front document
	end if
	set num to number of items in recs
	
	set fractionStepSize to 0.01 -- progress reporting interval
	set nextFraction to fractionStepSize -- progress reporting interval
	tell front document
		begin undo
		
		-- first pass
		repeat with i from 1 to num
			my fixIndividualPassOne(item i of recs)
			set fractionDone to i / (2 * num)
			if fractionDone > nextFraction then
				notify progress fraction fractionDone
				set nextFraction to nextFraction + fractionStepSize
			end if
		end repeat
		
		-- second pass
		--display dialog "Click to start second pass and finish"
		repeat with i from 1 to num
			my fixIndividualPassTwo(item i of recs)
			set fractionDone to 0.5 + i / (2 * num)
			if fractionDone > nextFraction then
				notify progress fraction fractionDone
				set nextFraction to nextFraction + fractionStepSize
			end if
		end repeat
		
		end undo action "Fix Family Roots Data"
	end tell
end tell

-- alert when done
set smry to ""
if missingParents > 0 then
	set smry to smry & "There were " & missingParents & " individuals listed as parents that could not be found in the file." & return
end if
if sexError > 0 then
	set smry to smry & "There were " & sexError & " individuals with wrong sex and could not be attached as a spouse." & return
end if

return smry

(* Create family records for all parents and get children attached
	This method assume each individual has at most one FAMC link
*)
on fixIndividualPassOne(INDI)
	tell application "GEDitCOM II"
		
		tell INDI
			set fath to evaluate expression "FATH"
			if fath is not "" then
				delete structure named "FATH"
			end if
			set moth to evaluate expression "MOTH"
			if moth is not "" then
				delete structure named "MOTH"
			end if
			set famc to evaluate expression "FAMC"
		end tell
		
		-- is there one famc link?
		if famc is not "" then
			-- does the family exist yet?
			try
				tell front document
					set famRec to family id famc
					-- the family exists, attach individual only if needed
					tell famRec
						set theChil to find structures tag "CHIL" value (id of INDI)
					end tell
					if number of items in theChil is 0 then
						tell INDI to delete structure named "FAMC"
						move INDI to famRec
					end if
				end tell
			on error
				-- no family record so make it now and attach this person as child
				tell INDI to delete structure named "FAMC"
				tell front document
					-- process father
					if fath is not "" then
						try
							set fathRec to individual id fath
						on error
							set fathRec to ""
							set missingParents to missingParents + 1
						end try
					else
						set fathRec to ""
					end if
					if fathRec is not "" then
						tell fathRec
							-- delete the FAMS link if present
							set fams to find structures tag "FAMS" value famc output "references"
							if number of items in fams > 0 then
								set sref to item 1 of fams
								delete sref
							end if
						end tell
					end if
					
					-- process mother
					if moth is not "" then
						try
							set mothRec to individual id moth
						on error
							set mothRec to ""
							set missingParents to missingParents + 1
						end try
					else
						set mothRec to ""
					end if
					if mothRec is not "" then
						tell mothRec
							-- delete the FAMS link if present
							set fams to find structures tag "FAMS" value famc output "references"
							if number of items in fams > 0 then
								set sref to item 1 of fams
								delete sref
							end if
						end tell
					end if
					
					-- create the family, but don't attash husband or wife in create since that
					-- results in a delayed attachment
					set famRec to make new family with properties {id:famc}
					if fathRec is not "" then
						try
							set husband of famRec to fathRec
						on error
							set sexError to sexError + 1
						end try
					end if
					if mothRec is not "" then
						try
							set wife of famRec to mothRec
						on error
							set sexError to sexError + 1
						end try
					end if
					
					-- attach as child
					move INDI to famRec
				end tell
			end try
			
		end if
		
	end tell
end fixIndividualPassOne

(* Create family records for all parents and get children attached
	This method assume each individual has at most one FAMC link
*)
on fixIndividualPassTwo(INDI)
	tell application "GEDitCOM II"
		
		-- read data from the individual
		tell INDI
			-- record FAMS links and delete them
			set famsIDs to find structures tag "FAMS"
			set numf to number of items in famsIDs
			repeat with famj from numf to 1 by -1
				set snum to item 2 of item famj of famsIDs
				delete structure snum
			end repeat
			
			-- delete unneeded data
			try
				delete structure named "NCHI"
			end try
			try
				delete structure named "NMAR"
			end try
			try
				delete structure named "ID"
			end try
			try
				delete structure named "SURN"
			end try
			set IndiSex to evaluate expression "SEX"
			set indiID to id
			
		end tell
		
		-- loop over FAMS links
		repeat with i from 1 to numf
			-- read next items
			set famID to item 1 of item i of famsIDs
			
			tell front document
				try
					-- if family exists, see if indi needs to be attached as spouse
					set famRec to family id famID
					
				on error
					-- need to create family with this individual - don't attash husband or wife in create since that
					-- results in a delayed attachment
					set newRec to make new family with properties {id:famID}
					if IndiSex is "M" then
						set husband of newRec to INDI
					else
						set wife of newRec to INDI
					end if
					set famRec to ""
				end try
				
				if famRec is not "" then
					tell famRec
						if IndiSex is "M" then
							set spLink to find structures tag "HUSB" value indiID
						else
							set spLink to find structures tag "HUSB" value indiID
						end if
					end tell
					if number of items in spLink is 0 then
						-- attach as the spouse
						tell famRec
							if IndiSex is "M" then
								set husband to INDI
							else
								set wife to INDI
							end if
						end tell
					else
						-- reattach the FAMS
						tell INDI
							make new structure at after last structure with properties {name:"FAMS", contents:famID}
						end tell
					end if
				end if
				
			end tell
		end repeat
		
		-- move MARR structures to corresponding family records
		tell front document
			set fami to 0
			repeat
				set fami to fami + 1
				if fami > numf then
					exit repeat
				end if
				tell INDI
					try
						set marr to structure named "MARR"
					on error
						exit repeat
					end try
					tell marr
						try
							delete structure named "SPOU"
						end try
						try
							delete structure named "REMA"
						end try
						set numsub to number of structures
					end tell
					if numsub is 0 then
						delete structure named "MARR"
					end if
				end tell
				if numsub > 0 then
					set famID to item 1 of item i of famsIDs
					tell family id famID
						try
							set currentMarr to structure named "MARR"
						on error
							set currentMarr to ""
						end try
					end tell
					if currentMarr is not "" then
						tell INDI
							delete structure named "MARR"
						end tell
					else
						tell family id famID
							move structure named "MARR" of INDI to after last structure
						end tell
					end if
				end if
			end repeat
		end tell
		
		-- change all DWEL to 1 RESI 2 ADDR
		tell front document
			tell INDI
				repeat
					try
						set dwel to structure named "DWEL"
					on error
						try
							set dwel to structure named "ADDR"
						on error
							exit repeat
						end try
					end try
					set addr to contents of dwel
					delete dwel
					set RESI to make new structure with properties {name:"RESI"}
					tell RESI
						make new structure with properties {name:"ADDR", contents:addr}
					end tell
				end repeat
			end tell
		end tell
		
	end tell
end fixIndividualPassTwo

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
