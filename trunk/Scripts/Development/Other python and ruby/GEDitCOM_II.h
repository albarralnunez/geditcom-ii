/*
 * GEDitCOM_II.h
 */

#import <AppKit/AppKit.h>
#import <ScriptingBridge/ScriptingBridge.h>


@class GEDitCOM_IIItem, GEDitCOM_IIApplication, GEDitCOM_IIColor, GEDitCOM_IIDocument, GEDitCOM_IIWindow, GEDitCOM_IIAttributeRun, GEDitCOM_IICharacter, GEDitCOM_IIParagraph, GEDitCOM_IIText, GEDitCOM_IIAttachment, GEDitCOM_IIWord, GEDitCOM_IIAlbum, GEDitCOM_IIGedcomRecord, GEDitCOM_IIBookStyle, GEDitCOM_IIFamily, GEDitCOM_IIHeader, GEDitCOM_IIIndividual, GEDitCOM_IIMultimedia, GEDitCOM_IINote, GEDitCOM_IIPlace, GEDitCOM_IIReport, GEDitCOM_IIRepository, GEDitCOM_IIResearchLog, GEDitCOM_IISource, GEDitCOM_IIStructure, GEDitCOM_IISubmission, GEDitCOM_IISubmitter, GEDitCOM_IIPrintSettings;

enum GEDitCOM_IISavo {
	GEDitCOM_IISavoAsk = 'ask ' /* Ask the user whether or not to save the file. */,
	GEDitCOM_IISavoNo = 'no  ' /* Do not save the file. */,
	GEDitCOM_IISavoYes = 'yes ' /* Save the file. */
};
typedef enum GEDitCOM_IISavo GEDitCOM_IISavo;

enum GEDitCOM_IIESrt {
	GEDitCOM_IIESrtTheChildren = 'skCH' /* The children linked to a family record */,
	GEDitCOM_IIESrtTheEvents = 'skEV' /* All events, attributes, residences, and ordinances in an individual or a family record */,
	GEDitCOM_IIESrtTheMultimedia = 'skMM' /* All multimedia objects at level 1 in an individual or a family record */,
	GEDitCOM_IIESrtTheSpouses = 'skSP' /* All spouses linked to an individual record */
};
typedef enum GEDitCOM_IIESrt GEDitCOM_IIESrt;

enum GEDitCOM_IITSty {
	GEDitCOM_IITStyChart = 'trCH' /* Family tree chart */,
	GEDitCOM_IITStyOutline = 'trOU' /* Family tree outline */
};
typedef enum GEDitCOM_IITSty GEDitCOM_IITSty;

enum GEDitCOM_IIXOpt {
	GEDitCOM_IIXOptBooks_Include = 'xOpG' /* Include book style records in the exported file */,
	GEDitCOM_IIXOptBooks_Omit = 'xOpH' /* Omit book style records from the exported file */,
	GEDitCOM_IIXOptChar_ANSEL = 'xOp2' /* Export using ANSEL charater set */,
	GEDitCOM_IIXOptChar_MacOS = 'xOp1' /* Export using MacOS Roman character set */,
	GEDitCOM_IIXOptChar_UTF16 = 'xOp4' /* Export using UTF16 character set */,
	GEDitCOM_IIXOptChar_UTF8 = 'xOp3' /* Export using UTF8 character set */,
	GEDitCOM_IIXOptChar_Windows = 'xOp5' /* Export using Windows Latin 1 character set */,
	GEDitCOM_IIXOptLines_CR = 'xOp7' /* Export using carriage return line endings */,
	GEDitCOM_IIXOptLines_CRLF = 'xOp8' /* Export using carriage return and line feed line endings */,
	GEDitCOM_IIXOptLines_LF = 'xOp6' /* Export with line feed line endings */,
	GEDitCOM_IIXOptLogs_Include = 'xOpC' /* Include research log records in the exported file */,
	GEDitCOM_IIXOptLogs_Omit = 'xOpD' /* Omit research log records from the exported file */,
	GEDitCOM_IIXOptMm_Embed = 'xOpA' /* Export with embedding multimedia object links (GEDCOM style) */,
	GEDitCOM_IIXOptMm_GEDitCOM = 'xOp9' /* Export multimedia using GEDitCOM II style multimedia records */,
	GEDitCOM_IIXOptMm_PhpGedView = 'xOpB' /* Export multimedia using PhpGedView style multimedia records */,
	GEDitCOM_IIXOptPlaces_Include = 'xOpE' /* Include place records in the exported file */,
	GEDitCOM_IIXOptPlaces_Omit = 'xOpF' /* Omit place records from the exported file */,
	GEDitCOM_IIXOptSettings_Embed = 'xOpI' /* Embed GEDitCOM II settings as BinHex data in the exported file's header record */,
	GEDitCOM_IIXOptSettings_Omit = 'xOpJ' /* Do not embed GEDitCOM settings in the exported file */,
	GEDitCOM_IIXOptThumbnails_Embed = 'xOpK' /* Embed thumbnails a BinHex data in multimedia records of the exported file */,
	GEDitCOM_IIXOptThumbnails_Omit = 'xOpL' /* Do not embed thumbnails in the exported file */
};
typedef enum GEDitCOM_IIXOpt GEDitCOM_IIXOpt;

