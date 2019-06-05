# JASON Data Processing Tools
Tools used to process data from the ROV Jason

## Installation

1. install python v3 and the python3-requests library
2. copy ./constants.py.dist to ./constants.py
3. setup the constants.py file to match the desired setup.
4. ensure the baseDir defined in the constants.py file exists and the desired user that will be processing the data has read/write privledges to it. 

## Tools

**build_data_directories.py** --> interactive script for building cruise and lowering directories

**build_cruise_scripts.py** --> interactive script for building/rebuilding cruise-related scripts
  - <cruise_id>_pull_data_rsync_script.sh --> builds a script for pulling data from DLog and Navest to the cruise data directory
  - <cruise_id>_backup_data_rsync_script.sh --> builds a script for making copies of the cruise data

**build_lowering_scripts.py** --> interactive script for building/rebuilding lowering-related scripts
  - <lowering_id>_proc_data_script.sh --> builds hourly by-datatype dlog data files from the raw dlog data files
  - <lowering_id>_make_lowering.sh --> copies the appropriate hourly by-datatype dlog data files for the specified lowering to the lowering subdirectory within ProcData
  - <lowering_id>_make_lowering_files.sh --> builds by-datatype files for the specified lowering
  - <lowering_id>_proc_clips.sh --> processes/renames the Highlights_4K and Highlights_1080 clips for the specified lowering
  - <lowering_id>_proc_sulis.sh --> processes/renames the SulisCam images for the specified lowering

## Cruise Data Directory Structure

```
/baseDir
  /<cruise_id>
    /Documentation
    /H264Recordings
      /<lowering_id>
    /Highlights
      /<lowering_id>
    /HDGrabs
      /<lowering_id>
    /Nav
      /<lowering_id>
    /ppi_ppfx
      /<lowering_id>
    /scripts
    /Sealog
    /StillCamera
      /<lowering_id>
    /Vehicle
      /ProcData
        /<lowering_id>
          /scripts
      /RawData
    /VirtualVan
```

## Sealog and the Templating Engine
These tools rely on the Sealog eventlogging framework for accessing cruise ids, cruise start/stop times, lowering ids and lowering start/on bottom/off bottom/stop times.  These tools take the data from Sealog, variables defined in the `constants.py` file and script template files to build cruise-specific and lowering-specific data retrieval and processing scripts.  All of the cruise-level scripts are stored in the `/<cruise_id>/scripts` directory.  All lowering-specific scripts are stored in the `/<cruise_id>/Vehicle/ProcData/<cruise_id>/<lowering_id>/scripts` directory.

The templates and the templating engine have been setup with the intention that the resulting scripts can be run from anywhere on the host machine.  The full paths for all commands, source directories/files and destination directories/files are fully defined in the scripts.  In cases where the working directory within the script must change, the script saves the starting directory and returns the working directory to the starting working directory before exiting.

## Pre-cruise Procedures
The first step is to setup the cruise record within Sealog.  Setting up cruise records in Sealog should be straight forward given that the cruise dates are well known by the time the ROV is mobilized onboard the vessel.  After the cruise record is created, run the `/<cruise_id>/scripts/build_data_directories.py` script to build the initial cruise data directory structure and run the `/<cruise_id>/scripts/build_cruise_scripts.py` to build the data retrival and backup scripts.

## Pre-lowering Procedures
The first step is to setup the lowering record within Sealog.  Setting up lowering records in Sealog will be more difficult than cruise records because of the fluid nature of schedule changes due to weather, mechanical failures, etc.  There is no penalty within Sealog for creating a lowering record after a lowering has started or for changing the record after it's been created.

## Post-lowering Procedures
The first step is to correct the lowering start/stops times within Sealog and define the lowering on_bottom/off_bottom times.  The Milestone/Stats page within the Lowering section of Sealog should streamline this process.  After the lowering record is corrected, run the `/<cruise_id>/scripts/build_data_directories.py` script to build the initial lowering data directory structure and the `/<cruise_id>/Vehicle/ProcData/<cruise_id>/<lowering_id>/scripts/build_lowering_scripts.py` to build the lowering data processing scripts.

### DLog Data
Pull the data from the vans to the processing maching by running the `/<cruise_id>/scripts/<cruise_ID>_pull_data_rsync_script.sh`.

Process the data from DLog1 with the `/<cruise_id>/Vehicle/ProcData/<cruise_id>/<lowering_id>/scripts/<lowering_id>_proc_data_script.sh`.

Run the `/<cruise_id>/Vehicle/ProcData/<cruise_id>/<lowering_id>/scripts/<lowering_id>_make_lowering.sh` script to build the `low_stat` file and copy the relavent files to the lowering directory in ProcData

Run the `/<cruise_id>/Vehicle/ProcData/<cruise_id>/<lowering_id>/scripts/<lowering_id>_make_lowering_files.sh` script to build the by-datatype files for the lowering

### Highlights_4K and Highlights_1080 clips
Retrieve the drives from the Vans.  For each drive:
 - Mount the drive on the iMac
 - Run the `/<cruise_id>/Vehicle/ProcData/<cruise_id>/<lowering_id>/scripts/<lowering_id>_proc_clips` script specifying the `-s <source dir>` argument where `<source dir>` is the directory on the mounted drive where the clips exist (i.e. `/Volumes/KiProDRV_01/data`). If the drive is from the KiPro Rack, also specify the `-2` argument.

### SulisCam Images
Copy the raw images from the SulisCam to the `<cruise_id>/StillCamera/<lowering_id>` directory.  Run the `/<cruise_id>/Vehicle/ProcData/<cruise_id>/<lowering_id>/scripts/<lowering_id>_proc_sulis.sh` script to rename the files.
