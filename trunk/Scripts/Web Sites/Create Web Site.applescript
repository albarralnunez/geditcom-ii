(*	Create Web Site script for GEDitCOM II
	12 AUG 2009, by John A. Nairn, many revisions by Simon Robbins
	Lastest Revisions: 6 FEB 2011

	This script will create a complete, self-contained web site for the entire file including
	multimedia objects. The script will ask you to select a save location and will create a
	new folder named "GC Site #" (where "#" will be added, if needed, to make folder's
	name unique). The web site will be created and then automatically opened in Safari
	so you can browse and test it.
	
	For more details see http://www.geditcom.com/tutorials/createweb.html
	
	Before running the script, you should
	1. Enter name, email, and (optionally) phone number into main submitter record.
	    These details will add contact into to the web site. (Hint: if you have more
	    than one submitter record, you can find the main submitter from a link in the
	    Header record).
	2. You can attach a "Privacy" restriction to any records and their records
	    will hide all dates, places, events, notes, and multimedia files. The
	    web site will still link them to parents, spouses, and children. Note: to omit
	    marriage dates, both spouses have to be "Privacy" records.
	3. You can set "Distribution" on notes and multimedia object and then when
	    running this script choose to omit some or all of them. Example might be notes
	    on sensitive issues or unflattering photos.
		
	You are not limited to the style web site created by this script. You can
	copy the "Create Web Site.scpt" file from ~/Library/Application Support/GEDitCOM II/System/Scripts
	to the same location in your user folder (~/Library/Application Support/GEDitCOM II/Scripts)
	and then edit it with Apple's Script Editor. You can change the display or content as
	desired or use that script as a model for creating an entirely new web-site creation script.
	
	For more details, see http://www.geditcom.com/tutorials/customweb.html
	
	Edited by Simon Robbins to show events and attributes in a table with more detail
	and many other features
*)

property scriptName : "Create Web Site"
property rootName : "GC Site"
property eventOut : {"BIRT", "DEAT", "BAPM", "CHR", "CENS", "EMMI", "IMMI", "NATU", "BURI", "RESI", "GRAD"}
property eventName : {"Birth", "Death", "Baptism", "Christening", "Census", "Emigration", "Immigration", "Naturalization", "Burial", "Residence", "Graduated"}
property attrOut : {"DSCR", "EDUC", "NATI", "OCCU", "RELI", "TITL"}
property attrName : {"Description", "Education", "National or Tribal Origin", "Occupation", "Religion", "Nobility Title"}
property mmTypes : {"jpg", "jpeg", "gif", "tif", "tiff", "png", "mov", "pdf"}
property movieTypes : {"mov"}
property relink : {INDI:"I%@.html"}
property IndiPage : {}
property NameIndex : {}
property evntAttrNotes : {}
property noteIDList : {}
property SourceQuality : {"Unreliable", "Questionable", "Secondary", "Primary"}
property NumbsCard : {"one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen", "seventeen", "eighteen", "nineteen", "twenty"}
property NumbsOrd : {"first", "second", "third", "fourth", "fifth", "sixth", "seventh", "eightth", "ninth", "tenth", "eleventh", "twelveth", "thirteenth", "fourteenth", "fifteenth", "sixteenth", "seventeenth", "eighteenth", "nineteenth", "twentieth"}

global rootFldr -- root folder for saving the web site
global indiFldr -- folder to save individual records
global MediaFldr -- folder to hold multimedia
global MediaPath -- POSIX path to the media folder

global MediaCount -- number of multimedia objects in current individual
global MediaPrefix -- unique prefix to use in copied multimedia file names
global MediaPortrait -- if portrait is used holds {file name, html file name} in list

global NameList -- reference to NameIndex or the table of names on the main page
global currentLet -- the current letter for names (assumed to be sorted by last name)
global namekey -- index of letters to be at tops of the index
global keynum -- the number of letters that have been found

global currentIndi, prevIndi, nextIndi -- file names of current, previous, and next individual 
global CurrentName -- current individual name (first last)
global ShortName -- current individual name 
global FirstName -- current individual first name 
global CurrentSpan -- current individual life span if known
global CurrentPrivate -- true for privacy records
global LastPlace -- store place for recent event in LastPlace
global IndiSex -- current individual sex
global HeShe -- He or She for current individual
global HeSheLwr -- He or She for current individual (lower case)
global HeSheNow -- He, She, or Name to use when (pro)noun is needed
global HisHer -- His or Her for current individual
global HisHerNow -- His, Her, or Name's to use when possive is needed
global indiRec -- the reference of the current individual
global FatherRef, MotherRef -- first set of parent's records (or "" if none)
global NoteNum -- the number of notes
global MainNum -- the number of level 1 notes

global notesOption -- which notes to include
global mmOption -- which multimedia to include
global obeyRESN -- true to hide details in private records

-- if no document is open then quit
if CheckAvailable(scriptName, 1.5) is false then return

-- get folder
if CreateSiteFolder(rootName) is false then return

-- start name index
set NameIndex to {}
set NameList to a reference to NameIndex
set end of NameList to "<table id='namelist'  summary='index of names'>" & return
set end of NameList to "<tr><th></th><th>Name</th><th>Life Span</th><th>Born</th><th>Died</th></tr>" & return
set namekey to "<b>Key: </b>"
set keynum to 0
set currentLet to ""
set notesOption to "hideNone"
set mmOption to "hideNone"
set obeyRESN to true

tell application "GEDitCOM II"
	-- export settings
	set thePrompt to "Would you like to 'Customize' the following settings or 'Use' them?"
	set msg to "Honor individual 'privacy' settings, "
	set msg to msg & "export all notes, "
	set msg to msg & "and export all compatible multimedia images."
	set priv to user option title thePrompt message msg buttons {"Use", "Cancel", "Customize"}
	if priv is "Cancel" then return
	
	-- customize
	if priv is "Customize" then
		-- RESN setting
		set thePrompt to "Would you like to 'Honor' or 'Ignore' record 'privacy' settings?"
		set msg to "When you honor privacy settings most information in records set to 'privacy' will be omitted."
		set priv to user option title thePrompt message msg buttons {"Honor", "Ignore"}
		if priv is not "Honor" then set obeyRESN to false
		
		-- _DIST options
		set notesOption to my GetDistStyle("notes")
		if notesOption is "" then return
		set mmOption to my GetDistStyle("compatible multimedia")
		if mmOption is "" then return
	end if
	
	-- make sure individuals are sort in alhpbetical order
	tell front document
		display byType "INDI" sorting "view"
		set recs to every individual
		set fname to name
	end tell
	set recsRef to a reference to recs
	
	-- loop over all individuals
	set fractionStepSize to 0.01 -- progress reporting interval
	set nextFraction to fractionStepSize -- progress reporting interval
	set num to number of items in recs
	set prevIndi to my GetHTMLName(item num of recsRef, "I")
	set currentIndi to my GetHTMLName(item 1 of recsRef, "I")
	set nextIndi to my GetHTMLName(item 2 of recsRef, "I")
	repeat with i from 1 to num
		set indiRec to item i of recsRef
		my SetINDIGlobals(indiRec)
		my ExportPage(indiRec)
		
		set prevIndi to currentIndi
		set currentIndi to nextIndi
		if i < num - 1 then
			set nextIndi to my GetHTMLName(item (i + 2) of recsRef, "I")
		else
			set nextIndi to my GetHTMLName(item 1 of recsRef, "I")
		end if
		
		-- if time, notify GEDitCOM II of the amount done
		set fractionDone to i / num
		if fractionDone > nextFraction then
			notify progress fraction fractionDone
			set nextFraction to nextFraction + fractionStepSize
		end if
		
	end repeat
end tell

-- the index file
set itext to {}
set end of itext to my GetFileHeader(fname & " Genealogy", "gcweb.css")
set end of itext to "<h1>" & fname & " Genealogy</h1>" & return
set end of itext to "<p>" & namekey & "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"
set end of itext to "| <a href='#contact'>Contact</a> |</p>" & return
set end of itext to (NameList as string) & return & "</table>" & return & return

-- contact info
tell application "GEDitCOM II"
	tell front document
		set ms to main submitter
		tell submitter id ms
			set msname to name
			set msemail to evaluate expression "_EMAIL"
			set msphone to evaluate expression "PHON"
		end tell
	end tell
end tell
set end of itext to "<p><a name='contact'></a>Genealogy data contact: " & msname
if msemail is not "" then
	set end of itext to "<br>Email: <a href='mailto:" & msemail & "'>" & msemail & "</a>" & return
end if
if msphone is not "" then
	set end of itext to "<br>Phone: " & msphone & return
end if
set end of itext to "</p>" & return

-- GEDitCOM credit
set end of itext to "<hr /><p>Web site created using the Macintosh genealogy software "
set end of itext to "<a href='http://www.geditcom.com'>GEDitCOM II</a><br>" & return
set end of itext to "(geditcom.com is not responsible for any content of this web site)"
set end of itext to "</p>" & return

set end of itext to "</body>" & return & "</html>" & return

-- write the html file
set indexFile to (rootFldr as string) & "index.html"
set inum to open for access indexFile with write permission
write (itext as string) to inum as Çclass utf8È
close access inum

tell application "Safari"
	open file indexFile
	activate
end tell

return

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