enum GEDitCOM_IIREsn {
	GEDitCOM_IIREsnLocked = 'rLck' /* The records is locked and cannot be changed */,
	GEDitCOM_IIREsnPrivacy = 'rPrv' /* The record should not be exported to protect privacy of individuals */,
	GEDitCOM_IIREsnUnlocked = 'rUnl' /* The records is unlocked and can be edited and exported */
};
typedef enum GEDitCOM_IIREsn GEDitCOM_IIREsn;

enum GEDitCOM_IIEnum {
	GEDitCOM_IIEnumStandard = 'lwst' /* Standard PostScript error handling */,
	GEDitCOM_IIEnumDetailed = 'lwdt' /* print a detailed report of PostScript errors */
};
typedef enum GEDitCOM_IIEnum GEDitCOM_IIEnum;



/*
 * Standard Suite
 */

// A scriptable object.
@interface GEDitCOM_IIItem : SBObject

@property (copy) NSDictionary *properties;  // All of the object's properties.

- (void) closeSaving:(GEDitCOM_IISavo)saving savingIn:(NSURL *)savingIn;  // Close an object.
- (void) delete;  // Delete an object.
- (void) duplicateTo:(SBObject *)to withProperties:(NSDictionary *)withProperties;  // Copy object(s) and put the copies at a new location.
- (BOOL) exists;  // Verify if an object exists.
- (void) moveTo:(SBObject *)to;  // Move object(s) to a new location.
- (void) saveAs:(NSString *)as in:(NSURL *)in_;  // Save an object.
- (void) beginUndo;  // Begin undo grouping (the matching 'end undo' must 'tell' to the same document and no user interaction should be between begin and end undo)
- (NSArray *) bulkReaderSelector:(NSArray *)selector target:(NSArray *)target argument:(NSArray *)argument;  // Return result of applying a selector to every object in the target list (since 1.6)
- (BOOL) canLinkRecordType:(NSString *)recordType;  // Returns true or false if a record can link to another type of record (since 1.6)
- (void) consolidateMultimediaToFolder:(NSString *)toFolder changeLinks:(BOOL)changeLinks preservePaths:(BOOL)preservePaths;  // Consolidate the multimedia in a new folder (since 1.3)
- (void) copyFileDestination:(NSString *)destination;  // Copy multimedia object file to the provided path (since 1.1)
- (NSString *) dateFormatFullDate:(NSString *)fullDate;  // Convert a GEDCOM date into the date style current selected in the GEDitCOM II preferences (since 1.1)
- (NSArray *) dateNumbersFullDate:(NSString *)fullDate;  // Returns day, month, and year numbers for Gregorian calendar in list (3 for 1 date or 6 for date range) (since 1.6.2)
- (NSArray *) datePartsFullDate:(NSString *)fullDate;  // Splits date into five parts {prefix, date1, conjunction, date2, comment} or if bad date return {error message}
- (NSString *) dateStyleFullDate:(NSString *)fullDate withFormat:(NSString *)withFormat;  // Reformat a custom date into specified style (since 1.6.2)
- (NSString *) dateTextSdn:(NSInteger)sdn withFormat:(NSString *)withFormat;  // Covert a serial day number to a Gregorian date (since 1.1)
- (NSString *) dateToday;  // Today's date as a string (since 1.1)
- (NSString *) dateYearFullDate:(NSString *)fullDate;  // Returns year for a date, including year range or c, <, or > if needed (since 1.6.2)
- (id) objectDescriptionOutputOptions:(NSArray *)outputOptions;  // Description of a record with many options (since 1.3)
- (void) detachChild:(GEDitCOM_IIIndividual *)child spouse:(NSString *)spouse;  // Detach data from a GEDCOM record
- (void) displayByName:(NSString *)byName byType:(NSString *)byType sorting:(NSString *)sorting;  // Display list of selected records in the index window and optionally sort the list (since 1.1)
- (void) endUndoAction:(NSString *)action;  // End undo grouping and set text for Undo menu item
- (NSString *) evaluateExpression:(NSString *)expression;  // Evaluate a GEDCOM expression for a gedcomRecord or structure
- (void) exportGedcomFilePath:(NSString *)filePath withOptions:(NSArray *)withOptions;  // Tell album or document to export their records to a stand-alone GEDCOM file (since 1.3)
- (NSArray *) findStructuresTag:(NSString *)tag output:(NSString *)output value:(NSString *)value;  // Find subordinate structures by name and optionally by contents
- (NSString *) formatNameValue:(NSString *)nameValue case:(NSString *)case_;  // Reformat name string into a GEDCOM name
- (NSString *) localStringForKey:(id)forKey;  // Convert input string to localized string using current language selected in the current interface format (since 1.5.2)
- (void) mergeWithRecord:(GEDitCOM_IIGedcomRecord *)withRecord force:(BOOL)force;  // Merge the target record with a compatible record of the same type (since 1.3)
- (NSArray *) namePartsGedcomName:(NSString *)gedcomName;  // Splits name with GEDCOM slashes into {prename, surname, postname} in a list.
- (void) notifyProgressFraction:(double)fraction message:(NSString *)message;  // Tell GEDitCOM II the fraction of the script that has been completed and/or post a message (since 1.1)
- (void) populateAlbum:(GEDitCOM_IIAlbum *)album;  // Populate new or existing album with records from the front window (since 1.3)
- (void) refreshFormats;  // Refresh for interface formats menu (since 1.7)
- (void) refreshScripts;  // Refresh the scripts menu (since 1.6)
- (void) runScriptAtPath:(NSString *)atPath;  // Run the script at the provided path (since 1.6)
- (NSString *) safeHtmlRawText:(NSString *)rawText insertPs:(NSString *)insertPs reformatLinks:(NSDictionary *)reformatLinks;  // Convert special HTML characters (&, ", <, and >) to HTML entities, unless raw text is a <div> element, and then reformat or remove internal links (since 1.1)
- (NSArray *) sdnRangeFullDate:(NSString *)fullDate;  // {Minimum, Maximum} serial day numbers for a date (or {0,0} if a date error) (since 1.1)
- (void) showAncestorsGenerations:(NSInteger)generations treeStyle:(GEDitCOM_IITSty)treeStyle;  // Show ancestors of the target individual record (since 1.3)
- (void) showBrowser;  // Open browser window for a GEDCOM record
- (void) showBrowserpaneWithId:(NSString *)withId;  // Open browser window for a GEDCOM record using a specific pane ID
- (void) showDescendantsGenerations:(NSInteger)generations treeStyle:(GEDitCOM_IITSty)treeStyle;  // Show descendants of the target individual record (since 1.3)
- (void) sortData:(GEDitCOM_IIESrt)data;  // Sort data in the record by relevant dates (since 1.3)
- (NSString *) soundexForText:(NSString *)forText;  // Return Soundex code for the supplied text (since 1.6.2)
- (NSArray *) userChoiceListItems:(NSArray *)listItems prompt:(NSString *)prompt buttons:(NSArray *)buttons multiple:(BOOL)multiple title:(NSString *)title;  // Display modal panel for user to select one or more items from a list. Returns list with {button clicked,{items' text},{items' numbers}} (since 1.5)
- (NSArray *) userInputPrompt:(NSString *)prompt buttons:(NSArray *)buttons initialText:(NSString *)initialText title:(NSString *)title;  // Display modal panel for user to enter a line of text. Returns list with {button clicked,text entered} (since 1.5)
- (NSString *) userOpenFileExtensions:(NSArray *)extensions prompt:(NSString *)prompt start:(NSString *)start title:(NSString *)title;  // Display modal panel for user to select any existing file and returns POSIX path (or empty if canceled) (since 1.5)
- (NSString *) userOpenFolderPrompt:(NSString *)prompt start:(NSString *)start title:(NSString *)title;  // Display modal panel for user to select any existing folder and returns POSIX path (or empty if canceled) (since 1.5)
- (NSString *) userOptionTitle:(NSString *)title buttons:(NSArray *)buttons message:(NSString *)message;  // Display modal dialog and let user select among 1 to 3 buttons and returns text of clicked button (since 1.5)
- (NSString *) userSaveFileExtensions:(NSArray *)extensions prompt:(NSString *)prompt start:(NSString *)start title:(NSString *)title;  // Display modal panel for user to select a file location for saving a file and returns POSIX path (or empty if canceled) (since 1.5)
- (void) userSelectByType:(NSString *)byType fromList:(NSString *)fromList prompt:(NSString *)prompt;  // Start panel for user to select a record from a document (since 1.6.2)

