% This script is a prototype for Jason ops and is customized to run in
% /home/jhowland/dslppJason. Derived from Scott McCues jason_797.m
% jch 11 April 2015


%% Start with a clean slate. As development matures, test processing by ceasing to
%  remove apriori .mat files. It's probably a good idea to purge desktop
%  instances of variables even through maturation.


!rm *dep.mat
!rm *dvz.mat
!rm *dvl.mat
!rm *gvx.mat


dvz=[];clear dvz;
dep=[];clear dep;
dvl=[];clear dvl;
gvx=[];clear gvx;

close all

%% Set these things by hand until a mechanism like Sentry has for writing out a
%  mission plan is in place.

m.mission_name=803;
% Get origin from DVZ records fields 23 and 24.
% grep -h ^DVZ YYYYmmDD_HHMMSS.DAT | cut -d' ' -f23,24
m.orglat=-31.200000;
m.orglon=-179.133333;
npath='/data/RR1506_nav/'    
%svp_path='/Users/scotty/Desktop/Jason/Data/RR1413_Moyer14/svp/'

%% Obtain time metadata as usual, e.g., from watchstander comments,
%  virtual van, etc. "Survey start" same as "on bottom".
launch_ymdhms = [2015 03 31 11 14 00];
survey_start_ymdhms = [2015 03 31 12 01 00];
ascent_start_ymdhms = [2015 03 31 22 16 00];
surface_ymdhms = [2015 03 31 23 30 00];

%% Shouldn't need to change anything after this point.

divenumber=m.mission_name;
orglat = m.orglat;
orglon = m.orglon;
vehicle_name=m.vehicle;
save('divenumber.mat', 'divenumber');
save('vehicle_name.mat','vehicle_name'); 

a=launch_ymdhms;
mission_times.launch_t= ymdhms_to_sec(a(1), a(2), a(3), a(4), a(5), a(6));

a=survey_start_ymdhms;
mission_times.survey_start_t= ymdhms_to_sec(a(1), a(2), a(3), a(4), a(5), a(6));

a=ascent_start_ymdhms;
mission_times.ascent_start_t= ymdhms_to_sec(a(1), a(2), a(3), a(4), a(5), a(6));

a=ascent_start_ymdhms;
mission_times.survey_end_t= ymdhms_to_sec(a(1), a(2), a(3), a(4), a(5), a(6));

a=surface_ymdhms;
mission_times.surface_t= ymdhms_to_sec(a(1), a(2), a(3), a(4), a(5), a(6));

t_launch = mission_times.launch_t
t_on_deck = mission_times.surface_t

%% End of setup. Start crunching numbers.

%% DEP 
% SJM 3/2015 depth is not included in the same records as Sentry.
% A customized read_dep is needed. Made a new entry in a jason-
% specific version of load_dir_struct.m.
if (exist(sprintf('%s_dep.mat',make_dive_name()),'file'))
  load (sprintf('%s_dep.mat',make_dive_name()))
else
  dep=load_dirstruct(npath,'DAT','JDEP',t_launch,t_on_deck);
  eval(sprintf('save %s_dep dep',make_dive_name()));
end

% SJM 3/2015 Determine mission times directly rather than using
% the graphical tool Sentry uses.

[t1, i] = find_nearestIndex(mission_times.launch_t, dep.t);
mission_times.launch_tm = dep.tm(i);

[t1, i] = find_nearestIndex(mission_times.survey_start_t, dep.t);
mission_times.survey_start_tm = dep.tm(i);

[t1, i] = find_nearestIndex(mission_times.ascent_start_t, dep.t);
mission_times.ascent_start_tm = dep.tm(i);

[t1, i] = find_nearestIndex(mission_times.survey_end_t, dep.t);
mission_times.survey_end_tm = dep.tm(i);

[t1, i] = find_nearestIndex(mission_times.surface_t, dep.t);
mission_times.surface_tm = dep.tm(i);

eval(sprintf('save jason%d_org orglat orglon',divenumber))
eval(sprintf('save jason%d_mission_times mission_times', divenumber));

