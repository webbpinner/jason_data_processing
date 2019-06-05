import json
import sys
import datetime
import os
import stat

sys.path.append('.')

from sealog import Sealog
from constants import baseDir, rawDir, cruiseDataRsyncScriptName, cruiseDataBackupRsyncScriptName, scriptDir, templatesDir
from utils import build_confirmation_menu

Sealog = Sealog()

if not os.path.isdir(baseDir):
    print("ERROR: Base Directory '" + baseDir + "' does not exist.")
    print("Quitting...")
    sys.exit(1)

cruise = Sealog.build_cruise_select_menu(newest=True)
if not cruise:
    print("Quitting...")
    sys.exit(0)

cruiseDir = os.path.join(baseDir, cruise['cruise_id'])
if not os.path.isdir(cruiseDir):
    print("Cruise directory not found. Quitting...")
    sys.exit(1)

scriptFN = cruiseDataRsyncScriptName.replace('<cruise_id>', cruise['cruise_id'])
scriptPath = os.path.join(cruiseDir, "scripts", scriptFN)

if os.path.isfile(scriptPath) and not build_confirmation_menu("\nRsync script: " + scriptFN + ", already exists.  Rebuild it?", defaultResponse=False):
    print("Quitting...")
    sys.exit(0)

cruiseStart = datetime.datetime.strptime(cruise['start_ts'], "%Y-%m-%dT%H:%M:%S.%fZ")
cruiseStop = datetime.datetime.strptime(cruise['stop_ts'], "%Y-%m-%dT%H:%M:%S.%fZ")

delta = cruiseStop - cruiseStart # timedelta

dates = []

for i in range(delta.days + 1):

    dates.append((cruiseStart + datetime.timedelta(days=i)).strftime("%Y%m%d"))


print("\nBuilding", scriptFN + "...")
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
            f.write("SCRIPTDIR=" + scriptDir + "\n\n")
            f.write("# From constants.py\n")
            f.write("BASEDIR=" + baseDir + "\n\n")
            f.write("# From constants.py\n")
            f.write("RAWDIR=" + rawDir + "\n\n")
            f.write("# From Sealog\n")
            f.write("CRUISEID=" + cruise['cruise_id'] + "\n\n")
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


scriptFN = cruiseDataBackupRsyncScriptName.replace('<cruise_id>', cruise['cruise_id'])
scriptPath = os.path.join(cruiseDir, "scripts", scriptFN)

if os.path.isfile(scriptPath) and not build_confirmation_menu("\nRsync script: " + scriptFN + ", already exists.  Rebuild it?", defaultResponse=False):
    print("Quitting...")
    sys.exit(0)

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

print("Done!\n")