@end

// An application's top level scripting object.
@interface GEDitCOM_IIApplication : SBApplication
+ (GEDitCOM_IIApplication *) application;

- (SBElementArray *) documents;
- (SBElementArray *) windows;

@property (readonly) BOOL frontmost;  // Is this the frontmost (active) application?
@property (copy, readonly) NSString *name;  // The name of the application.
@property (copy, readonly) NSString *version;  // The version of the application.

- (GEDitCOM_IIDocument *) open:(NSURL *)x;  // Open an object.
- (void) print:(NSURL *)x printDialog:(BOOL)printDialog withProperties:(GEDitCOM_IIPrintSettings *)withProperties;  // Print an object.
- (void) quitSaving:(GEDitCOM_IISavo)saving;  // Quit an application.

@end

// A color.
@interface GEDitCOM_IIColor : GEDitCOM_IIItem


@end

// A document.
@interface GEDitCOM_IIDocument : GEDitCOM_IIItem

@property (readonly) BOOL modified;  // Has the document been modified since the last save?
@property (copy) NSString *name;  // The document's name.
@property (copy) NSString *path;  // The document's path.


@end

// A window.
@interface GEDitCOM_IIWindow : GEDitCOM_IIItem

@property NSRect bounds;  // The bounding rectangle of the window.
@property (readonly) BOOL closeable;  // Whether the window has a close box.
@property (copy, readonly) GEDitCOM_IIDocument *document;  // The document whose contents are being displayed in the window.
@property (readonly) BOOL floating;  // Whether the window floats.
- (NSInteger) id;  // The unique identifier of the window.
@property NSInteger index;  // The index of the window, ordered front to back.
@property (readonly) BOOL miniaturizable;  // Whether the window can be miniaturized.
@property BOOL miniaturized;  // Whether the window is currently miniaturized.
@property (readonly) BOOL modal;  // Whether the window is the application's current modal window.
@property (copy) NSString *name;  // The full title of the window.
@property (readonly) BOOL resizable;  // Whether the window can be resized.
@property (readonly) BOOL titled;  // Whether the window has a title bar.
@property BOOL visible;  // Whether the window is currently visible.
@property (readonly) BOOL zoomable;  // Whether the window can be zoomed.
@property BOOL zoomed;  // Whether the window is currently zoomed.


@end



/*
 * Text Suite
 */

// This subdivides the text into chunks that all have the same attributes.
@interface GEDitCOM_IIAttributeRun : GEDitCOM_IIItem

