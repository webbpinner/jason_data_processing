function [west, east, north, south] = get_BB_from_renav1HzTxt(fname)

% Determine west,east,north,south bounding box from Jason renav.
% Uses the <diveID>__1Hz_renav.txt file.
% This m-file is handy when a dive has to be split into subsections
% due to switches between DVLs.
% Assemble all the subsection _1Hz_renav.txt files into a single large
% one (annoying because all files have the same name).
% I did this with, e.g.,
% find . -name J2-758_1Hz_renav.txt -exec cat {} > J2-758.bb.dat \;
%
% Then "pretreat" this file to get rid of headers:
% cat J2-758.bb.dat | grep ^201 > blah.dat

struct_fields = {'yr','mo','dy','hr','min','sec','x','y', ...
    'lat','lon','utmx','utmy','depth','d1','d2','d3','d4'};

fid = fopen(fname)

a = textscan(fid, '%f/%f/%f,%f:%f:%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f');

b = cell2struct(a, struct_fields, 2);

west = min(b.lon);
east = max(b.lon);
south = min(b.lat);
north = max(b.lat);




