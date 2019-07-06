#!/bin/csh -f
# -----------------------------------------------------------------------------
# Name: process_1_oos
# Description: preprocesses SVP data and makes it ready for manual editing
#
# Usage: process_1_oos <indir> <lowering>
#    where indir    - directory for processed data--base name
#    where lowering - lowering id, eg J2-1002
#
# Changelog:
# WJR & SJM 2010/06/14 
# SJM 2010/08/02 - Altered paths to support processing in individual accounts
#                expects Procdata to be at $HOME/$CRUISE/Procdata and scripts
#                in $HOME/bin
# SJM 2015/09/01 - Upon addition of Aanderaa 4330 optode as permanent
#                equipment, added code in the foreach loop to remove problem
#                characters in the sensors record. Native Aanderaa records
#                start with 3 non-ASCII characters, an annoyance. When logged
#                by in-van loggers we prepend our typical DSL prefix string
#                with timestamp. This is a 33 char prefix. 'clean_oos.pl' is a
#                util that replaces the 3 non-ASCII chars with spaces. It does 
#                this brute force, by replacing chars 34-36 of each oos record.
#                ** If the prefix is changed, clean_oos.pl will no longer work 
#                properly ** You will have to change the call to substr in 
#                clean_oos.pl. This is annoying of course, but I didn't succeed
#                in developing a regexp-based replacement method.
#
# JWP 2019/06/16 - changed calculated source/destinations directories from
#                $indir/$cruise/$lowering to $indir/$lowering
#                - assumes any sub-scripts are located in the the $PATH
#                - removed need to define vehicle or sensor
#                - general code cleanup
#
# -----------------------------------------------------------------------------

set _D = $PWD
set datatype_suffix = OOS
set datatype_input_subdir = oos

# -----------------------------------------------------------------------------
# Verify the required sub-commands are in the current path
# -----------------------------------------------------------------------------
set required_cmds = {"checkTimes.pl", "clean_oos.pl"}

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
  set outfile = $real_outdir/$lowering.$datatype_suffix.raw
   
  foreach f(`ls -1 $real_indir/*$datatype_suffix*|sort`)
    clean_oos.pl < $f > $outfile.tmp
    checkTimes.pl < $outfile.tmp  >> $outfile
    echo `date "+ %b %e %T %Z"` " checked for bad times in $f"
  end
  rm -f $outfile.tmp
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