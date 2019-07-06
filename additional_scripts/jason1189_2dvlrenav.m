%% ROV Jason Renavigation Script for 2018
% Instructions have been removed intentionally to streamline
% content. They do exist, just elsewhere.
% If you dont find them, contact smccue@whoi.edu.
%

%% Manually set basic dive params. 
% Struct 'm' is used to retain these params.

% SJM 13Feb2018 Used this dive to advance the state of renavigation.
% This script is the most mature as of this date and can be used
% as a template for at-sea renav.

divenumber=1189;
m.orglat=45.91666667;
m.orglon=-130.025;
m.mission_name=divenumber
m.this_process_time=datestr(datetime('now'),'yyyymmddHHMM');
usblcfg.orglat = m.orglat; 
usblcfg.orglon = m.orglon; 

launch_ymdhms = [2019 07 03 11 34 50];
survey_start_ymdhms = [2019 07 03 12 54 38];
ascent_start_ymdhms = [2019 07 03 21 35 50];
surface_ymdhms = [2019 07 03 22 43 21];

%% Set paths to the original (raw) data files
npath='/Volumes/CruiseData/AT42-12/Vehicle/Procdata/AT42-12/J2-1189/navest/';
svel_path='/Volumes/CruiseData/AT42-12/Vehicle/Procdata/AT42-12/J2-1189/svp/';
%% Define sensor offsets here rather than deal with the INI.M file
navcfg.dvl.pos=[ -2.850000 0.630000 -0.670000 42.09 0.000000 0.000000];
%navcfg.dvl.pos=[ -2.850000 0.630000 -0.670000 315.00 0.000000 0.000000];
%navcfg.dvl.pos=[ 0.0000 0.0000 0.0000 -45.570000 0.000000 0.000000];
navcfg.octans.pos=[ 0.000000 0.000000 0.000000 0.000000 0.000000 0.000000];

%% Define limits in the northings/eastings space
navpp_param.xmin = -50000;
navpp_param.xmax = 50000;
navpp_param.ymin = -50000;
navpp_param.ymax = 50000;

%% Define upper limit on velocity computed from individual DVL pings
max_veh_vel = 5.0;
%% Special processing flags
vfr=1;    % Use VFR records in processing (provides real time nav for e.g. comparison to renav)

% PPL file renavigation
% generate_ppl_flag=0 means the file isnt written.
% 1 means a .ppl file is generated, for use with bathy processing
% or just to provide high rate (octans measurement rate) re-navigation.
% pplfilterflag=0 means no filtering, =1 means apply filter.
% filter_flag tells the PPl write routine to apply low pass filtering to
% pitch and roll histories.
% 
% Primary filter goals were:
%       - cutoff below 5 Hz (the Nyquist freq) to reduce aliasing.
%       - no phase distortion (two pass filtering zero phase)
% The filter specs are generated in the write routine.
%
% lag_value is a value in seconds to be added to the renav unix
% epoch seconds passed to the PPL generation routine. Positive value shifts
% into the future, negative into the past.
generate_ppl_flag=0;
pplfilterflag=0;
lag_value = 0.0;

subset_usbl=0;   % Use to purge known-bad USBL periods from computing renav.
% usbl_down_ymdhms = [2015 08 28 04 16 00];
% usbl_up_ymdhms = [2015 08 28 05 46 00];

% clean_dvl.m doesnt yet exist.
clean_dvl = 0;   % Use to purge known-bad DVL periods from computing renav.
% purge_start_ymdhms = [2017 01 20 20 30 00];
% purge_stop_ymdhms = [2017 01 20 21 30 00];

%% Choose to purge old data files or not. Normal script behavior is
% to save ingested paramaters as .mat files and read these files
% on subsequent runs of the script. But this might interfere with
% troubleshooting. Un-comment the file deletes below to force
% re-ingestion of previously read sensor records.

%!rm *dep.mat;
%!rm *dvl.mat
%!rm *gvx.mat % or *octans.mat
%!rm *svel.mat
%!rm *dvz.mat
%!rm *usblcfg.mat

%% Choose to purge old workspace variables. Normal script behavior is
% to purge and re-read file, whether theyre original records or .mat
% files.

