(* Convert all dates in the file to Gregoria dates
*)
global changes
set changes to 0
tell application "GEDitCOM II"
	tell front document
		begin undo
		-- do individuals
		my convert(every individual whose gedcom contains "DATE")
		
		-- do families
		my convert(every family whose gedcom contains "DATE")
		end undo action "Convert Dates"
	end tell
end tell

return "Dates Converted: "&changes

(* Check all DATE tags in record with id recID. If any contain French
	Republic Month, convert to Gregorian.
*)
on convert(recRefs)
	local numRecs
	set numRecs to number of items in recRefs
	repeat with i from 1 to numRecs
		tell application "GEDitCOM II"
			tell item i of recRefs
				set recDates to find structures tag "DATE" output "references"
				set numd to number of items in recDates
				repeat with j from 1 to numd
					set oneDate to item j of recDates
					set currentDate to contents of oneDate
					tell application "Date Calculator"
						set newDate to convert the date currentDate calendar "Gregorian"
					end tell
					if newDate is not currentDate then
						set contents of oneDate to newDate
						set changes to changes+1
					end if
				end repeat
			end tell
		end tell
	end repeat
end convert

