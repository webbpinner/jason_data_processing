#!/usr/bin/env python3

import json
import sys
import datetime
import os
import shutil
import stat
import math

sys.path.append('.')

from sealog import Sealog
from constants import baseDir, rawDir, procDir, loweringBaseDir, loweringPullHourlyFilesToProcDataScriptName, loweringBuildByDatatypeFilesScriptName, loweringBuildLoweringFilesScriptName, loweringProcHighlighsScriptName, loweringRenameSulisScriptName, binDir, scriptDir, additionalScriptsDir, templatesDir, dslogDataTypes
from utils import build_confirmation_menu

Sealog = Sealog()

cruise = Sealog.build_cruise_select_menu(newest=True)
if not cruise:
    print("Quitting...")
    sys.exit(0)

lowering = Sealog.build_lowering_select_menu(cruiseID=cruise['cruise_id'], newest=True)
if not lowering:
    print("Quitting...")
    sys.exit(0)

scriptDir_proc = os.path.join(os.path.expanduser(scriptDir).replace('<cruise_id>', cruise['cruise_id']), lowering['lowering_id'])

if not os.path.isdir(scriptDir_proc):
    if build_confirmation_menu("Script Directory: " + scriptDir_proc + ", does not exists.  Create it?", defaultResponse=True):
        try:
            print('Creating Script Directory:')
            print(' +', scriptDir_proc)
            os.makedirs(scriptDir_proc, exist_ok=True)

        except:
            print("Unable to create script directory.  Please verify the current user has write permissions to the parent directory.")
            print("Quitting...")
            sys.exit(1)

    else:
        print("Quitting...")
        sys.exit(0)

print("")

# shutil.copytree(additionalScriptsDir, scriptDir_proc + '/additional_scripts')
for root, dirs, files in os.walk(additionalScriptsDir):
    dst_dir = root.replace(additionalScriptsDir, scriptDir_proc + '/additional_scripts', 1)
    if not os.path.exists(dst_dir):
        os.makedirs(dst_dir)
    for file_ in files:
        src_file = os.path.join(root, file_)
        dst_file = os.path.join(dst_dir, file_)
        if os.path.exists(dst_file):
            # in case of the src and dst are the same file
            if os.path.samefile(src_file, dst_file):
                continue
            os.remove(dst_file)
        shutil.copy2(src_file, dst_dir)

scriptFN = loweringPullHourlyFilesToProcDataScriptName.replace('<lowering_id>', lowering['lowering_id'])
scriptPath = os.path.join(scriptDir_proc, scriptFN)

if not os.path.isfile(scriptPath) or build_confirmation_menu("\n" + scriptFN + " already exists.  Rebuild it?", defaultResponse=False):

    loweringStart = datetime.datetime.strptime(lowering['start_ts'], "%Y-%m-%dT%H:%M:%S.%fZ")
    loweringStop = datetime.datetime.strptime(lowering['stop_ts'], "%Y-%m-%dT%H:%M:%S.%fZ")

    delta = loweringStop - loweringStart # timedelta

    dates = []

    for i in range(delta.days + 1):

        dates.append((loweringStart + datetime.timedelta(days=i)).strftime("%Y%m%d"))


    print("Building", scriptFN + "...")
    try:

        template = os.path.join(templatesDir, "pull_hourly_by_datatype_files_to_lowering.template")
        with open(template) as t:
            with open(scriptPath, "w") as f:
                f.write("#!/bin/bash\n")
                f.write("# ---------------------------------------------------------------\n")
                f.write("# Copies the appropriate hourly files to the lowering            \n")
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
                f.write("# Start of template copy_hourly_by_datatype_files_to_lowering.template\n\n")
                for line in t:
                    f.write(line)
                f.write("\n\n# Return the directory where the script was called from\n")
                f.write("cd ${_D}\n")

        st = os.stat(scriptPath)
        os.chmod(scriptPath, st.st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)

    except Exception as e:
        print("ERROR: Could not build script:", scriptPath)
        print(e)


scriptFN = loweringBuildByDatatypeFilesScriptName.replace('<lowering_id>', lowering['lowering_id'])
scriptPath = os.path.join(scriptDir_proc, scriptFN)

if not os.path.isfile(scriptPath) or build_confirmation_menu("\n" + scriptFN + " already exists.  Rebuild it?", defaultResponse=False):

    print("Building", scriptFN + "...")

    try:

        template = os.path.join(templatesDir, "proc_dlog_files.template")
        with open(template) as t:
            with open(scriptPath, "w") as f:
                f.write("#!/bin/bash\n")
                f.write("# ---------------------------------------------------------------\n")
                f.write("# Builds the hourly by-datatype files          \n")
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
                f.write("# From constants.py\n")
                f.write("PROCDIR=" + procDir + "\n\n")
                f.write("# From Sealog Cruise Record\n")
                f.write("CRUISEID=" + cruise['cruise_id'] + "\n\n")
                f.write("# From Sealog Lowering Record\n")
                f.write("LOWERINGID=" + lowering['lowering_id'] + "\n\n")
                for line in t:
                    f.write(line)
                f.write("\n\n# Return the directory where the script was called from\n")
                f.write("cd ${_D}\n")

        st = os.stat(scriptPath)
        os.chmod(scriptPath, st.st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)

    except Exception as e:
        print("ERROR: Could not build script:", scriptPath)
        print(e)



scriptFN = loweringBuildLoweringFilesScriptName.replace('<lowering_id>', lowering['lowering_id'])
scriptPath = os.path.join(scriptDir_proc, scriptFN)

