(*	 Report 'ˆ la brother ƒloi-GŽrard Talbot' Script
	GEDitCOM II Apple Script
	11 Dec 2009, by John A. Nairn, adapted March 2011 by StŽphane Lelaure to make it a "Talbot" report.

	Find any number of generations of descendants of the currently
	selected individual (or spouse in a family) and output them grouped
	by generation number. Read the output to understand how the Talbot number system works.
	
	Italics show duplicate individuals. Boxes around numbers are clickable boxes to the corresponding individuals. (They seem to be working mainly in Adobe Reader, though.)
	
	The report is output to LaTeX. This report also exists with output to html.
	
	Version 1.6.20110309
	*)

-- script name
property scriptName : "EGT Descendants Generations Report"

-- set these strings for preferred style or a new language
global MaxGen

-- get system language
global lang, babel
set lang to (do shell script "defaults read -g AppleLanguages")
set maxLang to number of words in lang
if maxLang > 4 then set maxLang to 4
set babel to {}
repeat with i from maxLang to 1 by -1
	set ulang to word i of lang
	if ulang is "en" then
		set end of babel to "english"
	else if ulang is "fr" then
		set end of babel to "francais"
	else if ulang is "de" then
		set end of babel to "german"
	else if ulang is "es" then
		set end of babel to "spanish"
	end if
end repeat
if ((count of babel) is 0) then
	set babel to {"francois"}
end if
set AppleScript's text item delimiters to ","
set babel to babel as string
set AppleScript's text item delimiters to ""

-- if no document is open then quit
if CheckAvailable(scriptName, 1.6) is false then return

-- get selected record
set indvRef to SelectedIndividual()
if indvRef is "" then
	beep
	tell application "GEDitCOM II"
		user option title "You have to select an individual or a family in GEDitCOM II to use this script" message "Select an individual and try again" buttons {"OK"}
	end tell
	return
end if

-- Get user input for number of generations (1 or higher)
tell application "GEDitCOM II"
	set iname to alternate name of indvRef
	set thePrompt to "Enter maximum number of generations of descendants of " & iname & Â
		" to include in the report"
	set r to user input prompt thePrompt initial text "4" buttons {"OK", "Cancel"}
	if item 1 of r is "Cancel" then return
	set MaxGen to item 2 of r
end tell
try
	set generations to MaxGen as integer
	if MaxGen < 1 then error
on error
	beep
	tell application "GEDitCOM II"
		user option title "The number of generations must be a number and be greater than zero." message "Try again and enter of number" buttons {"OK"}
	end tell
	return
end try

-- compile list of descendants
tell application "GEDitCOM II"
	set DList to my TraceDescendants(indvRef)
end tell

-- format the list into a report
WriteToReport(indvRef, DList)

return