dep=[];clear dep;
dvl=[];clear dvl;
gvx=[];clear gvx;
svel=[]; clear svel;

close all

%% Shouldnt need to change anything after this point.

% Cross-assign some variables to achieve some conformity between Jason and
% Sentry. Also, allow processing start/stop time to be defined
% independently. Routinely, start of renav processing is at first sight of
% bottom and stop time is the last time Jason leaves the bottom.
% 't' means unix epoch time in seconds.
t_launch=ymdhms_to_sec(launch_ymdhms(1),launch_ymdhms(2),launch_ymdhms(3),launch_ymdhms(4),launch_ymdhms(5),launch_ymdhms(6)); 
t_on_bottom=ymdhms_to_sec(survey_start_ymdhms(1),survey_start_ymdhms(2),survey_start_ymdhms(3),survey_start_ymdhms(4),survey_start_ymdhms(5),survey_start_ymdhms(6));
t_off_bottom=ymdhms_to_sec(ascent_start_ymdhms(1),ascent_start_ymdhms(2),ascent_start_ymdhms(3),ascent_start_ymdhms(4),ascent_start_ymdhms(5),ascent_start_ymdhms(6));
t_on_deck=ymdhms_to_sec(surface_ymdhms(1),surface_ymdhms(2),surface_ymdhms(3),surface_ymdhms(4),surface_ymdhms(5),surface_ymdhms(6));

mission_times.launch_t = t_launch;
mission_times.survey_start_t = t_on_bottom;
mission_times.ascent_start_t = t_off_bottom;
mission_times.survey_end_t = t_off_bottom;
mission_times.surface_t = t_on_deck;

tstart = t_on_bottom
tend = t_off_bottom

%% Save old versions of renavigation
%
% find previous processing results and and rename them with timestamp.
dd = dir('*rnv.mat');
if(length(dd) > 0)
  load(dd(1).name);
  proc_datetimestr = m.this_process_time;
  geopos_rnv=[]; clear geopos_rnv;
  rnv=[]; clear rnv;
  cmd=sprintf('mv %s %s.%s', dd(1).name, dd(1).name, proc_datetimestr);
  system(cmd)
else
  fprintf('no rnv files found\n');
end

dd = dir('*renav.mat');
if(length(dd) > 0)
  load(dd(1).name);
  proc_datetimestr = m.this_process_time;
  geopos_rnv=[]; clear geopos_rnv;
  rnv=[]; clear rnv;
  cf=[]; clear cf;
  drpp=[]; clear drpp;
  gps=[]; clear gps;
  cmd=sprintf('mv %s %s.%s', dd(1).name, dd(1).name, proc_datetimestr);
  system(cmd)
else
  fprintf('no renav files found\n');
end

%% Record processing params
vehicle_name=m.vehicle;  % I define m.vehicle in startup.m
save('divenumber.mat', 'divenumber');
save('vehicle_name.mat','vehicle_name'); 
orglat=m.orglat; orglon=m.orglon;
eval(sprintf('save jason%d_org orglat orglon',divenumber))
eval(sprintf('save jason%d_mission_times mission_times', divenumber));


%% End of setup. Start reading in measurements and crunching numbers.

%% DEPTH

if (exist(sprintf('%s_dep.mat',make_dive_name()),'file'))
  load (sprintf('%s_dep.mat',make_dive_name()))
  fprintf('Loading %s_dep.mat\n',make_dive_name())
else
  dep=load_dirstruct(npath,'DAT','JDEP',t_launch,t_on_deck);
  eval(sprintf('save %s_dep dep',make_dive_name()))
end

ind = find((dep.t > tstart) & (dep.t < tend));
dep = structextract(dep,ind);

%% GVX - 2012-04-27 JCK - in dvlnav this is the oct string
 if (exist(sprintf('%s_gvx.mat',make_dive_name()),'file'))
   load (sprintf('%s_gvx.mat',make_dive_name()))
   fprintf('Loading %s_gvx.mat\n',make_dive_name())
 else
  gvx=load_dirstruct(npath,'DAT','GVX',t_launch, t_on_deck);
  eval(sprintf('save %s_gvx gvx',make_dive_name()));