- (SBElementArray *) attachments;
- (SBElementArray *) attributeRuns;
- (SBElementArray *) characters;
- (SBElementArray *) paragraphs;
- (SBElementArray *) words;

@property (copy) NSColor *color;  // The color of the first character.
@property (copy) NSString *font;  // The name of the font of the first character.
@property NSInteger size;  // The size in points of the first character.


@end

// This subdivides the text into characters.
@interface GEDitCOM_IICharacter : GEDitCOM_IIItem

- (SBElementArray *) attachments;
- (SBElementArray *) attributeRuns;
- (SBElementArray *) characters;
- (SBElementArray *) paragraphs;
- (SBElementArray *) words;

@property (copy) NSColor *color;  // The color of the first character.
@property (copy) NSString *font;  // The name of the font of the first character.
@property NSInteger size;  // The size in points of the first character.


@end

// This subdivides the text into paragraphs.
@interface GEDitCOM_IIParagraph : GEDitCOM_IIItem

- (SBElementArray *) attachments;
- (SBElementArray *) attributeRuns;
- (SBElementArray *) characters;
- (SBElementArray *) paragraphs;
- (SBElementArray *) words;

@property (copy) NSColor *color;  // The color of the first character.
@property (copy) NSString *font;  // The name of the font of the first character.
@property NSInteger size;  // The size in points of the first character.


@end

// Rich (styled) text
@interface GEDitCOM_IIText : GEDitCOM_IIItem

- (SBElementArray *) attachments;
- (SBElementArray *) attributeRuns;
- (SBElementArray *) characters;
- (SBElementArray *) paragraphs;
- (SBElementArray *) words;

@property (copy) NSColor *color;  // The color of the first character.
@property (copy) NSString *font;  // The name of the font of the first character.
@property NSInteger size;  // The size in points of the first character.


@end

// Represents an inline text attachment.  This class is used mainly for make commands.
@interface GEDitCOM_IIAttachment : GEDitCOM_IIText

@property (copy) NSString *fileName;  // The path to the file for the attachment


@end

// This subdivides the text into words.
@interface GEDitCOM_IIWord : GEDitCOM_IIItem

- (SBElementArray *) attachments;
- (SBElementArray *) attributeRuns;
- (SBElementArray *) characters;
- (SBElementArray *) paragraphs;
- (SBElementArray *) words;

@property (copy) NSColor *color;  // The color of the first character.
@property (copy) NSString *font;  // The name of the font of the first character.
@property NSInteger size;  // The size in points of the first character.


@end



/*
 * GEDitCOM II suite
 */

// Album of records
@interface GEDitCOM_IIAlbum : GEDitCOM_IIItem

- (SBElementArray *) gedcomRecords;

- (NSString *) id;  // Album unique ID
@property (copy) NSString *name;  // Album name
@property (copy, readonly) NSArray *records;  // List of gedcomRecords in the album (deprecated, use 'every gedcomRecord' instead)


@end

// GEDitCOM II application
@interface GEDitCOM_IIApplication (GEDitCOMIISuite)

@property (readonly) NSInteger betaNumber;  // The current beta number for GEDitCOM II or 0 if an official release (since 1.1)
@property (readonly) NSInteger buildNumber;  // The current build number for the current version (since 1.6)
@property (copy) NSString *currentFormat;  // The full path to the current interface format (without the '.gfrmt' and may start with '$SYSTEM/' or '$USER/' for format is system or user library) (since 1.5)
@property (copy, readonly) NSString *formatLanguage;  // The current user-selected language for the interface format (since 1.2)
@property BOOL messageVisible;  // The current visibility of the panel that appears while running scripts (since 1.5, build 2)
@property (copy) NSString *scriptMessage;  // A message set by a script run from within a user interface format (since 1.5, build 2)
@property (readonly) double versionNumber;  // The current version number of GEDitCOM II (since 1.1)

@end

// GEDitCOM II document
@interface GEDitCOM_IIDocument (GEDitCOMIISuite)

- (SBElementArray *) albums;
- (SBElementArray *) bookStyles;
- (SBElementArray *) families;
- (SBElementArray *) gedcomRecords;
- (SBElementArray *) headers;
- (SBElementArray *) individuals;
- (SBElementArray *) multimedia;
- (SBElementArray *) notes;
- (SBElementArray *) places;
- (SBElementArray *) reports;
- (SBElementArray *) repositories;
- (SBElementArray *) researchLogs;
- (SBElementArray *) sources;
- (SBElementArray *) submissions;
- (SBElementArray *) submitters;

@property (copy, readonly) NSArray *editingDetails;  // Return {level, tag, structure} of current data being editing in a browser. Omits structure if new data and returns {} if nothing is being edited (since 1.3)
@property (copy) NSString *homeRecord;  // Home record ID
@property (copy, readonly) GEDitCOM_IIGedcomRecord *keyRecord;  // The key record for the front window - meaning depends on window type with most common use being the root record in a family tree (since 1.3)
@property (copy, readonly) NSArray *listedRecords;  // List of references to all records in the front most window of the document. The type of list depends on the type of window - see GEDitCOM II help for details (since 1.3).
@property (copy) NSString *mainSubmitter;  // Main submitter record ID
@property (copy, readonly) GEDitCOM_IIGedcomRecord *pickedRecord;  // The most recently picked record or "" is still picking or "Cancel" is selection was canceled (since 1.6.2)
@property (readonly) BOOL printing;  // True or false if printing in progress (since 1.5)
@property (copy, readonly) NSArray *selectedRecords;  // List of references to selected records in the front most window of the document
@property (copy) NSString *selectedText;  // Selected text in the front browser window (since 1.3)
@property (copy) NSArray *selectionRange;  // Range of selected text {a,b} (1 based)  from before character a to after character b (use b=-1 to select to the end) in the front browser window (since 1.3)
@property (copy, readonly) NSString *windowType;  // The type of the front most window for this document (since 1.3)

