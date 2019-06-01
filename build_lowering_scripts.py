import json
import sys
import datetime
import os
import stat
import math

sys.path.append('.')

from sealog import Sealog
from constants import baseDir, rawDir, procDir, loweringBaseDir, loweringProcDataScriptName, loweringMakeLoweringScriptName, loweringClipRenameScriptName, loweringSulisRenameScriptName, scriptDir, templatesDir, dslogDataTypes
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

lowering = Sealog.build_lowering_select_menu(cruise['cruise_id'], newest=True)
if not lowering:
    print("Quitting...")
    sys.exit(0)

loweringDir = os.path.join(cruiseDir, loweringBaseDir.replace('<cruise_id>', cruise['cruise_id']), lowering['lowering_id'])
if not os.path.isdir(loweringDir):
    print("Lowering directory not found. Quitting...")
    sys.exit(1)

scriptFN = loweringProcDataScriptName.replace('<lowering_id>', lowering['lowering_id'])
scriptPath = os.path.join(loweringDir, "scripts", scriptFN)

if not os.path.isfile(scriptPath) or build_confirmation_menu("\n" + scriptFN + " already exists.  Rebuild it?", defaultResponse=False):

    loweringStart = datetime.datetime.strptime(lowering['start_ts'], "%Y-%m-%dT%H:%M:%S.%fZ")
    loweringStop = datetime.datetime.strptime(lowering['stop_ts'], "%Y-%m-%dT%H:%M:%S.%fZ")

    delta = loweringStop - loweringStart # timedelta

    dates = []

    for i in range(delta.days + 1):

        dates.append((loweringStart + datetime.timedelta(days=i)).strftime("%Y%m%d"))


    print("\nBuilding", scriptFN + "...")
    try:

        template = os.path.join(templatesDir, "proc_lowering_by_day.template")
        with open(template) as t:
            with open(scriptPath, "w") as f:
                f.write("#!/bin/bash\n")
                f.write("# ---------------------------------------------------------------\n")
                f.write("# Processes dlog data for all days of the lowering               \n")
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
                f.write("# From constants.py\n")
                f.write("PROCDIR=" + procDir + "\n\n")
                f.write("# From Sealog\n")
                f.write("CRUISEID=" + cruise['cruise_id'] + "\n\n")
                f.write("# From Sealog\n")
                f.write("LOWERINGID=" + lowering['lowering_id'] + "\n\n")
                f.write("# From Lowering Record in Sealog\n")
                f.write("DATES=(\n  \"" + "\"\n  \"".join(dates) + "\"\n)\n\n")
                f.write("# From constants.py\n")
                f.write("DATA_TYPES=(\n  \"" + "\"\n  \"".join(dslogDataTypes) + "\"\n)\n\n")
                f.write("# Start of template proc_lowering_by_day.template\n\n")
                for line in t:
                    f.write(line)
                f.write("\n\n# Return the directory where the script was called from\n")
                f.write("cd ${_D}\n")

        st = os.stat(scriptPath)
        os.chmod(scriptPath, st.st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)

    except Exception as e:
        print("ERROR: Could not build script:", scriptPath)
        print(e)

scriptFN = loweringMakeLoweringScriptName.replace('<lowering_id>', lowering['lowering_id'])
scriptPath = os.path.join(loweringDir, "scripts", scriptFN)

if not os.path.isfile(scriptPath) or build_confirmation_menu("\n" + scriptFN + " already exists.  Rebuild it?", defaultResponse=False):

    print("\nBuilding", scriptFN + "...")

    loweringStart = datetime.datetime.strptime(lowering['start_ts'], "%Y-%m-%dT%H:%M:%S.%fZ")
    loweringOnBottom = datetime.datetime.strptime(lowering['lowering_additional_meta']['milestones']['lowering_on_bottom'], "%Y-%m-%dT%H:%M:%S.%fZ") if lowering['lowering_additional_meta']['milestones'] else ""
    loweringOffBottom = datetime.datetime.strptime(lowering['lowering_additional_meta']['milestones']['lowering_off_bottom'], "%Y-%m-%dT%H:%M:%S.%fZ") if lowering['lowering_additional_meta']['milestones'] else ""
    loweringStop = datetime.datetime.strptime(lowering['stop_ts'], "%Y-%m-%dT%H:%M:%S.%fZ")

    delta = loweringStop - loweringStart # timedelta
    filePrefixes = []

    for hour in range(math.floor(delta.seconds/3600)):
        # print("hour:", hour)
        filePrefixes.append((loweringStart + datetime.timedelta(hours=hour)).strftime("%Y%m%d_%H00"))     

    try:

        template = os.path.join(templatesDir, "make_lowering.template")
        with open(template) as t:
            with open(scriptPath, "w") as f:
                f.write("#!/bin/bash\n")
                f.write("# ---------------------------------------------------------------\n")
                f.write("# Runs make_lowering script with appropriate parameters          \n")
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
                f.write("# From constants.py\n")
                f.write("PROCDIR=" + procDir + "\n\n")
                f.write("# From Sealog Cruise Record\n")
                f.write("CRUISEID=" + cruise['cruise_id'] + "\n\n")
                f.write("# From Sealog Lowering Record\n")
                f.write("LOWERINGID=" + lowering['lowering_id'] + "\n\n")
                f.write("# From Sealog Lowering Record\n")
                f.write("DIVE_START=" + loweringStart.strftime("%Y%m%d%H%M") + "\n")
                f.write("ON_BOTTOM=" + loweringOnBottom.strftime("%Y%m%d%H%M") + "\n")
                f.write("OFF_BOTTOM=" + loweringOffBottom.strftime("%Y%m%d%H%M") + "\n")
                f.write("DIVE_STOP=" + loweringStop.strftime("%Y%m%d%H%M") + "\n\n")
                f.write("# From Sealog Lowering Record\n")
                f.write("FILE_PREFIXES=(\n  \"" + "\"\n  \"".join(filePrefixes) + "\"\n)\n\n")
                f.write("# Start of template make_lowering.template\n\n")
                for line in t:
                    f.write(line)
                f.write("\n\n# Return the directory where the script was called from\n")
                f.write("cd ${_D}\n")

        st = os.stat(scriptPath)
        os.chmod(scriptPath, st.st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)

    except Exception as e:
        print("ERROR: Could not build script:", scriptPath)
        print(e)

