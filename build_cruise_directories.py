#!/usr/bin/env python3

import json
import sys
import datetime
import shutil
import os

sys.path.append('.')

from sealog import Sealog
from constants import baseDir, cruiseSubDirs, loweringBaseDir, loweringSubDirs, otherLoweringBaseDirs
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
    if build_confirmation_menu("Cruise Directory: " + cruiseDir + ", does not exists.  Create it?", defaultResponse=True):
        try:
            print('Creating Cruise Directories:')
            print(' +', cruiseDir)
            os.mkdir(cruiseDir)
            for subDir in cruiseSubDirs:
                proc_subDir = subDir.replace("<cruise_id>", cruise['cruise_id'])
                print('   -', '.../' + os.path.join(cruise['cruise_id'], proc_subDir))
                os.makedirs(os.path.join(cruiseDir, proc_subDir))

        except:
            print("Unable to create cruise directory structure.  Please verify the base directory", baseDir, "exists and the current user has write permissions.")
            print("Quitting...")
            sys.exit(1)

    else:
        print("Quitting...")
        sys.exit(0)

lowering = Sealog.build_lowering_select_menu(cruise['cruise_id'], newest=True)
if not lowering:
    print("Quitting...")
    sys.exit(0)

loweringDir = os.path.join(cruiseDir, loweringBaseDir, lowering['lowering_id'])
if not os.path.isdir(loweringDir):
    if build_confirmation_menu("Lowering Directory: " + loweringDir + ", does not exists.  Create it?", defaultResponse=True):
        try:
            print('Creating Lowering Directories:')
            print(' +', loweringDir)
            os.mkdir(loweringDir)

        except:
            print("Unable to create lowering directory.  Please verify the base directory", os.path.join(cruiseDir, loweringBaseDir), "exists and verify the current user has write permissions.")
            print("Quitting...")
            sys.exit(1)

        for subDir in loweringSubDirs:
            proc_subDir = subDir.replace("<cruise_id>", cruise['cruise_id'])
            proc_subDir = proc_subDir.replace("<lowering_id>", lowering['lowering_id'])
            print('   -', '.../' + os.path.join(lowering['lowering_id'], proc_subDir))

            try:
                os.makedirs(os.path.join(loweringDir, proc_subDir))
            except:
                print("Unable to create lowering subdirectory.  Please verify the lowering directory", loweringDir, "exists and verify the current user has write permissions.")
                print("Quitting...")
                sys.exit(1)


        print('\nCreating other Lowering Base Directories:')
        for otherLoweringBaseDir in otherLoweringBaseDirs:
            print(' +', os.path.join(cruiseDir, otherLoweringBaseDir, lowering['lowering_id']))

            try:
                os.makedirs(os.path.join(cruiseDir, otherLoweringBaseDir, lowering['lowering_id']))

            except:
                print("Unable to create the lowering directory:", os.path.join(cruiseDir, otherLoweringBaseDir, lowering['lowering_id']) + ". Please verify the base directory", os.path.join(cruiseDir, otherLoweringBaseDir), "exists and verify the current user has write permissions.")
                print("Quitting...")
                sys.exit(1)

            if otherLoweringBaseDir == "H264Recordings":

                for h264SubDir in ["Metadata", "Subtitles", "Videos"]:
                    print(' +', os.path.join(cruiseDir, otherLoweringBaseDir, lowering['lowering_id'], h264SubDir))

                    try:
                        os.makedirs(os.path.join(cruiseDir, otherLoweringBaseDir, lowering['lowering_id'], h264SubDir))

                    except:
                        print("Unable to create the lowering directory:", os.path.join(cruiseDir, otherLoweringBaseDir, lowering['lowering_id'], h264SubDir) + ". Please verify the base directory", os.path.join(cruiseDir, otherLoweringBaseDir), "exists and verify the current user has write permissions.")
                        print("Quitting...")
                        sys.exit(1)


    else:
        print("Quitting...")
        sys.exit(0)


print("\nDone!!")


