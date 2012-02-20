(*	Descendants Report script
	A GEDitCOM II AppleScript
	Jan 2009
	
	Report and script designed by David Walton (Jan 2009)
	Modified by John Nairn to allow option to be GEDitCOM II report
		or be sent to Pages
	
	This script compiles a descendants report (for any entered number
	of generations) using a narrative stlye. The report can be output
	to a GEDitCOM II report or to a Pages document. This script
	requires access to the Pages application.
	
	It should be possible to output the report to other software, such
	as MS Word, and that feature may be added in the future.
*)

property scriptName : "Descendants Report"
property strNoPlace : "an unknown place"
property strNoPartner : "an unknown partner"
global output, generations, rpt

if CheckAvailable(scriptName) is false then return

(* First find the selected individual. If a family is selected, transfer to
	the husband or wife if they are attached
*)
tell application "GEDitCOM II"
	set recSet to selected records of front document
	if number of items in recSet is not 0 then
		set IndvRec to item 1 of recSet
		if record type of IndvRec is "FAM" then
			set husbRef to husband of IndvRec
			if husbRef is not "" then
				set IndvRec to husbRef
			else
				set wifeRef to wife of IndvRec
				if wifeRef is not "" then
					set IndvRec to wifeRef
				end if
			end if
		end if
		set recType to record type of IndvRec
	else
		set recType to ""
	end if
end tell

-- exit if did not find an individual
if CheckType(recType) is false then return

-- generations option (must be integer 1 or higher)
set r to display dialog Â
	"Enter maximum number of generations in the report" default answer "4" buttons {"Cancel", "OK"} Â
	default button "OK" cancel button "Cancel" with title scriptName
if button returned of r is "Cancel" then return
set genNum to text returned of r
try
	set generations to genNum as integer
	if genNum < 1 then error
on error
	display dialog "The number of generations must be a number and be greater than zero." buttons {"OK"} default button "OK" with title scriptName
	return
end try

-- user output option
display dialog "Would you like the output to go to Pages or a GEDitCOM II Report?" buttons {"Cancel", "Pages", "Report"} default button "Report" cancel button "Cancel" with title scriptName
set output to button returned of the result
if output is "Cancel" then return


(* Build list of lists of descendants as
       RecSet = {{indi}, {chilg2-1, ... chilg2-n2}, {chilg3-1, ... chilg3-n3}, ... }
    or item i in this list is all individuals in that generation
  Also start ParentSet with individuals parents prenames
*)
tell application "GEDitCOM II"
	-- name of the report individual and the report title
	set IndvName to my getProperName(IndvRec)
	set topHead to "Descendants of " & IndvName
	
	-- start RecSet with generation 1
	set recSet to {IndvRec}
	
	-- get parent of this individual (usually father, but may be mother)
	set parentlist to parents of IndvRec
	set numparents to count of parentlist
	if numparents = 0 then
		set ParentSet to {{"Unknown"}}
	else
		set parentName to my getPrenames(item 1 of parentlist)
		set ParentSet to {{parentName}}
	end if
	
	-- add generation 2 (children of generation 1) to the RecSet
	set prevChil to children of IndvRec
	set end of recSet to prevChil
	
	-- add all children in each remaining generation
	repeat with gens from 1 to generations
		set listrecs to {}
		repeat with IndvRec in prevChil
			set listrecs to listrecs & (children of IndvRec)
		end repeat
		set end of recSet to listrecs
		set prevChil to listrecs
	end repeat
	
end tell

(**********  Begin the report with the individual name
*)
if output is "Report" then
	set rpt to "<div>" & styleSheet() & return
	set rpt to rpt & "<h1>" & topHead & "</h1>" & return
else
	-- check if Pages is open with a front document
	tell application "Pages"
		make document
		set titleStyle to {capitalization type:all caps, alignment:center, bold:true, italic:true, font size:14, font name:"Times New Roman"}
		set genStyle to {alignment:center, bold:false, italic:true, font size:14, font name:"Times New Roman"}
		set indiStyle to {indent level:1, prevent widows and orphans:true, keep with next paragraph:true, keep lines together:true, alignment:justify, italic:false, font size:12, font name:"Times New Roman"}
		set parentStyle to {prevent widows and orphans:true, keep with next paragraph:true, indent level:1, keep lines together:true, alignment:justify, italic:false, font size:12, font name:"Times New Roman"}
		set childStyle to {prevent widows and orphans:true, indent level:2, italic:true, bold:false, font size:10, font name:"Times New Roman"}
	end tell
	sendToPages(topHead, titleStyle, return & return, 0)
end if

