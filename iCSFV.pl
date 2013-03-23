#!/opt/local/bin/perl
# iCSFV - iOS Application Code Signature File Validator
# Copyright(c) 2013 Anestis Bechtsoudis { Census, Inc }

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;

use XML::Simple;
use Data::Dumper;
use File::Find;
use List::MoreUtils 'any';
use File::Basename;
use Getopt::Std;
use Term::ANSIColor qw(:constants);
use if $^O eq "MSWin32", "Win32::Console::ANSI";

## Variables ##
# Global variables
my %iCSFV;		# Script description properties
my %args;		# Command line parsing arguments
my $debug = 0;		# Debug mode disabled by default
my $ipa_path = "";	# Application (.ipa) path
my $app_path = "";	# Unzipped application (.app) path
my $app_name = "";	# Application name
my $cr_path;		# CodeResources path
my $tmp_base = "/tmp";	# Base temporary directory to operate
my $tmp_dir;		# Temp directory to operate
my @files_array;        # Array with filenames retrieved from app directory
my @ex_array;		# Files exclude array

# System commands
my $unzip = "/usr/bin/unzip";

# XML help variables
my $xml;		# XML object
my $xml_data;		# XML data storage
my @xml_array;		# Parsed XML array

# Help variables
my $file;
my $find_in_system;
my $file_type;

# Program description properties
$iCSFV{author} = 'Anestis Bechtsoudis { Census, Inc. }';
$iCSFV{desc} = "iOS Application Code Signature File Validator";
$iCSFV{ver} = "0.1.1";
$iCSFV{email} = 'anestis@census.gr';
$iCSFV{twitter} = '@anestisb';
$iCSFV{web} = 'http://census.gr';
## End of variables ##


# Print logo
print_logo();

# Parse command arguments
getopts("i:fdh", \%args) or die BOLD,RED,"[-]",RESET," Problem with the supplied arguments.\n";

# Check for invalid arguments
if(defined $ARGV[0]) {
    print BOLD,RED,"[-]",RESET," Unknown option:$ARGV[0]\n";
    print_usage();
}

# Print usage in -h case
print_usage() if $args{h};

# Check for debug mode
if(defined $args{d}) { $debug = 1; }

# Check system commands
if (!-e $unzip) {
    print BOLD,RED,"[-]",RESET," 'unzip' utility not found in system.\n";
    exit;
}

# Check for IPA file path argument
if(!defined $args{i}) {
    print BOLD,RED,"[-]",RESET," No input IPA file specified.\n";
    print_usage();
} else {
    $ipa_path = $args{i};
    print BOLD,BLUE,"[*]",RESET," IPA file path is '$ipa_path'\n" if $debug;
}

# Validate IPA path
if (!-e $ipa_path) {
    print BOLD,RED,"[-]",RESET," IPA file does not exist.\n";
    exit;
}

# Validate IPA filetype
$file_type = `file $ipa_path`;
if(index($file_type, 'Zip archive data') == -1) {
    print BOLD,RED,"[-]",RESET," Provided input is not a valid IPA file.\n";
    exit;
}

# Create a temp dir
$tmp_dir = `mktemp -d $tmp_base/XXXXX`;
chomp($tmp_dir);

# Unzip IPA to tmp_dir
print BOLD,BLUE,"[*]",RESET," Unzipping '$ipa_path' to '$tmp_dir'.\n";
system("$unzip -q $ipa_path -d $tmp_dir");

# Parse unzipped data and locate app & binary paths
$app_path = `find $tmp_dir -type d -name "*.app"`;
chomp($app_path);
$app_name = basename("$app_path", ".app");
print BOLD,BLUE,"[*]",RESET," Validating '$app_name' protected resources.\n";

# Codesignature XML path
$cr_path = "$app_path/_CodeSignature/CodeResources";

# Check XML code signature path
if (!-e $app_path) {
    print BOLD,RED,"[-]",RESET," XML Codesignature file does not exist.\n";
    exit;
}

