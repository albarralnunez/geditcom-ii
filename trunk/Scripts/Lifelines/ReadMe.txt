INTRODUCTION
============
This folder contains all you need to convert and run Lifelines programs in GEDitCOM II. The process is to write a python script for GEDitCOM II that uses the provided "lifelines" python module to emulate nearly all the Lifelines programming commands. The conversion of a Lifelines program to a GEDitCOM II emulation mostly involves converting the program to python syntax.

INSTALLATION PROCESS
====================
1. Expand this Lifelines folder from the downloaded package (which you must have done already if you are reading this)

2. Drag the entire "LifeLines" folder to the

     ~/Library/Application Support/GEDitCOM II/Scripts

folder.

3. Drag the "lifelines.py" file in this package to the

     ~/Library/Application Support/GEDitCOM II/Modules

folder. If a "Modules" if not there, create it and add the file.

4. Start GEDitCOM II, or if it is already running, choose the "Refresh Scripts" menu command and a "Lifelines" submenu will appear in the Scripts menu with emulated Lifelines programs that can be run in GEDitCOM II.

5. This emulation requires GEDitCOM II, version 1.6, build 2, or newer.

CONTENTS OF THIS PACKAGE
========================
1. Documentation Folder: Open the "Emulation Documentation.html" file in a browser to read how to convert Lifelines programs into GEDitCOM II scripts. The folder also has the Lifelines quick reference manual.

2. Emulations: Contains Lifelines programs that have already been converted to GEDitCOM II scripts. The names of these programs match the corresponding Lifelines program except the extension is changed from "ll" to "py".

3. GEDitCOM II Native: Emulated scripts are not the most efficient scripts. This folder contains examples of conversion of Lifelines programs to a GEDitCOM II script but using native GEDitCOM II methods rather then the Lifelines emulation module. The names match the emulation version except "_gc" is add the the name (before the extension)

4. Reports Converted/Unconverted: These two folders contain all the reports that come with the default Lifelines installation package. The "Converted" ones are the originals of the programs that are converted in the "Emulations" folder. The "Unconverted" ones have not yet been converted to a GEDitCOM II script.
