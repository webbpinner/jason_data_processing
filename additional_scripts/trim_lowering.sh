#!/bin/csh -f
# -----------------------------------------------------------------------------
# trim_lowering_data
# trims the data in the datafile to fit the temporal bounds of the lowering.
# returns the data to stdout
#
# Usage: trim_lowering_data  <datafile> <dive_start> <dive_end>
#    where datafile   - the datafile to trim
#	 where dive_start - the dive start time in YYYYMMDDhhmm format
#	 where dive_end   - the dive end time in YYYYMMDDhhmm format
#
# JWP 2019/06/16 - initially created.  Based on low_cut script.
# -----------------------------------------------------------------------------

set _D = $PWD

# -----------------------------------------------------------------------------
# Check usage
# -----------------------------------------------------------------------------
if ( $#argv < 3 ) then
  echo "Usage: $0 <datafile> <dive_start> <dive_end>"
  echo "#    where datafile   - the datafile to trim"
  echo "#	 where dive_start - the dive start time in YYYYMMDDhhmm format"
  echo "#	 where dive_end   - the dive end time in YYYYMMDDhhmm format"
  echo " "
  exit 1
endif

set datafile = "$1" 
set dive_start = "$2" 
set dive_end = "$3"

# -----------------------------------------------------------------------------
# Verify datafile exist
# -----------------------------------------------------------------------------
if (! -d $datafile) then
	echo "Input datafile: $datafile, does not exist"
	cd $_D
	exit 1
endif

awk -v DiveStart=$dive_start -v DiveEnd=$dive_end -F '[./:, ]' '{if($2$3$4$5$6 >= DiveStart && $2$3$4$5$6 <= DiveEnd) print $0}' $datafile

cd $_D