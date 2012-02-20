#!/usr/bin/python
# -*- coding: utf-8 -*-
# Might be better called: PLAC wizard

'''
References:
http://wiki.phpgedview.net/en/index.php?title=Place_data # Some conventions it recommends are:
  (a) include type in names below ADM1 (e.g., Queens County or Acadia Parish)
  (b) use as many levels as necessary but do not skip anybody
  (c) if you change data, put the original info in Notes field
  From the phpgedview forum, it is clear that even the programmers are not very happy with the current support for PLAC.
http://www.francogene.com/gfna/gfna/998/places.htm -- Place Conventions for the Genealogy of the French in North America
'''

from ScriptingBridge import *
#from pysqlite2 import dbapi2 as sqlite
from sqlite3 import dbapi2 as sqlite
# TODO: test using 'from sqlite3 import dbapi2 as sqlite', which worked out-of-box on John's laptop, whereas 'pysqlite2' did not
import subprocess

''' Make output from script dependent on interest level of user by setting verbosity:
  1: show (a) what's in PLAC and FORM fields now, (b) best guess form (if none exists) or double-check summary if FORM was not empty, (b) best guess lat, lon
  2: all of (1) plus breakdown by datasource: i.e., show (a) what's in PLAC and FORM fields now,
       (b) first guess form, best guess form (if none exists) or double-check summary by datasource if FORM was not empty,
       (c) all reasonable guesses by datasource, best guess lat, lon
  debug: all of 2 plus document structure info, query parameters, elapsed query times?, weighting details contributing to decisions?
  
  In addition, (maybe) make the following doc changes:
  a) if FORM is empty initially, fill in a FORM (and supply an uncertainty QUAY?)
  b) if lat, lon is empty initially, fill it in (and supply an uncertainty QUAY?)
'''
''' TEST CASES:
1) Gartner.gedpkg, NAME='Manuel Pereira Serpa'
Initial state:
Birthplace="Prainha do Norte, Ilha Pico, Azores, Portugal"
Form="city, county, state, country"
_GPS=37.74, -25.66

Recommendations:


Final state:
Unchanged from initial?
2) 
'''
#####
#
# Functions
#
#####
def guessFormFromPlaceCommas(s):
  if s:
    englishLevelName = list() # initialize empty list
    placeList = s.split(',')
    # print 'placeList is %s' % placeList
    # print 'len(placeList) is ',len(placeList)
    for level in range(0,len(placeList)-4):
      # print 'level is ', level
      englishLevelName = englishLevelName + ['unk']
      # print 'englishLevelName is ', englishLevelName
    if len(placeList)>4:
      englishLevelName = englishLevelName + ['city','county','state','country']  # append
      # print 'placeList is %s' % placeList
    elif len(placeList)==4:
      # print 'placeList is %s' % placeList[0:4]
      englishLevelName = ['city','county','state','country']
    elif len(placeList)==3:
      # print 'placeList is %s' % placeList[0:3]
      englishLevelName = ['county','state','country']
    elif len(placeList)==2:
      # print 'placeList is %s' % placeList[0:2]
      englishLevelName = ['state','country']
    else: 
      # print 'placeList is %s' % placeList[0:1]
      englishLevelName = ['country']
    return englishLevelName
  else:
    # print "no value (i.e. None) or empty string (i.e. \'\') supplied"
    return englishLevelName
'''   
def pp(cursor, data=None, check_row_lengths=False):
  if not data:
    data = cursor.fetchall()
    # print "In pp(), cursor.rowcount is: ", cursor.rowcount, "while len(data) is: ", len(data)
    # Re above: pysqlite's cur.rowcount does not work in a useful way for SELECTs
    names = []
    lengths = []
    rules = []
    # print cursor.description
    for col, field_description in enumerate(cursor.description):
      field_name = field_description[0]
      # print col, field_description
      names.append(field_name)
      field_length = field_description[2] or 12
      field_length = max(field_length,len(field_name))
      # print field_name, field_length
      if check_row_lengths:
        # double-check in case unreliably given (by default the sqlite3 connection object assumes the detect_types parameter
        #  is 0; if you want you can set it to PARSE_DECLTYPES (or to PARSE_COLNAMES if you have custom datatypes)
        data_length = max([len(unicode(row[col])) for row in data])  # needed for queries against GeoLookup_fr, for example
        # data_length = max([len(str(row[col])) for row in data])
        field_length = max(field_length, data_length)
      lengths.append(field_length)
      rules.append('-' * field_length)
      # print data_length, field_length, lengths, rules
        
    format = " ".join(["%%-%ss" % l for l in lengths])
    # print format
    result = [format % tuple(names), format % tuple(rules)]
    for row in data:
      result.append(format % tuple(row))
    return "\n".join(result)
'''
def pp(cursor, data=None, check_row_lengths=False):
  if not data:
    data = cursor.fetchall()
    # print "In pp(), cursor.rowcount is: ", cursor.rowcount, "while len(data) is: ", len(data)
    # Re above: pysqlite's cur.rowcount does not work in a useful way for SELECTs
    names = []
    lengths = []
    rules = []
    # print cursor.description
    for col, field_description in enumerate(cursor.description):
      field_name = field_description[0]
      # print col, field_description
      names.append(field_name)
      field_length = field_description[2] or 12
      field_length = max(field_length,len(field_name))
      # print field_name, field_length
      if check_row_lengths:
        # double-check in case unreliably given (by default the sqlite3 connection object assumes the detect_types parameter
        #  is 0; if you want you can set it to PARSE_DECLTYPES (or to PARSE_COLNAMES if you have custom datatypes)
        for row in data:
          # print "type(row[col]) :", type(row[col])
          u = ""
          max_data_length=0
          if row[col] != None and type(row[col])is not int and type(row[col]) is not float:
  	        u=row[col].decode('utf-8')   # needed for queries against GeoLookup_fr, for example
          data_length = len(u)
          if data_length > max_data_length:
            max_data_length = data_length         
          field_length = max(field_length, max_data_length)
      lengths.append(field_length)
      rules.append('-' * field_length)
      #print "data_length, field_length: ", data_length, field_length
      #print "data_length, field_length, lengths, rules:", data_length, field_length, lengths, rules
        
    format = " ".join(["%%-%ss" % l for l in lengths])
    # print format
    result = [format % tuple(names), format % tuple(rules)]
    for row in data:
      result.append(format % tuple(row))
    return "\n".join(result)

