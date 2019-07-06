#!/usr/bin/env python
import os
import copy
from datetime import *
import time
import re
import sys

#########################   photoinfo.py  ####################################
#
# usage: python photoinfo.py [indexFile | imgFolder] navfile.ppi [outfile]
# default outfile is navfile.ppf
#
# requires python 2.6 or above
# mvanmiddle@gmail.com

############  NAV FILES
#
# nav file must contain lines in the format: 'date time lat lon depth heading pitch roll altitude'
# lines must be in order, with no duplicates.
#
# out of order lines or duplicates will not break code, but may occasionally result in 
# improper weighted averages
#
############

############ IMAGE FILES
#
# input is either an index file or folder. index file is expected to be a single column listing
# filenames. if folder is provided, all files matching *.tif are used.
#
############

############ OUTPUT
#
# Output is a .ppfx, which is a Sentry-style ppf with two additional columns: pitch and roll
#
#     YYYY/MM/DD HH:MM:SS.SSS unixTime filename lat lon heading depth altitude pitch roll
#
############

############ IMAGE FILE NAME FORMAT
#
#re_str_FMTNAME is a regex that matches filenames of given format FMTNAME
#it should contain one group, marked by parentheses, which represents the time

#time_FMTNAME is a string describing the time segment of the filename. 
#it will be used to parse the group identified by re_str_FMTNAME
#see strptime() documentation for format info

#TO ADD A NEW IMAGE FILENAME FORMAT:
# create a regex named re_str_FMTNAME
# compile using re_FMTNAME = re.compile(re_str_FMTNAME)
# create a time format time_FMTNAME
# create a tuple FMTNAME = (re_FMTNAME, time_FMTNAME)
# add the tuple FMTNAME to the list allFormats, below
#
############

#hdstills example: CAM_BS_2010Aug05_035610.93_000.tif
re_str_hdstills = 'CAM_BS_(\d{4}\w{3}\d{2}_\d{6}\.\d{2})_\d+\.tif'
re_hdstills = re.compile(re_str_hdstills)
time_hdstills = '%Y%b%d_%H%M%S.%f'

#new format for HD Stills example: RAW.20101022.025043517.0003059.tif
re_str_hdstillsnew = 'COL\.(\d{8}\.\d{9})\.\d+\.tif'
re_hdstillsnew = re.compile(re_str_hdstillsnew)
time_hdstillsnew = '%Y%m%d.%H%M%S%f'

#esc example: JAS-20100806-224236-0000814.tif
re_str_esc = 'cJAS-(\d{8}-\d{6})-\d+\.tif'
re_esc = re.compile(re_str_esc)
time_esc = '%Y%m%d-%H%M%S'

#dsc example: J2510YYMMDDmmHHSS_indexUnPadded.JPG
re_str_dsc = 'RR1413(\d{12})_\d+\.JPG'
re_dsc = re.compile(re_str_dsc)
time_dsc = '%y%m%d%H%M%S'

#new pilot cam frame grabs German 2012 example RGB.20120123_181748_780.tif
re_str_pilot = 'RGB\.(\d{8}_\d{6})_\d+\.tif'
re_pilot = re.compile(re_str_pilot)
time_pilot = '%Y%m%d_%H%M%S'

# Super Scorpio images renamed to form sscorpYYYYMMDDHHmmSS.jpg.
# SJM 3/22/2103
re_str_sscorp = 'sscorp(\d{14}).jpg'
re_sscorp = re.compile(re_str_sscorp)
time_sscorp = '%Y%m%d%H%M%S'

# sulis images renamed to form sulis_YYYYMMDDHHmmSS.jpg.
# JP 7/12/18 & SJM 2018Jul22
re_str_sulis = 'sulis_(\d{14})\.jpg'
re_sulis = re.compile(re_str_sulis)
time_sulis = '%Y%m%d%H%M%S'

# Seaplay framegrabs
# SJM 22July2018
re_str_spfg = '(\d{8}_\d{9})\.framegrab\d+\.jpg'
re_spfg = re.compile(re_str_spfg)
time_spfg = '%Y%m%d_%H%M%S%f[:-3]'

