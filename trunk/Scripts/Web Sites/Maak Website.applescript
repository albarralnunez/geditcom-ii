(*	Create Web Site script for GEDitCOM II - Dutch Version
	12 AUG 2009, by John A. Nairn
	Lastest Revisions: 16 NOV 2009

	This script will create a complete, self-contained web site for the entire file including
	multimedia objects. The script will ask you to select a save location and will create a
	new folder named "GC Site #" (where "#" will be added, if needed, to make folder's
	name unique). The web site will be created and then automatically opened in Firefox
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
		
	You are not limited to the style web site created by this script. You can
	copy the "Create Web Site.scpt" file from /Library/Application Support/GEDitCOMII/Scripts
	to the same location in your home folder (~/Library/Application Support/GEDitCOMII/Scripts)
	and then edit it with Apple's Script Editor. You can change the display or content as
	desired or use that script as a model for creating an entirely new web-site creation script.
	
	For more details, see http://www.geditcom.com/tutorials/customweb.html
*)

property scriptName : "Maak Web Site"
property rootName : "GC Site"
property eventOut : {"BAPM", "CHR", "CENS", "EMMI", "IMMI", "NATU", "BURI"}
property eventName : {"Doop", "Naamgeving", "Volkstelling", "Emigratie", "Immigratie", "Naturalisatie", "Begrafenis"}
property eventVerb : {"werd gedoopt", "kreeg de namen", "is geregistreerd in de volkstelling", "emigreerde", "immigreerde", "werd genaturaliseerd", "werd begraven"}
property attrOut : {"DSCR", "EDUC", "NATI", "OCCU", "RELI", "TITL", "EVEN4"}
property attrName : {"Beschrijving", "Opleiding", "Afstamming", "Beroep", "Godsdienst", "Adellijke titel", "Militaire Dienst"}
property mmTypes : {"jpg", "jpeg", "gif", "tif", "tiff", "png", "mov"}
property movieTypes : {"mov"}
property relink : {INDI:"I%@.html"}
property IndiPage : {}
property NameIndex : {}

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
global CurrentSpan -- current individual life span if known
global CurrentRESN -- "Privacy" for privacy records
global LastPlace -- store place for recent event in LastPlace
global IndiSex -- current individual sex
global HeShe -- He or She for current individual
global HeSheNow -- He, She, or Name to use when (pro)noun is needed
global HisHer -- His or Her for current individual
global HisHerNow -- His, Her, or Name's to use when possive is needed

global FatherRef, MotherRef -- first set of parent's records (or "" if none)

-- if no document is open then quit
if CheckAvailable(scriptName) is false then return

-- get folder
if CreateSiteFolder(rootName) is false then return

-- start name index
set NameIndex to {}
set NameList to a reference to NameIndex
set end of NameList to "<table id='namelist'  summary='index namen'>" & return
set end of NameList to "<tr><th></th><th>Naam</th><th>Levensloop</th><th>Geboren</th><th>Overleden</th></tr>" & return
set namekey to "<b>Sleutel: </b>"
set keynum to 0
set currentLet to ""

tell application "GEDitCOM II"
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
set end of itext to my GetFileHeader(fname & " Genealogie", "gcweb.css")
set end of itext to "<h1>" & fname & " Genealogie</h1>" & return
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
set end of itext to "<p><a name='contact'></a>Contactpersoon Genealogie: " & msname
if msemail is not "" then
	set end of itext to "<br>Email: <a href='mailto:" & msemail & "'>" & msemail & "</a>" & return
end if
if msphone is not "" then
	set end of itext to "<br>Phone: " & msphone & return
end if
set end of itext to "</p>" & return

-- GEDitCOM credit
set end of itext to "<hr /><p>Deze website is gecre‘erd met het Macintosh programma "
set end of itext to "<a href='http://www.geditcom.com'>GEDitCOM II</a><br>" & return
set end of itext to "(geditcom.com is niet verantwoordelijk voor de inhoud van deze website)"
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

