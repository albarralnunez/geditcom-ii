(*	importing Individuals in Tab-Delimited File script
	GEDitCOM II Apple Script
	7 JAN 2009, by John A. Nairn

	This script will import any tab-delimited file with data for individuals
	into the current front document.
	
	The requirements of the tab-delimited file are:
	
	1. The first row lists GEDCOM tags for the data in that column. For 
		subordinate data the tags are in the format "BIRT.DATE"
	2. The tags must be unique meaning you cannot, for example, import two
		census (CENS) events. The second one will overwrite the first one.
	3. Each row has data for a single individual
	4. The lines in the files must be terminated with line feed characters
		(ASCII 10). To work with other files, change the lineDelim property
		to the appropriate term (e.g., ASCII 13 for return character, or
		ASCII character 13 & ASCII character 10 for Windows carriage return
		and line feed (later has not been tested))
	
	Create family linkages is much harder. This script has some undocumented options,
	but they need work before the provided enough feature to support all
	family links. For now, this script should just be viewed as way to import new
	indviduals. After importing, you have to then manually link them into files
	in GEDitCOM II.
*)

-- key properties and variables
property scriptName : "Import Tab Delimited Script"
property fieldDelim : tab
property lineDelim : ASCII character 10
global impData, columns, recLine, tags

-- if no document is open then quit
if CheckAvailable(scriptName, 1.5) is false then return

-- get file name
copy (choose file with prompt "Select Tab-Delimited File to Import") to txtfile
open for access txtfile
set impData to read txtfile using delimiter lineDelim
close access txtfile

-- must have at least the header line and 1 record line
set numLines to number of items in impData
if numLines < 2 then
	display dialog "No data could be found in that file." buttons {"OK"} default button "OK" with title scriptName
	return
end if
-- faster to use a reference to the read a list according to Apple
set refData to a reference to impData

-- first line is list of tags
-- decode into list of lists of tags with one for each column
-- for example { {NAME}, {BIRT, DATE}, {BIRT, PLAC} } in final tags
set tagLine to item 1 of refData
set tags to {}
set the text item delimiters to {fieldDelim}
set columns to number of text items in tagLine
repeat with i from 1 to columns
	set tagExpr to text item i of tagLine
	set the text item delimiters to {"."}
	set numTags to number of text items in tagExpr
	set tagList to {}
	repeat with j from 1 to numTags
		set end of tagList to text item j of tagExpr
	end repeat
	set the text item delimiters to {fieldDelim}
	set end of tags to tagList
end repeat

-- decode each line read from the file
repeat with i from 2 to numLines
	set recLine to item i of refData
	tell application "GEDitCOM II"
		tell front document
			my fillRecord(make new individual)
		end tell
	end tell
end repeat

-- alert when done
set numLines to numLines - 1
if numLines is 1 then
	set msg to "1 record"
else
	set msg to ((numLines as string) & " records") as string
end if
return "Custom importing of " & msg & " was completed."

(* This subrotine will fill the new record referenced by recRef with the
	data in the global variable recLine. It will use the global variable
	tags to determine where to put the data
*)
on fillRecord(recRef)
	tell application "GEDitCOM II"
		repeat with j from 1 to columns
			-- read the next columnof data
			try
				set recData to text item j of recLine
			on error
				set recData to ""
			end try
			
			-- insert data if it is not empty
			if recData is not "" then
				-- get the tags for this column
				set tagList to item j of tags
				set numTags to number of items in tagList
				set tag1 to item 1 of tagList
				
				-- special case for single NAME tag
				if tag1 is "NAME" and numTags is 1 then
					tell recRef
						set name to recData
					end tell
					
				else
					-- get structure to set in current individual
					set sref to my GetStructure(tag1, recRef)
					set useRecRef to recRef
					set nextTag to 2
					
					-- need to trap those referencing a linked family record
					if (tag1 is "FAMC" or tag1 is "FAMS") and (numTags > 1) then
						-- get reference to the family, making one as needed
						set indiID to id of recRef
						set IndiSex to sex of recRef
						set tag2 to item 2 of tagList -- maybe HUSB, WIFE, spse, or CHIL or other
						set famID to contents of sref -- contents to FAMC or FAMS link in current indi
						
						-- if family was not created before, create it now
						if famID is "" then
							tell front document
								set linkfam to make new family
								set famID to id of linkfam
							end tell
							set useRecRef to linkfam
							
							-- set contents of link in recRef to point to new family
							set contents of sref to famID
							
							-- set return link in the new record
							if tag1 is "FAMC" then
								set backTag to "CHIL"
							else if tag2 is "HUSB" then
								set backTag to "WIFE"
							else if tag2 is "WIFE" then
								set backTag to "HUSB"
							else if IndiSex is "F" then
								set backTag to "WIFE"
							else
								set backTag to "HUSB"
							end if
							tell useRecRef
								set linkref to (make new structure with properties {name:backTag})
								set contents of linkref to indiID
							end tell
						else
							set useRecRef to family id famID of front document
						end if
						
						-- create individual linked to this family if needed
						if (tag2 is "HUSB" or tag2 is "WIFE" or tag2 is "spse") and (numTags > 2) then
							-- if used spse, find out which one
							if tag2 is "spse" then
								if IndiSex is "F" then
									set tag2 to "HUSB"
								else
									set tag2 to "WIFE"
								end if
							end if
							
							-- see if record was already created
							tell useRecRef
								set currentSpouse to evaluate expression tag2
							end tell
							if currentSpouse is "" then
								-- create the spouse
								tell front document
									set spouseRec to make new individual
								end tell
								if tag2 is "HUSB" then
									set sex of spouseRec to "M"
								else
									set sex of spouseRec to "F"
								end if
								set spouseid to id of spouseRec
								tell useRecRef
									set linkref to make new structure with properties {name:tag2}
									set contents of linkref to spouseid
								end tell
								set useRecRef to spouseRec
								
								-- link the new individual back to the family
								tell useRecRef
									set linkref to make new structure with properties {name:"FAMS"}
									set contents of linkref to famID
								end tell
							else
								-- use already-created spouse
								set useRecRef to individual id currentSpouse of front document
							end if
							
							-- go on to next tag within the individual record
							set tag3 to item 3 of tagList
							if tag3 is "NAME" and numTags is 3 then
								set name of useRecRef to recData
								set useRecRef to ""
							else
								-- get structure to set in the individual record
								set sref to my GetStructure(tag3, useRecRef)
								set nextTag to 4
							end if
							
						else
							-- get structure to set in the individual record
							set sref to my GetStructure(tag2, useRecRef)
							set nextTag to 3
						end if
						
					end if
					
					-- set contents of sref (it not set already) or find subordinate structure
					-- to set if there are remaining tags in tagList
					if useRecRef is not "" then
						repeat with k from nextTag to numTags
							set tagk to item k of tagList
							tell useRecRef
								try
									set subref to (a reference to structure named tagk of sref)
									name of subref
								on error
									tell sref
										set subref to (make new structure with properties {name:tagk})
									end tell
								end try
							end tell
							set sref to subref
						end repeat
						
						-- set the contents of the new structure
						set contents of sref to recData
					end if
				end if
			end if
		end repeat
	end tell
end fillRecord

-- get reference to structure with given tag in recRef
-- create the structure if not ther
on GetStructure(tag1, recRef)
	tell application "GEDitCOM II"
		tell recRef
			try
				set sref to (a reference to structure named tag1)
				name of sref
			on error
				set sref to (make new structure with properties {name:tag1})
			end try
		end tell
	end tell
	return sref
end GetStructure

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