@end

// GEDCOM record
@interface GEDitCOM_IIGedcomRecord : GEDitCOM_IIItem

- (SBElementArray *) structures;

@property (copy, readonly) NSString *alternateName;  // Alternate GEDCOM record name, but may be same as name
@property (copy, readonly) NSArray *citations;  // Record IDs of all sources this record cites in level 1
@property (copy) id contextInfo;  // Store any object during a script, must clear before using (since 1.3)
@property (copy, readonly) NSString *firstLine;  // First line of the GEDCOM data for the record
@property (copy) NSString *gcid;  // Alternate GEDCOM record ID for Ruby scripts  (can only set by using 'with properties' when making a new record, since 1.5)
@property (copy) NSString *gedcom;  // Raw GEDCOM data for the record
- (NSString *) id;  // GEDCOM record ID (can only set since 1.1 by using 'with properties' when making a new record)
- (void) setId: (NSString *) id;
@property (copy, readonly) NSArray *logs;  // Record IDs of all research logs linked to this record in level 1
@property (copy) NSString *name;  // Name of the record, which will depend on record type
@property (copy, readonly) NSArray *notations;  // Record IDs of all note records linked to this record in level 1
@property (copy, readonly) NSArray *objects;  // Record IDs of all multimedia objects linked to this record in level 1
@property (copy) NSString *recordType;  // GEDCOM record type (can only set since 1.5 by using 'with properties' when making a new custom record) 


@end

// Book style record
@interface GEDitCOM_IIBookStyle : GEDitCOM_IIGedcomRecord

@property (copy) NSString *authorEmail;
@property (copy) NSString *authorName;  // The author's name to appear in the book
@property (copy, readonly) NSDictionary *bookSettings;  // A dictionary of settings relevant to the book
@property (copy) NSString *name;  // A description of the book created by this record's settings
@property (copy) NSString *saveFolder;  // Full path to folder for saving the output files for the book


@end

// Family record
@interface GEDitCOM_IIFamily : GEDitCOM_IIGedcomRecord

@property (copy, readonly) NSArray *children;  // List of references to children's individual records
@property (readonly) BOOL connected;  // True if family is linked to two or more individuals (since 1.3)
@property (copy) GEDitCOM_IIIndividual *husband;  // Reference to husband's individual record (or "" if none)
@property (copy) NSArray *keywords;  // List of keywords
@property (copy) NSString *marriageDate;  // The marriage date (GEDCOM style) for the family (since 1.3)
@property (copy, readonly) NSString *marriageDateUser;  // The marriage date (user-preferred style) for the family (since 1.3)
@property (copy) NSString *marriagePlace;  // The marriage place for the family (since 1.3)
@property (readonly) NSInteger marriageSDN;  // Minimum marriage date as serial day number (0 if no date or invalid date) (since 1.3)
@property (readonly) NSInteger marriageSDNMax;  // Maximum marriage date as serial day number (0 if no date or invalid date) (since 1.3)
@property (copy, readonly) NSString *name;  // Husband's and wife's names (last, first)
@property (copy) GEDitCOM_IIIndividual *wife;  // Reference to wife's individual record (or "" if none)


@end

// Header record
@interface GEDitCOM_IIHeader : GEDitCOM_IIGedcomRecord

@property (copy) NSString *language;  // The preferred language for the data in this file (since 1.5)
@property (copy, readonly) NSString *name;  // The name of the header record is always "Header Record"
@property (copy) NSString *placeHierarchy;  // The default place hierarchy (e.g., "city, county, state, country") (since 1.5)


@end

// Individual record
@interface GEDitCOM_IIIndividual : GEDitCOM_IIGedcomRecord

