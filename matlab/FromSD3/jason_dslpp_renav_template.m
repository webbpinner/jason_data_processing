%% Template for ROV Jason navigation post-processing. Spring 2015, using
% mfiles from the 'dslpp' code collection.
% Primary work by Louis Whitcomb and James Kinsey.
% Adapted into 'dslpp' by James Kinsey and Stefano Suman.
% Further contributions by Jon Howland, Carl Kaiser, Scott McCue, and
% probably others. 
%
%% USAGE:
% 1. Under ~/matlab, install a startup.m script that defines prerequisites
% for this script. An example is given at the end of this script.
% 2. Edit the top block of the executable portion of the script.
%    - Edit the variable 'm.mission_name'. Use only the Jason lowering
%      *number* (e.g. "815") rather than the conventional ID (e.g. "J2-815")
% 3. Edit the variables defining the nav reference point, i.e., the origin.
%    Get origin from DVZ records fields 23 and 24 or from the DVLNAV INI.M file.
%    grep -h ^DVZ YYYYmmDD_HHMMSS.DAT | cut -d' ' -f23,24
% 4. Edit the paths containing files for Jason's sound velocity and
%    CTD data logs. 
% 5. Choose whether to use a GUI tool to pull milestone times from the
%    depth history, or to define by editing the time vectors at which
%    the vehicle entered and exited the ocean, and reached and departed
%    the ocean bottom. Get this info from records such as Virtual Van events.
%    Define variable 'GUI' to 1 (== yes) or 0 (== no).
%    Vector element order is [year month day hour minute second]
% 6. Unless there are not georeferenced positions in VFR records, keep
%    'VFR=1'.
% 7. Run matlab. Run this script in matlab.
%% Start with a clean slate. Processing isn't so lengthy we cant reread
% data each time we process.

!rm *dep.mat
!rm *dvl.mat
!rm *octans.mat

dep=[];clear dep;
dvl=[];clear dvl;
octans=[];clear octans;

close all

%% Set these things by hand until a mechanism like Sentry has for writing out a
%  mission plan is in place.

m.mission_name=827;
diveID = m.mission_name
% Get origin from DVZ records fields 23 and 24 or from the DVLNAV INI.M file.
% grep -h ^DVZ YYYYmmDD_HHMMSS.DAT | cut -d' ' -f23,24
m.orglat=47.50000;
m.orglon=-128.0000;
npath='/data/Procdata/TN328/J2-827/navest/'    
svp_path='/data/Procdata/TN328/J2-827/svp/'
ctd_path='/data/Procdata/TN328/J2-827/ct2/'

vfr=1;

%% Obtain time metadata as usual, e.g., from watchstander comments,
%  virtual van, etc. "Survey start" same as "on bottom".
launch_ymdhms = [2015 09 03 18 32 00];
survey_start_ymdhms = [2015 09 03 21 08 00];
ascent_start_ymdhms = [2015 09 04 09 58 00];
surface_ymdhms = [2015 09 04 12 05 00];

%% Shouldnt need to change anything after this point.

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
t_on_bottom = mission_times.survey_start_t
t_off_bottom = mission_times.ascent_start_t
tstart = t_on_bottom
tend = t_off_bottom

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

% mission_times = get_dep_mission_times(dep, vehicle_name)

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

if (exist(sprintf('%s_dvl.mat',make_dive_name()),'file'))
   load (sprintf('%s_dvl.mat',make_dive_name()))
 else
  dvl=load_dirstruct(npath,'DAT','DDVL',t_on_bottom, t_off_bottom);
  eval(sprintf('save %s_dvl dvl',make_dive_name()));
end

%% GVX - 2012-04-27 JCK - in dvlnav this is the oct string
 if (exist(sprintf('%s_gvx.mat',make_dive_name()),'file'))
   load (sprintf('%s_gvx.mat',make_dive_name()))
 else
%  gvx=load_dirstruct(npath,'DAT','GVX',t_on_bottom, t_off_bottom);
%  eval(sprintf('save %s_gvx gvx',make_dive_name()));
   octans=load_dirstruct(npath,'DAT','DOCT',t_on_bottom,t_off_bottom);
   eval(sprintf('save %s_octans octans',make_dive_name()));
end

ind = find((octans.t > tstart) & (octans.t < tend));
octans = structextract(octans,ind);

uhead = unwrap_hdg_deg(octans.position(:,4));
dvl.attitude(:,1) = interp1(make_monotonic(octans.t),uhead,dvl.t);
upitch = unwrap_hdg_deg(octans.position(:,5));
dvl.attitude(:,2) = interp1(make_monotonic(octans.t),upitch,dvl.t);
uroll = unwrap_hdg_deg(octans.position(:,6));
dvl.attitude(:,3) = interp1(make_monotonic(octans.t),uroll,dvl.t);