# next line uses ScriptingBridge
gedit = SBApplication.applicationWithBundleIdentifier_("com.geditcom.GEDitCOMII")
gdoc = gedit.documents()[0] #when I opened the Gartner file first, even if it's not the top window
# birthPlace_by_name = gdoc.individuals().objectWithName_("Gartner, Kevin Edward").birthPlace()

# current front document
gdoc = gedit.documents()[0]

pipe = subprocess.Popen('defaults read com.geditcom.GEDitCOMII.scripts "Factory: Place Hierarchy: verbosity"', shell=True, stdout=subprocess.PIPE)
verbosity=pipe.stdout.read()
print "plist value is: ", verbosity
#verbosity = "2"
verbosity = "debug"
fileDefaultLang = gdoc.headers()[0].language()
if fileDefaultLang == "English":
  lang = 'en'
elif fileDefaultLang is not None:
  langdesc = fileDefaultLang            # look up langdesc in database table? and then try and convert it to 2-letter code
else:
  lang = 'en'                           # use English if no language is specified

filePlaceFormatSpec = gdoc.headers()[0].structures().objectWithName_("FORM")
#fileDefaultFormText = filePlaceFormatSpec.contents()        #TODO: Why does this return None even when I have ADM3,ADM2,ADM1,ADM0
fileDefaultFormText = gdoc.headers()[0].placeHierarchy()

# TODO: ask John why print gdoc.evaluateExpression_("HEAD.LANG") returns None
# ANSWER: use gdoc.headers()[0].evaluateExpression_("LANG")

# retrieve the current field being edited
details = gdoc.editingDetails()
'''
I am in the state now (cursor sitting in DEAT.PLAC.FORM field, and, in my active Python script,
  I've assigned "details = gdoc.editingDetails()") where details is:
(
    3,
    FORM
)
Surprisingly (to me), no record of type FORM is visible when viewing the GEDCOM source through the GEDitCOM source editor.
So, len(details) is 1.

When I type in a lat, lon pair in the details window, _GPS appears in the source editor (at the end) even without my having
  saved the change.  But (prior to Save), the Python script does not see it -- 'details' still returns what it did above.

The last four lines in the source editor now look like:
1 DEAT
2 DATE 1936
2 PLAC , New Haven, Connecticut, USA
3 _GPS 30.,-70.

TODO: Ask John whether it's feasible to color-code unsaved changes (those not visible to other processes)  Hmmm.  Maybe a
  bigger discussion, as even after saved I am surprised by two things: (a) FORM shows in details but not in GEDCOM source,
  (b) _GPS shows in GEDCOM source but not in details revealed by script
  
  Ah, I see that 'details' does not remind you of your context, say by repeating the name of the current field. When the
  cursor is in DEAT.PLAC and I assign details to gdoc.editingDetails(), I see that details is:
  >>> details
(
    2,
    PLAC,
    "<GEDitCOMIIStructure @0x3116130: GEDitCOMIIStructure 1 of GEDitCOMIIStructure 27 of GEDitCOMIIIndividual id \"@I23@\" of GEDitCOMIIDocument \"Gartner.gedpkg\" of application \"GEDitCOM II\" (242)>"
)
  I presume that there are other methods for telling you (for example) the current field, siblings, and all details (and probably for showing just parts of the tree)
'''

# read current text being edited
if len(details)>2 :
    currentPlaceText = details[2].contents()  #TODO: discuss with John pros and cons of getContent() vs contents()
else :
    currentPlaceText = "(empty)"
print "Current PLAC text is", currentPlaceText

placeFormatSpec = None
if len(details) > 0:
  initialPlaceFormatSpec = details[2].structures().objectWithName_("FORM")  #FORM record for PLAC may not exist, but the specifier will still exist and remain unevaluated until needed
  placeFormatSpec = initialPlaceFormatSpec
  if verbosity == "debug":
    print 'len(details) is %s' %len(details)
    print 'details is: %s ' % details
    print 'placeFormatSpec is: ', placeFormatSpec
  print "Text of file's default FORM is :", fileDefaultFormText
  initialPlaceFormatText = initialPlaceFormatSpec.contents()
  print 'Current FORM contents for this PLAC is: ', initialPlaceFormatText
  # latLonWGS84 = details[2].structures().objectWithName_("LATLON").contents() #Hmmm.  How do I check for the validity of a given tag?  (LATLON should be _GPS)
  latLonWGS84 = details[2].structures().objectWithName_("_GPS").contents()
  print 'Current lat, lon is: %s ' %latLonWGS84
  

'''
If the FORM field associated with the current PLAC object has some text in it, then our first guess is that FORM is probably accurate, even if it disagrees with any file default FORM.  (But we can double check).
If the .gedpkg file has a default FORM, then we might(!) try this if we find the PLAC form is not accurate.  If the PLAC object has no associated FORM, then try the default (after checking the language)
If both the PLAC FORM and the default FORM are undefined, then we try to infer the FORM from the structure and content of PLAC.
'''
  
#####
#
# Infer the FORM from PLAC
#
#####

# decide on new text
print "Current place text: ", currentPlaceText
if currentPlaceText == "(empty)":
  placeFormatSpec = None
  print 'Without text in the PLAC field what should we do?  Recommend the file default FORM?  Replace the current PLAC.FORM field with the file default FORM?  Say "Not much we can do without a PLAC value"?'