@property (copy) NSString *birthDate;  // The birth date (GEDCOM style) for the individual (since 1.3)
@property (copy, readonly) NSString *birthDateUser;  // The birth date (user-preferred style) for the individual (since 1.3)
@property (copy) NSString *birthPlace;  // The birth place for the individual (since 1.3)
@property (readonly) NSInteger birthSDN;  // Minimum birth date as serial day number (0 if no date or invalid date) (since 1.3)
@property (readonly) NSInteger birthSDNMax;  // Maximum birth date as serial day number (0 if no date or invalid date) (since 1.3)
@property (copy, readonly) NSArray *children;  // List of references to children's records
@property (readonly) BOOL connected;  // True if individual is connected to at least one family record (since 1.3)
@property (copy) NSString *deathDate;  // The death date (GEDCOM style) for the individual (since 1.3)
@property (copy, readonly) NSString *deathDateUser;  // The death date (user-preferred style) for the individual (since 1.3)
@property (copy) NSString *deathPlace;  // The death place for the individual (since 1.3)
@property (readonly) NSInteger deathSDN;  // Minimum death date as serial day number (0 if no date or invalid date) (since 1.3)
@property (readonly) NSInteger deathSDNMax;  // Maximum death date as serial day number (0 if no date or invalid date) (since 1.3)
@property (copy, readonly) GEDitCOM_IIIndividual *father;  // Reference to father's record in first family as child record (or "" if none) (since 1.6.2)
@property (copy, readonly) NSString *firstName;  // The individual's first name (since 1.6)
@property (copy) NSArray *keywords;  // List of keywords
@property (copy, readonly) NSString *lifeSpan;  // Life span in years as "birth-death" if either are known or if known to be deceased (since 1.1)
@property (copy, readonly) NSString *middleName;  // The individual's middle name (since 1.6)
@property (copy, readonly) GEDitCOM_IIIndividual *mother;  // Reference to mother 'd record in the first family record as a child (or "" if none) (since 1.6.2)
@property (copy) NSString *name;  // Individual's name (last, first), but can set as "last, first" or "first last" and with or without slashes around the surname
@property (copy, readonly) NSArray *parentFamilies;  // List of references to parent's family records (since 1.1)
@property (copy, readonly) NSArray *parents;  // List of references to parent's records
@property GEDitCOM_IIREsn restriction;  // This individual is "unlocked," "locked," or a "privacy" record (since 1.3)
@property (copy) NSString *sex;  // Sex of an individual (M or F), but cannot set the sex if the individual is a spouse in a family record
@property (copy, readonly) NSArray *spouseFamilies;  // List of references to family records with spouses (since 1.1)
@property (copy, readonly) NSArray *spouses;  // List of references to spouse's records
@property (copy, readonly) NSString *surname;  // The individual's surname (since 1.6)
@property (copy, readonly) NSString *surnameSoundex;  // Soundex code for the individual's surname (since 1.6)


@end

// Multimedia object record
@interface GEDitCOM_IIMultimedia : GEDitCOM_IIGedcomRecord

@property (readonly) BOOL connected;  // True if multimedia object is linked to at least one record (since 1.3)
@property (copy) NSArray *keywords;  // List of keywords
@property (copy) NSString *name;  // Title of the multimedia object
@property (copy) NSString *objectDate;  // The recorded date (GEDCOM style) for the multimedia object (since 1.3)
@property (copy, readonly) NSString *objectDateUser;  // The recorded date (user-preferred style) for the multimedia object (since 1.3)
@property (copy) NSString *objectForm;  // The format for the multimedia object (if known) (since 1.5, built s)
@property (copy, readonly) NSString *objectPath;  // Full POSIX path (with /'s) to file for multimedia object or URL for web site. If a file and it is not found, returns empty string.
@property (copy) NSString *objectPlace;  // The recorded place for the mutimedia object (since 1.3)
@property (copy, readonly) NSArray *referencedBy;  // Record IDs of records that reference this multimedia object


@end

// Notes record
@interface GEDitCOM_IINote : GEDitCOM_IIGedcomRecord

@property (readonly) BOOL connected;  // True if notes are linked to at least one record (since 1.3)
@property (copy) NSArray *keywords;  // List of keywords
@property (copy, readonly) NSString *name;  // Name of the notes as first line of notes text or a designated name (if found)
@property (copy) NSString *notesText;  // Text of the notes in this record
@property (copy, readonly) NSArray *referencedBy;  // Record IDs of records that reference these notes


@end

// Place record (since 1.7)
@interface GEDitCOM_IIPlace : GEDitCOM_IIGedcomRecord

@property (readonly) BOOL connected;  // True if place is cited by at least one record
@property (copy) NSArray *keywords;  // List of keywords
@property (copy) NSString *name;  // The first place name in the place record
@property (copy, readonly) NSArray *referencedBy;  // Record IDs of individuals or families that reference this place record


@end

// Report record
@interface GEDitCOM_IIReport : GEDitCOM_IIGedcomRecord

@property (copy) NSString *body;  // The text body of the report
@property (copy) NSString *name;  // The title of the report


@end

// Repository record
@interface GEDitCOM_IIRepository : GEDitCOM_IIGedcomRecord

@property (readonly) BOOL connected;  // True if repository is linked to at least one source record (since 1.3)
@property (copy) NSArray *keywords;  // List of keywords
@property (copy) NSString *name;  // Name of the source repository


@end

// Research log record
@interface GEDitCOM_IIResearchLog : GEDitCOM_IIGedcomRecord

@property (readonly) BOOL connected;  // True if research log is linked to at least one record (since 1.3)
@property (copy) NSArray *keywords;  // List of keywords
@property (copy) NSString *name;  // The title of the research log
@property (copy, readonly) NSArray *referencedBy;  // Record IDs of records that reference this research log


@end

// Source record
@interface GEDitCOM_IISource : GEDitCOM_IIGedcomRecord

@property (readonly) BOOL connected;  // True if source is cited by at least one record (since 1.3)
@property (copy) NSArray *keywords;  // List of keywords
@property (copy) NSString *name;  // Will return abbreviated title (if found) otherwise the full title. When setting the name, it will set the abbreviated title.
@property (copy, readonly) NSArray *referencedBy;  // Records IDs of records that reference this source
@property (copy) NSString *sourceAuthors;  // Author(s) of the source
@property (copy) NSString *sourceDate;  // Publication date for a source
@property (copy) NSString *sourceDetails;  // Source details such as publisher, journal, magazine, comments, etc.
@property (copy) NSString *sourceTitle;  // Title of the source
@property (copy) NSString *sourceType;  // Type of source (book, article, web page, in book, unpublished, or general)
@property (copy) NSString *sourceUrl;  // URL of a web page source