if not os.path.isfile(scriptPath) or build_confirmation_menu("\n" + scriptFN + " already exists.  Rebuild it?", defaultResponse=False):

    print("Building", scriptFN + "...")

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

        template = os.path.join(templatesDir, "build_by_lowering_datatype_files.template")
        with open(template) as t:
            with open(scriptPath, "w") as f:
                f.write("#!/bin/bash\n")
                f.write("# ---------------------------------------------------------------\n")
                f.write("# Builds the by-datatype files for the lowering                  \n")
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
                f.write("# Start of template build_by_lowering_datatype_files.template\n\n")
                for line in t:
                    f.write(line)
                f.write("\n\n# Return the directory where the script was called from\n")
                f.write("cd ${_D}\n")

        st = os.stat(scriptPath)
        os.chmod(scriptPath, st.st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)

    except Exception as e:
        print("ERROR: Could not build script:", scriptPath)
        print(e)

scriptFN = loweringProcHighlighsScriptName.replace('<lowering_id>', lowering['lowering_id'])
scriptPath = os.path.join(scriptDir_proc, scriptFN)

if not os.path.isfile(scriptPath) or build_confirmation_menu("\n" + scriptFN + " already exists.  Rebuild it?", defaultResponse=False):

    print("Building", scriptFN + "...")

    loweringStart = datetime.datetime.strptime(lowering['start_ts'], "%Y-%m-%dT%H:%M:%S.%fZ")
    loweringOnBottom = datetime.datetime.strptime(lowering['lowering_additional_meta']['milestones']['lowering_on_bottom'], "%Y-%m-%dT%H:%M:%S.%fZ") if lowering['lowering_additional_meta']['milestones'] else ""
    loweringOffBottom = datetime.datetime.strptime(lowering['lowering_additional_meta']['milestones']['lowering_off_bottom'], "%Y-%m-%dT%H:%M:%S.%fZ") + datetime.timedelta(hours=1) if lowering['lowering_additional_meta']['milestones'] else ""
    loweringStop = datetime.datetime.strptime(lowering['stop_ts'], "%Y-%m-%dT%H:%M:%S.%fZ") + datetime.timedelta(hours=1)

    try:

        template = os.path.join(templatesDir, "proc_highlight_clips.template")
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
                f.write("BINDIR=" + binDir + "\n\n")
                f.write("# From constants.py\n")
                f.write("SCRIPTDIR=" + scriptDir_proc + "\n\n")
                f.write("# From constants.py\n")
                f.write("BASEDIR=" + baseDir + "\n\n")
                f.write("# From Sealog\n")
                f.write("CRUISEID=" + cruise['cruise_id'] + "\n\n")
                f.write("# From Sealog\n")
                f.write("LOWERINGID=" + lowering['lowering_id'] + "\n\n")
                f.write("# From constants.py\n")
                f.write("PROCDIR=" + procDir + "\n\n")
                f.write("# From Sealog Lowering Record\n")
                f.write("DIVE_START=" + loweringStart.strftime("%Y%m%d%H%M") + "\n")
                f.write("DIVE_STOP=" + loweringStop.strftime("%Y%m%d%H%M") + "\n\n")
                f.write("# Start of template proc_highlight_clips.template\n\n")
                for line in t:
                    f.write(line)
                f.write("\n\n# Return the directory where the script was called from\n")
                f.write("cd ${_D}\n")

        st = os.stat(scriptPath)
        os.chmod(scriptPath, st.st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)

    except Exception as e:
        print("ERROR: Could not build script:", scriptPath)
        print(e)

scriptFN = loweringRenameSulisScriptName.replace('<lowering_id>', lowering['lowering_id'])
scriptPath = os.path.join(scriptDir_proc, scriptFN)

if not os.path.isfile(scriptPath) or build_confirmation_menu("\n" + scriptFN + " already exists.  Rebuild it?", defaultResponse=False):

    print("Building", scriptFN + "...")

    loweringStart = datetime.datetime.strptime(lowering['start_ts'], "%Y-%m-%dT%H:%M:%S.%fZ")
    loweringOnBottom = datetime.datetime.strptime(lowering['lowering_additional_meta']['milestones']['lowering_on_bottom'], "%Y-%m-%dT%H:%M:%S.%fZ") if lowering['lowering_additional_meta']['milestones'] else ""
    loweringOffBottom = datetime.datetime.strptime(lowering['lowering_additional_meta']['milestones']['lowering_off_bottom'], "%Y-%m-%dT%H:%M:%S.%fZ") + datetime.timedelta(hours=1) if lowering['lowering_additional_meta']['milestones'] else ""
    loweringStop = datetime.datetime.strptime(lowering['stop_ts'], "%Y-%m-%dT%H:%M:%S.%fZ") + datetime.timedelta(hours=1)

    try:

        template = os.path.join(templatesDir, "proc_suliscam_files.template")
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
                f.write("BINDIR=" + binDir + "\n\n")
                f.write("# From constants.py\n")
                f.write("SCRIPTDIR=" + scriptDir_proc + "\n\n")
                f.write("# From constants.py\n")
                f.write("BASEDIR=" + baseDir + "\n\n")
                f.write("# From Sealog\n")
                f.write("LOWERINGID=" + lowering['lowering_id'] + "\n\n")
                f.write("# From Sealog Lowering Record\n")
                f.write("DIVE_START=" + loweringStart.strftime("%Y%m%d%H%M") + "\n")
                f.write("DIVE_STOP=" + loweringStop.strftime("%Y%m%d%H%M") + "\n\n")
                f.write("# Start of template proc_suliscam_files.template\n\n")
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