(*	Copy Special script
	GEDitCOM II Apple Script
	29 Oct 2009, by John A. Nairn

	This script copies specific information from currently selected records
	and places the text result on the clipboard. You can paste into an email
	message or into an text document. If multiple records are selected, it will
	oopy text for each one.
	
	To control what is copied for each type of record, edit the subroutine
	for that record. The subroutines are named copyTYPE(recRef)
	where TYPE is the GEDCOM record tag (e.g. INDI, FAM, etc.) and
	recRef is a reference to the record. Each subroutine returns a string
	with the desired information by that record.
*)

property scriptName : "Copy Special Script"

-- if no document is open then quit
if CheckAvailable(scriptName, 1.5) is false then return

-- get selected records
tell application "GEDitCOM II"
	set recs to selected records of front document
	if number of items in recs is 0 then
		beep
		user option title "You have to select one or more records to copy information from those records." buttons {"OK"}
		return
	end if
end tell

-- copy text for each record
set copyData to ""
tell application "GEDitCOM II"
	set fractionStepSize to 0.05 -- progress reporting interval
	set nextFraction to fractionStepSize -- progress reporting interval
	set num to number of items in recs
	repeat with i from 1 to num
		set recRef to item i of recs
		set recData to my copyRecord(recRef, record type of recRef)
		set copyData to copyData & recData
		
		-- if time, notify GEDitCOM II of the amount done
		set fractionDone to i / num
		if fractionDone > nextFraction then
			notify progress fraction fractionDone
			set nextFraction to nextFraction + fractionStepSize
		end if
	end repeat
end tell

set the clipboard to copyData
return

(* Copy specific data for each type of record. You can customize
       this method to determine what gets copied
*)
on copyRecord(recRef, recType)
	
	-- call method depending on record stype
	if recType is "INDI" then
		set recData to my copyINDI(recRef)
	else if recType is "FAM" then
		set recData to my copyFAM(recRef)
	else if recType is "HEAD" then
		set recData to my copyHEAD(recRef)
	else if recType is "SOUR" then
		set recData to my copySOUR(recRef)
	else if recType is "NOTE" then
		set recData to my copyNOTE(recRef)
	else if recType is "OBJE" then
		set recData to my copyOBJE(recRef)
	else if recType is "REPO" then
		set recData to my copyREPO(recRef)
	else if recType is "_LOG" then
		set recData to my copy_LOG(recRef)
	else if recType is "SUBM" then
		set recData to my copySUBM(recRef)
	else if recType is "SUBN" then
		set recData to my copySUBN(recRef)
	else
		set recData to "Unknown record type: " & recType & return
	end if
	
	-- return result and a return character
	return recData & return
end copyRecord

(* Copy INDI record information
*)
on copyINDI(recRef)
	set recData to ""
	tell application "GEDitCOM II"
		tell recRef
			-- name
			set iname to name of recRef
			set recData to recData & "Name: " & iname & return
			
			-- birth date
			set bdate to birth date user
			set bplace to birth place
		end tell
		set recData to recData & my DateAndPlaceString(bdate, bplace, "Born")
		
		-- death date
		tell recRef
			set bdate to death date user
			set bplace to death place
		end tell
		set recData to recData & my DateAndPlaceString(bdate, bplace, "Died")
		
		-- spouses and children
		set spouseRecs to spouse families of recRef
		set num to number of items in spouseRecs
		repeat with i from 1 to num
			set famRef to item i of spouseRecs
			
			-- spouse name
			try
				set sName to name of husband of famRef
			on error
				set sName to "(unknown)"
			end try
			if sName is iname then
				try
					set sName to name of wife of famRef
				on error
					set sName to "(unknown)"
				end try
			end if
			set recData to recData & "Spouse: " & sName & return
			
			-- marriage date
			tell famRef
				set bdate to marriage date user
				set bplace to marriage place
			end tell
			set recData to recData & my DateAndPlaceString(bdate, bplace, "  Married")
			
			-- children
			set chil to children of famRef
			set nc to number of items in chil
			if nc > 0 then
				set recData to recData & "  Children: "
				repeat with j from 1 to nc
					set chilRef to item j of chil
					if j > 1 then set recData to recData & "; "
					set recData to recData & (name of chilRef)
				end repeat
				set recData to recData & return
			end if
			
		end repeat
		
		-- parents
		set parRecs to parent families of recRef
		set num to number of items in parRecs
		repeat with i from 1 to num
			set parRef to item i of parRecs
			set famName to name of parRef
			set nw to offset of "Family" in famName
			if nw > 0 then
				set famName to (characters 1 thru (nw - 1) of famName) as string
			end if
			set recData to recData & "Parents: " & famName & return
		end repeat
		
	end tell
	return recData
end copyINDI

