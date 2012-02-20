-- echo 'SELECT en_short_name, alpha2_code, date_of_independence FROM iso_3166_1_countries_en;' | /Library/PostgreSQL/8.4/bin/psql -w -q --tuples-only -h relatedfolks.com -p 5432 -d genealogy -U postgres
property aQuery : "SELECT en_short_name, alpha2_code, date_of_independence FROM iso_3166_1_countries_en;"
property psqlpath : "/Library/PostgreSQL/8.4/bin/psql " -- POSIX path to postgresql's console application
property hostandportname : "-h relatedfolks.com -p 5432 "
property database : "-d genealogy " -- postgresql database name
property extraOpt : "-w --tuples-only " -- postgresql command line options
property username : "-U postgres " -- postgresql username
-- property passwd : "" -- postgresql password comes from ~/.pgpass (having *:5432:genealogy:postgres:sunrise10)

-- log "echo " & quoted form of aQuery & "|" & psqlpath & extraOpt & hostandportname & database & username

on doQuery(aQuery)
	do shell script "echo " & aQuery & "|" & psqlpath & extraOpt & hostandportname & database & username
end doQuery

set the_words to every paragraph of (doQuery(quoted form of aQuery))
log "the_words: " & the_words & ";"
set Final_Words to {}
set {astid, AppleScript's text item delimiters} to {AppleScript's text item delimiters, tab}
repeat with an_item in the_words
	set end of Final_Words to (an_item's every text item)
end repeat
set AppleScript's text item delimiters to astid
Final_Words