(**********  Loop over the desired number of generations
     nextItem = count of individual in the report
*)
set fred to {} as list
set nextItem to 1
repeat with genLevel from 1 to generations
	
	-- number of individuals in this generation, report done if hits zero
	set genList to item genLevel of recSet
	set numThisGen to count of genList
	if numThisGen = 0 then exit repeat
	set ancestList to item genLevel of ParentSet
	set parentlist to {}
	
	(**********  Header for generation genLevel
       *)
	set subHead to "Generation No. " & genLevel
	if output = "Report" then
		set rpt to rpt & "<h2>" & subHead & "</h2>" & return
	else
		sendToPages(subHead, genStyle, return, 0)
	end if
	
	(**********  Process each individual in this generation; for each one:
	       1. Print their name, details, and spouses
	       2. For each family list children with that family
       *)
	repeat with indiNum from 1 to numThisGen
		set IndvRec to item indiNum of genList
		try
			set parentName to item indiNum of ancestList
		on error
			set parentName to "?"
		end try
		
		-- get main individual properties
		tell application "GEDitCOM II"
			tell IndvRec
				set IndvBir to evaluate expression "BIRT.DATE"
				set IndvBirPlace to evaluate expression "BIRT.PLAC"
				set IndvSex to evaluate expression "SEX"
				set IndvDet to evaluate expression "DEAT.DATE"
				set IndvDetPlace to evaluate expression "DEAT.PLAC"
				set Indvid to id
				set IndvAnchor to my makeAnchor(Indvid)
				set famslist to find structures tag "FAMS" output "references"
			end tell
		end tell
		
		-- Build text for the main individual
		set IndvName to getProperName(IndvRec)
		set IndvPreNames to getPrenames(IndvRec)
		if IndvBirPlace = "" then set IndvBirPlace to strNoPlace
		if IndvDetPlace = "" then set IndvDetPlace to strNoPlace
		if IndvDet = "" and IndvDetPlace = strNoPlace then
			set death to " and there are no known death details"
		else
			set death to " and died " & getproperDate(IndvDet) & " in " & IndvDetPlace
		end if
		
		(**********  For each family with this individual as spouse:
	            1. Get spouse details
	            2. Add full text to partners
		     3. Add just name to listpartner list
		     4. Add lists of children to childrenlist
		     5. Add parent prename to ParentSet
             *)
		set numfams to (count famslist)
		set listpartner to {}
		set childrenList to {}
		set partners to ""
		set numChildren to 0
		if IndvSex = "M" then
			set SexName to "He"
			set SexPoss to "His"
		else
			set SexName to "She"
			set SexPoss to "Her"
		end if
		repeat with i from 1 to numfams
			tell application "GEDitCOM II"
				set famsRef to item i of famslist
				set famID to contents of famsRef
				set FamilyRec to family id famID of front document
				--get properties of FamilyRec
				tell FamilyRec
					set marrdate to evaluate expression "MARR.DATE"
					set marrplace to evaluate expression "MARR.PLAC"
					if IndvSex = "M" then
						set recpartner to wife
					else
						set recpartner to husband
					end if
					set famChil to children
					set numChildren to numChildren + (count famChil)
					set end of childrenList to famChil
				end tell
			end tell
			
			-- text for this spouse
			if recpartner is not "" then
				set other to getProperName(recpartner)
			else
				set other to strNoPartner
			end if
			
			if marrplace = "" then set marrplace to strNoPlace
			if (marrdate = "" and marrplace = strNoPlace and other = strNoPartner) then
				if numfams = 1 then
					set PfxSpouse to "There is no spouse information."
				else
					set PfxSpouse to "(" & i & ") There is no spouse information. "
				end if
			else
				set PfxSpouse to SexName & " married "
				if i > 1 then
					set PfxSpouse to PfxSpouse & "(" & i & ") "
				end if
				if marrdate = "" then
					set PfxSpouse to PfxSpouse & other & " in " & marrplace & "."
				else
					set PfxSpouse to PfxSpouse & other & " " & getproperDate(marrdate) & " in " & marrplace & ". "
				end if
			end if
			
			-- full text to partners, name only to listpartner
			set partners to partners & PfxSpouse
			set listpartner to listpartner & other
		end repeat
		
		(**********  Output the current individual in the main list
              *)
		set main to " (" & parentName & ") " & "was born " & getproperDate(IndvBir) & " in " & Â
			IndvBirPlace & death & ". "
		
		if output = "Report" then
			set rpt to rpt & "<p><b>" & nextItem & ".</b> "
			set rpt to rpt & "<a name='" & IndvAnchor & "'></a>"
			set rpt to rpt & "<a href='" & Indvid & "'>" & IndvName & "</a>"
			set rpt to rpt & main
			set rpt to rpt & addParents(IndvRec, SexPoss)
			set rpt to rpt & partners & "</p>" & return
		else
			set mainText to (nextItem & ". " & IndvName & main) as string
			set mainText to mainText & addParents(IndvRec, SexPoss)
			set mainText to mainText & partners
			sendToPages(mainText, indiStyle, return, 1)
		end if
		
		(**********  Output the children for each family of this individual
              *)
		set offspring to ""
		if numChildren > 0 then
			set child to 0
			repeat with f from 1 to numfams
				set other to item f of listpartner
				set listfamchildren to item f of childrenList
				set numfamchildren to (count of listfamchildren)
				if numfamchildren > 0 then
					-- header for next block of children
					if output = "Report" then
						tell application "GEDitCOM II"
							set famsRef to item f of famslist
							set famID to contents of famsRef
						end tell
						set rpt to rpt & "<p class='fams'>Children of "
						set rpt to rpt & "<a href='" & famID & "'>" & IndvName & " and " & other & "</a>"
						set rpt to rpt & " are:</p>" & return
					else
						set childheader to "Children of " & IndvName & " and " & other & " are:"
						sendToPages(childheader, parentStyle, return, 0)
					end if
				end if
				
				-- list of children
				if output = "Report" then
					set rpt to rpt & "<blockquote>" & return
				end if
				repeat with i from 1 to numfamchildren
					set ChildRec to item i of listfamchildren
					tell application "GEDitCOM II"
						tell ChildRec
							set ChildBir to evaluate expression "BIRT.DATE"
							set ChildBirPlace to evaluate expression "BIRT.PLAC"
							set ChildAnchor to my makeAnchor(id)
							set listdesc to children
						end tell
					end tell
					
					-- special prefix if this child has children
					set child to child + 1
					if (count of listdesc) > 0 then
						set tag to "+"
						set wpos to 2
					else
						set tag to " "
						set wpos to 1
					end if
					
					if ChildBirPlace = "" then set ChildBirPlace to strNoPlace
					set ChildName to getProperName(ChildRec)
					set famoffspring to ", b. " & getproperDate(ChildBir) & ", in " & ChildBirPlace & "."
					
					if output = "Report" then
						if tag = " " then set tag to "&nbsp;&nbsp;"
						set rpt to rpt & "<p><i>" & tag
						set rpt to rpt & "<b>" & child & ".</b> "
						set rpt to rpt & "<a href='#" & ChildAnchor & "'>" & ChildName & "</a>"
						set rpt to rpt & famoffspring
						set rpt to rpt & "</i></p>" & return
					else
						sendToPages(tag & child & ". " & ChildName & famoffspring, childStyle, "", wpos)
					end if
					
					set pnames to IndvPreNames & ", " & parentName
					set end of parentlist to pnames
				end repeat
				
				-- end list of children i this family
				if output = "Report" then
					set rpt to rpt & "</blockquote>" & return
				else
					sendToPages(return, childStyle, "", 0)
				end if
				
			end repeat
		end if
		
		-- on to next individual
		set nextItem to nextItem + 1
	end repeat
	
	-- parents of next generation
	set end of ParentSet to parentlist
