#!/bin/csh -f
# -----------------------------------------------------------------------------
# process_1_alt
# preprocesses altitude data and makes it ready for manual editing
#
# Usage: process_1_alt  <indir>  <lowering>
#    where indir    - directory for processed data--base name
#	   where lowering - lowering id, eg J2-1002
#
# JCH 2002/09/04
# CJS 2004/01/12 - changed bindir for data user
#
# SJM 2009/04/07 - changed bindir to /usr/local/bin
# SJM 2010/08/02 - altered paths to support processing in individual accounts
#                expects Procdata to be at $HOME/$CRUISE/Procdata
#                and scripts in $home/bin
# SJM 2015/04/20 - a bug in the code that generates the records that get
#                logged means that there are bad timestamps on records
#                without raw data. Filter so that only records with
#                measurements in the raw field make it through to the
#                delivered files. Performed using awk.
# JWP 2019/06/16 - changed calculated source/destinations directories from
#                $indir/$cruise/$lowering to $indir
#                - assumes any sub-scripts are located in the the $PATH
#                - removed need to define vehicle or sensor
#                - general code cleanup
# -----------------------------------------------------------------------------

set _D = $PWD
set datatype_suffix = ALT
set datatype_input_subdir = veh

# -----------------------------------------------------------------------------
# Verify the required sub-commands are in the current path
# -----------------------------------------------------------------------------
set required_cmds = {"checkTimes.pl"}

foreach i ($required_cmds)

  if(`where $i` == "") then
    echo "$i command not found, cannot proceed"
    exit 1
  endif
end

# -----------------------------------------------------------------------------
# Check usage
# -----------------------------------------------------------------------------
if ( $#argv != 2 ) then
  echo "Usage: $0 <indir> <lowering>"
  echo "    where indir    - base directory for organized data, eg /Vehicle/ProcData"
  echo "    where lowering - name of lowering, eg J2-1002"
  echo " "
  exit 1
endif

set indir = "$1"
set lowering = "$2"

set real_indir = $indir/$lowering/$datatype_input_subdir
set real_outdir = $indir/$lowering

# -----------------------------------------------------------------------------
# Verify source and destination directories exist
# -----------------------------------------------------------------------------
if (!( -d $real_indir && -r $real_indir)) then
	echo "Input directory does not exist or is non-readable: $real_indir"
	exit 2
endif

if (!( -d $real_outdir && -w $real_outdir)) then
  echo "Output directory does not exist or is non-writable: $real_outdir"
  exit 2
endif


# -----------------------------------------------------------------------------
# initialize processing summary
# -----------------------------------------------------------------------------
echo "    Processing $datatype_suffix data for lowering $lowering" 
echo "    Input Directory: $real_indir"
echo "    Output Directory: $real_outdir"
echo "    Written: "`date "+ %b %e %T %Z"`
echo " "
echo "*********************************************************"


# -----------------------------------------------------------------------------
# Main Loop
# -----------------------------------------------------------------------------

# If interrupted, exit gracefully
onintr QUIT_SCRIPT

  # Process the attitude data
  set outfile = $indir/$lowering.$datatype_suffix.raw
   
  foreach f(`ls -1 $real_indir/*$datatype_suffix*|sort`)
    # SJM 4/20/15 Extract only records that have a floating pt value in the
    # 4th field of the RAW field of full record (#8).
    cat $f | gawk '$8 ~ /f[,][[0-9][^.].*[.][0-9][^,].*[,]M/' > $outfile.tmp 
    checkTimes.pl <$outfile.tmp  >> $outfile
    echo `date "+ %b %e %T %Z"` " checked for bad times in $f"
  end
  rm $outfile.tmp 
  echo "Results saved to: $outfile"

goto DONE

QUIT_SCRIPT:
  echo ""
  echo "$0 was interrupted... "
 exit 1

DONE:
  echo ""
  echo ""
  echo `date "+ %b %e %T %Z"` "Completed phase 1 processing for lowering: $lowering, datatype: $datatype_suffix"
  echo ""
  echo ""
exit 1