(* Start GEDitCOM II (if needed) and verify that a document is open
	return true or false if at least one document is open
*)
on CheckAvailable(sName)
	tell application "GEDitCOM II"
		if versionNumber < 1.09 then
			display dialog "Dit script vereist GEDitCOM II, Versie 1.1 of nieuwer. AUB upgraden en opnieuw proberen" buttons {"OK"} default button "OK" with title sName
			return false
		end if
		if number of documents is 0 then
			display dialog "U moet een document openen in GEDitCOM II alvorens dit script te gebruiken" buttons {"OK"} default button "OK" with title sName
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
	set pickPrompt to "Kies folder waar de nieuwe '" & root & "' folder zal worden bewaard"
	set wfldr to choose folder with prompt pickPrompt
	if wfldr is "" then return false
	
	set webFolder to GetUniqueFolderName(wfldr as string, root)
	try
		log {webFolder}
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
			display dialog "Kan folder voor de website niet aanmaken. " & Â
				"Waarschijnlijk heeft u geen schrijfrechten op deze locatie; Kies aub een andere locatie."
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
	set css to css & "H3 {font-size: 11pt; margin-left: 12px; margin-right: 12px; margin-bottom: 3px;}" & return
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
			if sex is "M" then
				set HeShe to "Hij"
				set IndiSex to "M"
				set HisHer to "Zijn"
			else
				set HeShe to "Zij"
				set IndiSex to "V"
				set HisHer to "Haar"
			end if
			set CurrentRESN to evaluate expression "RESN"
			if CurrentRESN is "Privacy" then
				set CurrentSpan to ""
			else
				set CurrentSpan to life span
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
	set contnts to contnts & "<center><b>Inhoud</b></center>" & return
	set contnts to contnts & "<ul>" & return
	
	-- portrait
	
	(* The first section has birth and death details, parents names, and spouses.
		For each spouse, give marriage details and lists all children
	*)
	set contnts to contnts & "<li><a href='#faminfo'>Persoonlijke en gezins-gegevens</a></li>" & return
	set end of itext to "<h2><a name='faminfo'></a>Persoonlijke en gezins-gegevens</h2>" & return
	set HeSheNow to CurrentName
	
	set LastPlace to ""
	set pref to "<p>"
	if CurrentRESN is "Privacy" then
		set end of itext to "<p>(Datums, plaatsen, gebeurtenissen, opmerkingen en multimedia verwijderd vanwege privacy)</p>" & return
		set birthPlace to ""
		set deathPlace to ""
	else
		-- birth and death
		set etext to GetTextForEvent(indiRec, "BIRT", "werd geboren", pref, "")
		if etext is not "" then
			set pref to ""
			set end of itext to etext
			if last character of etext is return then
				-- if had notes, start new paragraph for in next section
				set pref to "<p>"
			end if
		end if
		set birthPlace to LastPlace
		
		set LastPlace to ""
		set etext to GetTextForEvent(indiRec, "DEAT", "overleed", pref, "")
		if etext is not "" then
			set pref to ""
			set end of itext to etext
			if last character of etext is return then
				-- if had notes, start new paragraph in next section
				set pref to "<p>"
			end if
		end if
		set deathPlace to LastPlace
	end if
	
	-- append name to the global index
	AddNameToMainIndex(indiRec, birthPlace, deathPlace)
	
	-- parents
	set par to GetParents(indiRec)
	if par is not "" then
		if last character of par is not return then
			set par to par & "</p>" & return
		end if
		set end of itext to pref & par
	end if
	
	-- spouses/partners
	set HeSheNow to CurrentName
	set end of itext to GetMarriages(indiRec)
	
	-- pedigree chart
	if FatherRef is not "" or MotherRef is not "" then
		set contnts to contnts & "<li><a href='#pedi'>Stamboom kaart</a></li>" & return
		set end of itext to "<h2><a name='pedi'></a>Stamboom kaart (3 generaties)</h2><br clear='all'>" & return
		set end of itext to GetPedigreeChart(indiRec)
	end if
	
	if CurrentRESN is not "Privacy" then
		-- events
		set HeShe to CurrentName
		set numEvnt to number of items in eventOut
		set evnts to ""
		repeat with e from 1 to numEvnt
			set evnts to evnts & GetTextForEvent(indiRec, item e of eventOut, item e of eventVerb, "<p>", item e of eventName)
		end repeat
		if evnts is not "" then
			set contnts to contnts & "<li><a href='#evnts'>Gebeurtenissen</a></li>" & return
			set end of itext to "<h2><a name='evnts'></a>Gebeurtenissen</h2>" & return
			set end of itext to evnts
		end if
		
		-- attributes
		set numAttr to number of items in attrOut
		set attrs to ""
		repeat with e from 1 to numAttr
			set attrs to attrs & GetRowForAttr(indiRec, item e of attrOut, item e of attrName)
		end repeat
		if attrs is not "" then
			set contnts to contnts & "<li><a href='#attrs'>Attributen</a></li>" & return
			set end of itext to "<h2><a name='attrs'></a>Attributen</h2>" & return
			set end of itext to "<table id='attr'>" & return
			set end of itext to "<tr><th>Attribuut</th><th>Details</th></tr>" & return
			set end of itext to attrs
			set end of itext to "</table>" & return & return
		end if
		
		-- notes
		set nts to GetMainNotes(indiRec)
		if nts is not "" then
			set contnts to contnts & "<li><a href='#notes'>Opmerkingen</a></li>" & return
			set end of itext to "<h2><a name='notes'></a>Opmerkingen</h2>" & return
			set end of itext to nts
		end if
		
		-- multimedia
		set mmtext to GetMultimedia(indiRec)
		if mmtext is not "" then
			set contnts to contnts & "<li><a href='#mmlist'>Multimedia</a></li>" & return
			set end of itext to "<h2><a name='mmlist'></a>Multimedia</h2>" & return
			set end of itext to mmtext
		end if
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
	set indbar to indbar & "<li><a href='../index.html'>Index namen</a></li> " & return
	set indbar to indbar & "<li><a href='" & prevIndi & "'>Vorige</a></li> " & return
	set indbar to indbar & "<li><a href='" & nextIndi & "'>Volgende</a></li> " & return
	set indbar to indbar & "</ul>" & return & "</div><br>" & return
	return indbar