# Check for only for one-level files validation
if (defined($args{f})) {
    $find_in_system = "find $app_path/* -type f -maxdepth 0";
    print BOLD,BLUE,"[*]",RESET," Validator will check only files in 1st level.\n";
} else {
    $find_in_system = "find $app_path/*";
    print BOLD,BLUE,"[*]",RESET," Validator will check both for files & dirs recursively.\n";
}

# Create XML Object
$xml = new XML::Simple;

# read XML file
$xml_data = $xml->XMLin($cr_path);

# Parse XML array
@xml_array = @{$xml_data->{dict}->{dict}->[0]->{key}};

# Print entire parsed XML array if debug enabled
if($debug) {
    foreach(@xml_array) {
	print BOLD,BLUE,"[*]",RESET," Protected file '$_'\n";
    }
}

# List all files in application directory
@files_array = `$find_in_system`;

# Remove head path, leaving only the relative part
@files_array = map { $_ =~ s/$app_path\///g; $_ } @files_array;

# Exclude files
# - Codesignature files and directory
# - Application binary (different code sign procedure)
push(@ex_array, "_CodeSignature/CodeResources");
push(@ex_array, "$app_name");
# Push any files here that you might want to exclude
# push(@ex_array, "<myFile>");

# Loop through the entiry files array and see if
# a matching signed record in XML array exists
foreach $file(@files_array)
{
    # Remove trailing new line
    chomp($file);

    # Check string value against XML array
    if ( grep ( /^$file$/, @xml_array ) ) {
	# Print signed files only in debug mode
	if($debug) {
	    if(-f "$app_path/$file") {
		print BOLD,GREEN,"[+]",RESET," '$file' signed.\n";
	    }
	}
    } elsif ( !grep ( /^$file$/, @ex_array ) ) {
	# Print not signed files
	if(-f "$app_path/$file") {
            print BOLD,RED,"[-]",RESET," '$file' not signed.\n";
        }
    }
}

# Preserve unzipped data in debug mode
if($debug) {
    print BOLD,BLUE,"[*]",RESET," '$app_name' is available at '$tmp_dir' for further investigation.\n";
} else {
    print BOLD,BLUE,"[*]",RESET," Deleting '$tmp_dir'. Use debug mode (-d) to keep it.\n";
    system("rm -rf $tmp_dir");
}

# Warning notice
print BOLD,YELLOW,"\n[!]",RESET," Changes in resources (png, jpg, nib, etc) that are not signed, does not\n";
print "    invalidate the signature. Check their use cases and proceed accordingly.\n";

exit;

#################################################################################
# Help functions
#################################################################################

#################################################################################
# Print logo
sub print_logo
{
    # Check if terminal for colored output
    if(-t STDOUT) {
        print "\n",BLUE,BOLD,"\tiCSFV $iCSFV{ver}",RESET;
        print BLUE," - $iCSFV{desc}\n";
        print GREEN,"\tCopyright (C) 2013 ",RESET,GREEN,BOLD,"$iCSFV{author}\n",RESET;
        print GREEN,"\t{ ",YELLOW,"$iCSFV{twitter} ",GREEN,"|",YELLOW," $iCSFV{email} ";
        print GREEN,"|",YELLOW," $iCSFV{web}",GREEN," }\n\n",RESET;

        # Flush output buffer
        $|++;
    }
    else {
        print "\n\tiCSFV $iCSFV{ver} - $iCSFV{desc}\n";
        print "\tCopyright (C) 2013 $iCSFV{author}\n";
        print "\t{ $iCSFV{twitter} | $iCSFV{email} | $iCSFV{web} }\n\n";
    }
}

#################################################################################
# Print help page
sub print_usage
{
print qq(
Usage: iCSFV.pl [options]

Options:
  -i            Application *.ipa file

  -f		Check application path only for files in 1st level
                    (Default: recursive check for both files and directories)

  -d            Enable debug output (verbose info + IPA payload preserve)

  -h            Display help and exit
);

exit;
}