(* Create a new folder in a folder selected by the user. The web site
	will be saved into the new folder. It will be named root (plus a number
	if needed).
*)
on CreateSiteFolder(root)
	-- pick folder or exit if canceled
	set pickPrompt to "Choose folder where the new '" & root & "' folder will be saved"
	set wfldr to choose folder with prompt pickPrompt
	if wfldr is "" then return false
	
	set webFolder to GetUniqueFolderName(wfldr as string, root)
	try
		if webFolder is "" then error
		tell application "Finder"
			-- create main folder
			set rootFldr to (make new folder at wfldr with properties {name:webFolder})
			-- create INDIs folder
			set indiFldr to (make new folder at rootFldr with properties {name:"INDIs"})
			-- create media folder
			set MediaFldr to (make new folder at rootFldr with properties {name:"media"})
		end tell
	on error
		tell application "GEDitCOM II"
			beep
			display dialog "Unable to create folder for the web site. " & Â
				"You may not have write permission at the selected location, " & Â
				"the location is full, or some other disk error occurred. Please choose a new location."
			return false
		end tell
	end try
	set MediaPath to (POSIX path of (MediaFldr as string))
	
	-- write the CSS file
	set cssFile to (rootFldr as string) & "gcweb.css"
	set refnum to open for access cssFile with write permission
	write CSSText() to refnum as Çclass utf8È
	close access refnum
	
	return true
end CreateSiteFolder

(* Get unique folder name by inserting numbers (if needed) after base path where
	base path is colon separated path
*)
on GetUniqueFolderName(basePath, root)
	-- check with Finder for file that does not exist
	tell application "Finder"
		set tempName to basePath & root
		set i to 0
		repeat while ((folder tempName exists) and (i < 1000))
			set i to i + 1
			set tempName to basePath & root & " " & i
		end repeat
	end tell
	
	-- return results or an error
	if i = 0 then
		return root
	else if i < 1000 then
		return root & " " & i
	else
		return ""
	end if
end GetUniqueFolderName



(* Text of the CSS file
*)
on CSSText()
	set css to "*  { font-family: Arial, Helvetica, Geneva, Swiss, SunSans-Regular; font-size: 10pt; }" & return
	set css to css & "BODY { background-color: #ffffff;" & return
	set css to css & "  margin: -16px 0px 0px 0px; }" & return
	
	set css to css & "H1 {font-size: 14pt; margin-left: 12px; margin-right: 12px;" & return
	set css to css & "  border-bottom: solid; border-bottom-width: thin; padding-top: 6px;}" & return
	set css to css & "H2 {font-size: 12pt; margin-left: 12px; margin-right: 12px;" & return
	set css to css & "  border-bottom: solid; border-bottom-width: thin;}" & return
	set css to css & "H3 {font-size: 11pt; margin-left: 0px; font-weight: bold;}" & return
	set css to css & "H4 {font-size: 13pt; margin-left: 12px; margin-right: 12px;" & return
	set css to css & "background: #6f6;}" & return
	set css to css & "p {margin: 0px 24px 6px 24px; line-height: 1.5;}" & return
	set css to css & "div {margin-left: 24px; margin-right: 12px; }" & return
	
	set css to css & "#header { margin: 0px 0px 0px 0px;" & return
	set css to css & "  background: #BBB; height: 44px;" & return
	set css to css & "  border-bottom: thin solid #888; }" & return
	
	set css to css & ".portrait { padding: 12px; margin-right: 12px; margin-left: 12px; margin-bottom: 12px;" & return
	set css to css & "  float: right; width: 128px; border: solid; border-width: thin; background-color: #CCC;}" & return
	set css to css & ".mmobject { padding-top: 12px; max-width: 800px; }" & return
	
	set css to css & "#namelist { border: thin black solid; margin: 0px 18px 0px 18px;" & return
	set css to css & "  border-collapse: collapse; }" & return
	set css to css & "#namelist th { border-bottom: thin solid black; text-align: left; }" & return
	set css to css & "#namelist td { padding: 4px 8px 0px 8px; }" & return
	
	set css to css & "#menu {margin: -15px 0px 20px 36px; }" & return
	set css to css & "#menu ul { margin: 0px 0px 0px 0px;" & return
	set css to css & "  padding: 0px 0px 0px 0px;" & return
	set css to css & "  list-style: none;" & return
	set css to css & "  line-height: normal; }" & return
	set css to css & "#menu li { float: left;" & return
	set css to css & "  margin: 0px 0px 0px 0px;" & return
	set css to css & "  background: #360;" & return
	set css to css & "  border-right: solid 1px #FFF; }" & return
	set css to css & "#menu a { display: block;" & return
	set css to css & "  width: auto;" & return
	set css to css & "  height: 24px;" & return
	set css to css & "  padding: 8px 20px 0px 20px;" & return
	set css to css & "  color: #FFFFFF;" & return
	set css to css & "  text-decoration: none; }" & return
	set css to css & "#menu a:hover { background: #6F6; }" & return
	set css to css & "#menu .last { border-right: none; }" & return
	
	set css to css & "#contents { padding: 3px 0px 0px 0px; background-color: #EEE;" & return
	set css to css & "  border: solid 1px #888; width: 200pt; margin-left: 36px;}" & return
	set css to css & "#contents ul { margin: 3px 0px 6px 0px; }" & return
	
	set css to css & ".mmtable { padding: 0px; margin-left: 24px; margin-right: 12px; }" & return
	set css to css & ".mmtable TD { padding: 6px;" & return
	set css to css & "  border: thin solid #AAAAAA;" & return
	set css to css & "  font-size: x-small" & return
	set css to css & "  text-align: center; }" & return
	
	set css to css & "a:link { color: #0000AA;  text-decoration: none; }" & return
	set css to css & "a:visited { color: #AA00AA;  text-decoration: none; }" & return
	set css to css & "a:active { color: #AA00AA;  text-decoration: none; }" & return
	set css to css & "a:hover { color: #FF6600;  text-decoration: none; }" & return
	
	set css to css & "p.member { border: thin black solid;" & return
	set css to css & "  margin: 1px 0px 1px 0px;" & return
	set css to css & "  line-height: 1.0;" & return
	set css to css & "  padding: 4px;" & return
	set css to css & "  font-size: x-small;" & return
	set css to css & "  background-color: #3CF;" & return
	set css to css & "  text-align: center; }" & return
	set css to css & "p.fember { border: thin black solid;" & return
	set css to css & "  margin: 1px 0px 1px 0px;" & return
	set css to css & "  line-height: 1.0;" & return
	set css to css & "  padding: 4px;" & return
	set css to css & "  font-size: x-small;" & return
	set css to css & "  background-color: #FCF;" & return
	set css to css & "  text-align: center; }" & return
	set css to css & "td.up { border-bottom: medium gray solid; border-right: medium gray solid;}" & return
	set css to css & "td.down { border-top: medium gray solid; border-right: medium gray solid;}" & return
	set css to css & "td.right {border-bottom: medium gray solid;}" & return
	set css to css & "td.lright {border-top: medium gray solid;}" & return
	
	set css to css & "#attr { margin: 0px 24px 0px 24px; border-collapse:collapse; }" & return
	set css to css & "#attr th { border: thin gray solid;" & return
	set css to css & " padding: 4px 10px 4px 10px; background-color: #DDD; }" & return
	set css to css & "#attr td { border: thin gray solid; padding: 4px 10px 4px 10px; }" & return
	set css to css & "#detail { margin: 0px 0px 0px 0px; border-collapse:collapse; }" & return
	set css to css & "#detail td { border: none; padding: 0px 10px 0px 0px; }" & return
	set css to css & "#source { margin: 0px 0px 0px 0px; border: thin gray solid; padding: 0px 10px 0px 0px; border-collapse:collapse; width: 100%}" & return
	set css to css & "#source th { border: thin gray solid; padding: 1px 5px 1px 5px; font-size: x-small; background-color: #ddd; }" & return
	set css to css & "#source td { border: thin gray solid; padding: 1px 5px 1px 5px; font-size: x-small; background-color: #f0f0f0;}" & return
	
	set css to css & "" & return
	set css to css & "" & return
	set css to css & "	/** css source pop up */" & return
	set css to css & "a.sour {" & return
	set css to css & "	border-bottom: 1px dashed;" & return
	set css to css & "	text-decoration: none;" & return
	set css to css & "	color: #0000AA;" & return
	set css to css & "}" & return
	set css to css & "" & return
	set css to css & "a.sour:hover {" & return
	set css to css & "	position: relative;" & return
	set css to css & "	cursor: help;" & return
	set css to css & "}" & return
	set css to css & "" & return
	set css to css & "a.sour span {" & return
	set css to css & "	display: none;" & return
	set css to css & "}" & return
	set css to css & "" & return
	set css to css & "a.sour:hover span {" & return
	set css to css & "	display: block;" & return
	set css to css & "   	position: absolute; top: 10px; left: 0;" & return
	set css to css & "	/* formatting only styles */" & return
	set css to css & "   	padding: 5px; margin: 10px; z-index: 100;" & return
	set css to css & "   	border: 1px solid #000000;" & return
	set css to css & "    text-decoration: none;" & return
	set css to css & "	background: #CCFDCC  100% 5% no-repeat;" & return
	set css to css & "	width: 360px;" & return
	set css to css & "	/* end formatting */" & return
	set css to css & "}" & return
	set css to css & "" & return
	set css to css & "	/** css object pop up */" & return
	set css to css & "a.obje {" & return
	set css to css & "	border-bottom: 1px solid;" & return
	set css to css & "	text-decoration: none;" & return
	set css to css & "	color: #0000AA;" & return
	set css to css & "}" & return
	set css to css & "" & return
	set css to css & "a.obje:hover {" & return
	set css to css & "	position: relative;" & return
	set css to css & "	cursor: help;" & return
	set css to css & "}" & return
	set css to css & "" & return
	set css to css & "a.obje span {" & return
	set css to css & "	display: none;" & return
	set css to css & "}" & return
	set css to css & "" & return
	set css to css & "a.obje:hover span {" & return
	set css to css & "	display: block;" & return
	set css to css & "   	position: absolute; top: 20px; left: 0;" & return
	set css to css & "}" & return
	set css to css & "" & return
	set css to css & "a span {" & return
	set css to css & "display: none;" & return
	set css to css & "}" & return
	set css to css & "a:hover {" & return
	set css to css & "	position: relative;" & return
	set css to css & "}" & return
	set css to css & "a:hover span {" & return
	set css to css & "	display: block;" & return
	set css to css & "   	position: absolute; top: 10px; left: 0;" & return
	set css to css & "}" & return
	set css to css & "#image { margin: 0px 0px 0px 0px; border: thin black solid; padding: 0px 10px 0px 0px; border-collapse:collapse; width: 100%}" & return
	set css to css & " #image th { border: thin black solid; padding: 1px 5px 1px 5px; font-size: x-small; background-color: #ddd; }" & return
	set css to css & "#image td { border: thin black solid; padding: 5px 5px 5px 5px; font-size: x-small; background-color: #CCFDCC;}" & return
	
	
	return css