%   octans=load_dirstruct(npath,'DAT','DOCT',t_launch, t_on_deck);
%   eval(sprintf('save %s_octans octans',make_dive_name()));
end

ind = find((gvx.t > tstart) & (gvx.t < tend));
gvx = structextract(gvx,ind);

%% DVZ
 if (exist(sprintf('%s_dvz.mat',make_dive_name()),'file'))
   fprintf('Loading %s_dvz.mat',make_dive_name())
   load (sprintf('%s_dvz.mat',make_dive_name()))
   fprintf('loading %s_dvz.mat\n',make_dive_name())
 else
  fprintf('Didnt find %s_dvz.mat',make_dive_name())
  dvz=load_dirstruct(npath,'DAT','DVZ',t_launch, t_on_deck);
  eval(sprintf('save %s_dvz dvz',make_dive_name()));
end

ind = find((dvz.t > tstart) & (dvz.t < tend));
dvz = structextract(dvz,ind);

%% SOUND VELOCITY
if (exist(sprintf('%s_svel.mat',make_dive_name()),'file'))
   load (sprintf('%s_svel.mat',make_dive_name()))
   fprintf('Loading %s_svel.mat\n',make_dive_name())
 else
  svel=load_dirstruct(svel_path,'SVP','SVEL',t_launch, t_on_deck);
  eval(sprintf('save %s_svel svel',make_dive_name()));
end


%% LOAD DVLs
curdir = pwd;

% Jason typically carries two DVLs. As of 2017 they arefrom two different
% vendors, Sonardyne (Syrinx) and RDI (Pathfinder).
% They of course produce different data records. Navigators will
% use them as they see fit, swapping them at arbitray times. The
% code has to accommodate that.
% IDs
% RDI = 0
% Syrinx = 1

rdi_id=0;
syr_id=1;

 % Ingest the first (RDI) history. Add RDI ID and sound vel to struct.
if (exist(sprintf('%s_dvl_rdi.mat',make_dive_name()),'file'))
  load (sprintf('%s_dvl_rdi.mat',make_dive_name()))
  fprintf('Loading %s_dvl_rdi.mat\n',make_dive_name())
else
  dvl_rdi=load_dirstruct(npath,'DAT','DDVL',t_on_bottom, t_off_bottom);
  eval(sprintf('save %s_dvl_rdi dvl_rdi',make_dive_name()));
end

if ~isempty(dvl_rdi)
   dvl_rdi=add_jason_svel_to_dvl(dvl_rdi, svel);
   id=ones(length(dvl_rdi.t),1) .* rdi_id;
   dvl_rdi.id = id;
   dvl_rdi_select = trim_dvl(dvl_rdi, 1);
else
   dvl_rdi_select = [];
end

% The second (Syrinx). Requires addition of ID, depth, attitude, and sound speed.
if (exist(sprintf('%s_dvl_syr.mat',make_dive_name()),'file'))
  load (sprintf('%s_dvl_syr.mat',make_dive_name()))
  fprintf('Loading %s_dvl_syr.mat\n',make_dive_name())
else
  dvl_syr=load_dirstruct(npath,'DAT','RSXR',t_on_bottom, t_off_bottom);
  eval(sprintf('save %s_dvl_syr dvl_syr',make_dive_name()));
end

if ~isempty(dvl_syr)
  dvl_syr = add_vehicle_depth_to_dvl(dvl_syr, dep);
  dvl_syr = add_dvzpos_gvxattitude_to_syrinx(dvl_syr, dvz,gvx);
  dvl_syr=add_jason_svel_to_dvl(dvl_syr, svel);
  id=ones(length(dvl_syr.t),1) .* syr_id;
  dvl_syr.id = id;
  dvl_syr_select = trim_dvl(dvl_syr, 1);
else  
  dvl_syr_select = [];
end

id=[]; clear id;

combined_dvl = sort_dvl(dvl_rdi_select, dvl_syr_select);

save('dvls','combined_dvl','dvl_rdi','dvl_syr');

% purge_dvl.m doesnt exist
if clean_dvl == 1
    dvl = purge_dvl(combined_dvl, purge_start_ymdhms, purge_stop_ymdhms);