else:
  newText = ""
  newList = guessFormFromPlaceCommas(currentPlaceText)
  for index in range(0,len(newList)-1):
    newText += str(newList[index])+','
  try:
    newText += str(newList[index+1])
  except NameError:
    newText = str(newList[0])
  print 'Our first guess is that the FORM for this PLAC should be %s' %newText
  # details[2].structures().objectWithName_("FORM").setContents_(newText)  #TODO: Do I need to create a new PLACE.FORM field if none exists yet?
 
# change the text
if len(details)>2 :  #TODO: apparent bug -- if you start with an empty PLACE.FORM, it does not change to a FORM more appropriate for PLACE.  Should this be >1?
    gdoc.beginUndo()
    # details[2].setContents_(newText) #this would affect the current field
    # placeFormatSpec.setContents_(newText)  #this affects the FORM field subordinate to the current field, but does not seem to work when FORM is initially empty
    if initialPlaceFormatText is None:
      print "No FORM record exists"
      p={"name":"FORM"}
      newform=gedit.classForScriptingClass_("structure").alloc().initWithProperties_(p)
      details[2].structures().insertObject_atIndex_(newform, 0)
      #initialPlaceFormatSpec = details[2].structures().objectWithName_("FORM")
      
    print "Changing format value"
    initialPlaceFormatSpec.setContents_(newText)

    gdoc.endUndoAction_("Change Field")
    if verbosity == "debug":
      print 'len(details): ',len(details)
      print 'FORM contents: ',details[2].structures().objectWithName_("FORM").setContents_(newText)
else :
    selRange = (1,-1)
    gdoc.setSelectionRange_(selRange)
    gdoc.setSelectedText_(newText)
    
if placeFormatSpec is None:
  print "FORM value not changed"
elif initialPlaceFormatText == newText: #might relax this by stripping out whitespace around commas
  print "No change in FORM, as it already matches PLAC format"
else:
  print "FORM value changed to %s" % newText  #TODO: reconcile with bug noted above
  
######
#
# Now check and see if our first guess for FORM stands up to testing
#
######

# Start with the largest entity, presumably country, and check and see whether there is such a country
placeList = currentPlaceText.split(',')
country = placeList[len(placeList)-1].strip()   # remove leading and trailing whitespace
iPhoto_country_code = None
lookfor = (country,)
con = sqlite.connect("/Applications/GEDitCOM Extras/GEDitCOM_Places.db")
cur = con.cursor()

if verbosity == "debug":
  print "len(country) is: ", len(country)
if len(country)==0:
  print "No country named"
elif len(country)==2:
  if verbosity == "2" or verbosity == "debug":
    print "Looking in GEDitCOM Extras for country having given 2-letter abbreviation"
  if lang == 'en' or lang is None:
    if verbosity == "2" or verbosity == "debug":
      cur.execute('SELECT alpha2_code, alpha3_code, en_short_name, official_uppercase_en_short_name, date_of_independence, comment \
        FROM iso_3166_countries_en \
        WHERE alpha2_code = ?',lookfor)
      print pp(cur,None,True)
    cur.execute('SELECT en_short_name \
        FROM iso_3166_countries_en \
        WHERE alpha2_code = ?',lookfor)
    for row in cur:  # rowcount will be either 0 or 1
      nonabbrev_country_short_name = row[0].decode('utf-8')
      country_exists = 1



  else:
    # if lang is 'fr' or 'de' or any other non-None value (AND if I copy the fr table on PostgreSQL to sqlite) then we 
    #   give them both english and french names for the country
    '''
    if verbosity == "2" or verbosity == "debug":
      cur.execute('SELECT FR.alpha2_code, EN.alpha3_code, fr_short_name, official_uppercase_fr_short_name, en_short_name, official_uppercase_en_short_name, date_of_independence, EN.comment, FR.comment \
        FROM iso_3166_1_countries_fr AS FR \
        INNER JOIN iso_3166_countries_en AS EN ON EN.alpha2_code=FR.alpha2_code \
        WHERE FR.alpha2_code = ?',lookfor)
      print pp(cur,None,True)
    cur.execute('SELECT fr_short_name, official_uppercase_fr_short_name, en_short_name, official_uppercase_en_short_name \
        FROM iso_3166_1_countries_fr AS FR \
        INNER JOIN iso_3166_countries_en AS EN ON EN.alpha2_code=FR.alpha2_code \
        WHERE FR.alpha2_code = ?',lookfor)
    '''
elif len(country)==3:
  if verbosity == "2" or verbosity == "debug":
    print "Looking in GEDitCOM Extras for country having given 3-letter abbreviation"	
  if verbosity == "debug":
    print "lang is: ", lang
  if lang == 'en' or lang is None:
    if verbosity == "2" or verbosity == "debug":
      cur.execute('SELECT alpha3_code, en_short_name, official_uppercase_en_short_name, date_of_independence, comment \
        FROM iso_3166_countries_en \
        WHERE alpha3_code = ?',lookfor)
      print pp(cur,None,True)  
    cur.execute('SELECT en_short_name \
      FROM iso_3166_countries_en \
      WHERE alpha3_code = ?',lookfor)
    for row in cur:  # rowcount will be either 0 or 1
      nonabbrev_country_short_name = row[0].decode('utf-8')
      country_exists = 1
  
  else:
    print "TODO: Add FR table to sqlite"
else:
  # len(country)>3
  nonabbrev_country_short_name = country
  

if nonabbrev_country_short_name is not None and nonabbrev_country_short_name != country:
  print "Looking in Apple's iPhoto database for country is %s, while non-abbreviated name used in search is %s" % (country, nonabbrev_country_short_name)
else:
  print "Looking in Apple's iPhoto database for country is %s" % country

iPhoto_country_match = 0
con = sqlite.connect("/Applications/iPhoto.app/Contents/Resources/PointOfInterest.db")
cur = con.cursor()
place = newList[len(newList)-1]

# sqlstring = 'SELECT country FROM Geolookup_en WHERE city=0 and county=0 and state=0'
# sqlstring = 'SELECT select alpha2_code, alpha3_code, en_short_name, official_uppercase_en_short_name, date_of_independence, comment from iso_3166_countries_en' \
#   