end CSSText

(* Get file name based on ID without the @ signs *)
on GetHTMLName(theRec, pref)
	tell application "GEDitCOM II"
		set fname to pref & (my GetID(theRec)) & ".html"
	end tell
	return fname
end GetHTMLName

(* Strip at signs from a record ID *)
on GetID(theRec)
	tell application "GEDitCOM II"
		set recID to id of theRec
	end tell
	set idLen to number of characters in recID
	set recID to (characters 2 thru (idLen - 1) of recID) as string
	return recID
end GetID

(* Set global variables for the next individual
*)
on SetINDIGlobals(indiRec)
	tell application "GEDitCOM II"
		-- read individual information
		tell indiRec
			set CurrentName to alternate name of indiRec
			set ShortName to format name value CurrentName case "title"
			set ShortName to name parts gedcom name ShortName
			try
				set FirstName to word 1 of (item 1 of ShortName)
				set ShortName to word 1 of (item 1 of ShortName) & " " & item 2 of ShortName & " " & item 3 of ShortName
			on error
				set ShortName to alternate name of indiRec
				set FirstName to ShortName
			end try
			
			if sex is "M" then
				set HeShe to "He"
				set IndiSex to "M"
				set HisHer to "His"
			else
				set HeShe to "She"
				set IndiSex to "F"
				set HisHer to "Her"
			end if
			set theRESN to restriction
			if theRESN is privacy and obeyRESN is true then
				set CurrentSpan to ""
				set CurrentPrivate to true
			else
				set CurrentSpan to (safe html raw text life span)
				set CurrentPrivate to false
			end if
		end tell
		set MediaPrefix to (my GetID(indiRec)) & "_mm"
		set MediaCount to 0
		set MediaPortrait to ""
	end tell
end SetINDIGlobals

(* Get hyperlink to an individual *)
on GetLinkTo(theRec, pref)
	tell application "GEDitCOM II"
		set fname to my GetHTMLName(theRec, "I")
		set iname to alternate name of theRec
	end tell
	return "<a href='" & pref & fname & "'>" & iname & "</a>"
end GetLinkTo

(* Get hyperlink to a child for list *)
on GetChilLinkTo(theRec, pref)
	tell application "GEDitCOM II"
		set fname to my GetHTMLName(theRec, "I")
		tell theRec
			set iname to item 1 of (name parts gedcom name (evaluate expression "NAME"))
			try
				set iname to characters 1 thru ((length of iname) - 1) of iname
			on error
				set iname to alternate name
			end try
			set bdate to date year full date birth date
			if bdate is "" then set bdate to "?"
			set ddate to date year full date death date
			if ddate is "" then set ddate to "?"
			set byears to safe html raw text (bdate & "-" & ddate)
			set iname to iname & " (" & byears & ")"
		end tell
	end tell
	return "<a href='" & pref & fname & "'>" & iname & "</a>"
end GetChilLinkTo