% 2014/04/29 DY
% gps offsets are applied in navest now, so they should be zero here
usblcfg.gps_offset = [0 0 0]';
% 2014/04/29 DY
% sometimes the usblcfg origin is wrong, this will save it properly
% from the value in the planning file (primary)
usblcfg.orglat = orglat; 
usblcfg.orglon = orglon; 
% save the updated usblcfg structure
cmd = sprintf('save jason%d_usblcfg usblcfg',divenumber);
eval(cmd);

%2014-01-31 CLK add a flag to confirm the use of the new nav string from
%topside navest.  Hopefully leaves the use of ATSASCII from DVLNAV and
%would only require new parsing to make it work for topside navest
vfr=1;
navpp_param.heading_offset = 0*pi/180;
navpp_param.pitch_offset=0*pi/180;
navpp_param.roll_offset=0*pi/180;
% solution parameters
navpp_param.descent_high_freq=1;
navpp_param.descent_low_freq=1;
navpp_param.on_bottom_high_freq=1;
navpp_param.on_bottom_low_freq=1;
navpp_param.ascent_high_freq=1;
navpp_param.ascent_low_freq=1;
navpp_param.read_dvlnav_raw=0;
navpp_param.usbl_dr_filter_on=1;
navpp_param.usbl_dr_filter_max_range=1500;
navpp_param.usbl_dr_filter_max_diff=[500,200,100];
%navpp_param.xmin=0;
%navpp_param.xmax = 100000;
%navpp_param.ymin = 00;
%navpp_param.ymax = 100000;
% dvl fixes with v velocity greater than this are "fixed"
navpp_param.max_v_allowed=1000;
cmd = sprintf('save jason%d_navpp_param navpp_param',divenumber);
eval(cmd);
%% LOAD DATA
curdir = pwd;
if(~exist('dvz'))
  fprintf('load_jason_minimal\n');
  load_jason_minimal;
end
%% time to check for big jumps in time in the dvl data
bigJumps = find(dvl.time_since_last_ping_dvl > 2.0);

dvl.time_since_last_ping_dvl(bigJumps) = 0.5;

%% GVX - 2012-04-27 JCK - in dvlnav this is the oct string
 if (exist(sprintf('%s_gvx.mat',make_dive_name()),'file'))
   load (sprintf('%s_gvx.mat',make_dive_name()))
 else
%  octans=load_dirstruct(npath,'DAT','DOCT',t_launch,t_on_deck);
  gvx=load_dirstruct(npath,'DAT','GVX',t_launch, t_on_deck);
  eval(sprintf('save %s_gvx gvx',make_dive_name()));
end

% find the oldest rnv
dd = dir('*rnv.mat');
if(length(dd) > 0)
  load(dd(1).name);
  geopos_rnv_old = geopos_rnv;
  rnv_old = rnv;
else
  fprintf('no rnv files found\n');
end


% read in gps
%gps = read_vprship_fromdir('../raw/topside-nav/');
% SJM 4/2105 
gps = load_vprgps_jason(npath);
ind = find((gps.t > mission_times.launch_t) & (gps.t < mission_times.surface_t));
gps = structextract(gps, ind);

%% convert DVZ to DRPP (Dead Reckoning Post Processing)
%% what the hell?  dont use dvz's for anything, they are contaminated by resets on Jason!  jch


dvz.sensor_depth = dvz.z;
% SJM svp is special jason case, ingested by load_jason_minimal
%dvz=add_jason_svp_to_dvz(dvz,svp);

