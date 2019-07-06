#!/usr/bin/env python3

import json
import sys
import datetime
import os
import stat

sys.path.append('.')

from sealog import Sealog
from constants import baseDir, rawDir, cruisePullDailyDataRsyncScriptName, cruiseBackupDataRsyncScriptName, cruisePullHourlyDataRsyncScriptName, binDir, scriptDir, templatesDir
from utils import build_confirmation_menu

Sealog = Sealog()

cruise = Sealog.build_cruise_select_menu(newest=True)
if not cruise:
    print("No cruises found in Sealog, Quitting...")
    sys.exit(0)

scriptDir_proc = os.path.expanduser(scriptDir).replace('<cruise_id>', cruise['cruise_id'])

if not os.path.isdir(scriptDir_proc):
    if build_confirmation_menu("Script Directory: " + scriptDir_proc + ", does not exists.  Create it?", defaultResponse=True):
        try:
            print('Creating Script Directory:')
            print(' +', scriptDir_proc)
            os.mkdir(scriptDir_proc)

        except:
            print("Unable to create script directory.  Please verify the current user has write permissions to the parent directory.")
            print("Quitting...")
            sys.exit(1)
    else:
        print("Quitting...")
        sys.exit(0)

print("")

scriptFN = cruisePullDailyDataRsyncScriptName.replace('<cruise_id>', cruise['cruise_id'])
scriptPath = os.path.join(scriptDir_proc, scriptFN)

if not os.path.isfile(scriptPath) or build_confirmation_menu("Rsync script: " + scriptFN + ", already exists.  Rebuild it?", defaultResponse=False):

    cruiseStart = datetime.datetime.strptime(cruise['start_ts'], "%Y-%m-%dT%H:%M:%S.%fZ")
    cruiseStop = datetime.datetime.strptime(cruise['stop_ts'], "%Y-%m-%dT%H:%M:%S.%fZ")

    delta = cruiseStop - cruiseStart # timedelta

    dates = []

    for i in range(delta.days + 1):

        dates.append((cruiseStart + datetime.timedelta(days=i)).strftime("%Y%m%d"))


    print("Building", scriptFN + "...")
    try:

        template = os.path.join(templatesDir, "rsync_cruise_by_day.template")
        with open(template) as t:
            with open(scriptPath, "w") as f:
                f.write("#!/bin/bash\n")
                f.write("# ---------------------------------------------------------------\n")
                f.write("# Pulls daily data from dlog via rsync for all days of the cruise\n")
                f.write("# ---------------------------------------------------------------\n")
                f.write("\n")
                f.write("# Directory where the script is being run from\n")
                f.write("_D=\"$(pwd)\"\n\n")
                f.write("# From constants.py\n")
                f.write("BINDIR=" + binDir + "\n\n")
                f.write("# From constants.py\n")
                f.write("SCRIPTDIR=" + scriptDir_proc + "\n\n")
                f.write("# From constants.py\n")
                f.write("BASEDIR=" + baseDir + "\n\n")
                f.write("# From constants.py\n")
                f.write("RAWDIR=" + rawDir + "\n\n")
                f.write("# From Sealog\n")
                f.write("CRUISEID=" + cruise['cruise_id'] + "\n\n")
                f.write("# From Sealog\n")
                f.write("NAVG_CRUISEID=" + cruise['cruise_id'] + "\n\n")
                f.write("# From Sealog cruise record\n")
                f.write("DATES=(\n  \"" + "\"\n  \"".join(dates) + "\"\n)\n\n")
                f.write("# Start of template rsync_cruise_by_day.template\n\n")
                for line in t:
                    f.write(line)
                f.write("\n\n# Return the directory where the script was called from\n")
                f.write("cd ${_D}\n")


        st = os.stat(scriptPath)
        os.chmod(scriptPath, st.st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)

    except Exception as e:
        print("ERROR: Could not build script:", scriptPath)
        print(e)


scriptFN = cruiseBackupDataRsyncScriptName.replace('<cruise_id>', cruise['cruise_id'])
scriptPath = os.path.join(scriptDir_proc, scriptFN)

if not os.path.isfile(scriptPath) or build_confirmation_menu("\nRsync script: " + scriptFN + ", already exists.  Rebuild it?", defaultResponse=False):

    print("Building", scriptFN + "...")
    try:

        template = os.path.join(templatesDir, "rsync_cruise_data_to_backups.template")
        with open(template) as t:
            with open(scriptPath, "w") as f:
                f.write("#!/bin/bash\n")
                f.write("# ---------------------------------------------------------------\n")
                f.write("# Rsync's cruise data to the specified destinations              \n")
                f.write("# ---------------------------------------------------------------\n")
                f.write("\n")
                f.write("# Directory where the script is being run from\n")
                f.write("_D=\"$(pwd)\"\n\n")
                f.write("# From constants.py\n")
                f.write("BASEDIR=" + baseDir + "\n\n")
                f.write("# From Sealog\n")
                f.write("CRUISEID=" + cruise['cruise_id'] + "\n\n")
                f.write("# Start of template rsync_cruise_data_to_backups.template\n\n")
                for line in t:
                    f.write(line)
                f.write("\n\n# Return the directory where the script was called from\n")
                f.write("cd ${_D}\n")

        st = os.stat(scriptPath)
        os.chmod(scriptPath, st.st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)

    except Exception as e:
        print("ERROR: Could not build script:", scriptPath)
        print(e)

    scriptFN = cruisePullHourlyDataRsyncScriptName.replace('<cruise_id>', cruise['cruise_id'])
    scriptPath = os.path.join(scriptDir_proc, scriptFN)

if not os.path.isfile(scriptPath) or build_confirmation_menu("\nRsync script: " + scriptFN + ", already exists.  Rebuild it?", defaultResponse=False):

    print("Building", scriptFN + "...")
    try:

        template = os.path.join(templatesDir, "rsync_last_hour.template")
        with open(template) as t:
            with open(scriptPath, "w") as f:
                f.write("#!/bin/bash\n")
                f.write("# ---------------------------------------------------------------\n")
                f.write("# Rsync's last hour of data to the specified destinations              \n")
                f.write("# ---------------------------------------------------------------\n")
                f.write("\n")
                f.write("# Directory where the script is being run from\n")
                f.write("_D=\"$(pwd)\"\n\n")
                f.write("# From constants.py\n")
                f.write("BASEDIR=" + baseDir + "\n\n")
                f.write("# From constants.py\n")
                f.write("RAWDIR=" + rawDir + "\n\n")
                f.write("# From Sealog\n")
                f.write("CRUISEID=" + cruise['cruise_id'] + "\n\n")
                f.write("# From Sealog\n")
                f.write("NAVG_CRUISEID=" + cruise['cruise_id'] + "\n\n")
                f.write("# Start of template rsync_last_hour.template\n\n")
                for line in t:
                    f.write(line)
                f.write("\n\n# Return the directory where the script was called from\n")
                f.write("cd ${_D}\n")

        st = os.stat(scriptPath)
        os.chmod(scriptPath, st.st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)

    except Exception as e:
        print("ERROR: Could not build script:", scriptPath)
        print(e)

print("\nDone!")