lookfor = [lang,nonabbrev_country_short_name]
#print type(lookfor)  # lookfor is a list

'''
SELECT Geolookup_en.searchString, country,description, recordLocator,
  Geoplaces.defaultname,type,subtype,latitude, longitude, version, parent,
  Geoplacenames.place,Geoplacenames.language,string 
FROM Geolookup_en INNER JOIN Geoplaces on country=recordLocator 
INNER JOIN Geoplacenames ON Geoplaces.primaryKey=place WHERE city=0 and county=0 and state=0
and Geoplacenames.language='en' and searchString='United States';
'''

# Above returns 3990 rows if you omit the Geoplacenames.language and searchString qualifiers,
#   330 rows if you say use language='en'
#   and two(!) identical rows if you add "AND string = 'United States'"

if verbosity == "debug" and lang == 'en' and nonabbrev_country_short_name is not None:
  # Following rowcount is 0, 1, or 2
  cur.execute("SELECT GL.searchString, country,description, recordLocator, \
      GP.defaultname,type,subtype,latitude, longitude, version, parent, \
      GPN.place,GPN.language,string \
    FROM Geolookup_en AS GL INNER JOIN Geoplaces AS GP on country=recordLocator \
    INNER JOIN Geoplacenames AS GPN ON GP.primaryKey=place \
    WHERE city=0 and county=0 and state=0 \
      and GPN.language=? and searchString=?", lookfor)
  print pp(cur, None, True)
  '''
  searchString	country	description		recordLocator	defaultName	type	subtype	latitude	longitude	version	parent	place	language	string	
  United States	1061338	United States	1061338			1			1		0		45.9126		-113.0991	1.08	0		1		en			United States	
  United States	1061338	United States	1061338			1			1		0		45.9126		-113.0991	1.08	0		1		en			United States	
  '''
  
if lang == 'en':
  cur.execute("SELECT country, latitude, longitude \
    FROM Geolookup_en AS GL INNER JOIN Geoplaces AS GP on country=recordLocator \
    INNER JOIN Geoplacenames AS GPN ON GP.primaryKey=place \
    WHERE city=0 and county=0 and state=0 \
      and GPN.language=? and searchString=?", lookfor)
  data = cur.fetchall()  # 0, 1, or 2 records returned
  #print data   # if there's data, this will show numbers in the form [( , ),( , )]
  #print len(data)
  for row in data:   # assuming lat, lon are identical in the duplicate rows
    iPhoto_country_match = 1
    iPhoto_country_code = row[0]
    country_lat=row[1]
    country_lon=row[2]
    country_exists = 1
  if verbosity == "debug":
    print "country, nonabbrev_country_short_name, iPhoto_country_code, contry_lat, country_lon :", country, nonabbrev_country_short_name, iPhoto_country_code, country_lat, country_lon
if lang != 'en' and lang != None:
  '''
  # I've found a way to use iPhoto's database to translate country names from English to one of their 10 or so supported languages (note that not all names
  #   are translated into all the languages).  I'll need to compose the sqlstring before calling cur.execute() as you cannot
  #   use ? parameter substitution to compose tablenames.
  SELECT Geolookup_fr.searchString, country,description, recordLocator,
    Geoplaces.defaultname,type,subtype,latitude, longitude, version, parent,
    Geoplacenames.place,Geoplacenames.language,string 
  FROM Geolookup_fr INNER JOIN Geoplaces on country=recordLocator 
  INNER JOIN Geoplacenames ON Geoplaces.primaryKey=place WHERE city=0 and county=0 and state=0
  and Geoplacenames.language='en' and string='United States';
  
  Above returns:
  searchString	country	description	recordLocator	defaultName	type	subtype	latitude	longitude	version	parent	place	language	string	
  États-Unis	1061338	États-Unis	1061338			1			1		0		45.9126		-113.0991	1.08	0		1		en			United States	
  États-Unis	1061338	États-Unis	1061338			1			1		0		45.9126		-113.0991	1.08	0		1		en			United States	

  '''
  pass
  #sqlstring
  
if iPhoto_country_match == 1 and (verbosity == "2" or verbosity == "debug"):
  print "Successful search: Row for country found in iPhoto database"
elif iPhoto_country_match == 0 and lang=='en':
  print "No country whose English-language name is %s was found in iPhoto database.  Maybe we should check other languages or change the FORM for this place from the file's default FORM."
  
#####
#
# Check ADM1 (State level, in US terms)
#
#####
'''
placeList = currentPlaceText.split(',')
country = placeList[len(placeList)-1].strip()   # remove leading and trailing whitespace
lookfor = (country,)
'''
verbosity="debug"

if len(placeList)>1:
  ADM1_value = placeList[len(placeList)-2].strip()   # remove leading and trailing whitespace
else:
  print "Place hierarchy is only 1 level deep"
  #return # not correct syntax
  
print "Looking in Apple's iPhoto database for ADM1 is %s" % ADM1_value
lookfor = [lang,iPhoto_country_code,ADM1_value]

if verbosity == "debug" and lang == 'en' and nonabbrev_country_short_name is not None:
  # Following rowcount is 0, 1, or 2
  '''
  SELECT GL.searchString, state, country,description, recordLocator,
      GP.defaultname,type,subtype,latitude, longitude, version, parent,
      GPN.place,GPN.language,string
    FROM Geolookup_en AS GL INNER JOIN Geoplaces AS GP on state=recordLocator
    INNER JOIN Geoplacenames AS GPN ON GP.primaryKey=place
    WHERE city=0 and county=0
      and GPN.language='en' and country =1061338 and searchString='Massachusetts'
  '''
  cur.execute("SELECT GL.searchString, state, country,description, recordLocator, \
      GP.defaultname,type,subtype,latitude, longitude, version, parent, \
      GPN.place,GPN.language,string \
    FROM Geolookup_en AS GL INNER JOIN Geoplaces AS GP on state=recordLocator \
    INNER JOIN Geoplacenames AS GPN ON GP.primaryKey=place \
    WHERE city=0 and county=0 \
      and GPN.language=? and country =? and searchString=?", lookfor)
  print pp(cur, None, True)
  '''
  For searchString="Massachusetts":
  searchString	state	country	description						recordLocator	defaultName	type	subtype	latitude	longitude	version	parent	place	language	string	
  Massachusetts	545688	1061338	Massachusetts, United States	545688			476			2		0		42.1601		-71.504		1.07	1		26		en			Massachusetts	
  Massachusetts	545688	1061338	Massachusetts, United States	545688			476			2		0		42.1601		-71.504		1.07	1		26		en			Massachusetts	
  '''
  
