filepath = "/Users/xizheng/Documents/florin/respiration/K1/K1_20191226_r0.mat";

%% read data

Temp = load(filepath,'session_data');
MyTraces = Temp.session_data.trace;
    
% get pressure sensor data
if find(ismember(Temp.session_data.trace_legend,'respiration'))
    whichcol = find(ismember(Temp.session_data.trace_legend,'respiration'));
    RespData = MyTraces(:,whichcol);
end

% get pressure sensor data
if find(ismember(Temp.session_data.trace_legend,'lever_DAC'))
    whichcol = find(ismember(Temp.session_data.trace_legend,'lever_DAC'));
    lever = MyTraces(:,whichcol);
end

% get pressure sensor data
if find(ismember(Temp.session_data.trace_legend,'trial_on'))
    whichcol = find(ismember(Temp.session_data.trace_legend,'trial_on'));
    trial_on = MyTraces(:,whichcol);
end

%% resp

% rescale the data
RespData = RespData - median(RespData);

% invert: inhalations should be negative
RespData = -RespData;

% smooth pressure data by moving mean filter
respData_filtered = smoothdata(RespData);

% find peak, valley, zci for pressure data

[pks_1,locs_1,w_1,p_1] = findpeaks(respData_filtered, 'MinPeakProminence', 0.3, 'MinPeakDistance', 20);
[pks_2,locs_2,w_2,p_2] = findpeaks(-respData_filtered, 'MinPeakProminence', 0.3, 'MinPeakDistance', 20, 'MinPeakHeight', 0.1);

zci = @(v) find(diff(sign(v))<0 & diff(v) < -0.001);
zero_crossings = zci(respData_filtered);

% zero_crossings = locs_2;

%% lever

% smooth lever
lever_smooth = smoothdata(lever, 'sgolay', 25, 'degree', 4);

velocity = gradient(lever_smooth);
velocity_smooth = smoothdata(velocity, 'sgolay', 25, 'degree', 4);

accel = gradient(velocity_smooth);

[accel_pks_1,accel_locs_1,accel_w_1,accel_p_1] = findpeaks(abs(accel), 'MinPeakProminence', 0.0005, 'MinPeakDistance', 10);

accel_locs_1_trial = accel_locs_1(ismember(accel_locs_1, find(trial_on~=0)));
zero_crossings_trial = zero_crossings(ismember(zero_crossings, find(trial_on~=0)));

closest_neighbor_zci = zeros(1, length(zero_crossings_trial));
for i = 1:length(zero_crossings_trial)
    dist = zeros(1, length(accel_locs_1_trial));
    for j = 1:length(accel_locs_1_trial)
        dist(j) = abs(zero_crossings_trial(i)-accel_locs_1_trial(j));
    end
    [minval, argmin] = min(dist);
    closest_neighbor_zci(i) = zero_crossings_trial(i)-(accel_locs_1_trial(argmin));
end

figure;
histogram(closest_neighbor_zci, 250);
title(sprintf('for each sniff, closest move (mean:%.2f, median:%.2f, sd:%.2f)\n', mean(closest_neighbor_zci), median(closest_neighbor_zci), std(closest_neighbor_zci)));

figure;
plot(lever_smooth);
hold on;
plot(accel_locs_1_trial, lever_smooth(accel_locs_1_trial), 'or');
plot(zero_crossings_trial, lever_smooth(zero_crossings_trial), 'og');

%% a null model

null_movement = randsample(find(trial_on~=0),length(accel_locs_1_trial));

closest_neighbor_zci_null = zeros(1, length(zero_crossings_trial));
for i = 1:length(zero_crossings_trial)
    dist = zeros(1, length(null_movement));
    for j = 1:length(null_movement)
        dist(j) = abs(zero_crossings_trial(i)-null_movement(j));
    end
    [minval, argmin] = min(dist);
    closest_neighbor_zci_null(i) = zero_crossings_trial(i)-(null_movement(argmin));
end

figure;
histogram(closest_neighbor_zci_null, 250);
title(sprintf('NULL: for each sniff, closest move (mean:%.2f, median:%.2f, sd:%.2f)\n', mean(closest_neighbor_zci_null), median(closest_neighbor_zci_null), std(closest_neighbor_zci_null)));