end GetIndiPageIndex

(* This method can display a portrait for the person on the top right of the page. To do so
	return html text to display the image.
	
	Also set MediaPortrait to { image file name, image display html file name } or to "" if
	no portrait is displayed
*)
on GetPortrait(indiRec)
	if CurrentRESN is "Privacy" then return ""
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
	
	set mmNames to CopyOBJEFile(objeRef)
	if mmNames is not "" then
		set mmName to item 1 of mmNames
		set por to "<img class='portrait' src='../media/" & mmName & "' alt='portrait'/>" & return
		set MediaPortrait to mmNames
	else
		set por to ""
	end if
	
	return por
end GetPortrait

(* Get text for an event or events, If no event(s) return empty (otherwise return something)
	If event, return date and place (if known)
	If has notes, append first set of notes
	If their were notes, will end in "</p>&return", otherwise will end in a space.
	h3Text gets multievents if there and begins each with <h3> and that text
		Also will always be complete html text ending in return
	
	theTag is GEDCOM tag word
	everb is event verb (e.g., was born, died, was buried, etc.)
	pref is text to start the text (e.g., <p>)
	h3Text is text for <h3> header and will look for multiple events
*)
on GetTextForEvent(theRec, theTag, everb, pref, h3Text)
	tell application "GEDitCOM II"
		-- look for for the structure
		tell theRec
			set evnts to find structures tag theTag output "references"
			set numEvnt to number of items in evnts
			if numEvnt = 0 then
				return ""
			end if
			if h3Text = "" then
				set numEvnt to 1
			end if
		end tell
		
		-- one is found, so process it
		set edall to ""
		repeat with i from 1 to numEvnt
			set evnt to item i of evnts
			set ed to ""
			tell evnt
				-- the date
				set edate to event date user
				if edate is not "" then
					set ed to HeSheNow & " " & everb & " " & edate
				end if
				
				-- the place
				set LastPlace to evaluate expression "PLAC"
				if LastPlace is "" then
					if ed is not "" then
						set ed to ed & ". "
					end if
				else
					if ed is "" then
						set ed to HeSheNow & "  " & everb & " in " & LastPlace & ". "
					else
						set ed to ed & " in " & LastPlace & ". "
					end if
				end if
				
				-- if no date and place, say so
				if ed is "" then
					set ed to HeSheNow & "  " & everb & ", maar datum en plaats onbekend. "
				end if
				
				-- change to pronuon
				set HeSheNow to HeShe
				
				-- get notes
				set enote to evaluate expression "NOTE"
			end tell
			
			-- if there, append the notes
			if enote is not "" then
				tell note id enote of front document
					set thenote to notes text
				end tell
				tell front document
					set htmlNote to safe html raw text thenote insert Ps "interior" reformat links relink
				end tell
				if (first character of htmlNote) is "<" then
					-- a <div> note
					set ed to ed & "</p>" & return & htmlNote & return
				else
					-- normal text
					set ed to ed & htmlNote & "</p>" & return
				end if
			end if
			
			-- append closing </p> and add header if multievents, otherwise just attach prefix
			if h3Text is not "" then
				if last character of ed is " " then
					set ed to ed & "</p>" & return
				end if
				set edall to edall & "<h3>" & h3Text & "</h3>" & return & pref & ed & return
			else
				set edall to pref & ed
			end if
			
		end repeat
	end tell
	
	return edall