if lang == 'en':
  cur.execute("SELECT state, latitude, longitude \
    FROM Geolookup_en AS GL INNER JOIN Geoplaces AS GP on state=recordLocator \
    INNER JOIN Geoplacenames AS GPN ON GP.primaryKey=place \
    WHERE city=0 and county=0 \
      and GPN.language=? and country =? and searchString=?", lookfor)
  data = cur.fetchall()  # 0, 1, or 2 records returned
  if len(data) == 0:
    iPhoto_state_match = 0
    iPhoto_state_code = None
    state_lat=None
    state_lon=None
    state_exists = 0
    # Apple's iPhoto'09 database (iPhoto version 8.1.2, db file dated Jul 31, 2009, db size 138.1MB), for example,
    #   has no entry for the Azores (iPhoto_country_code=1061122)
  #print data   # if there's data, this will show numbers in the form [( , ),( , )]
  #print len(data)
  for row in data:   # assuming lat, lon are identical in the duplicate rows
    iPhoto_state_match = 1
    iPhoto_state_code = row[0]
    state_lat=row[1]
    state_lon=row[2]
    state_exists = 1
  if verbosity == "debug":
    print "country, nonabbrev_country_short_name, iPhoto state id, state_lat, state_lon : ", country, nonabbrev_country_short_name, iPhoto_state_code, state_lat, state_lon

if lang != 'en' and lang != None:
  '''
  # Let's look at _fr table to see what happens.  I'll need to compose the sqlstring before calling cur.execute() as you cannot
  #   use ? parameter substitution to compose tablenames.
  SELECT Geolookup_fr.searchString, state, country,description, recordLocator,
    Geoplaces.defaultname,type,subtype,latitude, longitude, version, parent,
    Geoplacenames.place,Geoplacenames.language,string 
  FROM Geolookup_fr INNER JOIN Geoplaces on country=recordLocator 
  INNER JOIN Geoplacenames ON Geoplaces.primaryKey=place WHERE city=0 and county=0 and state=0
  and Geoplacenames.language='en' and country =1061338 and string='Massachusetts';
  
  Above returns:
  searchString	state	country	description					recordLocator	defaultName	type	subtype	latitude	longitude	version	parent	place	language	string	
  Massachusetts	545688	1061338	Massachusetts, États-Unis	545688			476			2		0		42.1601		-71.504		1.07	1		26		en			Massachusetts	
  Massachusetts	545688	1061338	Massachusetts, États-Unis	545688			476			2		0		42.1601		-71.504		1.07	1		26		en			Massachusetts	

  '''
  pass
  #sqlstring
  
  
if iPhoto_state_match == 1 and (verbosity == "2" or verbosity == "debug"):
  print "Successful search: Row for ADM1 (state) found in iPhoto database"
if iPhoto_state_match == 0: # for the Azores, for example
  print "Looking in GEDitCOM Extras database for exact match to ADM1 is %s" % ADM1_value
  conGED = sqlite.connect("/Applications/GEDitCOM Extras/GEDitCOM_Places.db")
  lookfor = [ADM1_value, ADM1_value]
  # fuzzy match would be: lookfor = [ADM1_value+'%', ADM1_value+'%']
  '''
  SELECT adm0_code, adm1_code, westernized_short_name, westernized_formal_name AS anglicized_expanded_name, geonameid
    FROM current_admin1_codes
    WHERE westernized_short_name = 'Azores' OR anglicized_expanded_name = 'Azores'
  '''
  sqlstring_min_exact = "  SELECT adm1_code, geonameid \
    FROM current_admin1_codes \
    WHERE westernized_short_name = ? OR westernized_formal_name = ?"
  sqlstring_verbose_exact = "  SELECT adm0_code, adm1_code, westernized_short_name, westernized_formal_name AS anglicized_expanded_name, geonameid \
    FROM current_admin1_codes \
    WHERE westernized_short_name = ? OR anglicized_expanded_name = ?"
  # print sqlstring_min_exact
  data = conGED.execute(sqlstring_min_exact, lookfor).fetchall()
  if verbosity=="2" or verbosity=="debug":
    curGEN = conGED.execute(sqlstring_verbose_exact, lookfor)
    print pp(curGEN, None, True)

  '''
  For searchString="Azores":
  adm0_code	adm1_code	westernized_short_name	anglicized_expanded_name	geonameid	
  PT		23			Azores					Regiao Autonoma dos Acores	3411865


  '''
  if len(data) == 0:
    Extras_state_match = 0
    Extras_state_code = None
    # The following were already set to None or 0 as result of search in iPhoto database
    # state_lat=None
    # state_lon=None
    # state_exists = 0
  for row in data:   # assuming lat, lon are identical in duplicate rows, if there are any (as there are for iPhoto countries and states)
    Extras_state_match = 1
    Extras_state_code = row[0]
    Extras_geonameid = row[1]
    '''
    Extras database does not include lat, lon for ADM1 as they are not supplied in admin1CodesASCII file.  We could find them in all_countries_hopper table in PostgreSQL.
    state_lat=row[n]
    state_lon=row[n+1]
    '''
    state_exists = 1
  
    
  if Extras_state_match == 1 and (verbosity == "2" or verbosity == "debug"):
    print "Successful search: Row for ADM1 (state) found in GEDitCOM Extras database"  