else 
    dvl = combined_dvl;
end

%% Check for big jumps in time in the dvl data. Likeliest source will
% be differences in DVL clocks.
nominal_dvl_ping_period = mode(dvl.time_since_last_ping_dvl);
bigTimeJumps = find(abs(dvl.time_since_last_ping_dvl) > 1.5 * nominal_dvl_ping_period);
dvl.time_since_last_ping_dvl(bigTimeJumps) = nominal_dvl_ping_period;

%% Attitude smoothing
%Interpolate attitude onto DVL timeline.
uhead = unwrap(degtorad(gvx.heading));
uheadi=interpend(make_monotonic(gvx.t),uhead,dvl.t);
dvl.attitude(:,1) = wrapTo360(radtodeg(uheadi));
dvl.pos(:,4) = dvl.attitude(:,1);

upitch = unwrap(degtorad(gvx.pitch));
upitchi = interpend(make_monotonic(gvx.t),upitch,dvl.t);
dvl.attitude(:,2) = wrapTo360(radtodeg(upitchi));
dvl.pos(:,5) = dvl.attitude(:,2);

uroll = unwrap(degtorad(gvx.roll));
urolli = interpend(make_monotonic(gvx.t),uroll,dvl.t);
dvl.attitude(:,3) = wrapTo360(radtodeg(urolli));
dvl.pos(:,6) = dvl.attitude(:,3);

%% Read in ship GPS info
gps = load_vprgps_jason(npath);
ind = find((gps.t > tstart) & (gps.t < tend));
gps = structextract(gps, ind);

%% Start renav processing. Largely unchanged from Sentry original.
% interpolate the dvl velocity error onto the drpp timebase
% negative error indicates 3 beams (no error computation possible)
% Sonardyne and RDI appear to define this error differently, so dont
% put too much faith in using it.
ind = find(dvl.bottom_vel(:,4) > 0);
dvl.dvl_error = dvl.bottom_vel(ind,4); 
 
dvl.source_file='Combined_RDI_and_Sonardyne';

[dvlRenav, pns] = renav_dvl_isnan(dvl,navcfg);

drpp = dvl_renav2drpp(dvlRenav);

if(vfr);
     fprintf('using navest vfr records')
% Navest logs VFR/USBL records for all Sonardyne beacons. Jason itself is
% typically beacon ID 0.
     geopos_rnv0=load_vfr_usbl_data_jason(vehicle_name);
     vehIndices = find(geopos_rnv0.veh_id == 0);
     geopos_rnv = structextract(geopos_rnv0,vehIndices);
     geopos_rnv.orglat=m.orglat;
     geopos_rnv.orglon=m.orglon;

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
     ind = find((geopos_rnv.t > tstart) & (geopos_rnv.t < tend));
     geopos_rnv = structextract(geopos_rnv,ind);
     geopos_rnv=time_fixup(geopos_rnv);
     fprintf('got geopos_rnv from vfr data\n');
else
   sprintf('vfr flag not set')  
%############ Insert code for alternative to VFR ################
end

%% CLEAN USBL

fprintf('automated usbl filtering\n');
if(vfr)
  ats = geopos_rnv;
  ats.lat = interpend(gps.t,gps.lat,ats.t);
  ats.lon = interpend(gps.t,gps.lon,ats.t);
  ats.beacon_pos = zeros(length(ats.t),3);
  [ats.beacon_pos(:,1),ats.beacon_pos(:,2)] = ...
      ll2xy(ats.lat,ats.lon,m.orglat,m.orglon);
else
  geopos_rnv = filter_usbl_by_dr(geopos_rnv,ats,drpp0,navpp_param);
end
  
if (subset_usbl)
  geopos_rnv = clean_usbl_bytime(geopos_rnv, usbl_down_ymdhms, usbl_up_ymdhms);
end
  

%% ON_BOTTOM

dvl_bottom = navextract(tstart,tend,dvlRenav);
%% Purge excessively large DVL-measured velocities
bigVelJumps = find(abs(dvl_bottom.vehicle_vel(:,1)) > max_veh_vel | ...
    abs(dvl_bottom.vehicle_vel(:,1)) > max_veh_vel | ...
    abs(dvl_bottom.vehicle_vel(:,1)) > max_veh_vel)