end repeat

if output = "Report" then
	tell application "GEDitCOM II"
		set rpt to rpt & "</div>"
		tell front document
			set newreport to make new report with properties {name:"Descendants Report", |body|:rpt}
			show browser of newreport
		end tell
	end tell
end if

return

--String parser for an individual's proper name 
on getProperName(recRef)
	set tempname to ""
	tell application "GEDitCOM II"
		tell recRef
			set NameList to find structures tag "NAME" output "references"
			if (count of NameList) is 0 then
				return ""
			end if
			set nameText to contents of item 1 of NameList
			set nameParts to name parts gedcom name nameText
			set fullName to (item 1 of nameParts) & (item 2 of nameParts) & (item 3 of nameParts)
		end tell
	end tell
end getProperName

(* Break date into parts and then reassembed with better description words
*)
on getproperDate(anydate)
	
	if anydate = "" then return "on an unknown date"
	
	-- split date into parts
	tell application "GEDitCOM II"
		tell individual 1 of front document
			set dparts to date parts full date anydate
		end tell
	end tell
	
	-- single item list is an error
	if number of items in dparts is 1 then
		return "on an unknown date"
	end if
	
	set pfx to item 1 of dparts
	set d1 to item 2 of dparts
	set conj to item 3 of dparts
	set d2 to item 4 of dparts
	set strPre to ""
	
	if pfx is "ABT" then
		return "about " & d1
		
	else if pfx is "AFT" then
		return "after " & d1
		
	else if pfx is "BEF" then
		return "before " & d1
		return strPre & item 2 of dparts
		
	else if pfx is "TO" then
		return "to " & d1
		
	else if pfx is "BET" then
		return "in the range " & d1 & "-" & d2
		
	else if pfx is "FROM" then
		if conj = "TO" then
			return "in the range " & d1 & "-" & d2
		else
			return "from " & d1
		end if
		
	else if pfx is "INT" then
		return item 5 of dparts
		
	else
		return d1
	end if
	
