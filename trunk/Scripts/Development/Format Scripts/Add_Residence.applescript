tell application "GEDitCOM II"
	tell front document
		begin undo
		set recRef to key record
		tell recRef
			set resiRef to (make new structure with properties {name:"RESI"})
			tell resiRef
				make new structure with properties {name:"ADDR", contents:"New Address"}
			end tell
		end tell
		end undo action "Add New Residence"
	end tell
end tell