dvl_bottom.bottom_vel(bigVelJumps,:) = 0.0;
%% 
[drpp2,dvl_renav2] = sentry_do_dvl_renav(dvl_bottom,navcfg);
geopos_rnv_bot = navextract(tstart,tend,geopos_rnv);

ind = find( (geopos_rnv.t > tstart) & (geopos_rnv.t < tend) );
geopos_rnv0 = structextract(geopos_rnv,ind);
ind = find( (dvl_renav2.t > mission_times.survey_start_t) & ...
	    (dvl_renav2.t < mission_times.survey_end_t));
drpp0 = structextract(dvl_renav2,ind);
geopos_rnv0.drpp_pos=zeros(size(geopos_rnv0.pos));
geopos_rnv0.drpp_pos(:,1) = interpend(dvl_renav2.t,dvl_renav2.pos(:,1),geopos_rnv0.t);
geopos_rnv0.drpp_pos(:,2) = interpend(dvl_renav2.t,dvl_renav2.pos(:,2),geopos_rnv0.t);
dx = geopos_rnv0.pos(:,1)-geopos_rnv0.drpp_pos(:,1);
dy = geopos_rnv0.pos(:,2)-geopos_rnv0.drpp_pos(:,2);

navpp_param.dr_xoffset = median(dx);
navpp_param.dr_yoffset = median(dy);
%  ind_error = find(drpp2.dvl_error > 0.05);
plot(geopos_rnv0.pos(:,1),geopos_rnv0.pos(:,2),'k.', ...
     geopos_rnv.pos(:,1),geopos_rnv.pos(:,2),'g.', ...
     drpp2.pos(:,1)+navpp_param.dr_xoffset, ...
     drpp2.pos(:,2)+navpp_param.dr_yoffset,'b.');
axis equal
grid on
%% Save plots of the current figure
renav_plot_fig1 = sprintf('J2-%d_renav_plot1.fig', divenumber);
renav_plot_png1 = sprintf('J2-%d_renav_plot1.png', divenumber);
saveas(gcf, renav_plot_fig1, 'fig');
saveas(gcf, renav_plot_png1, 'png');

[geopos_rnv,dr]=match_dr_to_usbl(geopos_rnv0,dvl_renav2,20,50);
plot(geopos_rnv0.pos(:,1),geopos_rnv0.pos(:,2),'r.', ...
     geopos_rnv.pos(:,1),geopos_rnv.pos(:,2),'g.', ...
     dr.pos(:,1),dr.pos(:,2));
axis equal
grid on

%% Save plots of the current figure
renav_plot_fig2 = sprintf('J2-%d_renav_plot2.fig', divenumber);
renav_plot_png2 = sprintf('J2-%d_renav_plot2.png', divenumber);
saveas(gcf, renav_plot_fig2, 'fig');
saveas(gcf, renav_plot_png2, 'png');


%% COMPLEMENTARY FILTER
cf_ok = 0;
default_cutoff = 1e-3;

while cf_ok ~= 1
    cutoff_freq = input('Enter complementary filter cutoff frequency (enter 0 for default 1e-3):');
    if(cutoff_freq==0)
        cutoff = default_cutoff;
    else
        cutoff = cutoff_freq;
    end
    [cf, plot_h] = do_complementary_filter(geopos_rnv,drpp2,0,cutoff);

    
    %% Save plots of the current figure
    renav_plot_fig3 = sprintf('J2-%d_renav_plot3.fig', divenumber);
    renav_plot_png3 = sprintf('J2-%d_renav_plot3.png', divenumber);
    saveas(plot_h, renav_plot_fig3, 'fig');
    saveas(plot_h, renav_plot_png3, 'png');
    
    
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

%% Until modeled DVL records are recorded during descent and ascent,
%  limit renavigation to t_on_bottom through t_off_bottom.
%  If depth with timeframe t_launch through t_surface is passed to
%  make_rnv, then renav from t_launch through t_surface is produced.

ind = find((dep.t > t_on_bottom) & (dep.t < t_off_bottom));
dep_bottom = structextract(dep, ind);

