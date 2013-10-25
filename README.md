iCSFV
=====
```Text
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
         _  ____ ____  _______     __
        (_)/ ___/ ___||  ___\ \   / /
        | | |   \___ \| |_   \ \ / / 
        | | |___ ___) |  _|   \ V /  
        |_|\____|____/|_|      \_/   

iOS Application Code Signature File Validator
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@


     Written by: Anestis Bechtsoudis @anestisb
Copyright (C) 2013 Anestis Bechtsoudis ( Census, Inc. )
```

License
=======
GPLv3. Check included LICENSE file for more information


Requirements
============
* Perl
* XML::LibXML::Simple library
* Unzip command line tool
* security command line tool
* openssl command line tool (as an alternative to security tool)
* codesign command line tool


Usage
=====
```
Usage: iCSFV.pl [options]

Options:
  -i            Application *.ipa file
  -f            Check application path only for files in 1st level
                    (Default: recursive check for both files and directories)
  -m            Print mobile provision profile data
  -e            Print entitlements data
  -d            Enable debug output (verbose info + IPA payload preserve)
  -h            Display help and exit
```

Examples
========
1. Check for unprotected files & directories (recursively) located into "test.ipa"
```
./iCSFV.pl -i iOS/Binaries/test.ipa
```

2. Check for unprotected files only in 1st level (depth 0) located into "test.ipa"
```
./iCSFV.pl -f -i iOS/Binaries/test.ipa
```

3. Make the same checks with (2.) in debug mode (verbose info + IPA payload preserve)
```
./iCSFV.pl -d -f -i /iOS/Binaries/test.ipa 
```


Example Output
==============
```text
./iCSFV.pl -i iOS/Binaries/test.ipa

	iCSFV 0.1.2 - iOS Application Code Signature File Validator
	Copyright (C) 2013 Anestis Bechtsoudis { Census, Inc. }
	{ @anestisb | anestis@census.gr | http://census.gr }

[*] Unzipping 'test.ipa' to '/tmp/qaHXC'.
[*] Validating 'Test' protected resources.
[*] Validator wil check both for files & dirs recursively.
[-] 'extra/Test.plist' file not signed.
[-] 'Icn_+_Sample.png' file not signed.
[-] 'Info.plist' file not signed.
[-] 'InfoPlist.strings' file not signed.
[-] 'MainWindow.nib' file not signed.
[*] Deleting '/tmp/qaHXC'. Use debug mode (-d) to keep it.

[!] Changes in resources (png, jpg, nib, etc) that are not signed, does not
    invalidate the signature. Check their use cases and proceed accordingly.
```
