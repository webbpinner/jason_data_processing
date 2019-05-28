# jason_data_processing
Scripts used to process data from the ROV Jason

## Installation

copy ./constants.py.dist to ./constants.py

requires python v3 and the python3-requests library

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