# Framegrabber (dual-input), Dec 2014, cam[12]_YYYYMMDDHHmmSS.tif
re_str_fg = 'cam._(\d{14}).tif'
re_fg = re.compile(re_str_fg)
time_fg = '%Y%m%d%H%M%S'

#create an array containing known formats. formats are stored as a 
#tuple of (regex, timeFormat). when processing a list of images, this program
#will select the format whose regex matches the first filename in the list of
#image files
hdstills = (re_hdstills, time_hdstills)
hdstillsnew = (re_hdstillsnew, time_hdstillsnew)
esc = (re_esc, time_esc)
dsc = (re_dsc, time_dsc)
pilot = (re_pilot, time_pilot)
sscorp = (re_sscorp, time_sscorp)
fg = (re_fg, time_fg)
sulis = (re_sulis, time_sulis)
spfg = (re_spfg, time_spfg)

allFormats = [hdstills,hdstillsnew,hdstills,esc,dsc,pilot,sscorp,fg,sulis]

class coord(object):
  """this is a class representing a gps coordinate, in degrees, along with a
     datetime object representing the timestamp"""
  def __init__(self, navline):
    """navline is a string in the ppi nav format:
       date time lat lon depth heading pitch roll altitude"""
    splitline = navline.split(" ")
    if splitline[1].endswith("60.000"):    #weird bug in ppi where 60 is sometimes in seconds field
      print "weird HH:MM:60.000 encountered."
      self.timestamp = datetime.strptime(splitline[0]+' '+splitline[1].split("60.")[0], "%Y/%m/%d %H:%M:")
      self.timestamp += timedelta(seconds=60)
    else:
      self.timestamp = datetime.strptime(splitline[0]+' '+splitline[1], "%Y/%m/%d %H:%M:%S.%f")
    #self.timestamp = datetime.datetime(*time.strptime(splitline[0]+' '+splitline[1], "%Y/%m/%d %H:%M:%S.%f")[0:5])
    self.lat = float(splitline[2])
    self.lon = float(splitline[3])
    self.depth = float(splitline[4])
    self.heading = float(splitline[5])
    self.altitude = float(splitline[8])
    self.pitch = float(splitline[6])
    self.roll = float(splitline[7])
#  def __init__(self, navline):
#    """navline is a string in the jason nav format:
#       date,time,localX,localY,Lat,Lon,UTMX,UTMY,depth,pitch,heading,roll,altitude"""
#    splitline = navline.split(",")
#    self.timestamp = datetime.strptime(splitline[0]+' '+splitline[1], "%Y/%m/%d %H:%M:%S.%f")
#    self.lat = float(splitline[4])
#    self.lon = float(splitline[5])
#    self.depth = float(splitline[8])
#    self.heading = float(splitline[10])
#    self.altitude = float(splitline[12])

  def __str__(self):
    return datetime.strftime(self.timestamp, '%H:%M:%S.%f')[:-3] + ' ' + str(self.lat) + ' ' + str(self.lon)

def coordAndFNameToString(c, fn, delim, extendedOutput):
  #return '{0}   {1}   {2}   {3} {4} {5} {6} {7}'.format(datetime.strftime(c.timestamp, '%Y/%m/%d   %H:%M:%S.%f'), datetimeToSeconds(c.timestamp), fn, c.lat, c.lon, c.heading, c.depth, c.altitude)
  retstr =  "{0}{8}{1:.3f}{8}{2}{8}{3:11.8f}{8}{4:11.8f}{8}{5:5.1f}{8}{6:6.3f}{8}{7:6.3f}".format(\
      datetime.strftime(c.timestamp, '%Y/%m/%d %H:%M:%S.%f')[:-3], \
      datetimeToDecSeconds(c.timestamp), fn, c.lat, c.lon, c.heading,\
      c.depth, c.altitude, delim)
  if extendedOutput:
    retstr = "{0}{3}{1:7.3f}{3}{2:6.3f}".format(retstr, c.pitch, c.roll, delim)
  #now remove any extra spaces if our delim isn't whitespace
  #if delim[0]!=" " and delim[0]!="\t":
############################################################################################################
  return retstr
    
