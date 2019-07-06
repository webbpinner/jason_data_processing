#!/usr/bin/env perl
# -----------------------------------------------------------------------------
# Name: clean_oos
# Description: Replace non-printable characters produced natively by Aanderaa
#              optode. These occur at the beginning of each record. We prepend
#              the standard DSL string, inclusing timestamp, that in this case
#              is 33 characters. So, this filter replaces chars 34-36 with 
#              spaces. If the length of the string prepended to the native
#              optode record changes, change the range of replacement in the
#              call to substr below.
#
# Usage: clean_oos < infile > outfile
##
# Changelog:
# SJM 2013/09/01 - J2-XXX.*.raw files were failing inexplicably. Turns out that
#                the date check below failed for years > 2012. Fix.
# JWP 2019/06/16 - general code cleanup
#
# -----------------------------------------------------------------------------

while (<STDIN>) {

    $inline = $_;

    if ($inline =~ m/MEASUREMENT/) {
	substr($inline, 33, 3) = "   "; 
	printf STDOUT "%s", $inline;
    }
}
