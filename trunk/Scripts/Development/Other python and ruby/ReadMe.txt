This folder has scripts written using python or ruby and Apple's ScriptingBridge. They are here mostly for development and not part of the standard install package. They require MacOS Leopard to newer to work. They should not be used in MacOS 10.6.0 to 10.6.2 due to AppleEvents bug in those MacOS version.

The file GEDitCOM II.h is ScriptingBridge translation where you can look up commands and properties to make sure the scripts use the proper form. This file can be generated from latest version of GEDitCOM II using command line:

sdef "/Applications/GEDitCOM II.app" | sdp -fh --basename GEDitCOM_II --bundleid com.geditcom.GEDitCOMII

or for development version on laptop use

sdef "/Users/nairnj/Programming/Cocoa_HomeProjects/GEDitCOM_II/build/Release/GEDitCOM II.app" | sdp -fh --basename GEDitCOM_II --bundleid com.geditcom.GEDitCOMII

on Lion use

sdef "/Users/nairnj/Library/Developer/Xcode/DerivedData/GEDitCOM_Pro-bimxoxdrzkwdkqgvskiwmvgvydje/Build/Products/Develop/GEDitCOM II.app" | sdp -fh --basename GEDitCOM_II --bundleid com.geditcom.GEDitCOMII

