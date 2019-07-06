#!/bin/csh -f
# -----------------------------------------------------------------------------
# Name: process_1_vfr
# Description: Extracts VPR and VFR records from navest. SOLN_DEADRECK,
# SOLN_GPS0, SOLN_USL are processed individually.  Other VFR records, which
# perhaps dont exist, go into another file.
#
# Usage: process_1_vfr <indir> <lowering>
#    where indir    - directory for processed data--base name
#    where lowering - lowering id, eg J2-1002
#
# Changelog:
# SJM 2014/12/01 - initial creation
# JWP 2019/06/16 - changed calculated source/destinations directories from
#                $indir/$cruise/$lowering to $indir/$lowering
#                - assumes any sub-scripts are located in the the $PATH
#                - removed need to define vehicle or sensor
#                - general code cleanup
#
# -----------------------------------------------------------------------------

set _D = $PWD
set datatype_input_subdir = navest

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
echo "    Processing navest VPR and VFR data for $lowering" 
echo "    Input Directory: $real_indir"
echo "    Output Directory: $real_outdir"
echo "    Written: "`date "+ %b %e %T %Z"`
echo " "
echo "*********************************************************"

# if we get interrupted, exit gracefully
onintr QUIT_SCRIPT

# -----------------------------------------------------------------------------
# processing VPR records
# -----------------------------------------------------------------------------
  set vprfile = $real_outdir/$lowering.VPR.raw
  # extract the files from the navest logs
  cd $real_indir
  foreach f(*.DAT)
    set basen = $f:r
    if (-M $f > -M $real_outdir/$datatype_input_subdir/$basen.vpr ||
      ! -e $real_outdir/$datatype_input_subdir/$basen.vpr) then
      echo "Processing $f for VPR records"
      grep -h VPR $f > $basen.vpr
    else
      echo "No new VPR to parse"
    endif
  end

  foreach f(`ls -1 $real_indir/*.vpr|sort`)
    checkTimes.pl <$f  >> $vprfile
    echo `date "+ %b %e %T %Z"` " checked for bad times in $f"
  end
  echo "Results saved to: $vprfile"


# -----------------------------------------------------------------------------
# processing VFR dead reckoning records
# -----------------------------------------------------------------------------
  set deadreckfile = $real_outdir/$lowering.VFR_DR.raw

  cd $real_indir
  foreach f(*.DAT)
    set basen = $f:r
    if (-M $f > -M $real_outdir/$datatype_input_subdir/$basen.vfr_dr ||
      ! -e $real_outdir/$datatype_input_subdir/$basen.vfr_dr) then
      echo "Processing $f for SOLN_DEADRECK"
      grep -h VFR $f | grep SOLN_DEADRECK > $basen.vfr_dr
    else
      echo "No new VFR:SOLN_DEADRECK to parse"
    endif
  end

  foreach f(`ls -1 $real_indir/*.vfr_dr|sort`)
    checkTimes.pl <$f  >> $deadreckfile
    echo `date "+ %b %e %T %Z"` " checked for bad times in $f"
  end
  echo "Results saved to: $deadreckfile"
 
  foreach f(*.DAT)
    set basen = $f:r
    if (-M $f > -M $real_outdir/$datatype_input_subdir/$basen.vfr_usbl ||
      ! -e $real_outdir/$datatype_input_subdir/$basen.vfr_usbl) then
	    echo "Processing $f for SOLN_USBL"
      grep -h VFR $f | grep SOLN_USBL > $basen.vfr_usbl
    else
      echo "No new VFR:SOLN_USBL to parse"
    endif
  end
  

# -----------------------------------------------------------------------------
# processing the VFR USBL records
# -----------------------------------------------------------------------------
  set usblfile = $real_outdir/$lowering.VFR_USBL.raw
   
  foreach f(`ls -1 $real_indir/*VFR_USBL*|sort`)   
    checkTimes.pl <$f  >> $usblfile
    echo `date "+ %b %e %T %Z"` " checked for bad times in $f"
  end
  echo "Results saved to: $usblfile"


# -----------------------------------------------------------------------------
# process the VFR GPS records
# -----------------------------------------------------------------------------
  set gps0file = $real_outdir/$lowering.VFR_GPS0.raw

  foreach f(*.DAT)
    set basen = $f:r
    if (-M $f > -M $real_outdir/$datatype_input_subdir/$basen.vfr_gps0 ||
      ! -e $real_outdir/$datatype_input_subdir/$basen.vfr_gps0) then
	    echo "Processing $f for SOLN_GPS0"
      grep -h VFR $f | grep SOLN_GPS0 > $basen.vfr_gps0
    else
      echo "No new VFR:SOLN_GPS0 to parse"
    endif
  end
   
  foreach f(`ls -1 $real_indir/*.vfr_gps0|sort`) 
    checkTimes.pl <$f  >> $gps0file
    echo `date "+ %b %e %T %Z"` " checked for bad times in $f"
  end
  echo "Results saved to: $gps0file"


# -----------------------------------------------------------------------------
# process the VFR data that are not DR, GPS, or USBL
# -----------------------------------------------------------------------------
  set vfrfile = $real_outdir/$lowering.VFR_O.raw

  foreach f(*.DAT)
    set basen = $f:r
    if (-M $f > -M $real_outdir/$datatype_input_subdir/$basen.vfr_O ||
      ! -e $real_outdir/$datatype_input_subdir/$basen.vfr_O) then
	    echo "Processing $f for other VFRs"
      grep -h VFR $f | grep -v SOLN_USBL | grep -v SOLN_GPS0 | grep -v SOLN_DEADRECK > $basen.vfr_O
    else
      echo "No new VFR:SOLN_O to parse"
    endif
  end
   
  foreach f(`ls -1 $real_indir/*.vfr_O|sort`) 
    checkTimes.pl <$f  >> $vfrfile
    echo `date "+ %b %e %T %Z"` " checked for bad times in $f"
  end
  echo "Results saved to: $vfrfile"

goto DONE

QUIT_SCRIPT:
  echo ""
  echo "$0 was interrupted... "
  cd $_D
 exit 1

DONE:
  echo ""
  echo ""
  echo `date "+ %b %e %T %Z"` "Phase 1 VFR Processing  Done for $lowering "
  echo ""
  echo ""
  cd $_D
exit 1

