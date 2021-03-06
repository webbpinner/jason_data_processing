#!/bin/csh -f
# -----------------------------------------------------------------------------
# Name: process_1_lss
# Description: preprocesses LSS data and makes it ready for manual editing
#
# Usage: process_1_lss <indir> <lowering>
#    where indir    - directory for processed data--base name
#    where lowering - lowering id, eg J2-1002
#
# Changelog:
# JCH 2002/09/04 - initial creation
# CJS 2004/01/12 - changed bindir for data user
# SJM 2009/04/07 - changed bindir to /usr/local/bin
# SJM 2010/08/02 - altered paths to support processing in individual accounts
#                expects Procdata to be at $HOME/$CRUISE/Procdata
#                and scripts in $home/bin
# SJM 2013/03/22 - Added code to rewrite datestring from form YY/MM/DD to
#                YYYY/MM/DD so that records get past checkTimes.pl. 
# SJM 2013/08/18 - SJM Added application of 'lss_raw2ftu_seapoint.py' to
#                J2-xxx.LSS.raw, yielding J2-xxx.FTU.proc 
# JWP 2019/06/16 - changed calculated source/destinations directories from
#                $indir/$cruise/$lowering to $indir/$lowering
#                - assumes any sub-scripts are located in the the $PATH
#                - removed need to define vehicle or sensor
#                - general code cleanup
#
# -----------------------------------------------------------------------------

set _D = $PWD
set datatype_suffix = LSS
set datatype_input_subdir = lss

# -----------------------------------------------------------------------------
# Verify the required sub-commands are in the current path
# -----------------------------------------------------------------------------
set required_cmds = {"checkTimes.pl", "lss_raw2ftu_seapoint.py"}

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
    awk '{printf("%s %s %s %s %s %s\n",$1,"20"$2,$3,$5,$6,$7)}' $f > $outfile.tmp
    checkTimes.pl < $outfile.tmp  >> $outfile
    echo `date "+ %b %e %T %Z"` " checked for bad times in $f"
  end
  rm -f $outfile.tmp
  echo "Results save to: $outfile"

  set ftufile = $real_outdir/$real_outdir/$lowering.FTU.proc
  lss_raw2ftu_seapoint.py $outfile $ftufile
  echo "FTU Results saved to: $ftufile"

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