scriptFN = loweringClipRenameScriptName.replace('<lowering_id>', lowering['lowering_id'])
scriptPath = os.path.join(loweringDir, "scripts", scriptFN)

if not os.path.isfile(scriptPath) or build_confirmation_menu("\n" + scriptFN + " already exists.  Rebuild it?", defaultResponse=False):

    print("\nBuilding", scriptFN + "...")

    loweringStart = datetime.datetime.strptime(lowering['start_ts'], "%Y-%m-%dT%H:%M:%S.%fZ")
    loweringOnBottom = datetime.datetime.strptime(lowering['lowering_additional_meta']['milestones']['lowering_on_bottom'], "%Y-%m-%dT%H:%M:%S.%fZ") if lowering['lowering_additional_meta']['milestones'] else ""
    loweringOffBottom = datetime.datetime.strptime(lowering['lowering_additional_meta']['milestones']['lowering_off_bottom'], "%Y-%m-%dT%H:%M:%S.%fZ") + datetime.timedelta(hours=1) if lowering['lowering_additional_meta']['milestones'] else ""
    loweringStop = datetime.datetime.strptime(lowering['stop_ts'], "%Y-%m-%dT%H:%M:%S.%fZ") + datetime.timedelta(hours=1)

    try:

        template = os.path.join(templatesDir, "rsync_proc_rename_clips.template")
        with open(template) as t:
            with open(scriptPath, "w") as f:
                f.write("#!/bin/bash\n")
                f.write("# ---------------------------------------------------------------\n")
                f.write("# Processes Highlight and KiPro1080 clips for a lowering         \n")
                f.write("# ---------------------------------------------------------------\n")
                f.write("\n")
                f.write("# Directory where the script is being run from\n")
                f.write("_D=\"$(pwd)\"\n\n")
                f.write("# From constants.py\n")
                f.write("SCRIPTDIR=" + scriptDir + "\n\n")
                f.write("# From constants.py\n")
                f.write("BASEDIR=" + baseDir + "\n\n")
                f.write("# From Sealog\n")
                f.write("CRUISEID=" + cruise['cruise_id'] + "\n\n")
                f.write("# From Sealog\n")
                f.write("LOWERINGID=" + lowering['lowering_id'] + "\n\n")
                f.write("# From constants.py\n")
                f.write("PROCDIR=" + procDir + "\n\n")
                f.write("# Start of template rsync_proc_rename_clips.template\n\n")
                for line in t:
                    f.write(line)
                f.write("\n\n# Return the directory where the script was called from\n")
                f.write("cd ${_D}\n")

        st = os.stat(scriptPath)
        os.chmod(scriptPath, st.st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)

    except Exception as e:
        print("ERROR: Could not build script:", scriptPath)
        print(e)

scriptFN = loweringSulisRenameScriptName.replace('<lowering_id>', lowering['lowering_id'])
scriptPath = os.path.join(loweringDir, "scripts", scriptFN)

if not os.path.isfile(scriptPath) or build_confirmation_menu("\n" + scriptFN + " already exists.  Rebuild it?", defaultResponse=False):

    print("\nBuilding", scriptFN + "...")

    loweringStart = datetime.datetime.strptime(lowering['start_ts'], "%Y-%m-%dT%H:%M:%S.%fZ")
    loweringOnBottom = datetime.datetime.strptime(lowering['lowering_additional_meta']['milestones']['lowering_on_bottom'], "%Y-%m-%dT%H:%M:%S.%fZ") if lowering['lowering_additional_meta']['milestones'] else ""
    loweringOffBottom = datetime.datetime.strptime(lowering['lowering_additional_meta']['milestones']['lowering_off_bottom'], "%Y-%m-%dT%H:%M:%S.%fZ") + datetime.timedelta(hours=1) if lowering['lowering_additional_meta']['milestones'] else ""
    loweringStop = datetime.datetime.strptime(lowering['stop_ts'], "%Y-%m-%dT%H:%M:%S.%fZ") + datetime.timedelta(hours=1)

    try:

        template = os.path.join(templatesDir, "rename_suliscam_files.template")
        with open(template) as t:
            with open(scriptPath, "w") as f:
                f.write("#!/bin/bash\n")
                f.write("# ---------------------------------------------------------------\n")
                f.write("# Processes SulisCam still images for a lowering.               \n")
                f.write("# ---------------------------------------------------------------\n")
                f.write("\n")
                f.write("# Directory where the script is being run from\n")
                f.write("_D=\"$(pwd)\"\n\n")
                f.write("# From constants.py\n")
                f.write("SCRIPTDIR=" + scriptDir + "\n\n")
                f.write("# From constants.py\n")
                f.write("BASEDIR=" + baseDir + "\n\n")
                f.write("# From Sealog\n")
                f.write("LOWERINGID=" + lowering['lowering_id'] + "\n\n")
                f.write("# Start of template rename_suliscam_files.template\n\n")
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