(* Export page for this individual
*)
on ExportPage(indiRec)
	
	-- start new page
	set pretext to GetFileHeader(CurrentName, "../gcweb.css")
	
	-- individual index
	set pretext to pretext & GetIndiPageIndex()
	set pretext to pretext & "<h1>" & CurrentName & "</h1>" & return
	set pretext to pretext & GetPortrait(indiRec)
	
	-- start the body and the contents
	set IndiPage to {}
	set itext to a reference to IndiPage
	set contnts to "<div id='contents'>" & return
	set contnts to contnts & "<center><b>Contents</b></center>" & return
	set contnts to contnts & "<ul>" & return
	
	-- Before getting details read and store main notes
	set NoteNum to 0
	set evntAttrNotes to {}
	set noteIDList to {}
	if CurrentPrivate is false then
		tell application "GEDitCOM II"
			tell indiRec
				if notesOption is "hideAll" then
					set theNotes to {}
				else
					set theNotes to find structures tag "NOTE"
				end if
			end tell
			
			set nn to number of items in theNotes
			repeat with i from 1 to nn
				set noteData to item i of theNotes
				if number of items in noteData is 2 then
					set noteID to item 1 of noteData
					set noteRec to note id noteID of front document
					set thenote to my GetNotesText(noteRec)
					if thenote is not "" then
						set NoteNum to NoteNum + 1
						set end of evntAttrNotes to thenote
						set end of noteIDList to noteID
					end if
				end if
			end repeat
		end tell
	end if
	set MainNum to NoteNum
	
	(* The first section has birth and death details, parents names, and spouses.
		For each spouse, give marriage details and lists all children
	*)
	set contnts to contnts & "<li><a href='#faminfo'>Personal and Family Information</a></li>" & return
	set end of itext to "<h2><a name='faminfo'></a>Personal and Family Information</h2>" & return
	set HeSheNow to CurrentName
	
	set LastPlace to ""
	set pref to "<p>"
	if CurrentPrivate is true then
		set end of itext to "<p>(Dates, places, events, notes, and multimedia removed for privacy reasons)</p>" & return
		set birthPlace to ""
		set deathPlace to ""
		
		-- append name to the global index
		AddNameToMainIndex(indiRec, "", "")
		
	else
		-- birth and parents
		tell application "GEDitCOM II"
			tell indiRec
				--Get birth details
				set BirtRef to "" -- clear before start of new individual
				set birth to find structures tag "BIRT" output "references"
				set numBirt to number of items in birth
				if numBirt = 0 then
					set bdate to ""
					set bplace to ""
				else
					set bprep to ""
					set BirtRef to item 1 of birth
					tell BirtRef
						set bedu to event date user
						set bdate to date parts full date bedu
						if item 1 of bdate is "ABT" or item 1 of bdate is "EST" or item 1 of bdate is "INT" or item 1 of bdate is "c" then
							set bdate to item 2 of bdate
							set bprep to " about"
						else if item 1 of bdate is "BEF" then
							set bdate to item 2 of bdate
							set bprep to " before"
						else if item 1 of bdate is "AFT" then
							set bdate to item 2 of bdate
							set bprep to " after"
						else
							set bdate to bedu
						end if
						set bplace to event place
					end tell
				end if
				
				--Get parent details
				set famc to parent families
				set numPar to number of items in famc
				if numPar = 0 then
					set par to ""
					set fath to ""
					set moth to ""
				else
					set par to ""
					set famRef to item 1 of famc
					tell famRef
						try
							set fath to husband
						on error
							set fath to ""
						end try
						try
							set moth to wife
						on error
							set moth to ""
						end try
					end tell
				end if
				set FatherRef to fath
				set MotherRef to moth
				
				-- compile list of parents with links
				if IndiSex is "M" then
					set chil to "son"
					set HisHerLwr to "his"
					set HeSheLwr to "he"
				else
					set chil to "daughter"
					set HisHerLwr to "her"
					set HeSheLwr to "she"
				end if
				set par to par & "the " & chil & " of "
				if fath is "" then
					if moth is "" then
						set par to par & "unknown parents"
					else
						set par to par & my GetLinkTo(moth, "") & " but " & HisHerLwr & " father is unknown"
					end if
				else
					if moth is "" then
						set par to par & my GetLinkTo(fath, "") & " but " & HisHerLwr & " mother is unknown"
					else
						set par to par & my GetLinkTo(fath, "") & " and " & my GetLinkTo(moth, "")
					end if
				end if
				
				if bdate is "" then
					if bplace is "" then
						set end of itext to "<p>" & FirstName & " was " & par & ". The date and place of " & HisHerLwr & " birth have not been found."
					else
						set end of itext to "<p>" & FirstName & " was born in " & bplace & ", " & par & ". The date is not known."
					end if
				else
					if bprep is "" then
						set brange to sdn range full date bdate
						if item 1 of brange = item 2 of brange then
							set bprep to " on"
						else
							set bprep to " in"
						end if
					end if
					if bplace is "" then
						set end of itext to "<p>" & FirstName & " was born" & bprep & " " & bdate & ", " & par & ". The place is not known."
					else
						set end of itext to "<p>" & FirstName & " was born" & bprep & " " & bdate & " in " & bplace & ", " & par & "."
					end if
				end if
				
				if BirtRef is not "" then
					set end of itext to my GetBirtDeatNotes(BirtRef)
				end if
				
				--Get death details
				set DeathRef to "" -- clear before start of new individual
				set death to find structures tag "DEAT" output "references"
				set numDeat to number of items in death
				if numDeat = 0 then
					set ddate to ""
					set dplace to ""
					set died to "N"
				else
					set died to "Y"
					set dprep to ""
					set DeathRef to item 1 of death
					tell DeathRef
						set dedu to event date user
						set ddate to date parts full date dedu
						if item 1 of ddate is "ABT" or item 1 of ddate is "EST" or item 1 of ddate is "INT" or item 1 of ddate is "c" then
							set ddate to item 2 of ddate
							set dprep to " about"
						else if item 1 of ddate is "BEF" then
							set ddate to item 2 of ddate
							set dprep to " before"
						else if item 1 of ddate is "AFT" then
							set ddate to item 2 of ddate
							set dprep to " after"
						else
							set ddate to dedu
						end if
						set dplace to event place
					end tell
				end if
				
				if ddate is "" then
					if dplace is not "" then
						set end of itext to "<p>" & HeShe & " died in " & dplace & ". The date is not known."
					else if died is not "N" then
						set end of itext to "<p>" & HeShe & " has died but the date and place are unknown."
					end if
				else
					if dprep is "" then
						set drange to sdn range full date ddate
						if (item 1 of drange) = (item 2 of drange) then
							set dprep to " on"
						else
							set dprep to " in"
						end if
					end if
					if dplace is "" then
						set end of itext to "<p>" & HeShe & " died" & dprep & " " & ddate & ". The place is not known."
					else
						set end of itext to "<p>" & HeShe & " died" & dprep & " " & ddate & " in " & dplace & "."
					end if
				end if
				
				if DeathRef is not "" then
					set end of itext to my GetBirtDeatNotes(DeathRef)
				end if
			end tell
		end tell
		
		set end of itext to GetMarriages(indiRec)
		
		-- append name to the global index
		AddNameToMainIndex(indiRec, bplace, dplace)
		
	end if
	
	-- pedigree chart
	if FatherRef is not "" or MotherRef is not "" then
		set contnts to contnts & "<li><a href='#pedi'>Pedigree Chart</a></li>" & return
		set end of itext to "<h2><a name='pedi'></a>Pedigree Chart (3 generations)</h2><br clear='all'>" & return
		set end of itext to GetPedigreeChart(indiRec)
	end if
	
	-- Before getting events and attributes set note counter to 0
	set bborder to "Y"
	if CurrentPrivate is false then
		-- events
		set HeShe to CurrentName
		set numEvnt to number of items in eventOut
		set evnts to ""
		repeat with e from 1 to numEvnt
			set evnts to evnts & GetRowForEvnt(indiRec, item e of eventOut, item e of eventName)
		end repeat
		if evnts is not "" then
			set contnts to contnts & "<li><a href='#evnts'>Events</a></li>" & return
			set end of itext to "<h2><a name='evnts'></a>Events</h2>" & return
			set end of itext to "<table id='attr'>" & return
			set end of itext to "<tr><th>Event</th><th>Date</th><th>Details</th><th>Source</th><th>Multimedia</th><th>Notes</th></tr>" & return
			set end of itext to evnts
			set end of itext to "</table>" & return & return
		end if
		
		-- attributes
		set numAttr to number of items in attrOut
		set attrs to ""
		repeat with e from 1 to numAttr
			set attrs to attrs & GetRowForAttr(indiRec, item e of attrOut, item e of attrName)
		end repeat
		if attrs is not "" then
			set contnts to contnts & "<li><a href='#attrs'>Attributes</a></li>" & return
			set end of itext to "<h2><a name='attrs'></a>Attributes</h2>" & return
			set end of itext to "<table id='attr'>" & return
			set end of itext to "<tr><th>Attribute</th><th>Date</th><th>Description</th><th>Details</th><th>Source</th><th>Multimedia</th><th>Notes</th></tr>" & return
			set end of itext to attrs
			set end of itext to "</table>" & return & return
		end if
		
		set bborder to "Y"
		
		-- multimedia
		set mmtext to GetMultimedia(indiRec)
		if mmtext is not "" then
			set bborder to "N"
			set contnts to contnts & "<li><a href='#mmlist'>Multimedia</a></li>" & return
			set end of itext to "<h2><a name='mmlist'></a>Multimedia</h2>" & return
			set end of itext to mmtext
		end if
		
		
		-- notes
		set nts to GetMainNotes(indiRec)
		if nts is not "" then
			set bborder to "N"
			set contnts to contnts & "<li><a href='#notes'>Notes</a></li>" & return
			set end of itext to "<h2><a name='notes'></a>Notes</h2>" & return
			set end of itext to nts
		end if
		
		-- sources
		set srcs to GetSourceDetail(indiRec, "<li>", "</li>")
		if srcs is not "" then
			set bborder to "N"
			set contnts to contnts & "<li><a href='#sours'>Sources</a></li>" & return
			set end of itext to "<h2><a name='sours'></a>Sources</h2>" & return
			set end of itext to "<ol style='padding-bottom: 90pt;'>" & srcs & "</ol>"
		end if
		
	end if
	
	-- If no notes or multimedia add a few blank rows at bottom so attribute table not right at bottom
	if bborder is "Y" then
		set end of itext to "<br><br><br><br><br><br><br><br>"
	end if
	
	-- finish contents
	set contnts to contnts & "</ul></div>" & return
	
	-- document footer
	set pagetext to pretext & contnts & (itext as string) & GetFileFooter()
	
	-- write the html file
	set indiFile to (indiFldr as string) & currentIndi
	set inum to open for access indiFile with write permission
	write pagetext to inum as Çclass utf8È
	close access inum
end ExportPage

(* Header for an individual record file
*)
on GetFileHeader(theTitle, csslink)
	set head to "<!DOCTYPE HTML PUBLIC '-//W3C//DTD HTML 4.01 Transitional//EN' "
	set head to head & "'http://www.w3.org/TR/html4/loose.dtd'>" & return
	
	set head to head & "<html>" & return
	set head to head & "<head>" & return
	set head to head & "  <meta http-equiv='Content-Type' content='text/html; charset=UTF-8'/>" & return
	set head to head & "  <link rel='stylesheet' type='text/css' href='" & csslink & "'>" & return
	set head to head & "  <title>" & theTitle & "</title>" & return
	set head to head & "</head>" & return
	set head to head & "<body>" & return & return
end GetFileHeader

(* Add individual indi the global main index
	NameList is the table of names on main page built as a list and converted to string at the end
	Namekey is index of letters to be at tops of the index (and possible elsewhere)
	CurrentLet is the current letter for names (assumed to be sorted by last name)
	Keynum is the number of letters that have been found
*)
on AddNameToMainIndex(indiRec, birthPlace, deathPlace)
	tell application "GEDitCOM II"
		-- get name as last name, first names
		set aname to name of indiRec
		
		-- append to the index of letters if a new letter
		set aKey to first character of aname
		if aKey is not currentLet then
			set currentLet to aKey
			set keynum to keynum + 1
			
			-- add to key list
			set thiskey to "l" & keynum
			if currentLet is "-" then
				set namekey to namekey & "<a href='#" & thiskey & "'>&ndash;</a> "
			else
				set namekey to namekey & "<a href='#" & thiskey & "'>" & currentLet & "</a> "
			end if
			
			-- table row with link
			set end of NameList to "<tr><td width='20'><b><a name='" & thiskey & "'></a>" & currentLet & "</b></td>" & return
		else
			set end of NameList to "<tr><td></td>" & return
		end if
		set end of NameList to "<td><a href='INDIs/" & currentIndi & "'>" & aname & "</a></td>"
		set end of NameList to "<td>" & CurrentSpan & "</td>"
		set end of NameList to "<td>" & birthPlace & "</td>"
		set end of NameList to "<td>" & deathPlace & "</td></tr>" & return
	end tell
end AddNameToMainIndex

(* This method called once at the start of each individual web page. It can return
     standard features for the top of the page (such as a menu bar, graphics, or
	 any thing else) all in standard html commands. return "" to have nothing at
	 the top of each page.

   Some use globals are prevIndi and nextIndi for file names for previous and next
     individuals (they will be in the same folder as this page). CurrentName is
	 name of current individual
*)
on GetIndiPageIndex()
	set indbar to "<div id='header'><p>&nbsp;</p></div>" & return
	set indbar to indbar & "<div id='menu'>" & return & "<ul>" & return
	set indbar to indbar & "<li><a href='../index.html'>Name Index</a></li> " & return
	set indbar to indbar & "<li><a href='" & prevIndi & "'>Previous</a></li> " & return
	set indbar to indbar & "<li><a href='" & nextIndi & "'>Next</a></li> " & return
	set indbar to indbar & "</ul>" & return & "</div><br>" & return
	return indbar
end GetIndiPageIndex

