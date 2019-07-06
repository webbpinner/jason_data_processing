#!/usr/bin/perl
# -----------------------------------------------------------------------------
# Name: checkTimes
# Description: checks data for good time records. must be a valid date/time.
#              Reads from stdin, writes to stdout. Time cannot go backward,
#              though it can stand still. Perl replacement for
#              'check_time_flow.c'
#
# Usage: checkTimes < infile > outfile
#
#  PreRequesits: Need to install Time::timegm
#                `brew install cpanminus`
#                `cpanm --sudo Time::timegm`
#
# Changelog:
# SJM 2013/03/22 - J2-XXX.*.raw files were failing inexplicably. Turns out that
#                the date check below failed for years > 2012. Fix.
# JWP 2019/06/16 - Total seconds calculated via Time::timegm CPAN module. This
#                removed dependency on '/usr/local/include/dateToDays.pl'
#                - general code cleanup
#
# -----------------------------------------------------------------------------

use Time::timegm qw( timegm );

# Assume first time is in sequence
$lastTime = -1;			

# Process input
while ($inputLine = <STDIN>)
{
    ($dataType, $dateStg, $timeStg) = split (' ', $inputLine, 3);

    # Parse date/time
    ($yr,$mon,$day) = split ('/', $dateStg, 3);
    ($hr,$min,$sec) = split (':', $timeStg, 3);

    # Validate each of the date values
    if (($yr < 1970)) { next; }
    if (($mon < 1) || ($mon > 12))	{ next; }
    if (($day < 1) || ($day > 31))	{ next; }
    if (($hr  < 0) || ($hr  > 23))	{ next; }
    if (($min < 0) || ($min > 59))	{ next; }
    if (($sec < 0) || ($sec > 59))	{ next; }

    # Compute the total seconds since UNIX epoch
    $thisTime = timegm($sec,$min,$hr,$day,$mon-1,$yr-1900);

    # Verify time is not going backwards
    if ($lastTime > $thisTime)	{ next; }

    # Pass only the rows where the current time is >= to previous time 
    printf ("%s", $inputLine);

    # Set previous time to current time
    $lastTime = $thisTime;
}
exit;


 