#####
#
# Check ADM2 (County level, in US terms).  This has to use GEDitCOM Extras as iPhoto database does
#   not contain county information.  
#
# If county is empty (as it often is in the US), then try to guess it from the combination of city and state.
#
# If the county part of PLAC has a value, then check it against county in GEDitCOM Extras
#
#####
'''
placeList = currentPlaceText.split(',')
country = placeList[len(placeList)-1].strip()   # remove leading and trailing whitespace
lookfor = (country,)
'''
verbosity="debug"

if len(placeList)>2:
  ADM2_value = placeList[len(placeList)-3].strip()   # remove leading and trailing whitespace
else:
  pass
  print "Need an action plan when AMD2 is an empty string.  Might also need to deal with a format that does not include ADM2."
  
print "Looking in GEDitCOM's Extras database for ADM2 is %s" % ADM2_value

if verbosity == "debug" and lang == 'en' and nonabbrev_country_short_name is not None:
  '''
  Try using Apple's database to find county information (hint: it's not very helpful):
  SELECT GL.searchString, county, state, country,description, recordLocator,
      GP.defaultname,type,subtype,latitude, longitude, version, parent,
      GPN.place,GPN.language,string
    FROM Geolookup_en AS GL INNER JOIN Geoplaces AS GP on county=recordLocator
    INNER JOIN Geoplacenames AS GPN ON GP.primaryKey=place
    WHERE city=0 and state = 545688
      and GPN.language='en' and country =1061338
  Above returns (note that no searchString was specified; 'Bristol' would return no rows):
  searchString		county	state	country	description										recordLocator	defaultName	type	subtype	latitude	longitude	version	parent	place	language	string	
  Martha's Vineyard	2039759	545688	1061338	Martha's Vineyard, Massachusetts, United States	2039759			603767		48		0		41.389		-70.6546	1.04	31794	31795	en			Martha's Vineyard	
  Martha's Vineyard	2039759	545688	1061338	Martha's Vineyard, Massachusetts, United States	2039759			603767		48		0		41.389		-70.6546	1.04	31794	31795	en			Martha's Vineyard	
  Nantucket Island	2039955	545688	1061338	Nantucket Island, Massachusetts, United States	2039955			798363		48		0		41.2829		-70.0773	1.03	42038	42039	en			Nantucket Island	
  Nantucket Island	2039955	545688	1061338	Nantucket Island, Massachusetts, United States	2039955			798363		48		0		41.2829		-70.0773	1.03	42038	42039	en			Nantucket Island	
  
  It turns out that the only two "county" values in Massachusetts are the two big islands.  A look at the rest of the
    country (USA) shows many islands have "city = 0 and county > 0".  So do a number of golf resorts and other tourist attractions.
  
  Let's look at table for ADM2 in Extras:
  SELECT geonameid, westernized_name_utf8, asciiname, alternatenames, latitude_wgs84, longitude_wgs84, iso_3166_1_country_code, admin1_code, admin2_code, population
    FROM Geonames_ADM2
    WHERE asciiname like 'Bristol%'
  Above returns:
  geonameid	westernized_name_utf8	asciiname			alternatenames						latitude_wgs84	longitude_wgs84	iso_3166_1_country_code	admin1_code	admin2_code	population	
  5858042	Bristol Bay Borough		Bristol Bay Borough	Arrondissement de Bristol Bay		58.750557		-156.83333		US						AK			060			1410	
  4931378	Bristol County			Bristol County		Comte de Bristol,Comté de Bristol	41.833435		-71.16616		US						MA			005			506325	
  5221078	Bristol County			Bristol County		Comte de Bristol,Comté de Bristol	41.71677		-71.27171		US						RI			001			48859	
  Note that the table uses codes (two-letter state codes in the case of the US) for admin1_code column.
  
  So, what's the right source for ADM1 codes?  According to "Marc" and Doug Cooper, writing authoritatively
    at http://forum.geonames.org/gforum/:
    "The file 'admin1Codes.txt' includes obsolete admin divisions [and, added Doug, 'historical spelling variations'].
    The file 'admin1CodesASCII.txt' has the current admin divisions only."
    
    -- The original version of the file had a combined admin1 code, e.g., AD.00 --  
    I replaced each such code by two tab-delimited columns having the two parts of
    the code using a regular expression: replace all ^([A-Z]-A-Z])\. with \1\t 
    
  # con = sqlite.connect("/Applications/GEDitCOM Extras/GEDitCOM_Places.db")
  Let's look at the current_admin1_codes table in GEDitCOM Extras I created on May 25, 2010:
  ATTACH DATABASE "/Applications/GEDitCOM Extras/GEDitCOM_Places.db" AS GEDitCOM_Extras
  or
  attach database "/Applications/iPhoto.app/Contents/Resources/PointOfInterest.db" AS iPhotoDB;
  SELECT adm0_code, adm1_code, westernized_short_name, westernized_formal_name AS anglicized_possibly_expanded_name, geonameid
    FROM current_admin1_codes
    WHERE westernized_short_name like 'Massachusetts%'
  Above returns only one row:
  adm0_code	adm1_code	westernized_short_name	anglicized_formal_name	geonameid	
  US		MA			Massachusetts			Massachusetts			6254926
  with westernized_short_name = 'Massachusetts', and it shows that the column 'westernized_formal_name' is not that formal --
    if it had been truly formal it would say 'Commonwealth of Massachusetts' rather than 'Massachusetts' (identical to westernized_short_name).
  '''
  
  # In order to use the Geonames_ADM2 table in GEDitCOM_Places.db, we'll need to get the alpha2 country code and the alphanumeric ADM1 code from the strings provided in PLAC.
  conGED = sqlite.connect("/Applications/GEDitCOM Extras/GEDitCOM_Places.db")
  if len(country)==2:       # assume that country is really the 2-letter code for the country
    alpha2_country_code = country
  elif len(country)==3:     # assume this is the 3-letter code
    lookfor=(country,)
    sqlstring = "SELECT alpha2_code FROM iso_3166_countries_en WHERE alpha3_code =?"
    result = conGED.execute(sqlstring,lookfor).fetchall()
    for row in result:  # returns one row at most
      alpha2_country_code = row[0]
  else:
    if lang=='en':
      lookfor = (country,)
      sqlstring = "SELECT alpha2_code FROM iso_3166_countries_en WHERE en_short_name = ?"
      result = conGED.execute(sqlstring,lookfor).fetchall()
      for row in result:  # returns one row at most
        alpha2_country_code = row[0]
    else:
      lookfor = [lang,lang]
      sqlstring = "SELECT alpha2_code FROM iso_3166_1_countries_%s WHERE...TODO: might do better to use geolookup_<lang> to get english equivalent to the value of <country>"

  print "alpha2_country_code is :", alpha2_country_code
  print "lookfor is :", lookfor
  
  # Now get the ADM1 code (state, in the US) from the ADM1 string, stored in ADM1_value.
  lookfor = [alpha2_country_code,ADM1_value,ADM1_value]
  sqlstring = "SELECT adm1_code FROM current_admin1_codes WHERE adm0_code = ? AND (westernized_short_name = ? or westernized_formal_name = ?)"
  result = conGED.execute(sqlstring,lookfor).fetchall()
  for row in result:  # returns one row at most
    ADM1_code = row[0]
  print "ADM1_code is :", ADM1_code
  if len(result)>0:
    Extras_state_match = 1

  lookfor = [alpha2_country_code, ADM1_code, ADM2_value+'%', ADM2_value+'%']
  if verbosity == "debug":
    print "lookfor is :",lookfor
  '''
  SELECT geonameid, westernized_name_utf8, asciiname, alternatenames, latitude_wgs84, longitude_wgs84, iso_3166_1_country_code, admin1_code, admin2_code, population
    FROM Geonames_ADM2
    WHERE iso_3166_1_country_code = 'US' and admin1_code = 'MA' and (asciiname like 'Bristol%' or westernized_name_utf8 like 'Bristol%')
  
  There's some problem with alternatenames column and its non-ascii characters:
  sqlstring = "  SELECT geonameid, westernized_name_utf8, asciiname, alternatenames, latitude_wgs84, longitude_wgs84, iso_3166_1_country_code, admin1_code, admin2_code, population \
  File "/Users/kevingartner/Library/Application Support/GEDitCOMII/Scripts/python/Test_FORM.py", line 137, in pp
    u=row[col].decode('utf-8')   # needed for queries against GeoLookup_fr, for example
  File "/System/Library/Frameworks/Python.framework/Versions/2.6/lib/python2.6/encodings/utf_8.py", line 16, in decode
    return codecs.utf_8_decode(input, errors, True)
  UnicodeEncodeError: 'ascii' codec can't encode character u'\xe9' in position 21: ordinal not in range(128)
  '''
  '''More TODOs:
  - admin2_code currently (May 28 2010) in Geonames_ADM2 is same as geonameid, at least for Portugal.  Is this proper transformation of geonames info?  Should I add/replace column with FIPS or other code?
  - no rows exist in Geonames_ADM2 for Azore islands (admin1_code='23'); should I add them and what's the general procedure so that it gets easier to do it?
  - note that admin1_code is '23' in geonames.org, but ISO 3166-2 lists the code for 'Região Autónoma dos Açores' as 'PT-20' (at least according to wikipedia.org); this points out the value of being informative rather than rigidly enforcing the file's default FORM or a GEDitCOM policy decision
  '''
  sqlstring_verbose = "  SELECT geonameid, westernized_name_utf8, asciiname, latitude_wgs84, longitude_wgs84, iso_3166_1_country_code, admin1_code, admin2_code, population \
    FROM Geonames_ADM2 \
    WHERE iso_3166_1_country_code = ? and admin1_code = ? and (asciiname like ? or westernized_name_utf8 like ?)"
  sqlstring_min = "  SELECT westernized_name_utf8, asciiname, latitude_wgs84, longitude_wgs84, iso_3166_1_country_code, admin1_code, admin2_code \
    FROM Geonames_ADM2 \
    WHERE iso_3166_1_country_code = ? and admin1_code = ? and (asciiname like ? or westernized_name_utf8 like ?)"
  # print sqlstring_min
  data = conGED.execute(sqlstring_min, lookfor).fetchall()
  if verbosity=="2" or verbosity=="debug":
    curGEN = conGED.execute(sqlstring_verbose, lookfor)
    print pp(curGEN, None, True)
  '''
  For asciiname like "Bristol%":
  geonameid    westernized_name_utf8 asciiname      latitude_wgs84 longitude_wgs84 iso_3166_1_country_code admin1_code  admin2_code  population  
  ------------ --------------------- -------------- -------------- --------------- ----------------------- ------------ ------------ ------------
  4931378      Bristol County        Bristol County 41.8334345     -71.1661579     US                      MA           005          506325      

  '''
  if len(data) == 0:
    geonames_county_match = 0
    geonames_county_code = None
    county_lat=None
    county_lon=None
    county_exists = 0
 
  for row in data:   # assuming lat, lon are identical in duplicate rows, if there are any (as there are for iPhoto countries and states)
    #TODO: think about different plan for fuzzy matches -- might need lists of codes, lat, lon to handle wildcard matches
    geonames_county_match = 1
    print "adm2_westernized_name_utf8 should be : ", row[0].decode('utf-8')
    county_exists = 1  # TODO: think about county_exists versus county_fuzzy_match_exists
    geonames_county_code = row[6]
    county_lat=row[2]
    county_lon=row[3]
    if verbosity == "debug":
      print "country, nonabbrev_country_short_name, ADM2_value, geonames county id, county_lat, county_lon : ", country, nonabbrev_country_short_name, ADM2_value, geonames_county_code, county_lat, county_lon

  