(* This method can display a portrait for the person on the top right of the page. To do so
	return html text to display the image.
	
	Also set MediaPortrait to { image file name, image display html file name } or to "" if
	no portrait is displayed
*)
on GetPortrait(indiRec)
	if CurrentPrivate is true then return ""
	if mmOption is "hideAll" then return ""
	set MediaPortrait to ""
	tell application "GEDitCOM II"
		tell indiRec
			-- exit if _NOPOR is set
			set nopor to evaluate expression "_NOPOR"
			if nopor is not "" then return ""
			
			-- load OBJE or exit if none
			try
				set obje to structure named "OBJE"
			on error
				-- no portrait found
				return ""
			end try
		end tell
		
		-- read portrait
		set objeRef to a reference to multimedia id (contents of obje) of front document
	end tell
	
	set mmNames to CopyOBJEFile(objeRef, indiRec)
	if mmNames is not "" then
		set mmName to item 1 of mmNames
		set por to "<img class='portrait' src='../media/" & mmName & "' alt='portrait'/>" & return
		set MediaPortrait to mmNames
	else
		set por to ""
	end if
	
	return por
end GetPortrait


(* Get row of attribute table
	
	theTag is GEDCOM tag word
	theName is attribute name
*)
on GetRowForAttr(theRec, theTag, theName)
	tell application "GEDitCOM II"
		-- look for for the structure
		tell theRec
			set attrs to find structures tag theTag output "references"
			set numAttrs to number of items in attrs
			if numAttrs = 0 then
				return ""
			end if
		end tell
		
		set attrAll to ""
		repeat with i from 1 to numAttrs
			set attr to item i of attrs
			set attrText to contents of attr
			tell attr
				set adate to evaluate expression "DATE"
				set aplac to evaluate expression "PLAC"
				set aage to evaluate expression "AGE"
				set atype to evaluate expression "TYPE"
				set aaddr to evaluate expression "ADDR"
				set acaus to evaluate expression "CAUS"
				set aagnc to evaluate expression "AGNC"
				--set asour to evaluate expression "SOUR.TITL"
			end tell
			if attrText is not "" then
				set attrAll to attrAll & "<tr><td>" & theName & "</td><td>" & adate & "</td><td>" & attrText & "</td>"
				set attrAll to attrAll & "<td>"
				set attrAll to attrAll & "<table  id='detail'>" & return
				if aplac is not "" then
					set attrAll to attrAll & "<tr><td align='right'><b>Place: </b></td><td>" & aplac & "</td></tr>" & return
				end if
				if aage is not "" then
					set attrAll to attrAll & "<tr><td align='right'><b>Age: </b></td><td>" & aage & "</td></tr>" & return
				end if
				if atype is not "" then
					set attrAll to attrAll & "<tr><td align='right'><b>Type: </b></td><td>" & atype & "</td></tr>" & return
				end if
				if aaddr is not "" then
					set attrAll to attrAll & "<tr><td align='right'><b>Address: </b></td><td>" & aaddr & "</td></tr>" & return
				end if
				if acaus is not "" then
					set attrAll to attrAll & "<tr><td align='right'><b>Cause: </b></td><td>" & acaus & "</td></tr>" & return
				end if
				if aagnc is not "" then
					set attrAll to attrAll & "<tr><td align='right'><b>Agency: </b></td><td>" & aagnc & "</td></tr>" & return
				end if
				
				set attrAll to attrAll & "</table>" & return
				set attrAll to attrAll & "</td>" & return
				set attrAll to attrAll & "<td>" & return
				set attrAll to attrAll & my GetSourceDetail(attr, "", "<br>")
				set attrAll to attrAll & "</td>" & return
				set attrAll to attrAll & "<td>" & return
				set attrAll to attrAll & my GetEventAttrMM(attr, theRec)
				set attrAll to attrAll & "</td>" & return
				set attrAll to attrAll & "<td>" & return
				set attrAll to attrAll & my GetEventAttrNotes(attr)
				set attrAll to attrAll & "</td></tr>" & return
				
			end if
		end repeat
	end tell
	return attrAll
end GetRowForAttr

(* Get row of event table
	
	theTag is GEDCOM tag word
	theName is event name
*)
on GetRowForEvnt(theRec, theTag, theName)
	tell application "GEDitCOM II"
		-- look for for the structure
		tell theRec
			set evnts to find structures tag theTag output "references"
			set numEvnts to number of items in evnts
			if numEvnts = 0 then
				return ""
			end if
		end tell
		
		set evntAll to ""
		repeat with i from 1 to numEvnts
			set evnt to item i of evnts
			tell evnt
				set edate to evaluate expression "DATE"
				set eplac to evaluate expression "PLAC"
				set eage to evaluate expression "AGE"
				set etype to evaluate expression "TYPE"
				set eaddr to evaluate expression "ADDR"
				set ecaus to evaluate expression "CAUS"
				set eagnc to evaluate expression "AGNC"
				
			end tell
			set evntAll to evntAll & "<tr><td>" & theName & "</td><td>" & edate & "</td>"
			set evntAll to evntAll & "<td>"
			set evntAll to evntAll & "<table  id='detail'>" & return
			if eplac is not "" then
				set evntAll to evntAll & "<tr><td align='right'><b>Place: </b></td><td>" & eplac & "</td></tr>" & return
			end if
			if eage is not "" then
				set evntAll to evntAll & "<tr><td align='right'><b>Age: </b></td><td>" & eage & "</td></tr>" & return
			end if
			if etype is not "" then
				set evntAll to evntAll & "<tr><td align='right'><b>Type: </b></td><td>" & etype & "</td></tr>" & return
			end if
			if eaddr is not "" then
				set evntAll to evntAll & "<tr><td align='right'><b>Address: </b></td><td>" & eaddr & "</td></tr>" & return
			end if
			if ecaus is not "" then
				set evntAll to evntAll & "<tr><td align='right'><b>Cause: </b></td><td>" & ecaus & "</td></tr>" & return
			end if
			if eagnc is not "" then
				set evntAll to evntAll & "<tr><td align='right'><b>Agency: </b></td><td>" & eagnc & "</td></tr>" & return
			end if
			
			set evntAll to evntAll & "</table>" & return
			set evntAll to evntAll & "</td>" & return
			set evntAll to evntAll & "<td>" & return
			set evntAll to evntAll & my GetSourceDetail(evnt, "", "<br>")
			set evntAll to evntAll & "</td>" & return
			set evntAll to evntAll & "<td>" & return
			set evntAll to evntAll & my GetEventAttrMM(evnt, theRec)
			set evntAll to evntAll & "</td>" & return
			set evntAll to evntAll & "<td>" & return
			set evntAll to evntAll & my GetEventAttrNotes(evnt)
			set evntAll to evntAll & "</td></tr>" & return
		end repeat
	end tell
	return evntAll
end GetRowForEvnt

(* Get source info and citation details for all subordinate source links
	Each sounce in a <a> link. The link will be preceeded by pre and followed by post
*)
on GetSourceDetail(sour, pre, post)
	-- find and display all sources 
	tell application "GEDitCOM II"
		tell sour
			set sours to find structures tag "SOUR" output "references"
		end tell
		
		set snum to number of items in sours
		if snum = 0 then
			return ""
		end if
		set sData to ""
		repeat with s from 1 to snum
			set srec to item s of sours
			set sourID to contents of srec
			set sourRec to source id sourID of front document
			tell sourRec
				set stitl to source title
				set sauth to source authors
				set srdate to source date
				set srdtls to source details
			end tell
			
			tell srec
				set sdate to evaluate expression "DATA.DATE"
				set spage to evaluate expression "PAGE"
				set sevnt to evaluate expression "EVEN"
				set srol to evaluate expression "EVEN.ROLE"
				set stxt to evaluate expression "DATA.TEXT"
				set squa to evaluate expression "QUAY"
				if squa is not "" then
					set squa to item (squa + 1) of SourceQuality
				end if
			end tell
			
			set sData to sData & pre & "<a class='sour'>" & stitl & "<span>" & return
			set sData to sData & "<table  id='source'>" & return
			if stitl is not "" then
				set sData to sData & "<tr><th align='right' width='45'>Source: </th><th align='left'>" & stitl & "</th></tr>" & return
			end if
			if sauth is not "" then
				set sData to sData & "<tr><th align='right' width='45'>Authors: </th><th align='left'>" & sauth & "</th></tr>" & return
			end if
			if srdate is not "" then
				set sData to sData & "<tr><th align='right' width='45'>Date: </th><th align='left'>" & srdate & "</th></tr>" & return
			end if
			if srdtls is not "" then
				set sData to sData & "<tr><th align='right' width='45'>Publisher: </th><th align='left'>" & srdtls & "</th></tr>" & return
			end if
			if sdate is not "" then
				set sData to sData & "<tr><td align='right'>Citation Date: </td><td>" & sdate & "</td></tr>" & return
			end if
			if spage is not "" then
				set sData to sData & "<tr><td align='right'>Page: </td><td>" & spage & "</td></tr>" & return
			end if
			if sevnt is not "" then
				set sData to sData & "<tr><td align='right'>Event: </td><td>" & sevnt & "</td></tr>" & return
			end if
			if srol is not "" then
				set sData to sData & "<tr><td align='right'>Role: </td><td>" & srol & "</td></tr>" & return
			end if
			if stxt is not "" then
				set sData to sData & "<tr><td align='right'>Text: </td><td>" & stxt & "</td></tr>" & return
			end if
			if squa is not "" then
				set sData to sData & "<tr><td align='right'>Quality: </td><td>" & squa & "</td></tr>" & return
			end if
			set sData to sData & "</table>" & return
			set sData to sData & "</span></a>" & post & return
			
		end repeat
	end tell
	return sData
