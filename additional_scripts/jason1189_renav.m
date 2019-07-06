%% usbl_renav
% S McCue Jan 2017
% SJM June 2019
%    - codify replacement of USBL Z with paro depth.
%    - tweak filter params to track fine features better, depart from CF params.2019
%    - add figures that compare real time with filtered X & Y
%    - add legends and improved titles to plots.

%% Hand edit the metadata
m.mission_name=1189;
m.this_process_time=datestr(datetime('now'),'yyyymmddHHMM');
diveID = m.mission_name
% Get origin from DVZ records fields 23 and 24 or from the DVLNAV INI.M file.
% grep -h ^DVZ YYYYmmDD_HHMMSS.DAT | cut -d' ' -f23,24
% Or, can get from navest INI.M dvl.site.latitude and .longitude.
npath='/Volumes/CruiseData/AT42-12/Vehicle/Procdata/AT42-12/J2-1189/navest/';
m.orglat=45.91666667;
m.orglon=-130.02500000;
launch_ymdhms = [2019 07 03 11 34 50];
survey_start_ymdhms = [2019 07 03 12 54 38];
ascent_start_ymdhms = [2019 07 03 21 35 50];
surface_ymdhms = [2019 07 03 22 43 21];

%% Define some filtering parameters

% Max difference of USBL depth from Jasons Parosound depth
max_z_delta =20.0

% Low pass filter params
filter_order = 3;
% A USBL update freq of 1/12 secs generally yields good results. Can get
% a more accurate number using mode(diff(geopos_rt.t)), but use of this
% more accurate number doesnt guarantee a better fit.
usbl_sample_freq_hz = 1/12;   
cutoff_freq_hz = 0.003;

m.filter_order = filter_order;
m.usbl_sample_freq_hz = usbl_sample_freq_hz;
m.cutoff_freq_hz = cutoff_freq_hz;
%% The metadata is turned into processing paramters
divenumber=m.mission_name;
orglat = m.orglat;
orglon = m.orglon;
vehicle_name=m.vehicle;
save('divenumber.mat', 'divenumber');
save('vehicle_name.mat','vehicle_name'); 

a=launch_ymdhms;
m.launch_t= ymdhms_to_sec(a(1), a(2), a(3), a(4), a(5), a(6));

a=survey_start_ymdhms;
m.survey_start_t= ymdhms_to_sec(a(1), a(2), a(3), a(4), a(5), a(6));

a=ascent_start_ymdhms;
m.ascent_start_t= ymdhms_to_sec(a(1), a(2), a(3), a(4), a(5), a(6));

a=ascent_start_ymdhms;
m.survey_end_t= ymdhms_to_sec(a(1), a(2), a(3), a(4), a(5), a(6));

a=surface_ymdhms;
m.surface_t= ymdhms_to_sec(a(1), a(2), a(3), a(4), a(5), a(6));

t_launch = m.launch_t
t_on_deck = m.surface_t
t_on_bottom = m.survey_start_t
t_off_bottom = m.ascent_start_t
tstart = t_on_bottom
tend = t_off_bottom

eval(sprintf('save jason%d_org orglat orglon',divenumber))

%% Load depth first becaue its used to derive other parameters
if (exist(sprintf('%s_dep.mat',make_dive_name()),'file'))
  load (sprintf('%s_dep.mat',make_dive_name()))
else
  dep=load_dirstruct(npath,'DAT','JDEP',t_launch,t_on_deck);
  eval(sprintf('save %s_dep dep',make_dive_name()))
end

% [t1, i] = find_nearestIndex(m.launch_t, dep.t);
% m.launch_tm = dep.tm(i);
% 
% [t1, i] = find_nearestIndex(m.survey_start_t, dep.t);
% m.survey_start_tm = dep.tm(i);
% 
% [t1, i] = find_nearestIndex(m.ascent_start_t, dep.t);
% m.ascent_start_tm = dep.tm(i);
% 
% %[t1, i] = find_nearestIndex(m.survey_end_t, dep.t);
% %m.survey_end_tm = dep.tm(i);
% 
% [t1, i] = find_nearestIndex(m.surface_t, dep.t);
% m.surface_tm = dep.tm(i);

eval(sprintf('save jason%d_dep dep', divenumber));