end GetTextForEvent

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
			if attrText is not "" then
				set attrAll to attrAll & "<tr><td>" & theName & "</td><td>" & attrText & "</td></tr>" & return
			end if
		end repeat
	end tell
	return attrAll
end GetRowForAttr

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
				set chil to "de zoon"
			else
				if IndiSex is "V" then
					set chil to "de dochter"
				else
					set chil to "het kind (onbekend geslacht)"
				end if
			end if
			set par to par & HeSheNow & " was " & chil & " van "
			if fath is "" then
				if moth is "" then
					set par to par & "onbekende ouders. "
				else
					set par to par & " een onbekende vader en " & my GetLinkTo(moth, "") & ". "
				end if
			else
				if moth is "" then
					set par to par & my GetLinkTo(fath, "") & " en een onbekende moeder. "
				else
					set par to par & my GetLinkTo(fath, "") & " en " & my GetLinkTo(moth, "") & ". "
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
		set HisHerNow to CurrentName & "'s"
		set mtext to "<p>"
		if nmr > 1 then
			set mtext to mtext & HeSheNow & " had " & nmr & " huwelijken/partners. "
			set HeSheNow to HeShe
			set HisHerNow to HisHer
			set ordn to " 1e "
		else
			set ordn to " "
		end if
		
		-- for each marriage give spouse, marriage details, and children
		repeat with m from 1 to nmr
			
			-- if more than on marriage, get an ordinal
			if m = 2 then
				set ordn to " 2e "
			else if m = 3 then
				set ordn to " 3e "
			else if m > 3 then
				set ordn to " " & m & "e "
			end if
			
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
					set spseName to "vrouw"
				else
					set spseName to "man"
				end if
				set mtext to mtext & HisHerNow & ordn & spseName
			else
				set mtext to mtext & HisHerNow & ordn & " partner"
			end if
			set HisHerNow to HisHer
			
			-- link to spouse or say unknown
			if spse is not "" then
				set mtext to mtext & " was " & my GetLinkTo(spse, "") & ". "
			else
				set mtext to mtext & " onbekend. "
			end if
			
			-- marriage details
			if CurrentRESN is not "Privacy" then
				if umr is not "Y" then
					set HeSheNow to "Zij"
					set mtext to mtext & my GetTextForEvent(famRec, "MARR", "trouwden", "", "")
					if last character of mtext is return then
						set mtext to mtext & "<p>"
					end if
					set HeSheNow to HeShe
				else
					set mtext to mtext & "waren nooit getrouwd. "
				end if
			end if
			
			-- list all children or say none
			set nch to number of items in chils
			if nch = 0 then
				set mtext to mtext & "Zij hadden voorzover bekend geen kinderen"
			else
				if nch = 1 then
					set mtext to mtext & "Hun enige bekende kind was "
				else
					set mtext to mtext & "Hun " & nch & " bekende kinderen waren "
				end if
				repeat with c from 1 to nch
					set chilID to contents of item c of chils
					if c > 1 then
						if c = nch then
							set mtext to mtext & " en "
						else
							set mtext to mtext & ", "
						end if
					end if
					set mtext to mtext & my GetLinkTo(individual id chilID of front document, "")
				end repeat
				
			end if
			set mtext to mtext & ".</p>" & return
			
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
		tell indiRec
			set theNotes to find structures tag "NOTE"
		end tell
		set nn to number of items in theNotes
		repeat with i from 1 to nn
			set noteData to item i of theNotes
			if number of items in noteData is 2 then
				set noteID to item 1 of noteData
				tell note id noteID of front document
					set thenote to notes text
					if thenote is not "" then
						set htmlNote to safe html raw text thenote insert Ps "all" reformat links relink
						set nts to nts & htmlNote & return
					end if
				end tell
			end if
		end repeat
	end tell
	return nts