@end

// GEDCOM structure
@interface GEDitCOM_IIStructure : GEDitCOM_IIItem

- (SBElementArray *) structures;

@property (copy, readonly) NSArray *citations;  // Record IDs of all sources cited at first subordinate level in this structure
@property (copy) NSString *contents;  // The line value of the first line of the structure
@property (copy) NSString *eventDate;  // Subordinate date (GEDCOM style) for this structure (since 1.1)
@property (copy, readonly) NSString *eventDateUser;  // Subordinate date (user-preferred style) for this structure (since 1.3)
@property (copy) NSString *eventPlace;  // Subordinate place for this structure (since 1.3)
@property (readonly) NSInteger eventSDN;  // Minimum subordinate date as serial day number (0 if no date or invalid date) (since 1.3)
@property (readonly) NSInteger eventSDNMax;  // Maximum subordinate date as serial day number (0 if no date or invalid date) (since 1.3)
@property (copy, readonly) NSString *firstLine;  // GEDCOM text for first line of the structure (level, tag, and line value)
@property (copy, readonly) NSString *gedcom;  // Raw GEDCOM data for the structure
@property (readonly) NSInteger level;  // Structure level number
@property (copy, readonly) NSArray *logs;  // Record IDs of all reseearh logs linked at first subordinate level to this structure
@property (copy) NSString *memo;  // A memo on this structure (since 1.6)
@property (copy) NSString *name;  // Structure's GEDCOM tag word in its first line
@property (copy, readonly) GEDitCOM_IIStructure *nextStructure;  // The next structure at this structure's level (since 1.6.2)
@property (copy, readonly) NSArray *notations;  // Record IDs of all notes linked at first subordinate level to this structure
@property (copy, readonly) NSArray *objects;  // Record IDs of all multimedia objects linked at first subordinate level to this structure
@property (copy, readonly) GEDitCOM_IIStructure *parentStructure;  // The parent structure of this structure (may be the record) (since 1.6.2)
@property (copy, readonly) GEDitCOM_IIStructure *prevStructure;  // The previous structure at this structure's level (since 1.6.2)


@end

// Submission record
@interface GEDitCOM_IISubmission : GEDitCOM_IIGedcomRecord

@property (copy, readonly) NSString *name;  // The name of the submission record is always "Submission Record"


@end

// Submitter record
@interface GEDitCOM_IISubmitter : GEDitCOM_IIGedcomRecord

@property (copy) NSString *name;  // The name of the submitter


@end



/*
 * Type Definitions
 */

@interface GEDitCOM_IIPrintSettings : SBObject

@property NSInteger copies;  // the number of copies of a document to be printed
@property BOOL collating;  // Should printed copies be collated?
@property NSInteger startingPage;  // the first page of the document to be printed
@property NSInteger endingPage;  // the last page of the document to be printed
@property NSInteger pagesAcross;  // number of logical pages laid across a physical page
@property NSInteger pagesDown;  // number of logical pages laid out down a physical page
@property (copy) NSDate *requestedPrintTime;  // the time at which the desktop printer should print the document
@property GEDitCOM_IIEnum errorHandling;  // how errors are handled
@property (copy) NSString *faxNumber;  // for fax number
@property (copy) NSString *targetPrinter;  // for target printer

