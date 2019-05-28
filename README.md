# jason_data_processing
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
  - <lowering_id>_proc_data_script.sh --> builds a script for correctly calling the data_parse script for the specified lowering
  - <lowering_id>_make_lowering.sh --> builds a script for correctly calling the make_lowering script for the specified lowering
  - <lowering_id>_proc_clips.sh --> builds a script for processing the Highlight and KiPro1080 scripts for the specified lowering
  - <lowering_id>_proc_sulius.sh --> build a script for renaming the SuliusCam images for the specified lowering

## Cruise Data Directory Structure

```
/baseDir
  /<cruise_id>
    /Documentation
    /H264Recordings
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
        /<cruise_id>
          /<lowering_id>
            /scripts
      /RawData
    /VirtualVan
```

## Sealog and the Templating Engine
These tools rely on the Sealog eventlogging framework for accessing cruise ids, cruise start/stop times, lowering ids and lowering start/on bottom/off bottom/stop times.  These tools take the data from Sealog, variables defined in the `constants.py` file and script template files to build cruise-specific and lowering-specific data retrieval and processing scripts.

## Pre-cruise Procedures
The first step is to setup the cruise record within Sealog.  Setting up cruise records in Sealog should be straight forward given that the cruise dates are well known by the time the ROV is mobilized onboard the vessel.  After the cruise record is created, run the `build_data_directories.py` script to build the initial cruise data directory structure and the `build_cruise_scripts.py` to build the data retrival and backup scripts.

## Post-lowering Procedures
The first step is to setup the lowering record within Sealog.  Setting up lowering records in Sealog will be more difficult than cruise records simply beacause of the fluid nature of causing due to weather, mechanical failures, etc.  There is no penaty within Sealog for creating a lowering record after a lowering has started or for changing the record after it's been created.  The important thing here is to ensure that the start/stop times in the lowering records are roughly correct and if necessay error on the side of being outside the actualy bounds (i.e. Start time is too early, Stop time is too late).  After the lowering record is created, run the `build_lowering_scripts.py` script to build the lowering processing scripts.