def datetimeToDecSeconds(dt):
  return time.mktime(dt.timetuple()) + (dt.microsecond / 1000000.0)

def findFormatIndex(sampleFName):
  for i in range(len(allFormats)):
    if allFormats[i][0].search(sampleFName) != None:
      return i
  return -1

def isBefore(coord, decSeconds):
  """returns True if coord is before the timestamp of decSeconds"""
  if (decSeconds - datetimeToDecSeconds(coord.timestamp)) >= 0:
    return True
  return False

def isAfter(coord, decSeconds):
  """returns True if coord is after the timestamp of decSeconds"""
  if (decSeconds - datetimeToDecSeconds(coord.timestamp)) <= 0:
    return True
  return False

def weightedAverage(beforeCoord, afterCoord, targetSec):
  """perform a weighted average of beforeCoord and afterCoord to interpolate position 
  at t=targetSec"""
  #print "Average of ", beforeCoord, " and ", afterCoord,
  if beforeCoord == None or afterCoord == None:
    return None
  targetCoord = copy.deepcopy(beforeCoord)
  beforeSec = datetimeToDecSeconds(beforeCoord.timestamp)
  afterSec = datetimeToDecSeconds(afterCoord.timestamp)
  tdiff = afterSec - beforeSec
  if tdiff==0:
    return targetCoord
  beforeWeight = (targetSec - beforeSec) / tdiff
  afterWeight = (afterSec - targetSec) / tdiff
  targetCoord.timestamp = datetime.fromtimestamp(targetSec)
  targetCoord.lat = (beforeCoord.lat * beforeWeight) + (afterCoord.lat * afterWeight)
  targetCoord.lon = (beforeCoord.lon * beforeWeight) + (afterCoord.lon * afterWeight)
  targetCoord.altitude = (beforeCoord.altitude * beforeWeight) + (afterCoord.altitude * afterWeight)
  targetCoord.depth = (beforeCoord.depth * beforeWeight) + (afterCoord.depth * afterWeight)
  targetCoord.pitch = (beforeCoord.pitch * beforeWeight) + (afterCoord.pitch * afterWeight)
  targetCoord.roll = (beforeCoord.roll * beforeWeight) + (afterCoord.roll * afterWeight)
  if afterWeight>.5:
    targetCoord.heading = afterCoord.heading
  #print " is ", targetCoord
#'snapping' heading because a) it's harder to average, b) it changes less rapidly than other data

  return targetCoord

def findBefore(navdict, decSecs, noretry=False):
  """find item in navdict immediately preceeding decSecs"""
  key = int(decSecs*10)
  for i in range(600):
    if (key in navdict) and isBefore(navdict[key], decSecs):
      return navdict[key]
    key -= 1
  if noretry:
    return None
  print "No nav data found in 60 seconds before ",decSecs," giving up and returning after"
  return findAfter(navdict, decSecs, True)

def findAfter(navdict, decSecs, noretry=False):
  """find item in navdict immediately preceeding decSecs"""
  key = int(decSecs*10)
  for i in range(600):
    if (key in navdict) and isAfter(navdict[key], decSecs):
      return navdict[key]
    key += 1
  if noretry:
    return None
  print "No nav data found in 60 seconds after ",decSecs," giving up and returning before"
  return findBefore(navdict, decSecs, True)

def matchFilesToNav(files, navdict, lineregex, timeformat, outfile, delim, extendedOutput=False, headerOutput=False):
  print "Matching image files to nav.",
  out = open(outfile, 'w')
  if headerOutput:
    out.write("YYYY/MM/DD HH:MM:SS unixSeconds filename lat lon heading depth altitude ")
    if extendedOutput:
      out.write("pitch roll")
    out.write("\n")
  i=0
  for fname in files:
    try:
      secs = datetimeToDecSeconds(strToDatetime(fname, lineregex, timeformat))
    except Exception:
      print "Invalid filename line ", files.index(fname) + 1, ": \"", fname, "\" skipping."
      continue #skip this file
    avg = weightedAverage(findBefore(navdict, secs), findAfter(navdict, secs), secs)
    if avg == None:
      print "Found no nav data for image file", fname
      continue
    line = coordAndFNameToString(avg, fname, delim, extendedOutput)
    out.write(line + "\n")
    i += 1
    if (i%100) == 0:
      sys.stdout.write(".")
      sys.stdout.flush()
  print "done."