end GetSourceDetail
(* List parents for the current individual
	Will be empty if no parents of text (ending in space) if any information (even unknown parents)
*)
on GetParents(indiRec)
	tell application "GEDitCOM II"
		set FatherRef to ""
		set MotherRef to ""
		tell indiRec
			set famc to parent families
			set numPar to number of items in famc
			if numPar = 0 then return ""
		end tell
		
		-- read parents records
		set par to ""
		repeat with f from 1 to numPar
			set famRef to item f of famc
			tell famRef
				try
					set fath to husband
				on error
					set fath to ""
				end try
				try
					set moth to wife
				on error
					set moth to ""
				end try
			end tell
			
			-- save first parents for pedigree chart
			if f is 1 then
				set FatherRef to fath
				set MotherRef to moth
			end if
			
			-- compile list of parents with links
			if IndiSex is "M" then
				set chil to "son"
			else
				set chil to "daughter"
			end if
			set par to par & HeSheNow & " was the " & chil & " of "
			if fath is "" then
				if moth is "" then
					set par to par & "unknown parents. "
				else
					set par to par & " an unknown father and " & my GetLinkTo(moth, "") & ". "
				end if
			else
				if moth is "" then
					set par to par & my GetLinkTo(fath, "") & " and an unknown mother. "
				else
					set par to par & my GetLinkTo(fath, "") & " and " & my GetLinkTo(moth, "") & ". "
				end if
			end if
			
			set HeSheNow to HeShe
		end repeat
	end tell
	return par
end GetParents

(* Get output for all marriages, return empty if none, otherise return complete html
*)
on GetMarriages(indiRec)
	tell application "GEDitCOM II"
		-- read marriage info
		tell indiRec
			set famses to spouse families
			set nmr to number of items in famses
			if nmr is 0 then return ""
		end tell
		
		-- if any then start paragraph; if more than one mention that first
		--set HisHerNow to CurrentName & "'s"
		set mtext to "<p>"
		if nmr > 1 then
			if nmr > 20 then
				set nmrCard to nmr
			else
				set nmrCard to item nmr of NumbsCard
			end if
			set mtext to mtext & HeShe & " had " & nmrCard & " marriages/partners. "
			set HeSheNow to HeShe
			set HisHerNow to HisHer
		end if
		
		-- for each marriage give spouse, marriage details, and children
		if nmr > 1 then
			set ordn to " first "
		else
			set ordn to " "
		end if
		repeat with m from 1 to nmr
			-- if second or higher, start new paragrpah
			if m > 1 then
				set mtext to mtext & "<p>"
			end if
			
			-- get details from the family record
			set famRec to item m of famses
			tell famRec
				try
					if IndiSex is "M" then
						set spse to wife
					else
						set spse to husband
					end if
				on error
					set spse to ""
				end try
				set umr to evaluate expression "_UMR"
				set chils to find structures tag "CHIL" output "references"
			end tell
			
			-- a spouse or a partner?
			if umr is not "Y" then
				if IndiSex is "M" then
					set spseName to "wife"
				else
					set spseName to "husband"
				end if
				set mtext to mtext & HisHer & ordn & spseName
			else
				set mtext to mtext & HisHer & ordn & "partner"
			end if
			
			-- link to spouse or say unknown
			if spse is not "" then
				set mtext to mtext & " was " & my GetLinkTo(spse, "")
			else
				set mtext to mtext & " is not known"
			end if
			
			tell famRec
				set mdate to evaluate expression "MARR.DATE"
				set mplace to evaluate expression "MARR.PLAC"
				if CurrentPrivate is false then
					if umr is not "Y" then
						
						if mdate is not "" then
							if item 1 of (sdn range full date (mdate)) = item 2 of (sdn range full date (mdate)) then
								set mprep to " on"
							else
								set mprep to " in"
							end if
						end if
						if mdate is not "" and mplace is not "" then
							if spse is not "" then
								set mtext to mtext & ", who " & HeSheLwr & " married" & mprep & " " & mdate & " in " & mplace & "."
							else
								set mtext to mtext & ", but they married" & mprep & " " & mdate & " in " & mplace & "."
							end if
						end if
						if mdate is "" and mplace is "" then
							set mtext to mtext & ". They were married, but the date and place have not been found."
						end if
						if mdate is "" and mplace is not "" then
							if spse is not "" then
								set mtext to mtext & ", who " & HeSheLwr & " married in " & mplace & ". The date has not been found."
							else
								set mtext to mtext & ", but they were married in " & mplace & ". The date has not been found."
							end if
						end if
						if mdate is not "" and mplace is "" then
							if spse is not "" then
								set mtext to mtext & ", who " & HeSheLwr & " married" & mprep & " " & mdate & ". The place has not been found."
							else
								set mtext to mtext & ", but they were married" & mprep & " " & mdate & ". The place has not been found."
							end if
						end if
						
					else
						if spse is not "" then
							set mtext to mtext & ", but they were never married."
						else
							set mtext to mtext & "They were never married."
						end if
						
					end if
				end if
			end tell
			
			-- list all children or say none
			set nch to number of items in chils
			if nch = 0 then
				set mtext to mtext & " They had no known children"
			else
				if nch = 1 then
					set mtext to mtext & " Their only known child was "
				else if nch < 21 then
					set mtext to mtext & " Their " & item nch of NumbsCard & " known children were "
				else
					set mtext to mtext & " Their " & nch & " known children were "
				end if
				repeat with c from 1 to nch
					set chilID to contents of item c of chils
					if c > 1 then
						if c = nch then
							set mtext to mtext & " and "
						else
							set mtext to mtext & ", "
						end if
					end if
					set mtext to mtext & my GetChilLinkTo(individual id chilID of front document, "")
				end repeat
				
			end if
			set mtext to mtext & ".</p>" & return
			
			-- get next ordinal
			if m < 22 then
				set ordn to " " & item (m + 1) of NumbsOrd & " "
			else
				set ordn to " " & (m + 1) & "th "
			end if
			
		end repeat
	end tell
	
	return mtext
end GetMarriages

