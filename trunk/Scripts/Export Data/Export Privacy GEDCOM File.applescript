(*	Export Privacy GEDCOM script
	GEDitCOM II Apple Script
	5 JAN 2009, by John A. Nairn
	
	This script will export a GEDCOM file but will handle records
	marked as "Privacy" records differently. To mark records as
	"Privacy" records in GEDitCOM II, open the individual and select
	the Attach->Restriction menu command.
	
	For privacy records, the export will include only the family links
	which are required to generate family trees. For the name, you
	have the option of exporting the "Actual Name" or the text
	"Hidden Name"
*)

property scriptName : "Privacy GEDCOM File Script"
property recText : {}
global GEDFile
global gednum
global whichName
global numHidden

-- if no document is open then quit
if CheckAvailable(scriptName, 1.5) is false then return

-- get file name
copy (choose file name with prompt "Select Privacy GEDCOM File Name" default name "privacy.ged") to GEDFile
-- choose all records or selected records (with option to cancel)
tell application "GEDitCOM II"
	set whichName to user option title "Select export option for the names of privacy individuals." buttons {"Actual Name", "Cancel", "Hidden Name"}
	if whichName is "Cancel" then return
	
	set gednum to open for access GEDFile with write permission
	set numHidden to 0
	
	tell front document
		try
			my writeGEDOM(every header)
		end try
		try
			my writeGEDOM(every submission)
		end try
		try
			my writeGEDOM(every submitter)
		end try
		try
			my writeGEDOM(every individual)
		end try
		try
			my writeGEDOM(every family)
		end try
		try
			my writeGEDOM(every note)
		end try
		try
			my writeGEDOM(every source)
		end try
		try
			my writeGEDOM(every repository)
		end try
		try
			my writeGEDOM(every multimedia)
		end try
		try
			my writeGEDOM(every research log)
		end try
	end tell
end tell

write ("0 TRLR" & return) to gednum as Çclass utf8È
close access gednum

return

(* Given a list of GEDCOM records, write to the selected file
*)
on writeGEDOM(recRefs)
	local numRecs
	set numRecs to number of items in recRefs
	repeat with i from 1 to numRecs
		tell application "GEDitCOM II"
			tell item i of recRefs
				set resn to evaluate expression "RESN"
				if resn is "privacy" then
					set recText to {}
					set numHidden to numHidden + 1
					set end of recText to first line
					if whichName is "Actual Name" then
						set nameLine to structure named "NAME"
						set end of recText to (first line of nameLine)
					else
						set end of recText to "1 NAME Name /Hidden " & numHidden & "/" & return
					end if
					set end of recText to "1 RESN privacy" & return
					my writeLinks("FAMS", find structures tag "FAMS")
					my writeLinks("FAMC", find structures tag "FAMC")
					set recString to recText as string
				else
					set recString to gedcom
				end if
			end tell
		end tell
		write recString to gednum as Çclass utf8È
	end repeat
end writeGEDOM

(* Write family links at level 1 to a privacy individual
 	Input  is list of found structures
*)
on writeLinks(linkTag, foundTags)
	set numTags to number of items in foundTags
	repeat with i from 1 to numTags
		-- only include level 1 tags (i.e., 2 items in the found list)
		set oneTag to item i of foundTags
		if number of items in oneTag is 2 then
			set end of recText to "1 " & linkTag & " " & item 1 of oneTag & return
		end if
	end repeat
end writeLinks

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