drpp = dvz2drpp(dvz); 
% interpolate the dvl velocity error onto the drpp timebase
% negative error indicates 3 beams (no error computation possible)
ind = find(dvl.bottom_vel(:,4) > 0);
drpp.dvl_error = interpend(dvl.t(ind),dvl.bottom_vel(ind,4),drpp.t); 
cmd = sprintf('load jason%03d_usblcfg',divenumber);
eval(cmd);
%% get DVLNAV ini file
% SJM- more work needed here to replace the INI.M when DVLNav is no longer
% used.
navcfg = get_most_recent_dvlnav_ini(); 
%cd(curdir)
[dvlRenav, pns] = renav_dvl(dvl,navcfg);
%% RENAV all USBL data
%load the ats ascii, gpgga, prdid and dvlnav sps data from scratch
%if(vfr)
%    topsidenavpath = '../raw/topside-nav/';
%else
%    topsidenavpath = '../raw/dvlnav';
%end
%cd(topsidenavpath)
% 2013/05/22 DY added beacon number from config
%%%%%[ats,gps,gyro,sps] = load_ats_usbl_data(usblcfg.beacon_num); 

if(vfr);
     fprintf('using navest vfr records')
     geopos_rnv=load_vfr_usbl_data_jason(vehicle_name);
     vehIndices = find(geopos_rnv.veh_id == 0);
     geopos_rnv = structextract(geopos_rnv,vehIndices);
     geopos_rnv.orglat=orglat;
     geopos_rnv.orglon=orglon;
     cd(curdir)
     [x,y]=ll2xy(geopos_rnv.lat,geopos_rnv.lon,geopos_rnv.orglat, ...
 		geopos_rnv.orglon);
     geopos_rnv.pos=[x,y,geopos_rnv.depth];
     if(isfield(navpp_param,'xmin'))
       ind = find( (x > navpp_param.xmin) &  ...
 		  (x < navpp_param.xmax) &  ...
 		  (y > navpp_param.ymin) & ...
 		  (y < navpp_param.ymax));
       geopos_rnv = structextract(geopos_rnv,ind);
     end
     % 
     ind = find((geopos_rnv.t > mission_times.launch_t) & (geopos_rnv.t < mission_times.surface_t));
     geopos_rnv = structextract(geopos_rnv,ind);
     geopos_rnv=time_fixup(geopos_rnv);
     fprintf('got geopos_rnv from vfr data\n');
     %keyboard
else
   sprintf('vfr flag not set')  
   %if(navpp_param.read_dvlnav_raw | ~exist('ats'))
     %fprintf('load ats_usbl_data\n');
     %[ats_raw,gps,gyro,sps] = load_ats_usbl_data(usblcfg.beacon_num);
   %end