- (void) closeSaving:(GEDitCOM_IISavo)saving savingIn:(NSURL *)savingIn;  // Close an object.
- (void) delete;  // Delete an object.
- (void) duplicateTo:(SBObject *)to withProperties:(NSDictionary *)withProperties;  // Copy object(s) and put the copies at a new location.
- (BOOL) exists;  // Verify if an object exists.
- (void) moveTo:(SBObject *)to;  // Move object(s) to a new location.
- (void) saveAs:(NSString *)as in:(NSURL *)in_;  // Save an object.
- (void) beginUndo;  // Begin undo grouping (the matching 'end undo' must 'tell' to the same document and no user interaction should be between begin and end undo)
- (NSArray *) bulkReaderSelector:(NSArray *)selector target:(NSArray *)target argument:(NSArray *)argument;  // Return result of applying a selector to every object in the target list (since 1.6)
- (BOOL) canLinkRecordType:(NSString *)recordType;  // Returns true or false if a record can link to another type of record (since 1.6)
- (void) consolidateMultimediaToFolder:(NSString *)toFolder changeLinks:(BOOL)changeLinks preservePaths:(BOOL)preservePaths;  // Consolidate the multimedia in a new folder (since 1.3)
- (void) copyFileDestination:(NSString *)destination;  // Copy multimedia object file to the provided path (since 1.1)
- (NSString *) dateFormatFullDate:(NSString *)fullDate;  // Convert a GEDCOM date into the date style current selected in the GEDitCOM II preferences (since 1.1)
- (NSArray *) dateNumbersFullDate:(NSString *)fullDate;  // Returns day, month, and year numbers for Gregorian calendar in list (3 for 1 date or 6 for date range) (since 1.6.2)
- (NSArray *) datePartsFullDate:(NSString *)fullDate;  // Splits date into five parts {prefix, date1, conjunction, date2, comment} or if bad date return {error message}
- (NSString *) dateStyleFullDate:(NSString *)fullDate withFormat:(NSString *)withFormat;  // Reformat a custom date into specified style (since 1.6.2)
- (NSString *) dateTextSdn:(NSInteger)sdn withFormat:(NSString *)withFormat;  // Covert a serial day number to a Gregorian date (since 1.1)
- (NSString *) dateToday;  // Today's date as a string (since 1.1)
- (NSString *) dateYearFullDate:(NSString *)fullDate;  // Returns year for a date, including year range or c, <, or > if needed (since 1.6.2)
- (id) objectDescriptionOutputOptions:(NSArray *)outputOptions;  // Description of a record with many options (since 1.3)
- (void) detachChild:(GEDitCOM_IIIndividual *)child spouse:(NSString *)spouse;  // Detach data from a GEDCOM record
- (void) displayByName:(NSString *)byName byType:(NSString *)byType sorting:(NSString *)sorting;  // Display list of selected records in the index window and optionally sort the list (since 1.1)
- (void) endUndoAction:(NSString *)action;  // End undo grouping and set text for Undo menu item
- (NSString *) evaluateExpression:(NSString *)expression;  // Evaluate a GEDCOM expression for a gedcomRecord or structure
- (void) exportGedcomFilePath:(NSString *)filePath withOptions:(NSArray *)withOptions;  // Tell album or document to export their records to a stand-alone GEDCOM file (since 1.3)
- (NSArray *) findStructuresTag:(NSString *)tag output:(NSString *)output value:(NSString *)value;  // Find subordinate structures by name and optionally by contents
- (NSString *) formatNameValue:(NSString *)nameValue case:(NSString *)case_;  // Reformat name string into a GEDCOM name
- (NSString *) localStringForKey:(id)forKey;  // Convert input string to localized string using current language selected in the current interface format (since 1.5.2)
- (void) mergeWithRecord:(GEDitCOM_IIGedcomRecord *)withRecord force:(BOOL)force;  // Merge the target record with a compatible record of the same type (since 1.3)
- (NSArray *) namePartsGedcomName:(NSString *)gedcomName;  // Splits name with GEDCOM slashes into {prename, surname, postname} in a list.
- (void) notifyProgressFraction:(double)fraction message:(NSString *)message;  // Tell GEDitCOM II the fraction of the script that has been completed and/or post a message (since 1.1)
- (void) populateAlbum:(GEDitCOM_IIAlbum *)album;  // Populate new or existing album with records from the front window (since 1.3)
- (void) refreshFormats;  // Refresh for interface formats menu (since 1.7)
- (void) refreshScripts;  // Refresh the scripts menu (since 1.6)
- (void) runScriptAtPath:(NSString *)atPath;  // Run the script at the provided path (since 1.6)
- (NSString *) safeHtmlRawText:(NSString *)rawText insertPs:(NSString *)insertPs reformatLinks:(NSDictionary *)reformatLinks;  // Convert special HTML characters (&, ", <, and >) to HTML entities, unless raw text is a <div> element, and then reformat or remove internal links (since 1.1)
- (NSArray *) sdnRangeFullDate:(NSString *)fullDate;  // {Minimum, Maximum} serial day numbers for a date (or {0,0} if a date error) (since 1.1)
- (void) showAncestorsGenerations:(NSInteger)generations treeStyle:(GEDitCOM_IITSty)treeStyle;  // Show ancestors of the target individual record (since 1.3)
- (void) showBrowser;  // Open browser window for a GEDCOM record
- (void) showBrowserpaneWithId:(NSString *)withId;  // Open browser window for a GEDCOM record using a specific pane ID
- (void) showDescendantsGenerations:(NSInteger)generations treeStyle:(GEDitCOM_IITSty)treeStyle;  // Show descendants of the target individual record (since 1.3)
- (void) sortData:(GEDitCOM_IIESrt)data;  // Sort data in the record by relevant dates (since 1.3)
- (NSString *) soundexForText:(NSString *)forText;  // Return Soundex code for the supplied text (since 1.6.2)
- (NSArray *) userChoiceListItems:(NSArray *)listItems prompt:(NSString *)prompt buttons:(NSArray *)buttons multiple:(BOOL)multiple title:(NSString *)title;  // Display modal panel for user to select one or more items from a list. Returns list with {button clicked,{items' text},{items' numbers}} (since 1.5)
- (NSArray *) userInputPrompt:(NSString *)prompt buttons:(NSArray *)buttons initialText:(NSString *)initialText title:(NSString *)title;  // Display modal panel for user to enter a line of text. Returns list with {button clicked,text entered} (since 1.5)
- (NSString *) userOpenFileExtensions:(NSArray *)extensions prompt:(NSString *)prompt start:(NSString *)start title:(NSString *)title;  // Display modal panel for user to select any existing file and returns POSIX path (or empty if canceled) (since 1.5)
- (NSString *) userOpenFolderPrompt:(NSString *)prompt start:(NSString *)start title:(NSString *)title;  // Display modal panel for user to select any existing folder and returns POSIX path (or empty if canceled) (since 1.5)
- (NSString *) userOptionTitle:(NSString *)title buttons:(NSArray *)buttons message:(NSString *)message;  // Display modal dialog and let user select among 1 to 3 buttons and returns text of clicked button (since 1.5)
- (NSString *) userSaveFileExtensions:(NSArray *)extensions prompt:(NSString *)prompt start:(NSString *)start title:(NSString *)title;  // Display modal panel for user to select a file location for saving a file and returns POSIX path (or empty if canceled) (since 1.5)
- (void) userSelectByType:(NSString *)byType fromList:(NSString *)fromList prompt:(NSString *)prompt;  // Start panel for user to select a record from a document (since 1.6.2)

@end