%% SAVE RENAV DATA
% make certain that the 3rd argument is dep, not pkd
rnv = make_rnv(cf,gvx,dep_bottom,dvl_bottom,usblcfg.orglat,usblcfg.orglon);

ind = find((rnv.t > t_on_bottom) & (rnv.t < t_off_bottom));
rnv_bottom = structextract(rnv, ind)
rnv_bottom.orglat = rnv.orglat;
rnv_bottom.orglon = rnv.orglon;

[mycf1, mycf2] = plot_jason_rnv(geopos_rnv,rnv_bottom);

%% Save plots of the current figure
 renav_plot_fig4 = sprintf('J2-%d_renav_plot4.fig', divenumber);
 renav_plot_png4 = sprintf('J2-%d_renav_plot4.png', divenumber);
 saveas(mycf1, renav_plot_fig4, 'fig');
 saveas(mycf1, renav_plot_png4, 'png');
 
 renav_plot_fig5 = sprintf('J2-%d_renav_plot5.fig', divenumber);
 renav_plot_png5 = sprintf('J2-%d_renav_plot5.png', divenumber);
 saveas(mycf2, renav_plot_fig5, 'fig');
 saveas(mycf2, renav_plot_png5, 'png');
 
fname_base = make_postproc_fname();
navpp_param.fname_base = fname_base;
rnv.fname_base = fname_base;
save_rnv(rnv_bottom,geopos_rnv);

query = input('save raw? (y or n): ','s');
if(query=='y')
  
  cmd = sprintf('save %s_renav navpp_param gps rnv drpp cf geopos_rnv', ...
		fname_base);
  eval(cmd);
end

ppi_fname = sprintf('J2-%d_renav.ppi', divenumber);
ppl_fname = sprintf('J2-%d_renav.ppl', divenumber);
vvan_fname = sprintf('J2-%d_renav_vvan.txt', divenumber);

fprintf('Writing 1hz ppi file %s from renav\n', ppi_fname)
write_ppi_from_rnv(rnv, ppi_fname);
if generate_ppl_flag == 1
  fprintf('Writing high rate ppl file %s from renav\n', ppl_fname)
  write_ppl_jason(ppl_fname, rnv, gvx, pplfilterflag, lag_value);
end
fprintf('Writing 1hz file %s for VirtualVan re-merge from renav\n', vvan_fname)
%addpath('/home/scotty/matlab/nav-adds')
write_vvan_from_dslpp_renav(rnv, vvan_fname);

write_BB_from_dslpp_renav(rnv)

%% Matlab startup mfile for renavigating navest data.
% m.vehicle='jason';
% dslpp_base = '/home/scotty/dslpp/mfiles';
% path(path, dslpp_base);
% path(path, strcat(dslpp_base,'/nav'));
% path(path, strcat(dslpp_base,'/nav/dvl_renav'));
% path(path, strcat(dslpp_base,'/nav/nav_filters'));
% path(path, strcat(dslpp_base,'/nav/phins'));
% path(path, strcat(dslpp_base,'/nav/renav-scripts'));
% path(path, strcat(dslpp_base,'/nav/renav_navproc'));
% path(path, strcat(dslpp_base,'/nav/usbl'));
% path(path, strcat(dslpp_base,'/vehicle/jason'));
% path(path, strcat(dslpp_base,'/utils'));
% path(path, strcat(dslpp_base,'/utils/navextract'));
% path(path, strcat(dslpp_base,'/utils/rotations'));
% path(path, strcat(dslpp_base,'/utils/conversions'));
% path(path, strcat(dslpp_base,'/utils/time_fcns'));
% path(path, strcat(dslpp_base,'/utils/string_fcns'));
% path(path, strcat(dslpp_base,'/structures'));
% path(path, strcat(dslpp_base,'/matlab_community_mfiles/multiprod'));
% path(path, strcat(dslpp_base,'/matlab_community_mfiles/clickableLegend'));
% path(path, strcat(dslpp_base,'/matlab_community_mfiles/ginput_zoom'));
% path(path, strcat(dslpp_base,'/plotting_funcs'));
% path(path, strcat(dslpp_base,'/output_files'));
%
% 