end getproperDate

(* Get name without surname
*)
on getPrenames(recRef)
	tell application "GEDitCOM II"
		tell recRef
			set NameList to find structures tag "NAME" output "references"
			if (count of NameList) is 0 then
				return "unknown"
			end if
			set nameText to contents of item 1 of NameList
			set nameParts to name parts gedcom name nameText
		end tell
	end tell
	set preName to (item 1 of nameParts)
	if length of preName is 0 then
		set preName to (item 2 of nameParts) & (item 3 of nameParts)
	end if
	set preWords to number of words in preName
	set preName to (words 1 thru preWords of preName)
	set text item delimiters to " "
	set preName to preName as string
	set text item delimiters to ""
	return preName
end getPrenames

(* convert ID to anchor without the at signs
*)
on makeAnchor(indiID)
	set alen to number of characters in indiID
	if alen < 2 then
		return "a" & indiID
	end if
	set subset to (characters 2 thru (alen - 1) of indiID as string)
	return "a" & subset
end makeAnchor

(* sentence about an individual parents
*)
on addParents(indiRef, possWord)
	tell application "GEDitCOM II"
		tell indiRef
			set famcID to evaluate expression "FAMC"
		end tell
		if famcID = "" then
			return possWord & " parents are not known. "
		end if
		set famcRef to a reference to family id famcID of front document
		
		-- get father and mother names (or "")
		try
			set FatherRef to husband of famcRef
			set fatherName to my getProperName(FatherRef)
		on error
			set fatherName to ""
		end try
		try
			set MotherRef to wife of famcRef
			set motherName to my getProperName(MotherRef)
		on error
			set motherName to ""
		end try
	end tell
	
	if motherName = "" and fatherName = "" then
		return possWord & " parents are not known. "
	else if motherName = "" then
		set retPar to possWord & " father was "
		set bothPar to fatherName
	else if fatherName = "" then
		set retPar to possWord & " mother was "
		set bothPar to motherName
	else
		set retPar to possWord & " parents were "
		set bothPar to fatherName & " and " & motherName
	end if
	
	if output = "Report" then
		return retPar & "<a href='" & famcID & "'>" & bothPar & "</a>. "
	else
		return retPar & bothPar & ". "
	end if
end addParents

(* Append theText to end of current text using paragraph properties in
     pstyle. When done and extra (some number of returns). If boldWord>0
	 make that word of the paragraph bold text
*)
on sendToPages(theText, pstyle, extra, boldWord)
	tell application "Pages"
		tell front document
			set paranum to count of paragraphs
			set last paragraph to theText & return & return
			tell paragraph paranum
				set properties to pstyle
				if boldWord > 0 then
					tell word boldWord
						set properties to {bold:true}
					end tell
				end if
			end tell
			set last character to extra
		end tell
	end tell
end sendToPages

(* Enhance the report style sheet with some modifications
*)
on styleSheet()
	set ss to "p { margin-left: 19pt;" & return
	set ss to ss & "  text-indent: -13pt; }" & return
	set ss to ss & " blockquote { margin-left: 36pt; }" & return
	set ss to ss & "blockquote p { margin-top: 1pt;" & return
	set ss to ss & "  margin-bottom: 1pt; }" & return
	set ss to ss & ".fams { text-indent: 0pt; }" & return
	return "<head><style type='text/css'>" & return & ss & "</style></head>"
end styleSheet


(* Make sure one document is open
*)
on CheckAvailable(sName)
	tell application "GEDitCOM II"
		if number of documents is 0 then
			display dialog "You have to open a document in GEDitCOM II to use this script" buttons {"OK"} default button "OK" with title scriptName
			return false
		end if
	end tell
	return true
end CheckAvailable

(* Error message if selected record is not an individual
*)
on CheckType(recType)
	if recType is "INDI" then return true
	display dialog "You have to select an individual in GEDitCOM II to use this script" buttons {"OK"} default button "OK" with title scriptName
	return false
end CheckType