(* Get full pedigree chart using css table
*)
on GetPedigreeChart(indiRec)
	tell application "GEDitCOM II"
		
		-- collect through great grand parents in ugly style
		set pp to ""
		set pm to ""
		set mp to ""
		set mm to ""
		set ppp to ""
		set ppm to ""
		set pmp to ""
		set pmm to ""
		set mpp to ""
		set mpm to ""
		set mmp to ""
		set mmm to ""
		if FatherRef is not "" then
			set gps to my GetParentRefs(FatherRef)
			set pp to item 1 of gps
			if pp is not "" then
				set ggps to my GetParentRefs(pp)
				set ppp to item 1 of ggps
				set ppm to item 2 of ggps
			end if
			set pm to item 2 of gps
			if pm is not "" then
				set ggps to my GetParentRefs(pm)
				set pmp to item 1 of ggps
				set pmm to item 2 of ggps
			end if
		end if
		if MotherRef is not "" then
			set gps to my GetParentRefs(MotherRef)
			set mp to item 1 of gps
			if mp is not "" then
				set ggps to my GetParentRefs(mp)
				set mpp to item 1 of ggps
				set mpm to item 2 of ggps
			end if
			set mm to item 2 of gps
			if mm is not "" then
				set ggps to my GetParentRefs(mm)
				set mmp to item 1 of ggps
				set mmm to item 2 of ggps
			end if
		end if
	end tell
	
	-- row 1: indi, father, pp, ppp
	set pc to "<div><table cellpadding='0' cellspacing='0' width='100%'>" & return & return
	set pc to pc & "<tr>" & return
	set pc to pc & "<td rowspan='4'>&nbsp;</td>" & return
	set pc to pc & my GetPediCell(indiRec, "member", 8)
	set pc to pc & "<td rowspan='2'>&nbsp;</td>" & return
	set pc to pc & my GetPediCell(FatherRef, "member", 4)
	set pc to pc & "<td>&nbsp;</td>" & return
	set pc to pc & my GetPediCell(pp, "member", 2)
	if ppp is not "" then
		set pc to pc & "<td class='right'>&nbsp;</td>" & return
	else
		set pc to pc & "<td>&nbsp;</td>" & return
	end if
	set pc to pc & my GetPediCell(ppp, "member", 1)
	set pc to pc & my GetPlus(ppp)
	set pc to pc & "</tr>" & return & return
	
	-- row 2: ppm
	set pc to pc & "<tr>" & return
	if pp is not "" then
		set pc to pc & "<td class='up'>&nbsp;</td>" & return
	else
		set pc to pc & "<td>&nbsp;</td>" & return
	end if
	if ppm is not "" then
		set pc to pc & "<td class='lright'>&nbsp;</td>" & return
	else
		set pc to pc & "<td>&nbsp;</td>" & return
	end if
	set pc to pc & my GetPediCell(ppm, "fember", 1)
	set pc to pc & my GetPlus(ppm)
	set pc to pc & "</tr>" & return & return
	
	-- row 3: pm and pmp
	set pc to pc & "<tr>" & return
	if FatherRef is not "" then
		set pc to pc & "<td rowspan='2' class='up'>&nbsp;</td>" & return
	else
		set pc to pc & "<td>&nbsp;</td>" & return
	end if
	if pm is not "" then
		set pc to pc & "<td class='down'>&nbsp;</td>" & return
	else
		set pc to pc & "<td>&nbsp;</td>" & return
	end if
	set pc to pc & my GetPediCell(pm, "fember", 2)
	if pmp is not "" then
		set pc to pc & "<td class='right'>&nbsp;</td>" & return
	else
		set pc to pc & "<td>&nbsp;</td>" & return
	end if
	set pc to pc & my GetPediCell(pmp, "member", 1)
	set pc to pc & my GetPlus(pmp)
	set pc to pc & "</tr>" & return & return
	
	--row 4: pmm
	set pc to pc & "<tr>" & return
	set pc to pc & "<td>&nbsp;</td>" & return
	if pmm is not "" then
		set pc to pc & "<td class='lright'>&nbsp;</td>" & return
	else
		set pc to pc & "<td>&nbsp;</td>" & return
	end if
	set pc to pc & my GetPediCell(pmm, "fember", 1)
	set pc to pc & my GetPlus(pmm)
	set pc to pc & "</tr>" & return & return
	
	-- row 5: mother, mp, mpp
	set pc to pc & "<tr>" & return
	set pc to pc & "<td rowspan='4'>&nbsp;</td>" & return
	if MotherRef is not "" then
		set pc to pc & "<td rowspan='2' class='down'>&nbsp;</td>" & return
	else
		set pc to pc & "<td>&nbsp;</td>" & return
	end if
	set pc to pc & my GetPediCell(MotherRef, "fember", 4)
	set pc to pc & "<td>&nbsp;</td>" & return
	set pc to pc & my GetPediCell(mp, "member", 2)
	if mpp is not "" then
		set pc to pc & "<td class='right'>&nbsp;</td>" & return
	else
		set pc to pc & "<td>&nbsp;</td>" & return
	end if
	set pc to pc & my GetPediCell(mpp, "member", 1)
	set pc to pc & my GetPlus(mpp)
	set pc to pc & "</tr>" & return & return
	
	-- row 6: mpm
	set pc to pc & "<tr>" & return
	if mp is not "" then
		set pc to pc & "<td class='up'>&nbsp;</td>" & return
	else
		set pc to pc & "<td>&nbsp;</td>" & return
	end if
	if mpm is not "" then
		set pc to pc & "<td class='lright'>&nbsp;</td>" & return
	else
		set pc to pc & "<td>&nbsp;</td>" & return
	end if
	set pc to pc & my GetPediCell(mpm, "fember", 1)
	set pc to pc & my GetPlus(mpm)
	set pc to pc & "</tr>" & return & return
	
	-- row 7: mm, mmp
	set pc to pc & "<tr>" & return
	set pc to pc & "<td rowspan='2'>&nbsp;</td>" & return
	if mm is not "" then
		set pc to pc & "<td class='down'>&nbsp;</td>" & return
	else
		set pc to pc & "<td>&nbsp;</td>" & return
	end if
	set pc to pc & my GetPediCell(mm, "fember", 2)
	if mmp is not "" then
		set pc to pc & "<td class='right'>&nbsp;</td>" & return
	else
		set pc to pc & "<td>&nbsp;</td>" & return
	end if
	set pc to pc & my GetPediCell(mmp, "member", 1)
	set pc to pc & my GetPlus(mmp)
	set pc to pc & "</tr>" & return & return
	
	-- row 8: mmm
	set pc to pc & "<tr>" & return
	set pc to pc & "<td>&nbsp;</td>" & return
	if mmm is not "" then
		set pc to pc & "<td class='lright'>&nbsp;</td>" & return
	else
		set pc to pc & "<td>&nbsp;</td>" & return
	end if
	set pc to pc & my GetPediCell(mmm, "fember", 1)
	set pc to pc & my GetPlus(mmm)
	set pc to pc & "</tr>" & return & return
	
	-- close the table
	set pc to pc & "</table></div>" & return & return
	
	return pc
	
end GetPedigreeChart

(* Get {mother,father} in a list as references or "" if not available
*)
on GetParentRefs(childRef)
	tell application "GEDitCOM II"
		set famc to parent families of childRef
		set numPar to number of items in famc
		if numPar = 0 then return {"", ""}
		set famRef to item 1 of famc
		tell famRef
			try
				set fath to husband
			on error
				set fath to ""
			end try
			try
				set moth to wife
			on error
				set moth to ""
			end try
		end tell
	end tell
	return {fath, moth}
end GetParentRefs

(* Plus sign if individual has parents
*)
on GetPlus(childRef)
	tell application "GEDitCOM II"
		if childRef is not "" then
			set famc to parents of childRef
		else
			set famc to {}
		end if
	end tell
	if number of items in famc > 1 then
		set plusSign to "<td><b>+</b></td>" & return
	else
		set plusSign to "<td>&nbsp;</td>" & return
	end if
	return plusSign
end GetPlus


(* Format a cell for the pedigree chart
*)
on GetPediCell(indiRef, cellClass, rowSpan)
	if indiRef is "" then
		set cell to "<td rowspan='" & rowSpan & "' width='20%'>&nbsp;<br>&nbsp;</td>"
	else
		tell application "GEDitCOM II"
			tell indiRef
				set pediName to alternate name
				set ls to life span
				if ls = "" then
					set ls to "&nbsp;"
				else
					if (evaluate expression "RESN") is "Privacy" then
						set ls to "(private)"
					else
						set ls to "(" & ls & ")"
					end if
				end if
			end tell
			set pediFile to my GetHTMLName(indiRef, "I")
			if rowSpan > 1 then
				set cell to "<td rowspan='" & rowSpan & "'>" & return
			else
				set cell to "<td>" & return
			end if
			set cell to cell & "<p class='" & cellClass & "'>"
			set cell to cell & "<a href='" & pediFile & "#pedi'>" & pediName & "<br>" & return
			set cell to cell & ls & "</a></p></td>" & return
		end tell
	end if
	return cell
end GetPediCell

(* Copile all level 1 NOTEs to html text
*)
on GetMainNotes(indiRec)
	set nts to ""
	tell application "GEDitCOM II"
		repeat with i from 1 to MainNum
			set thenote to item i of evntAttrNotes
			if thenote is not "" then
				tell indiRec
					set htmlNote to safe html raw text thenote insert Ps "all" reformat links relink
				end tell
				set nts to nts & "<p><h4><p><a name='" & i & "'></a><p><b>Note " & i & "</b></h4></p>" & htmlNote & return
			end if
		end repeat
		
		-- now add any event/attribute notes
		set NoteNum to number of items in evntAttrNotes
		repeat with n from (MainNum + 1) to NoteNum
			set nts to nts & "<p><h4><p><a name='Note" & n & "'></a>" & item n of evntAttrNotes & "</p>" & return
		end repeat
		
	end tell
	return nts
end GetMainNotes

on GetMultimedia(indiRec)
	if mmOption is "hideAll" then return ""
	tell application "GEDitCOM II"
		tell indiRec
			set objes to find structures tag "OBJE" output "references"
		end tell
		set numobje to number of items in objes
		if numobje is 0 then return ""
		
		set mmOut to ""
		set thisRow to 0
		set numLevel1 to 0
		repeat with mm from 1 to numobje
			set obje to item mm of objes
			set objeID to contents of obje
			if level of obje is 1 then
				set numLevel1 to numLevel1 + 1
				--end if
				set objeRef to (a reference to multimedia id objeID of front document)
				
				if numLevel1 = 1 and MediaPortrait is not "" then
					set mmNames to MediaPortrait
				else
					set mmNames to my CopyOBJEFile(objeRef, indiRec)
				end if
				
				if mmNames is not "" then
					set mmName to item 1 of mmNames
					set mmHtml to item 2 of mmNames
					set mmForm to item 3 of mmNames
					set mmTitle to name of objeRef
					if number of characters in mmTitle > 14 then
						set mmTitle to (characters 1 thru 12 of mmTitle) as string
						set mmTitle to mmTitle & "..."
					end if
					if thisRow = 6 then
						set mmOut to mmOut & "</tr>" & return & "<tr>" & return
						set thisRow to 0
					end if
					set mmOut to mmOut & "<td><a href='../media/" & mmHtml & "'>"
					if movieTypes contains mmForm then
						set mmOut to mmOut & "<center>Movie</center><br>"
					else
						set mmOut to mmOut & "<img src='../media/" & mmName & "' alt='media' width='96'/>"
					end if
					set mmOut to mmOut & "<br>" & mmTitle & "</a></td>" & return
					set thisRow to thisRow + 1
				end if
			end if
		end repeat
	end tell
	
	if mmOut is not "" then
		set mmOut to "<table class='mmtable'>" & return & "<tr>" & return & mmOut
		set mmOut to mmOut & "</tr>" & return & "</table>" & return
	end if
	return mmOut
end GetMultimedia


on GetEventAttrMM(struct, indiRec)
	if mmOption is "hideAll" then return ""
	tell application "GEDitCOM II"
		tell struct
			set objes to find structures tag "OBJE" output "references"
		end tell
		set numobje to number of items in objes
		if numobje is 0 then return ""
		
		set mmOut to ""
		repeat with mm from 1 to numobje
			set obje to item mm of objes
			set objeID to contents of obje
			set objeRef to (a reference to multimedia id objeID of front document)
			
			set mmNames to my CopyOBJEFile(objeRef, indiRec)
			
			if mmNames is not "" then
				set mmName to item 1 of mmNames
				set mmHtml to item 2 of mmNames
				set mmForm to item 3 of mmNames
				set mmTitle to name of objeRef
				
				set mmOut to mmOut & "<a class='obje' href='../media/" & mmHtml & "'>" & mmTitle & "<span>" & return
				
				set mmOut to mmOut & "<table  id='image'><tr><td>" & return
				
				if movieTypes contains mmForm then
					set mmOut to mmOut & "<center>Movie</center><br>" & return
				else
					set mmOut to mmOut & "<img src='../media/" & mmName & "' alt='media' height=130/>" & return
				end if
				
				set mmOut to mmOut & "</tr></td></table>" & return
				set mmOut to mmOut & "</span></a><br>" & return
				
			end if
		end repeat
	end tell
	
	return mmOut