#key is int(seconds*10), value is coordinate
def populateDictFromNavFile(path):
  infile = open(path, 'r')
  d = dict()
  i=0
  print "Processing nav data",
  for linestr in infile:
    if (i%1000)==0:
      sys.stdout.write(".")
      sys.stdout.flush()
    try:
      c = coord(linestr.strip())
      key = int(10*datetimeToDecSeconds(c.timestamp))
      d[key] = c
      i += 1
    except ValueError, e:
      print "ERROR parsing nav file: ", e
      print "line caused error:",linestr
      pass
  infile.close()
  print ""
  return d

def strToDatetime(instr, regex, timefmt):
  timestr = regex.match(instr).group(1)
#print "time string = ", timestr
  return datetime.strptime(timestr, timefmt)
  #return datetime.datetime(*time.strptime(timestr, timefmt))

def fileOrFolderToList(path, lineFormat='(\S+)'):
  """path is a path to an image index file or folder of images. if path is *.IMLOG,
     filenames will be obtained from the FOURTH column. 
     if path is an arbitrary filename,
     lineFormat is a regex that should match each valid line of the index file, 
     with a single group representing the image file name.
     if path is a file and no lineFormat is provided, it is assumed to be a single
     column of filenames"""
  if path.endswith("IMLOG"):
    lineFormat='\S+\s+\S+\s+\S+\s+(\S+).*'
  if os.path.isdir(path):
    templist = os.listdir(path)
    newlist = []
    for x in templist:
      if x.lower().endswith(".tif") or x.lower().endswith(".jpg"):
        newlist.append(x)
    return newlist
  if os.path.isfile(path):
    infile = open(path, 'r')
    fnamelist = []
    lineregex = re.compile(lineFormat)
    for line in infile:
      try:
        thisname = lineregex.match(line.strip()).group(1)
        if thisname.lower().endswith(".tif") or thisname.lower().endswith(".jpg"):
          fnamelist.append(thisname)
      except Exception:
        print "line does not appear to be a valid file listing: ", line.strip()
    return fnamelist
  print "error: path is neither file nor directory"
  return []

if __name__ == "__main__":
  if len(sys.argv) < 3:
    print "usage: python photoinfo.py [-xh] img=[indexFile | imgFolder] nav=navfile.ppi [out=outfile.ppf delim=\"   \"]"
    print "\tdefault outfile is navfile.ppf"
    exit(0)
  print sys.argv
  out = None
  img = None
  nav = None
  extendedOutput = False
  headerOutput = True
  delim = "   "
  for arg in sys.argv[1:]:
    if "=" in arg: #add quotes, then run arg as assignment of variable
      #print arg.replace("=","=\"") + "\""
      exec(arg.replace("=","=\"") + "\"")
    if arg[0] == '-':
      for char in arg[1:]:
        if char == "x":
          extendedOutput = True
        if char == "h":
          headerOutput = True
  
  if img==None or nav==None:
    print "usage: python photoinfo.py [-xh] img=[indexFile | imgFolder] nav=navfile.ppi [out=outfile.ppf delim=\"   \"]"
    exit()
  if out == None:
    try:
      if extendedOutput:
        out = img.split(".")[0] + ".ppfx"
      else:
        out = img.split(".")[0] + ".ppf"
    except Exception, e:
      outfile = "DEFAULT.ppf"
  flist = fileOrFolderToList(img)
  if len(flist) == 0:
    print "No matching files found"
    exit()

  index = findFormatIndex(flist[0])
  if index == -1:
    print "First image file", flist[0], "matched no known image filename formats. Please add appropriate regex to script"
    exit()
  else:
    print "Auto-detected file format #" + str(index)

  navdict = populateDictFromNavFile(nav)
  matchFilesToNav(sorted(flist), navdict, allFormats[index][0], allFormats[index][1], out, delim, extendedOutput, headerOutput)