end
%   [gps.x,gps.y] = ll2xy(gps.lat,gps.lon,usblcfg.orglat,usblcfg.orglon);
%   n = length(ats_raw.t);
%   ats = ats_raw;
%   for i = 1:n,
%     R = hpr2rotation(navpp_param.heading_offset, ...
% 		     navpp_param.pitch_offset, ...
% 		     navpp_param.roll_offset);
%     % confusion about the ordering of the elements of beacon_pos
%     % read_ats_ascii says fwd, stbd, down
%     % looking at the data, it looks stbd, fwd, down (uvw)
%     ats.beacon_pos(i,:) = (R*ats_raw.beacon_pos(i,:)')';
%   end
%   if(exist('sps'))
%     spsorg = sps;
%   end
%   cd(curdir)
%   
%   
%   %geopos_rnv = renav_usbl_from_ats_ascii(ats,gps,gyro,usblcfg,sps);
%   % check for day wrap-around
%   ind = find(geopos_rnv.t > mission_times.launch_t);
%   geopos_rnv = structextract(geopos_rnv,ind);
%   geopos_rnv = time_fixup(geopos_rnv);
%   %keep only the data between launch and recovery
%   fprintf('extracting from %s to %s\n', ...
% 	  tm_to_hms_string(mission_times.launch_tm), ...
% 	  tm_to_hms_string(mission_times.recovery_tm));
%   [gyro,ats,gps,geopos_rnv] = navextract(mission_times.launch_t, ...
% 					 mission_times.recovery_t,...
% 					 gyro,ats,gps,geopos_rnv);
%   % check if we have a kill file
%   if(exist('kill_points.mat'))
%     load kill_points
%     ind = zeros(length(xy),1);
%     fprintf('killing %d points\n',length(ind));
%     for i = 1:length(xy)
%       [xx,ind(i)] = min( sqrt( (geopos_rnv.pos(:,1)-xy(i,1)).^2 + ...
% 			       (geopos_rnv.pos(:,2)-xy(i,2)).^2));
%     end
%     geopos_rnv.pos(ind,1) = NaN*ones(size(ind));
%     ind = find(~isnan(geopos_rnv.pos(:,1)));
%     geopos_rnv = structextract(geopos_rnv,ind);
%   end
% end

% DESCENT 
% get descent times
fprintf('Descent stanza\n');
tstart = mission_times.launch_t;
tend = mission_times.survey_start_t;

%choose renav method
switch navpp_param.descent_high_freq
    case 1
        drpp1 = navextract(tstart,tend,dvlRenav);
    case 2
        error('Option not implemented'); 
    case 3
        error('Option not implemented'); 
    otherwise 
        error('Option not implemented'); 
end


switch navpp_param.descent_low_freq
 case 1
  fprintf('using USBL for descent low frequency source\n');
  geopos_rnv_desc = navextract(tstart,tend,geopos_rnv); 
 case 2
  error('Option not implemented');
 case 3
  error('Option not implemented');
 otherwise 
  error('Option not implemented'); 
end

%% ON_BOTTOM
%get on-bottom times
tstart = mission_times.survey_start_t
tend = mission_times.ascent_start_t

switch navpp_param.on_bottom_high_freq
 case 1
  fprintf('using dvl for on-bottom high frequency component\n');
  dvl_bottom = navextract(tstart,tend,dvlRenav); 
  [drpp2,dvl_renav2] = sentry_do_dvl_renav(dvl_bottom,navcfg);
 case 2
  error('Option not implemented');
 otherwise 
  error('Option not implemented'); 
end

switch navpp_param.on_bottom_low_freq
 case 1
  fprintf('using USBL for on-bottom low frequency component\n');
  geopos_rnv_bot = navextract(tstart,tend,geopos_rnv);
 case 2
  error('Option not implemented');
 case 3
  error('Option not implemented');
 otherwise 
  error('Option not implemented'); 
end

% %% ASCENT
% %get ascent times
% tstart = mission_times.survey_end_t;
% tend = mission_times.survey_end_t+10;
% 
% %choose renav method
% switch navpp_param.ascent_high_freq
%  case 1
%   fprintf('using model velocities for ascent high frequency component\n');
%   drpp3 = navextract(tstart,tend,drpp);
%  case 2
%   error('Option not implemented'); 
%  case 3
%   error('Option not implemented'); 
%  otherwise 
%   error('Option not implemented'); 
% end
% 
% switch navpp_param.ascent_low_freq
%  case 1
%   fprintf('using USBL for ascent low frequency component\n');
%   geopos_rnv_asc = navextract(tstart,tend,geopos_rnv);
%  case 2
%   error('Option not implemented');
%  case 3
%   error('Option not implemented');
%  otherwise 
%   error('Option not implemented'); 
% end
%  %keyboard
% %% LINK DEAD RECKONING DESCENT, ON-BOTTOM, ASCENT
% cat_drpp;
% dvl = cleanup_dvl(dvl,dvz,gvx,navpp_param.max_v_allowed);
% drpp = dvl;
% drpp.pos = [dvl.x2,dvl.y2,interpend(dep.t,dep.depth,dvl.t)];
% %% LINK LOW FREQUENCY SOLUTION
% geopos_rnv = structcat(geopos_rnv_desc,geopos_rnv_bot);

% geopos_rnv = structcat(geopos_rnv,geopos_rnv_asc);

%close all
ind = find( (geopos_rnv.tm > mission_times.survey_start_tm) & ...
	    (geopos_rnv.tm < mission_times.survey_end_tm));
geopos_rnv0 = structextract(geopos_rnv,ind);
ind = find( (dvl_renav2.tm > mission_times.survey_start_tm) & ...
	    (dvl_renav2.tm < mission_times.survey_end_tm));
drpp0 = structextract(dvl_renav2,ind);
geopos_rnv0.drpp_pos=zeros(size(geopos_rnv0.pos));
geopos_rnv0.drpp_pos(:,1) = interpend(dvl_renav2.t,dvl_renav2.pos(:,1),geopos_rnv0.t);
geopos_rnv0.drpp_pos(:,2) = interpend(dvl_renav2.t,dvl_renav2.pos(:,2),geopos_rnv0.t);
dx = geopos_rnv0.pos(:,1)-geopos_rnv0.drpp_pos(:,1);
dy = geopos_rnv0.pos(:,2)-geopos_rnv0.drpp_pos(:,2);
%% CLEAN USBL
if(1)
  fprintf('automated usbl filtering\n');
  if(vfr)
    ats = geopos_rnv;
    ats.lat = interpend(gps.t,gps.lat,ats.t);
    ats.lon = interpend(gps.t,gps.lon,ats.t);
    ats.beacon_pos = zeros(length(ats.t),3);
    [ats.beacon_pos(:,1),ats.beacon_pos(:,2)] = ...
        ll2xy(ats.lat,ats.lon,orglat,orglon);

  else
  geopos_rnv = filter_usbl_by_dr(geopos_rnv0,ats,drpp0,navpp_param);
  end
  navpp_param.dr_xoffset = median(dx);
  navpp_param.dr_yoffset = median(dy);
%  ind_error = find(drpp2.dvl_error > 0.05);
  plot(geopos_rnv0.pos(:,1),geopos_rnv0.pos(:,2),'k.', ...
       geopos_rnv.pos(:,1),geopos_rnv.pos(:,2),'g.', ...
       drpp2.pos(:,1)+navpp_param.dr_xoffset, ...
       drpp2.pos(:,2)+navpp_param.dr_yoffset,'b.');
  axis equal
  grid on
end
%geopos_rnv0
%drpp0
[geopos_rnv,dr]=match_dr_to_usbl(geopos_rnv0,dvl_renav2,20,50);
plot(geopos_rnv0.pos(:,1),geopos_rnv0.pos(:,2),'r.', ...
     geopos_rnv.pos(:,1),geopos_rnv.pos(:,2),'g.', ...
     dr.pos(:,1),dr.pos(:,2));
axis equal
grid on
%% COMPLEMENTARY FILTER
cf_ok = 0;
default_cutoff = 1e-4;
while cf_ok ~= 1
    cutoff_freq = input('Enter complementary filter cutoff frequency (enter 0 for default 1e-4):');
    if(cutoff_freq==0)
        cutoff = default_cutoff;
    else
        cutoff = cutoff_freq;
    end
    cf = do_complementary_filter(geopos_rnv,drpp2,0,cutoff);
    navpp_param_cf = navpp_param;
    navpp_param_cf.heading_offset=0;
    navpp_param_cf.pitch_offset=0;
    navpp_param_cf.roll_offset=0;
    % turn this off for now
    navpp_param_cf.usbl_dr_filter_max_diff=[1000];
    % do the flyer rejection again using the cf solution
    %geopos_rnv = filter_usbl_by_dr(geopos_rnv,ats,cf,navpp_param_cf);
    navpp_param.cf_cutoff = cutoff;
    str = input('Reapply filter with different cutoff? <y/n> :','s');
    switch lower(str)
        case 'y'
            cf_ok = 0;
        case 'n'
            cf_ok = 1;
        otherwise
            cf_ok = 1;
    end
end
%% SAVE RENAV DATA
% make certain that the 3rd argument is dep, not pkd
rnv = make_rnv(cf,gvx,dep,dvz,usblcfg.orglat,usblcfg.orglon);
%plot_rnv(geopos_rnv,rnv); 
fname_base = make_postproc_fname();
navpp_param.fname_base = fname_base;
rnv.fname_base = fname_base;
save_rnv(rnv,geopos_rnv);

query = input('save raw? (y or n): ','s');
if(query=='y')
  
  cmd = sprintf('save %s_renav navpp_param gps rnv drpp cf geopos_rnv', ...
		fname_base);
  eval(cmd);
end