end GetEventAttrMM

(* if mmPath is a support file type, copy it to the media folder using a unique name
	and return list with name of mm file and html file that displays it at full size in a list.
	If not acceptable file then return ""
*)
on CopyOBJEFile(objeRef, indiRec)
	tell application "GEDitCOM II"
		tell objeRef
			if mmOption is not "hideNone" then
				set dist to evaluate expression "_DIST"
				if dist is "Owner" then return ""
				if dist is "Family" and mmOption is "hideFamily" then return ""
			end if
			try
				set mmForm to contents of structure named "FORM"
			on error
				-- if no form, look for file extension
				set newPath to object path
				set mmForm to "unavailable"
				set pc to (number of characters in newPath)
				repeat with dotc from pc to 1 by -1
					if character dotc of newPath is "." then
						set mmForm to (characters (dotc + 1) thru pc of newPath) as string
						exit repeat
					end if
				end repeat
			end try
			if mmTypes does not contain mmForm then
				return ""
			end if
		end tell
		
		-- get name based on ID
		set MediaCount to MediaCount + 1
		set stubID to (my GetID(objeRef))
		set mmName to "M" & stubID & "." & mmForm
		set mmHtml to "I" & (my GetID(indiRec)) & "-" & stubID & ".html"
		set destPath to MediaPath & mmName
		
		tell objeRef
			-- copy the file
			try
				copyFile destination destPath
			on error
				-- no need to copy file again, but do html file that references this individual
				-- it must already be there, no need to make html file
				--return {mmName, mmHtml, mmForm}
			end try
			
			-- no separate file needed for pdf
			--if mmForm is "pdf" then
			--	return {mmName, mmHtml, mmForm}
			--end if
			
			-- read info
			set mmTitle to name
			set mmLoc to ""
			set latlon to ""
			try
				set theLoc to structure named "_LOC"
				set mmLoc to contents of theLoc
				tell theLoc
					set latlon to contents of structure named "_GPS"
				end tell
			on error
				set latlon to ""
			end try
			try
				set theDate to contents of structure named "_DATE"
				set theDate to date format full date theDate
			on error
				set theDate to ""
			end try
			
		end tell
		
		-- start new page
		set mmtext to my GetFileHeader(mmName, "../gcweb.css")
		
		-- multimedia detail
		set mmtext to mmtext & "<br><h1>Multimedia Object for " & CurrentName & "</h1>" & return
		set mmtext to mmtext & "<h2>Title: " & mmTitle & "</h2>" & return
		if mmLoc is not "" or theDate is not "" then
			set mmtext to mmtext & "<p>The location is "
			if mmLoc is "" then
				set mmtext to mmtext & theDate
			else if theDate is "" then
				set mmtext to mmtext & mmLoc
			else
				set mmtext to mmtext & mmLoc & " in " & theDate
			end if
			if latlon is not "" then
				set mmtext to mmtext & " (<a href='"
				set mmtext to mmtext & "http://maps.google.com/maps?hl=en&client=safari&rls=en&q="
				set mmtext to mmtext & latlon & "'>map</a>)"
			end if
			set mmtext to mmtext & ".</p>" & return
		end if
		
		-- show the object itself
		set mmtext to mmtext & "<br><center>" & return
		if movieTypes contains mmForm then
			set mmtext to mmtext & "<a href='" & mmName & "'>Click to see movie</a>" & return
		else if mmForm is "pdf" then
			set mmtext to mmtext & "<a href='" & mmName & "'>"
			set mmtext to mmtext & "<img class='mmobject' src='" & mmName & "' alt='image' /></a>" & return
		else
			set mmtext to mmtext & "<img class='mmobject' src='" & mmName & "' alt='image' />" & return
		end if
		set mmtext to mmtext & "</center>" & return
		
	end tell
	
	set mmtext to mmtext & my GetFileFooter()
	
	-- write the html file
	set objeFile to (MediaFldr as string) & mmHtml
	set onum to open for access objeFile with write permission
	write mmtext to onum as Çclass utf8È
	close access onum
	
	return {mmName, mmHtml, mmForm}
end CopyOBJEFile

(* Get reference to notes for attribute and event tables *)
on GetEventAttrNotes(struct)
	tell application "GEDitCOM II"
		tell struct
			if notesOption is "hideAll" then
				set theNotes to {}
			else
				set theNotes to find structures tag "NOTE"
			end if
		end tell
		
		set nts to ""
		set nn to number of items in theNotes
		repeat with i from 1 to nn
			set noteData to item i of theNotes
			set noteID to item 1 of noteData
			if noteID is in noteIDList then
				set nid to number of items in noteIDList
				repeat with j from 1 to nid
					if noteID is item j of noteIDList then
						if nts is not "" then
							set nts to nts & "<br>" & return
						end if
						set nts to nts & "<a href='#Note" & j & "'>See Note " & j & "</a>"
						exit repeat
					end if
				end repeat
			else
				set noteRec to note id noteID of front document
				set thenote to my GetNotesText(noteRec)
				if thenote is not "" then
					set NoteNum to NoteNum + 1
					tell noteRec
						set htmlNote to safe html raw text thenote insert Ps "all" reformat links relink
					end tell
					
					set end of evntAttrNotes to "<p><b>Note " & NoteNum & "</b></h4></p>" & htmlNote & return
					set end of noteIDList to noteID
					if nts is not "" then
						set nts to nts & "<br>" & return
					end if
					set nts to nts & "<a href='#Note" & NoteNum & "'>See Note " & NoteNum & "</a>"
				end if
			end if
		end repeat
	end tell
	
	return nts
end GetEventAttrNotes

(* Get notes, but watch out for distribution setting *)
on GetNotesText(noteRec)
	tell application "GEDitCOM II"
		tell noteRec
			if notesOption is not "hideNone" then
				set dist to evaluate expression "_DIST"
				if dist is "Owner" then
					set thenote to ""
				else if dist is "Family" and notesOption is "hideFamily" then
					set thenote to ""
				else
					set thenote to notes text
				end if
			else
				set thenote to notes text
			end if
		end tell
	end tell
	return thenote
end GetNotesText

(* Get reference to notes for attribute and event tables *)
on GetBirtDeatNotes(struct)
	tell application "GEDitCOM II"
		tell struct
			if notesOption is "hideAll" then
				set theNotes to {}
			else
				set theNotes to find structures tag "NOTE"
			end if
		end tell
		
		set oldNum to NoteNum
		set nts to ""
		set nn to number of items in theNotes
		repeat with i from 1 to nn
			set noteData to item i of theNotes
			set noteID to item 1 of noteData
			if noteID is in noteIDList then
				set nid to number of items in noteIDList
				repeat with j from 1 to nid
					if noteID is item j of noteIDList then
						if nts is not "" then
							set nts to nts & ", "
						end if
						set nts to nts & "<a href='#Note" & j & "'>" & j & "</a>"
						exit repeat
					end if
				end repeat
			else
				set noteRec to note id noteID of front document
				set thenote to my GetNotesText(noteRec)
				if thenote is not "" then
					set NoteNum to NoteNum + 1
					tell noteRec
						set htmlNote to safe html raw text thenote insert Ps "all" reformat links relink
					end tell
					set end of evntAttrNotes to "<p><b>Note " & NoteNum & "</b></h4></p>" & htmlNote & return
					set end of noteIDList to noteID
					if nts is not "" then
						set nts to nts & ", "
					end if
					set nts to nts & "<a href='#Note" & NoteNum & "'>" & NoteNum & "</a>"
				end if
			end if
		end repeat
		
		if NoteNum = oldNum + 1 then
			set nts to "<sup>[Note " & nts & "]</sup>"
		else if NoteNum > oldNum + 1 then
			set nts to "<sup>[Notes " & nts & "]</sup>"
		end if
	end tell
	
	return nts
end GetBirtDeatNotes

(* Footer for an individual record
*)
on GetFileFooter()
	set ftr to ""
	set ftr to ftr & "</body>" & return
	set ftr to ftr & "</html>" & return
	return ftr
end GetFileFooter

-- get export style
on GetDistStyle(dkind)
	tell application "GEDitCOM II"
		-- what to find
		set expOptions to {"Include All", "Omit 'Owner'", "Omit 'Owner' and 'Family'", "Omit All"}
		set thePrompt to "Choose which " & dkind & " to export in the web site."
		set r to user choice prompt thePrompt list items expOptions buttons {"OK", "Cancel"} title scriptName
		if item 1 of r is "Cancel" then return ""
		set theStyle to item 1 of item 2 of r
		if theStyle is item 1 of expOptions then
			return "hideNone"
		else if theStyle is item 2 of expOptions then
			return "hideOwner"
		else if theStyle is item 3 of expOptions then
			return "hideFamily"
		else if theStyle is item 4 of expOptions then
			return "hideAll"
		end if
		return ""
	end tell
end GetDistStyle