if geonames_county_match == 1 and (verbosity == "2" or verbosity == "debug"):
  print "Successful search: Row for ADM2 (county) = %s found in GEDitCOM Extras database" %ADM2_value
elif geonames_county_match != 1:
  print "No entry found for ADM2 = %s in GEDitCOM Extras database" %ADM2_value
  
#####
#
# Check ADM3 (City level, in US terms).  We'll start with a look in the iPhoto database.
#   not contain county information.  
#
#####
'''
placeList = currentPlaceText.split(',')
country = placeList[len(placeList)-1].strip()   # remove leading and trailing whitespace
lookfor = [lang,iPhoto_country_code,ADM1_value]
'''
verbosity="debug"

if len(placeList)>3:
  ADM3_value = placeList[len(placeList)-4].strip()   # remove leading and trailing whitespace
else:
  pass
  print "Need an action plan when AMD3 is an empty string but the format includes ADM3."
  
print "Looking in iPhoto database for ADM3 is %s" % ADM3_value

if verbosity == "debug" and lang == 'en' and nonabbrev_country_short_name is not None:
  '''
  Try using Apple's database to find city information:
  SELECT GL.searchString, city, county, state, country,description, recordLocator,
      GP.defaultname,type,subtype,latitude, longitude, version, parent,
      GPN.place,GPN.language,string
    FROM Geolookup_en AS GL INNER JOIN Geoplaces AS GP on city=recordLocator
    INNER JOIN Geoplacenames AS GPN ON GP.primaryKey=place
    WHERE city!=0 and state = 545688
      and GPN.language='en' and country =1061338 and searchString='New Bedford'
  Above returns (searchString ='New Bedford'):
  searchString	city	county	state	country	description						recordLocator	defaultName	type	subtype	latitude	longitude	version	parent	place	language	string	
  New Bedford	2029343	546941	545688	1061338	Massachusetts, United States	2029343			922077		16		0		41.6362		-70.9342	1.07	33367	48552	en			New Bedford	
  New Bedford	2029343	546941	545688	1061338	Massachusetts, United States	2029343			922077		16		0		41.6362		-70.9342	1.07	33367	48552	en			New Bedford	
  '''
  lookfor = [lang,iPhoto_country_code,iPhoto_state_code,ADM3_value]
  cur.execute("SELECT GL.searchString, city, state, country,description, recordLocator, \
      GP.defaultname,type,subtype,latitude, longitude, version, parent, \
      GPN.place,GPN.language,string \
    FROM Geolookup_en AS GL INNER JOIN Geoplaces AS GP on city=recordLocator \
    INNER JOIN Geoplacenames AS GPN ON GP.primaryKey=place \
    WHERE city!=0 \
      and GPN.language=? and country =? and state = ? and searchString=?", lookfor)
  print pp(cur, None, True)
  