%% Load DVZ records, which will be used to build a complete renav structure
if (exist(sprintf('%s_dvz.mat',make_dive_name()),'file'))
  load (sprintf('%s_dvz.mat',make_dive_name()))
else
  dvz=load_dirstruct(npath,'DAT','DVZ',t_on_bottom, t_off_bottom);
  eval(sprintf('save %s_dvz dvz',make_dive_name()))
  att_src = dvz;
end
%% J2-1086, DVZ records changed and ingestion failed. Look for alternative.
if (isempty(att_src))
  gvx=load_dirstruct(npath,'DAT','GVX',t_launch, t_on_deck);
  eval(sprintf('save %s_gvx gvx',make_dive_name()));
%   octans=load_dirstruct(npath,'DAT','DOCT',t_launch, t_on_deck);
%   eval(sprintf('save %s_octans octans',make_dive_name()));
  att_src = gvx;
  att_src.altitude = zeros(length(att_src.t),1);
end

%% Now start processing the USBL for the dive timeframe
fprintf('Loading USBL from vfr data\n');

if (exist(sprintf('%s_usbl.mat',make_dive_name()),'file'))
  load (sprintf('%s_usbl.mat',make_dive_name()))
else
  geopos_rt=load_vfr_usbl_data_jason(vehicle_name);
  eval(sprintf('save %s_usbl geopos_rt',make_dive_name()))
end

% Jason beacon ID is usually 0
vehIndices = find(geopos_rt.veh_id == 0);
geopos_rt = structextract(geopos_rt,vehIndices);

% We need eastings and northings in meters if were going to impose
% constraints
[x,y]=ll2xy(geopos_rt.lat,geopos_rt.lon,m.orglat, ...
 		m.orglon);
geopos_rt.pos=[x,y,geopos_rt.depth];
geopos_sample_freq_hz = median(diff(geopos_rt.t));
 
ind = find((geopos_rt.t > tstart) & (geopos_rt.t < tend));
geopos_ob = structextract(geopos_rt,ind);
geopos_ob=time_fixup(geopos_ob);

%% Do some filtering on the USBL data.
% Interpolate depth onto USBL timeline
re_depth = interpend(make_monotonic(dep.t), dep.depth, make_monotonic(geopos_ob.t));
delta_depth = abs(re_depth - geopos_ob.depth);
idx = find(delta_depth < max_z_delta);

geopos_f1 = structextract(geopos_ob, idx);

%% Low pass filtering of USBL
% Precreate the destination structure for low pass filtered positions
% Column 1 of pos field is x, col 2 is y.
geopos_f2 = geopos_f1;

% Compute params for low pass filter
wn= cutoff_freq_hz / (0.5 * usbl_sample_freq_hz);
[B,A] = butter(filter_order, wn, 'low');
% Apply
geopos_f2.pos(:,1) = filtfilt(B,A,geopos_f1.pos(:,1));
geopos_f2.pos(:,2) = filtfilt(B,A,geopos_f1.pos(:,2));
geopos_f2.pos(:,3) = re_depth;

[geopos_f2.lat, geopos_f2.lon] = xy2ll(geopos_f2.pos(:,1), geopos_f2.pos(:,2), orglat, orglon);

%% Deltas of X and Y between rawe and filtered eastings and northings.
[samet, idx_raw, idx_filt] = intersect(geopos_rt.t, geopos_f2.t);
delta_x = geopos_rt.pos(idx_raw,1) - geopos_f2.pos(idx_filt,1);
delta_y = geopos_rt.pos(idx_raw,1) - geopos_f2.pos(idx_filt,1);

%% Plotting
% Deltas
figure(1)
subplot(3,1,1)
plot(geopos_ob.t, delta_depth,'b.')
titlestr=sprintf('J2-%d: ParoScientific - USBL Depth', m.mission_name);
title(titlestr);
ylabel('\Delta Z, m')

subplot(3,1,2)
plot(samet, delta_x,'b.');
title('\Delta Eastings in USBL position, RealTime and Renav');
ylabel('\Delta X, m');

subplot(3,1,3)
plot(samet, delta_y,'b.');
title('\Delta Northings in USBL position, RealTime and Renav');
ylabel('\Delta Y, m')
xlabel('Unix epoch seconds');