(* Copy FAM record information
*)
on copyFAM(recRef)
	set recData to ""
	tell application "GEDitCOM II"
		-- husband's name
		try
			set sName to name of husband of recRef
			if sex of husband of recRef is "M" then
				set sName to "Husband: " & sName
			else
				set sName to "Wife: " & sName
			end if
		on error
			set sName to "Husband: (unknown)"
		end try
		set recData to recData & sName & return
		
		-- wife's name
		try
			set sName to name of wife of recRef
			if sex of wife of recRef is "M" then
				set sName to "Husband: " & sName
			else
				set sName to "Wife: " & sName
			end if
		on error
			set sName to "Wife: (unknown)"
		end try
		set recData to recData & sName & return
		
		-- marriage date
		tell recRef
			set bdate to marriage date user
			set bplace to marriage place
		end tell
		set recData to recData & my DateAndPlaceString(bdate, bplace, "Married")
		
		-- children
		set chil to children of recRef
		set num to number of items in chil
		if num > 0 then
			set recData to recData & "Children:" & return
			repeat with i from 1 to num
				set theChil to item i of chil
				set recData to recData & "  " & name of theChil & ", "
				if sex of theChil is "M" then
					set recData to recData & "son"
				else
					set recData to recData & "daughter"
				end if
				
				tell theChil
					set bdate to birth date user
				end tell
				set recData to recData & my DateAndPlaceString(bdate, "", ", b")
				if last character of recData is not return then
					set recDate to recData & return
				end if
			end repeat
		end if
	end tell
	
	return recData
end copyFAM

(* Copy HEAD record information
*)
on copyHEAD(recRef)
	set recData to name of recRef & return
	tell application "GEDitCOM II"
		set recData to recData & "Filename: " & name of document 1 & return
		tell recRef
			set vn to evaluate expression "SOUR.VERS"
		end tell
	end tell
	set recData to recData & "Software: GEDitCOM II, version " & vn & return
	return recData
end copyHEAD

(* Copy NOTE record information
*)
on copyNOTE(recRef)
	set recData to "Notes: " & name of recRef & return
	tell application "GEDitCOM II"
		set recData to recData & (notes text of recRef) & return
	end tell
	return recData
end copyNOTE

(* Copy SOUR record information
*)
on copySOUR(recRef)
	tell application "GEDitCOM II"
		set recData to "Source: " & source title of recRef & return
		set sType to source type of recRef
		if sType is not "" then
			set recData to recData & "Type: " & source type of recRef & return
		end if
		set sAuthors to source authors of recRef
		if sAuthors is not "" then
			set recData to recData & "Authors: " & sAuthors & return
		end if
		set sDetails to source details of recRef
		if sDetails is not "" then
			set recData to recData & "Details: " & sDetails & return
		end if
		if sType is "Web Page" then
			set recData to recData & "URL: " & source url of recRef & return
		end if
		set sDate to source date of recRef
		if sDate is not "" then
			set recData to recData & "Date: " & sDate & return
		end if
	end tell
	return recData
end copySOUR

(* Copy REPO record information
*)
on copyREPO(recRef)
	set recData to "Repository: " & name of recRef & return
	set recData to recData & my GetTag(recRef, "ADDR", "Address")
	set recData to recData & my GetTag(recRef, "PHON", "Phone")
	set recData to recData & my GetTag(recRef, "_EMAIL", "E-mail")
	return recData
end copyREPO

(* Copy OBJE record information
*)
on copyOBJE(recRef)
	set recData to "Multimedia Object: " & name of recRef & return
	tell application "GEDitCOM II"
		set mform to (evaluate expression "FORM") of recRef
	end tell
	if mform is "url" or mform is "URL" then
		set mlabel to "URL"
	else
		set mlabel to "File"
	end if
	set recData to recData & my GetTag(recRef, "_FILE", mlabel)
	set recData to recData & my GetTag(recRef, "_LOC", "Location")
	set recData to recData & my GetTag(recRef, "_LOC._GPS", "Lat, Lon")
	set recData to recData & my GetTag(recRef, "_DATE", "Date")
	return recData
end copyOBJE

(* Copy _LOG record information
*)
on copy_LOG(recRef)
	set recData to "Research Log: " & name of recRef & return
	set recData to recData & my GetTag(recRef, "_OBJECT", "Objective")
	return recData
end copy_LOG

(* Copy SUBM record information
*)
on copySUBM(recRef)
	set recData to "Submitter: " & name of recRef & return
	set recData to recData & my GetTag(recRef, "ADDR", "Address")
	set recData to recData & my GetTag(recRef, "PHON", "Phone")
	set recData to recData & my GetTag(recRef, "_EMAIL", "E-mail")
	return recData
end copySUBM

(* Copy SUBN record information
*)
on copySUBN(recRef)
	set recData to name of recRef & return
	return recData
end copySUBN

(* combine date and place into a string
*)
on DateAndPlaceString(bdate, bplace, blabel)
	if bdate is not "" then
		set bdate to blabel & ": " & bdate
	end if
	if bplace is not "" then
		if bdate is "" then
			set bdate to blabel & ":"
		end if
		set bdate to bdate & " in " & bplace
	end if
	if bdate is not "" then
		set bdate to bdate & return
	end if
	return bdate
end DateAndPlaceString

(* add one tag if it is there using the provided label
*)
on GetTag(recRef, expr, label)
	tell application "GEDitCOM II"
		set gdata to (evaluate expression expr) of recRef
	end tell
	if gdata is not "" then
		return label & ": " & gdata & return
	else
		return ""
	end if
end GetTag

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