if lang == 'en':
  cur.execute("SELECT city, latitude, longitude \
    FROM Geolookup_en AS GL INNER JOIN Geoplaces AS GP on city=recordLocator \
    INNER JOIN Geoplacenames AS GPN ON GP.primaryKey=place \
    WHERE city!=0 \
      and GPN.language=? and country =? and state = ? and searchString=?", lookfor)
  data = cur.fetchall()  # 0, 1, or 2 records returned
  if len(data) == 0:
    iPhoto_city_match = 0
    iPhoto_city_code = None
    city_lat=None
    city_lon=None
    city_exists = 0
  #print data   # if there's data, this will show numbers in the form [( , ),( , )]
  #print len(data)
  for row in data:   # assuming lat, lon are identical in the duplicate rows
    iPhoto_city_match = 1
    iPhoto_city_code = row[0]
    city_lat=row[1]
    city_lon=row[2]
    city_exists = 1
  if verbosity == "debug":
    print "country, nonabbrev_country_short_name, iPhoto state id, iPhoto city id, state_lat, state_lon : ", country, nonabbrev_country_short_name, iPhoto_state_code, iPhoto_city_code, city_lat, city_lon

if iPhoto_city_match == 1 and (verbosity == "2" or verbosity == "debug"):
  print "Successful search: Row for ADM3 (city) = %s found in iPhoto database" %ADM3_value
elif iPhoto_city_match != 1:
  print "No entry found for ADM3 = %s in iPhoto database" %ADM3_value
  
#####
#
# Now use preferences to set lat, lon and enter Notes
#
#####
placeGpsSpec = None
if len(details) > 0:
  initialPlaceGpsSpec = details[2].structures().objectWithName_("_GPS")  #_GPS record for PLAC may not exist, but the specifier will still exist and remain unevaluated until needed
  placeGpsSpec = initialPlaceGpsSpec
  if verbosity == "debug":
    print 'len(details) is %s' %len(details)
    print 'details is: %s ' % details
    print 'placeGpsSpec is: ', placeFormatSpec
  initialPlaceGpsText = initialPlaceGpsSpec.contents()
  print 'Current _GPS contents for this PLAC are: ', initialPlaceGpsText
# Suggest new lat - lon, after deciding what's the most accurate lat - lon you've found
newGps = str(city_lat)+", "+str(city_lon)   #TODO: add logic to assign the best lat, lon
if len(details)>2 :  #TODO: consider updating existing _GPS only if value there is outside bounding box for the smallest recognized PLAC level
    gdoc.beginUndo()

    if initialPlaceGpsText is None:
      print "No _GPS record exists"
      p={"name":"_GPS"}
      createGps=gedit.classForScriptingClass_("structure").alloc().initWithProperties_(p)
      details[2].structures().insertObject_atIndex_(createGps, 0)
      
      print "Creating _GPS value"
      initialPlaceGpsSpec.setContents_(newGps)
      if verbosity == "debug":
        print 'len(details): ',len(details)
        print '_GPS contents: ',newGps

    gdoc.endUndoAction_("Create _GPS Record")

else :
   pass
    
if placeGpsSpec is None:
  print "_GPS value not changed"
elif initialPlaceGpsText == newGps: #might relax this by stripping out whitespace around commas
  print "No change in _GPS, as it is identical to what's already there"
else:
  print "_GPS value changed to %s" % newGps  #TODO: reconcile with bug noted above