% find the oldest rnv
dd = dir('*rnv.mat');
if(length(dd) > 0)
  load(dd(1).name);
  geopos_rnv_old = geopos_rnv;
  rnv_old = rnv;
else
  fprintf('no rnv files found\n');
end

%% time to check for big jumps in time in the dvl data
bigJumps = find(dvl.time_since_last_ping_dvl > 2.0);
dvl.time_since_last_ping_dvl(bigJumps) = 0.5;
 
gps = load_vprgps_jason(npath);
ind = find((gps.t > tstart) & (gps.t < tend));
gps = structextract(gps, ind);

% interpolate the dvl velocity error onto the drpp timebase
% negative error indicates 3 beams (no error computation possible)
ind = find(dvl.bottom_vel(:,4) > 0);
dvl.dvl_error = dvl.bottom_vel(ind,4); 
cmd = sprintf('load jason%03d_usblcfg',divenumber);
eval(cmd);

%% get DVLNAV ini file
cd(npath)
navcfg = get_most_recent_dvlnav_ini(); 

[dvlRenav, pns] = renav_dvl(dvl,navcfg);

drpp = dvl_renav2drpp(dvlRenav);

if(vfr);
     fprintf('using navest vfr records')
% Navest logs VFR/USBL records for all Sonardyne beacons. Jason itself is
% typically beacon ID 0.
     geopos_rnv=load_vfr_usbl_data_jason(vehicle_name);
     vehIndices = find(geopos_rnv.veh_id == 0);
     geopos_rnv = structextract(geopos_rnv,vehIndices);

     geopos_rnv.orglat=orglat;
     geopos_rnv.orglon=orglon;

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

%% ON_BOTTOM

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

% geopos0 timeframe is t_on_bottom to t_off_bottom
%ind = find( (geopos_rnv.tm > mission_times.survey_start_tm) & ...
%	    (geopos_rnv.tm < mission_times.survey_end_tm));
ind = find( (geopos_rnv.t > t_on_bottom) & (geopos_rnv.t < t_off_bottom) );
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
%% Save plots of the current figure
 renav_plot_fig1 = sprintf('J2-%d_renav_plot1.fig', diveID);
 renav_plot_png1 = sprintf('J2-%d_renav_plot1.png', diveID);
 saveas(gcf, renav_plot_fig1, 'fig');
% saveas(gcf, renav_plot_png1, 'png');

end

[geopos_rnv,dr]=match_dr_to_usbl(geopos_rnv0,dvl_renav2,20,50);
plot(geopos_rnv0.pos(:,1),geopos_rnv0.pos(:,2),'r.', ...
     geopos_rnv.pos(:,1),geopos_rnv.pos(:,2),'g.', ...
     dr.pos(:,1),dr.pos(:,2));
axis equal
grid on

%% Save plots of the current figure
 renav_plot_fig2 = sprintf('J2-%d_renav_plot2.fig', diveID);
 renav_plot_png2 = sprintf('J2-%d_renav_plot2.png', diveID);
 saveas(gcf, renav_plot_fig2, 'fig');
% saveas(gcf, renav_plot_png2, 'png');


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
 renav_plot_fig3 = sprintf('J2-%d_renav_plot3.fig', diveID);
 renav_plot_png3 = sprintf('J2-%d_renav_plot3.png', diveID);
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
rnv = make_rnv(cf,octans,dep_bottom,dvl_bottom,usblcfg.orglat,usblcfg.orglon);

ind = find((rnv.t > t_on_bottom) & (rnv.t < t_off_bottom));
rnv_bottom = structextract(rnv, ind)
rnv_bottom.orglat = rnv.orglat;
rnv_bottom.orglon = rnv.orglon;

mycf = plot_jason_rnv(geopos_rnv,rnv_bottom);

%% Save plots of the current figure
 renav_plot_fig4 = sprintf('J2-%d_renav_plot4.fig', diveID);
 renav_plot_png4 = sprintf('J2-%d_renav_plot4.png', diveID);
 saveas(mycf, renav_plot_fig4, 'fig');
 saveas(mycf, renav_plot_png4, 'png');
 
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

ppi_fname = sprintf('J2-%d_renav.ppi', diveID);
ppl_fname = sprintf('J2-%d_renav.ppl', diveID);
vvan_fname = sprintf('J2-%d_renav_vvan.txt', diveID);

fprintf('Writing 1hz ppi file %s from renav\n', ppi_fname)
write_ppi(rnv, ppi_fname);
fprintf('Writing high rate ppl file %s from renav\n', ppl_fname)
write_ppl(rnv, ppl_fname, vehicle_name);
fprintf('Writing 1hz file %s for VirtualVan re-merge from renav\n', ppi_fname)
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