(* Let GEDitCOM II find the Descendants. First get listed records, but those
	are in outline order (see GEDitCOM II documentation). They need to be
	rearranged into generations. When done each item of the returnd list will
	have a list for that generation with elements as follows:
	
	For Direct Descendants:
		Unique name: {gen #, indi ref}
		Duplicate name: {gen #,indi ref,integer}
	For spouses:
		Known: { gen #, indi ref, fam ref}
		Unknown: { gen #, "", fam ref}
	Where
		gen # = generation number (0 for source, 1, 2, ...) (not needed here)
		indi ref = reference to individual record or "" if unknown spouse
		fam ref = those that are spouses include link to the family record
	                		(spouses will follow associated direct decendant)
*)
on TraceDescendants(indvRef)
	-- tell GEDitCOM II to compile outline of descendants
	tell application "GEDitCOM II"
		notify progress message "Finding Descendants"
		tell front document
			show descendants indvRef generations MaxGen tree style outline
			set DList to listed records
		end tell
		close front window
		notify progress message "Arranging Descendants by Generation"
	end tell
	
	-- rearrange into generations as described above
	set numDList to count of DList
	set DGList to {}
	repeat with i from 1 to numDList
		-- read item for outline list and its gen number
		set ditem to item i of DList
		set iGen to (item 1 of ditem) + 1
		
		-- convert duplicates from {gen #, link #}  to {iGen, indi ref, 0)
		if number of items in ditem is 2 and class of item 2 of ditem is integer then
			set oldnum to item 2 of ditem
			set orig to item 2 of item oldnum of DList -- find indi ref in DList
			set ditem to {iGen - 1, orig, 0} -- actual number does not matter here
		end if
		
		-- create new generation or add to end of existing one
		if iGen > (count of DGList) then
			set end of DGList to {ditem}
		else
			set end of item iGen of DGList to ditem
		end if
	end repeat
	return DGList
end TraceDescendants

(* Get type of descendent. The style are
	Direct Descendent is {gen #,rec ref} or {gen #,rec ref,link num} if needs name link
	Spouses are {gen #,rec ref,fam ref} or {gen #,"",fam ref} for unknown spouse
	Duplicate Direct have {gen #,prev num} where prev num is number in the list
*)
on GetDescendantType(oneIndi)
	if number of items in oneIndi is 2 then
		return "direct"
	else
		if class of item 3 of oneIndi is integer then
			return "named direct"
		else
			return "spouse" -- may be unknown spouse
		end if
	end if
end GetDescendantType

(* Write the results now in the global variables to a
     GEDitCOM II report *)
on WriteToReport(indvRef, DList)
	
	set leftColNb to "" -- left-hand column family number as text
	set numFamc to 0 -- left-hand column family counter
	set prevFamcID to ""
	set rightColNb to "" -- right-hand column family number as text
	set numFams to 0 -- right-hand column family counter
	
	-- get user input for papersize
	tell application "GEDitCOM II"
		set p to user option title "Select physical page size for your printer and/or your LaTeX configuration." buttons {"US Letter", "A4", "Cancel"}
		if p = "Cancel" then
			return
		else
			if p = "US Letter" then
				set paperSize to "letterpaper"
				set xcm to "23"
			else
				if p = "A4" then
					set paperSize to "a4paper"
					set xcm to "25"
				end if
			end if
		end if
	end tell
	
	
	-- build report using LaTeX elements beginning with comments
	set hrpt to {"% Instructions to compile this file:" & return Â
		& "% 1- compile the .tex file (pdflatex) a first time." & return Â
		& "% 2- run makeindex on the files people.idx and places.idx you got after compilation" & return Â
		& "% 3- compile the .tex file again. You should get a complete PDF output." & return}
	
	set end of hrpt to "\\documentclass[" & paperSize & ",11pt]{article}" & return
	set end of hrpt to "\\usepackage[" & babel & "]{babel}" & return
	set end of hrpt to "\\usepackage[applemac]{inputenc}" & return
	set end of hrpt to "\\usepackage[T1]{fontenc}" & return
	set end of hrpt to "\\usepackage{supertabular}" & return
	set end of hrpt to "\\usepackage{textcomp}" & return
	set end of hrpt to "\\usepackage{multirow}" & return
	set end of hrpt to "\\usepackage{booktabs}" & return
	set end of hrpt to "\\usepackage{lscape}" & return
	set end of hrpt to "\\usepackage{makeidx}" & return
	set end of hrpt to "\\usepackage{multind}" & return
	set end of hrpt to "\\usepackage[pdftex,bookmarks]{hyperref}" & return
	set end of hrpt to "% \\usepackage[pdftex,bookmarks,colorlinks]{hyperref} use this line for color links" & return
	set end of hrpt to "% Shrink the margins to use more of the page." & return
	set end of hrpt to "% This is taken from fullpage.sty, which is on some systems." & return
	set end of hrpt to "\\usepackage{anysize}" & return
	set end of hrpt to "\\marginsize{1.5cm}{1.5cm}{1.5cm}{1.5cm}" & return
	set end of hrpt to "\\textheight " & xcm & "cm" & return
	--	set end of hrpt to "\\pagestyle{empty} % no page numbers" & return
	set end of hrpt to return
	
	-- numbers on the left and right of the report will be placed with LaTeX newcommands as defined here
	set end of hrpt to "%----------------- New command defs ----------------" & return
	set end of hrpt to "\\newcommand{\\leftlink}[1]{\\hypertarget{#1}{} \\hyperlink{#1 up}{#1}}" & return
	set end of hrpt to "\\newcommand{\\rightlink}[1]{\\hypertarget{#1 up}{} \\hyperlink{#1}{#1}}" & return
	set end of hrpt to "%(#1 = first name, #2 = surname, #3 = index name (w/o accented letters), #4 = suffix)" & return
	set end of hrpt to "\\newcommand{\\peopleidx}[4]{#1~\\textsc{#2}#4\\index{people}{#3@\\textsc{#2}!#1}}" & return
	-- same newcommand with names in boldface for direct descendants
	set end of hrpt to "\\newcommand{\\peopleidxbold}[4]{\\textbf{#1~\\textsc{#2}#4}\\index{people}{#3@\\textsc{#2}!#1}}" & return
	-- same newcommand with names in italics for duplicatess
	set end of hrpt to "\\newcommand{\\peopleidxital}[4]{\\textit{#1~#2#4}\\index{people}{#3@\\textsc{#2}!#1}}" & return
	--newcommand to index places
	set end of hrpt to "\\newcommand{\\placeidx}[1]{#1\\index{places}{#1}}" & return & return
	
	set end of hrpt to "\\makeindex{people}" & return
	set end of hrpt to "\\makeindex{places}" & return & return
	
	set end of hrpt to "\\begin{document}" & return
	
	-- begin report with titlepage	
	set author to authorDialog()
	tell application "GEDitCOM II"
		set contextInfo of every individual of front document to ""
		set fname to my getProperName("n", indvRef)
	end tell
	set numDList to number of items in DList
	set end of hrpt to "\\title{Descendants of " & fname & "}" & return
	set end of hrpt to "\\author{" & author & "}" & return
	set end of hrpt to "% \\date{\\today}" & return
	set end of hrpt to "\\maketitle" & return & return
	
	-- loop over each generation
	set irpt to {} -- the index
	set dNum to 1 -- descendant number
	set numDups to 0 -- number that are duplicates
	set thisRow to {} -- table row
	set thisPerson to "" -- indi's info
	set thisFams to {} -- his/her family's info (spouse)
	set dgNum to 0 -- number of descendants for this generation
	set numdgDups to 0 -- number of duplicates for this generation
	set dgCount to {} -- descendant counter for each generation
	
	set rpt to {"\\begin{landscape}"} & return -- body of report
	set end of rpt to "\\begin{center}" & return
	set end of rpt to "\\tablefirsthead{}" & return
	set end of rpt to "\\tablehead{\\multicolumn{" & "4}{" & "l}{\\small\\sl " & "Continued from previous page" & "}\\" & "\\%" & return
	set end of rpt to "\\hline\\noalign{\\smallskip}}" & return
	set end of rpt to "\\tabletail{\\hline\\noalign{\\smallskip}%" & return
	set end of rpt to "\\multicolumn{" & "4}{" & "r}{\\small\\sl " & "Continuation on next page" & "} \\" & "\\ }" & return
	set end of rpt to "\\tablelasttail{\\hline\\noalign{\\smallskip}}" & return & return
	set end of rpt to "\\begin{supertabular}{r p{15cm} p{6cm} r}" & return
	set end of rpt to "\\toprule" & return & return
	
	repeat with i from 1 to numDList
		tell application "GEDitCOM II" to notify progress message "Writing Generation No. " & (i - 1)
		
		-- start the generation by inserting the generation header
		set end of rpt to "%----------------- Generation No. " & i & " ----------------" & return
		set end of rpt to "\\multicolumn{" & "4}{" & "c}{\\bf " & "Generation No. " & i & Â
			"}\\\\" & return & "\\multicolumn{" & "4}{" & "c}{}\\\\" & return
		
		
		set dGen to item i of DList -- list for this generation
		set numGen to number of items in dGen
		set j to 1
		repeat while j ² numGen
			set dIndi to item j of dGen
			set dType to GetDescendantType(dIndi)
			set thisIndi to item 2 of dIndi
			
			-- must be a direct decendant (spouses, if any, will follow)
			tell application "GEDitCOM II"
				tell thisIndi
					
					-- get left-column number
					if i > 1 then
						set FamcID to evaluate expression "FAMC"
						if FamcID = prevFamcID then
							set leftColNb to ""
						else
							set prevFamcID to FamcID
							set numFamc to numFamc + 1
							set leftColNb to "\\leftlink{" & (numFamc as string) & "}"
						end if
					else
						set leftColNb to "" & tab
					end if
					
					-- see if a duplicate and set linkNum to previous appearance (left number) if yes
					set {linkNum, fetchFamilies, skipFamilies} to {"", false, false}
					if dType is "named direct" then
						set linkID to item 3 of dIndi
						set linkNum to contextInfo
						if linkNum is "" then
							-- first appearance in the report, if linkID is 0 will need to get families here
							set contextInfo to numFamc
							if linkID = 0 then set fetchFamilies to true
						else
							-- subsequent appearance, if linkID>0 then should skip families now
							if linkID > 0 then set skipFamilies to true
						end if
					end if
					
					if linkNum is "" then
						-- for unique individuals, output GEDitCOM II description with options
						--	set des to alternate name
						set des to my getProperName("bf", thisIndi)
						
						set binfo to my eventDate("", birth date user, birth place)
						set dinfo to my eventDate("", death date user, death place)
						if dinfo is not "" then
							if binfo is not "" then
								set theEvents to " {\\footnotesize  (" & binfo & " Ð " & dinfo & ")} "
							else
								set theEvents to " {\\footnotesize (d. " & dinfo & ")}"
							end if
						else
							if binfo is not "" then
								set theEvents to " {\\footnotesize  (" & binfo & ")}"
							else
								set theEvents to ""
							end if
						end if
						
						set thisRow to leftColNb & " & "
						set thisPerson to des & theEvents
					else
						
						-- for duplicates, provide link back to original appearance (and no description)
						set thisRow to leftColNb & " & "
						set end of thisPerson to my getProperName("it", thisIndi)
						set end of thisPerson to " (see \\#\\hyperlink{" & linkNum & "up}{" & linkNum & "})"
						set numDups to numDups + 1
						set numdgDups to numdgDups + 1 -- increment duplicates for this generation
					end if
					
					if fetchFamilies is true then set famRefs to spouse families
				end tell
				set dNum to dNum + 1 -- increment number
				set dgNum to dgNum + 1 -- increment number for this generation
			end tell
			
			-- on to next descendant
			set j to j + 1
			
			-- collect families
			set fams to {}
			if fetchFamilies is true then
				-- collect families when person was a duplicate, but appeared first
				repeat with jj from 1 to count of famRefs
					set fam to item jj of famRefs
					tell application "GEDitCOM II"
						tell fam
							set spse to husband
							if spse is not "" and spse is thisIndi then
								set spse to wife
							end if
						end tell
					end tell
					set end of fams to {0, spse, fam}
				end repeat
			else
				-- collect from those that follow the individual
				repeat while j ² numGen
					set dIndi to item j of dGen
					set dType to GetDescendantType(dIndi)
					if dType is not "spouse" then exit repeat
					if skipFamilies is false then set end of fams to dIndi
					set j to j + 1
				end repeat
			end if
			
			-- Any subsequent items that are spouses are spouse for previous individual
			-- process all that are found
			if fams is {} then
				set thisPerson to thisPerson & " & & \\\\" & return
				set end of rpt to thisRow
				set end of rpt to thisPerson
				set thisRow to {}
				set thisPerson to ""
			else
				repeat with jj from 1 to (count of fams)
					-- if not a spouse, exit this loop and continue to next direct descendant
					set thisFams to {}
					set dIndi to item jj of fams
					
					-- process this spouse
					set spouse to item 2 of dIndi
					set fam to item 3 of dIndi
					
					-- spouse's name
					if spouse is "" then
						set end of thisFams to "\\par x unknown spouse "
					else
						tell application "GEDitCOM II"
							tell spouse
								set end of thisFams to "\\par" & " x " & my getProperName("n", spouse)
								
								-- parents' name
								try
									set spfather to my getProperName("n", father)
								on error
									set spfather to ""
								end try
								try
									set spmother to my getProperName("n", mother)
								on error
									set spmother to ""
								end try
								if spmother is not "" then
									if spfather is not "" then
										set spParents to " {\\footnotesize  (Parents: " & spfather & " and " & spmother & ")}"
									else
										set spParents to " {\\footnotesize  (Mother: " & spmother & ")}"
									end if
								else
									if spfather is not "" then
										set spParents to " {\\footnotesize  (Father: " & spfather & ")}"
									else
										set spParents to " {\\footnotesize  (Unknown parents)}"
									end if
								end if
								set end of thisFams to spParents
							end tell
						end tell
					end if
					
					-- marriage date and place
					tell application "GEDitCOM II"
						tell fam to set md to my eventDate("", marriage date user, marriage place)
						if md is not "" then
							set end of thisFams to " & " & md
						else
							set end of thisFams to " &"
						end if
					end tell
					
					-- right-handside column number with LaTeX links (unless in the final generation)
					if i < numDList then
						tell application "GEDitCOM II"
							tell fam
								set numChil to count of children
								if numChil > 0 then
									set numFams to numFams + 1
									set rightColNb to numFams as text
									set end of thisFams to " & \\rightlink{" & rightColNb & "}"
								else
									set end of thisFams to " &"
								end if
							end tell
						end tell
					else
						-- no right-handside number for the final generation
						if i = numDList then
							set end of thisFams to " &"
						end if
					end if -- end of right column number block
					
					if jj > 1 then
						-- do not repeat number on the left if indi is spouse in more than 1 family
						set thisRow to " & "
						-- set descendant in italics (to show it is the same individual as previously displayed)
						tell thisIndi
							set des to my getProperName("it", thisIndi)
							set thisPerson to des & "\\textit{" & theEvents & "}"
						end tell
					end if
					
					-- build each row with both spouses
					set end of rpt to thisRow & thisPerson & thisFams & " \\\\" & return
				end repeat -- end of spouses
			end if
			
			-- individual and spouse done
			set thisPerson to {}
			
		end repeat -- end of one generation
		
		-- do not print separation line after last generation
		if i < numDList then
			set end of rpt to "\\midrule" & return & return
		end if
		
		set end of dgCount to {dgNum, numdgDups}
		log dgCount
		set dgNum to 0
		set numdgDups to 0
		
	end repeat -- end of all generations
	
	-- end the report
	set end of rpt to return & "\\bottomrule" & return
	set end of rpt to "\\end{supertabular}" & return
	set end of rpt to "\\end{center}" & return
	set end of rpt to "\\end{landscape}" & return
	set end of rpt to "\\clearpage" & return
	set end of rpt to "\\printindex{people}{" & "Index of People" & "}" & return
	set end of rpt to "\\printindex{places}{" & "Index of Places" & "}" & return
	set end of rpt to "\\end{document}"
	
	-- add statistics to header
	set gchilone to {"child", "grandchild", "great-grandchild"}
	set gchilmany to {"children", "grandchildren", "great-grandchildren"}
	set end of hrpt to "%----------------- Statistics ----------------" & return
	set end of hrpt to "\\vfill" & return
	set end of hrpt to "Number of unique descendants: " & ((dNum - numDups) - 2) & return & return
	set end of hrpt to fname & " had:" & return
	set end of hrpt to "\\begin{itemize}" & return
	repeat with k from 2 to (count of dgCount)
		set gc to item k of dgCount
		set numgc to (item 1 of gc) - (item 2 of gc)
		set end of hrpt to "\\item " & numgc & " "
		if k < 4 then
			if numgc = 1 then
				set end of hrpt to item (k - 1) of gchilone & return
			else
				set end of hrpt to item (k - 1) of gchilmany & return
			end if
		else
			set end of hrpt to "descendants (generation " & k & ")" & return
		end if
	end repeat
	set end of hrpt to "\\end{itemize}" & return & return
	
	-- credits
	set vr to version of application "GEDitCOM II"
	set end of hrpt to "%----------------- Credits ----------------" & return
	set end of hrpt to "\\mbox{ }" & return
	set end of hrpt to "\\vfill" & return
	set end of hrpt to "\\begin{center}" & return
	set end of hrpt to "Copyright \\copyright \\ \\today \\\\" & author & "\\\\ \\LaTeX{} - GEDitCOM II " & vr & return
	set end of hrpt to "\\end{center}" & return & return
	
	-- option to insert a presentation of brother Talbot and his cross-reference system
	set end of hrpt to Introduction()
	
	set rpt to (hrpt as string) & return & (rpt as string)
	
	
	-- create the report as .tex and .pdf files or to be pasted in new .tex document from clipboard
	set r to display dialog "Would you like to" & return & "Ð copy the report to clipboard?" & return & "Ð create the tex and pdf files?" buttons {"Cancel", "Copy to clipboard", "Create pdf"} Â
		default button "Create pdf" cancel button {"Cancel"} with title scriptName with icon 1
	if button returned of r is "Cancel" then
		return
	else
		if button returned of r = "Copy to clipboard" then
			tell application "Finder"
				set the clipboard to (rpt as string) -- Encoding problem?: please use "\usepackage{utf8x}"
			end tell
		else
			if button returned of r = "Create pdf" then
				WriteToTex(rpt) -- Encoding problem?: please use "\usepackage{applemac}"
			end if
		end if
	end if
end WriteToReport


(*	Presentation of brother Talbot's system (option)
*)
on Introduction()
	tell application "GEDitCOM II"
		set p to user option title "Would you like to print a presentation of Brother Talbot's cross-reference number system?" message "This can be useful if you intend to give the report to someone who does not know this system yet." buttons {"Print", "Skip", "Cancel"}
		if p = "Print" then
			set talbot to space & "\\textsc{Talbot}" & space
			set intro to {"%----------------- Presentation of the Talbot system ----------------
"} & return
			set end of intro to "\\clearpage" & return
			set end of intro to "\\section*{" & "The Talbot Cross-Reference Number System" & "}" & return
			--	set end of irpt to "\\subsection*{" & "Presentation" & "}" & return
			set end of intro to "This report is based on the clever system of cross-reference numbers invented by an experienced genealogist, very famous in Canada especially in Quebec, marist brother ƒloi-GŽrard"
			set end of intro to talbot & "(1899-1976). He used this original and different method to classify and publish the result of his religious and civil record listings during his research on the history of eight Canadian families." & return & return
			set end of intro to "Contrary to the Quebecois genealogistÕs works however, this report shows all descendants, including people who have not founded a family (children who died at an early age, religious people, single people without descendancy). Similarly, lineage through women, which the genealogies Mr" & talbot & "reconstituted do not present, is included here, which implies systematic printing of the family names. This report also gives the name of the spouseÕs parents and can print generation headers. To make it easier to use, it also includes an index of names and an index of places at the end." & return & return
			set end of intro to "For further information on brother" & talbot & ", you can read this book by Laurent \\textsc{Potvin}, \\textit{Eloi-GŽrard Talbot. Un gŽnŽalogiste chevronnŽ}, published in 2008 and available for free in French on this website: " & "\\url{http://classiques.uqac.ca/contemporains/potvin_laurent/eloi_gerard_talbot/eloi_gerard_talbot.html}." & return & return
			set end of intro to "\\subsection*{" & "How this report works:" & "}" & return
			set end of intro to "\\begin{itemize}" & return
			set end of intro to "\\item " & "The numbers on each side of the list always refer to a family (whether the spouses are married or not)" & return
			set end of intro to "\\item " & "The number on the right refers to the family a person made with his/her spouse, thus to his/her children. It allows to find his/her descendancy by looking at the same number on the left further down the report. No number will be printed on the right of someone without (known) children." & return
			set end of intro to "\\item " & "The number on the left refers to the family a person was the child in, thus to the couple his/her parents made. It allows to find his/her ascendancy.  The number is printed on the left of the first child in a family only. His siblings are printed below him/her, without a number. You can find a personÕs parents by finding the first number on the left up the list." & return
			set end of intro to "\\item " & "The first person in a couple is always a descendant of the first couple in the report." & return
			set end of intro to "\\item " & "If a descendant had more than one spouse, he/she is printed in italics for his/her subsequent unions and all his/her families are printed with a different number in the right hand-side column." & return
			set end of intro to "\\end{itemize}" & return
			set end of intro to "\\subsection*{" & "How to use this report:" & "}" & return
			set end of intro to "\\begin{enumerate}" & return
			set end of intro to "\\item " & "Choose a couple at random in your report." & return
			set end of intro to "\\item " & "Locate the number on the left of the couple. If there is no number, locate the closest number up the column. You have just gone through the elder siblings of the main spouse in the chosen couple." & return
			set end of intro to "\\item " & "Take this number and find the same in the right-handside column further up the report. You will thus get to the parents of the main spouse." & return
			set end of intro to "\\item " & "Repeat step 2: from left-handside number to right-handside number, you will find the main spouseÕs grandparents, great grandsparents, etc in this lineage and finally reach his/her topmost ancestors, the first couple in this report." & return
			set end of intro to "\\item " & "Get back to the chosen couple in step 1. If there is no number on the right, it means this couple did not have children." & return
			set end of intro to "\\item " & "If there is one, locate the same number in the left-handside column further down the list. You will get the first child in the couple. If he has any, his/her siblings share the same number: they are mentioned below without a number on the left." & return
			set end of intro to "\\item " & "Choose one of the children and repeat the previous step. That way you will go along the lineage down to the most recent generations." & return
			set end of intro to "\\end{enumerate}" & return
			return intro
		else
			if p = "Skip" then
				return ""
			else
				return
			end if
		end if
	end tell
end Introduction

(*	save LaTeX file
	enregistre le fichier LaTeX
	get path to GEDCOM file
	rŽcupre le chemin du fichier GEDCOM
*)
on WriteToTex(rpt)
	tell application "GEDitCOM II"
		try
			set docname to name of document 1
			set docpath to path of document 1
		on error
			display dialog "Your genealogy file has never been saved. First you must save it before outputting your report to LaTeX." buttons {"OK"} default button "OK" with title scriptName with icon stop
			return
		end try
	end tell
	set AppleScript's text item delimiters to "/"
	set docpath to docpath's text items
	set last item of docpath to ""
	set docpath to docpath as string
	set AppleScript's text item delimiters to ""
	set hfsdocpath to POSIX file docpath
	
	-- save LaTeX file in the same folder as GEDCOM file by default
	-- enregistre le fichier LaTeX dans le mme dossier que le fichier GEDCOM par dŽfaut
	set texFileName to choose file name default location (POSIX file docpath) Â
		with prompt "Where would you like to record your LaTeX file?" default name "EGTDescReport" & ".tex"
	set texFilePath to quoted form of POSIX path of texFileName
	set referenceNumber to open for access texFileName with write permission
	try
		write rpt to texFileName
	on error
		close access referenceNumber
	end try
	close access referenceNumber
	
	set AppleScript's text item delimiters to "/"
	set outpath to text items of texFilePath
	set inpath to last item of outpath
	set inpath to "'" & inpath
	set last item of outpath to ""
	set outpath to outpath as string
	set qoutpath to outpath & "'"
	set AppleScript's text item delimiters to ""
	
	-- compile .tex and .idx files to pdf
	-- compile les fichiers .tex et .idx en pdf
	do shell script "/usr/texbin/pdflatex -output-directory " & qoutpath & " " & inpath
	delay 0.2
	do shell script "/usr/texbin/makeindex " & outpath & "people.idx'"
	do shell script "/usr/texbin/makeindex " & outpath & "places.idx'"
	delay 0.2
	do shell script "/usr/texbin/pdflatex -output-directory " & qoutpath & " " & inpath
	
	set AppleScript's text item delimiters to "."
	set pdfpath to text items of inpath
	set last item of pdfpath to ""
	set pdfpath to pdfpath as string
	set AppleScript's text item delimiters to ""
	set pdfpath to pdfpath & "pdf"
	set pdfpath to (characters 2 thru (number of characters in pdfpath) of pdfpath) as string
	set fldrpath to (characters 2 thru (number of characters in outpath) of outpath) as string
	set pdfpath to fldrpath & pdfpath
	
	tell application "Finder"
		set filePath to POSIX file pdfpath as text
		if not (exists file filePath) then
			display dialog "Your PDF report could not be opened. " & "You can try opening the '.tex' file that was just saved and then try typesetting the report manually." buttons {"OK"} default button {"OK"} with icon 1 with title scriptName
			return
		end if
	end tell
	
	tell application "Preview"
		activate
		open file filePath
	end tell
	
end WriteToTex

(*	String parser for an individual's proper name
	Analyse du nom d'un individu
*)
on getProperName(style, recRef)
	tell application "GEDitCOM II"
		tell recRef
			set nameStruct to find structures tag "NAME" output "references"
			if (count of nameStruct) is 0 then
				error
			end if
		end tell
		set nameText to contents of item 1 of nameStruct
		set nameTextAlt to format name value nameText case "title"
		set nameParts to name parts gedcom name nameText
		set fn to item 1 of nameParts -- get first names as is
		set fn to my safeTeX(fn)
		set suf to item 3 of nameParts -- get suffix as is
		set suf to my safeTeX(suf) -- get suffix as is
		
		-- get index name without accented French letters (applies only to French system)
		set idxn to item 2 of nameParts
		set idxn to my safeTeX(idxn)
		if lang is "fr" then set idxn to my indexSafe(idxn)
		
		set nameParts to name parts gedcom name nameTextAlt
		set sn to my safeTeX(item 2 of nameParts) -- get surname ready for LaTeX smallcaps
		-- removes space at the end of the first names
		set lfn to length of fn
		if lfn > 0 then set fn to (characters 1 thru (lfn - 1) of fn as string)
		
		if style = "bf" then
			-- creates the direct descendants's name in bold with surname in small caps and index
			set fullName to "\\peopleidxbold{" & fn & "}{" & sn & "}{" & idxn & "}{" & suf & "}"
		else
			-- creates the duplicate descendant's name in italics
			if style = "it" then
				set fullName to "\\peopleidxital{" & fn & "}{" & sn & "}{" & idxn & "}{" & suf & "}"
			else
				-- creates other individuals in roman style
				set fullName to "\\peopleidx{" & fn & "}{" & sn & "}{" & idxn & "}{" & suf & "}"
			end if
		end if
	end tell
end getProperName

(*	Get rid of accents to sort LaTeX index properly
*)
on indexSafe(str)
	set AppleScript's text item delimiters to ""
	set accents to {"Ë", "å", "€", "‚", "é", "ƒ", "æ", "è", "ì", "ï", "…", "ô", "ó", "†", "Ù"}
	set noaccents to {"A", "A", "A", "C", "E", "E", "E", "E", "I", "O", "O", "U", "U", "U", "Y"}
	set ca to count of accents
	repeat with i from 1 to ca
		set AppleScript's text item delimiters to item i of accents
		set itemList to text items of str
		set AppleScript's text item delimiters to item i of noaccents
		set str to itemList as string
		set AppleScript's text item delimiters to ""
	end repeat
	return str
end indexSafe

(*	Look for special TeX characters : &, $, %, #, _
*)
on safeTeX(str)
	set AppleScript's text item delimiters to ""
	set symbols to {"&", "$", "£", "_", "|", " ", "©", "%", "#"}
	set nosymbols to {"\\&", "\\$", "\\pounds", "\\_", "\\textbar", "\\dag", "\\copyright", "\\%", "\\#"}
	repeat with i from 1 to (count of symbols)
		set AppleScript's text item delimiters to item i of symbols
		set itemList to text items of str
		set AppleScript's text item delimiters to item i of nosymbols
		set str to itemList as string
		set AppleScript's text item delimiters to ""
	end repeat
	set AppleScript's text item delimiters to ""
	return str
end safeTeX

(*	Ask for the author's name and format it in smallcaps for LaTex output
	Demande le nom de l'auteur et formattage en petite capitales pour sortie LaTeX
*)
on authorDialog()
	-- get main submitter's name (usually the person who made the GEDCOM file)
	tell application "GEDitCOM II"
		tell front document
			set ms to main submitter
			tell submitter id ms
				set msprop to properties
				set msname to name
			end tell
		end tell
		set r to display dialog "Please valid the authorÕs name or enter another one:" default answer msname buttons {"Cancel", "OK"} Â
			default button "OK" cancel button {"Cancel"} with title scriptName with icon 1
		if button returned of r is "Cancel" then return
		set author to my safeTeX(text returned of r)
		if author = "" then
			display dialog "The name field was empty!" buttons {"OK"} default button Â
				"OK" with title scriptName with icon 2
			authorDialog()
		else
			set nam to format name value author case "title"
			set namlist to name parts gedcom name nam
			set author to item 1 of namlist & "\\textsc{" & item 2 of namlist & "}"
		end if
	end tell
	return author
end authorDialog

(* Given date and place (either of which might be empty) return string to
     include in the report. If neither there, return "". If either, start with
     eKey and add each (separated by comma if has both)

    Be sure to get safe html in case text has special characters
*)
on eventDate(eKey, theDate, thePlace)
	tell front document of application "GEDitCOM II"
		set theDate to safe html raw text theDate
		set thePlace to my safeTeX(thePlace)
	end tell
	if theDate is not "" then
		set ed to eKey & "" & theDate
	else
		set ed to ""
	end if
	if thePlace is not "" then
		if ed is "" then
			set ed to eKey
		end if
		set ed to ed & ", \\placeidx{" & thePlace & "}"
	end if
	return ed
end eventDate


(* Find the selected record. If it is a family record, switch to
     the first spouse found. Finally, return "" if the selected record
     is not an indivdual record or if no record is selected
*)
on SelectedIndividual()
	tell application "GEDitCOM II"
		set indvRef to ""
		set recSet to selected records of front document
		if number of items in recSet is not 0 then
			set indvRef to item 1 of recSet
			if record type of indvRef is "FAM" then
				set husbRef to husband of indvRef
				if husbRef is not "" then
					set indvRef to husbRef
				else
					set indvRef to wife of IndvRec
				end if
			end if
			if record type of indvRef is not "INDI" then
				set indvRef to ""
			end if
		end if
	end tell
	return indvRef
end SelectedIndividual

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