mycf=gcf;
renav_plot_fig1 = sprintf('J2-%d_renavUSBL_plot1.fig', diveID);
renav_plot_png1 = sprintf('J2-%d_renavUSBL_plot1.png', diveID);
saveas(mycf, renav_plot_fig1, 'fig');
saveas(mycf, renav_plot_png1, 'png');

% Eastings and Northings vs time
figure(2)
subplot(2,1,1)
plot(geopos_ob.t, geopos_ob.pos(:,1), 'g.', geopos_f2.t, geopos_f2.pos(:,1),'b.')
titlestr=sprintf('J2-%d: Real time USBL Eastings and Filtered Eastings vs time', m.mission_name);
title(titlestr);
ylabel('Eastings, m')
legend('RealTime', 'Renav')

subplot(2,1,2)
plot(geopos_ob.t, geopos_ob.pos(:,2), 'g.', geopos_f2.t, geopos_f2.pos(:,2),'b.')
title('Real time USBL Northings and Filtered Northings vs time');
ylabel('Northings, m')
xlabel('Lowering Time, unix seconds');
legend('RealTime', 'Renav');

mycf=gcf;
renav_plot_fig2 = sprintf('J2-%d_renavUSBL_plot2.fig', diveID);
renav_plot_png2 = sprintf('J2-%d_renavUSBL_plot2.png', diveID);
saveas(mycf, renav_plot_fig2, 'fig');
saveas(mycf, renav_plot_png2, 'png');

figure(3)
plot(geopos_ob.pos(:,1), geopos_ob.pos(:,2),'g-', geopos_f2.pos(:,1),geopos_f2.pos(:,2),'b.')
titlestr=sprintf('J2-%d: Real Time vs Filtered USBL-only Navigation, Local Coords', m.mission_name);
  title(titlestr);
xlabel('Eastings, m')
ylabel('Northings, m')
legend('RealTime', 'Renav')

mycf=gcf;
renav_plot_fig3 = sprintf('J2-%d_renavUSBL_plot3.fig', diveID);
renav_plot_png3 = sprintf('J2-%d_renavUSBL_plot3.png', diveID);
saveas(mycf, renav_plot_fig3, 'fig');
saveas(mycf, renav_plot_png3, 'png');

figure(4)
plot(geopos_ob.lon, geopos_ob.lat,'g-', geopos_f2.lon,geopos_f2.lat,'b.')
titlestr=sprintf('J2-%d: Real Time vs Filtered USBL-only Navigation, Geo Coords',m.mission_name);
title(titlestr);
xlabel('Lon')
ylabel('Lat')
legend('RealTime', 'Renav')

mycf=gcf;
renav_plot_fig4 = sprintf('J2-%d_renavUSBL_plot4.fig', diveID);
renav_plot_png4 = sprintf('J2-%d_renavUSBL_plot4.png', diveID);
saveas(mycf, renav_plot_fig4, 'fig');

saveas(mycf, renav_plot_png4, 'png');

%% Build an rnv structure to better resemble other NDSF renav products.
% Attitude and altitude are required for output files. Obtain from DVZ records.
rnv = geopos_f2;

% Unwrap heading, pitch, roll measurements to be in range 0-360 degrees.
uhead = unwrap_hdg_deg(att_src.heading);
rnv.pos(:,4) = interpend(att_src.t,uhead,rnv.t);
upitch = unwrap_hdg_deg(att_src.pitch);
rnv.pos(:,5) = interpend(att_src.t,upitch,rnv.t);
uroll = unwrap_hdg_deg(att_src.roll);
rnv.pos(:,6) = interpend(att_src.t,att_src.roll,rnv.t);
rnv.alt = interpend(att_src.t,att_src.altitude,rnv.t);    
%% Produce text files in ppi and virtualvan formats

ppi_fname = sprintf('J2-%d_renav.ppi', diveID);
vvan_fname = sprintf('J2-%d_renav_vvan.txt', diveID);

fprintf('Writing 1hz ppi file %s from renav\n', ppi_fname)
write_ppi(rnv, ppi_fname);
fprintf('Writing 1hz file %s for VirtualVan\n', vvan_fname)
write_vvan_from_dslpp_renav(rnv, vvan_fname);

fprintf('Renav bounding box: west, east, south, north');
write_BB_from_dslpp_renav(rnv)

%% Save important results
matfile = sprintf('J2-%d_renav_data.mat', diveID);
save matfile rnv m