end GetMainNotes

on GetMultimedia(indiRec)
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
			end if
			set objeRef to (a reference to multimedia id objeID of front document)
			
			if numLevel1 = 1 and MediaPortrait is not "" then
				set mmNames to MediaPortrait
			else
				set mmNames to my CopyOBJEFile(objeRef)
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
					set mmOut to mmOut & "<center>Film</center><br>"
				else
					set mmOut to mmOut & "<img src='../media/" & mmName & "' alt='media' width='96'/>"
				end if
				set mmOut to mmOut & "<br>" & mmTitle & "</a></td>" & return
				set thisRow to thisRow + 1
			end if
		end repeat
	end tell
	
	if mmOut is not "" then
		set mmOut to "<table class='mmtable'>" & return & "<tr>" & return & mmOut
		set mmOut to mmOut & "</tr>" & return & "</table>" & return
	end if
	return mmOut
end GetMultimedia

(* if mmPath is a support file type, copy it to the media folder using a unique name
	and return list with name of mm file and html file that displays it at full size in a list.
	If not acceptable file then return ""
*)
on CopyOBJEFile(objeRef)
	tell application "GEDitCOM II"
		tell objeRef
			try
				set mmForm to contents of structure named "FORM"
			on error
				-- if no form, look for file extension
				set newPath to (POSIX file mmPath) as string
				set fileRef to file newPath
				set mmForm to name extension of fileRef
			end try
			if mmTypes does not contain mmForm then
				return ""
			end if
			
			-- copy the file
			set MediaCount to MediaCount + 1
			set mmName to MediaPrefix & MediaCount & "." & mmForm
			set mmHtml to MediaPrefix & MediaCount & ".html"
			set destPath to MediaPath & mmName
			copyFile destination destPath
			
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
		set mmtext to mmtext & "<br><h1>Multimedia Object voor " & CurrentName & "</h1>" & return
		set mmtext to mmtext & "<h2>Title: " & mmTitle & "</h2>" & return
		if mmLoc is not "" or theDate is not "" then
			set mmtext to mmtext & "<p>Het multimedia object was in "
			if mmLoc is "" then
				set mmtext to mmtext & theDate
			else if theDate is "" then
				set mmtext to mmtext & mmLoc
			else
				set mmtext to mmtext & mmLoc & " in " & theDate
			end if
			if latlon is not "" then
				set mmtext to mmtext & " (<a href='"
				set mmtext to mmtext & "http://maps.google.com/maps?hl=en&client=firefox&rls=en&q="
				set mmtext to mmtext & latlon & "'>map</a>)"
			end if
			set mmtext to mmtext & ".</p>" & return
		end if
		
		-- show the object itself
		set mmtext to mmtext & "<br><center>" & return
		if movieTypes contains mmForm then
			set mmtext to mmtext & "<a href='" & mmName & "'>Klik om de film te zien</a>" & return
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

(* Footer for an individual record
*)
on GetFileFooter()
	set ftr to ""
	set ftr to ftr & "</body>" & return
	set ftr to ftr & "</html>" & return
	return ftr
end GetFileFooter

