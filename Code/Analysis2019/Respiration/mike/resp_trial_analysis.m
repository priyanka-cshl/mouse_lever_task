filepath = "/Users/xizheng/Documents/florin/respiration/K1/K1_20191226_r0.mat";

[Traces, TrialInfo] = ParseBehaviorAndPhysiology(filepath);

idx = 2;

%% sniffs

RespData = Traces.Sniffs{idx};
trial_on = Traces.Trial{idx};
licks = Traces.Licks{idx};
licks_idx = find(licks ~= 0);

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

figure;
plot(respData_filtered);
hold on;
plot(locs_1,respData_filtered(locs_1),'or');
plot(locs_2,respData_filtered(locs_2),'ob');
plot(zero_crossings, respData_filtered(zero_crossings),'og');

%% lever

lever = Traces.Lever{idx};

% smooth lever
lever_smooth = smoothdata(lever, 'sgolay', 25, 'degree', 4);

velocity = gradient(lever_smooth);
velocity_smooth = smoothdata(velocity, 'sgolay', 25, 'degree', 4);

accel = gradient(velocity_smooth);
% accel = smoothdata(accel, 'sgolay', 25);

[accel_pks_1,accel_locs_1,accel_w_1,accel_p_1] = findpeaks(abs(accel), 'MinPeakProminence', 0.0005, 'MinPeakDistance', 10);

accel_high = find(abs(accel) > 0.0007);

figure;
plot(lever_smooth);
hold on;
% plot(100*velocity_smooth);
plot(400*accel);
% plot(200*abs(gradient(gradient(lever_smooth))));
% plot(accel_high, lever_smooth(accel_high), 'ob');
% plot(accel_high, 400*accel(accel_high), 'ob');
plot(accel_locs_1, lever_smooth(accel_locs_1), 'or');
plot(accel_locs_1, 400*accel(accel_locs_1), 'or');


for i = 1:length(zero_crossings)
    xline(zero_crossings(i));
end


%% during trial

accel_locs_1_trial = accel_locs_1(ismember(accel_locs_1, find(trial_on~=0)));
zero_crosings_trial = zero_crossings(ismember(zero_crossings, find(trial_on~=0)));

closest_neighbor_zci = zeros(1, length(zero_crosings_trial));
for i = 1:length(zero_crosings_trial)
    dist = zeros(1, length(accel_locs_1_trial));
    for j = 1:length(accel_locs_1_trial)
        dist(j) = abs(zero_crosings_trial(i)-accel_locs_1_trial(j));
    end
    [minval, argmin] = min(dist);
    closest_neighbor_zci(i) = zero_crosings_trial(i)-(accel_locs_1_trial(argmin));
end

figure;
histogram(closest_neighbor_zci, 50);
title(sprintf('for each sniff, closest move (mean:%.2f, median:%.2f, sd:%.2f)\n', mean(closest_neighbor_zci), median(closest_neighbor_zci), std(closest_neighbor_zci)));

figure;
plot(lever_smooth);
hold on;
% plot(5*(trial_on~=0));
plot(accel_locs_1_trial, lever_smooth(accel_locs_1_trial), 'or');
for i = 1:length(zero_crosings_trial)
    xline(zero_crosings_trial(i));
end

%% lever

lever = Traces.Lever{3};

% smooth lever
lever_smooth = smoothdata(lever, 'sgolay', 25, 'degree', 4);

velocity = gradient(lever_smooth);
velocity_smooth = smoothdata(velocity, 'sgolay', 25, 'degree', 4);

accel = gradient(velocity_smooth);
% accel = smoothdata(accel, 'sgolay', 25);

[accel_pks_1,accel_locs_1,accel_w_1,accel_p_1] = findpeaks(lever_smooth, 'MinPeakProminence', 0.1, 'MinPeakDistance', 10);
[accel_pks_2,accel_locs_2,accel_w_2,accel_p_2] = findpeaks(-lever_smooth, 'MinPeakProminence', 0.1, 'MinPeakDistance', 10);

% accel_high = find(abs(accel) > 0.0007);

figure;
plot(lever_smooth);
yline(0);
hold on;
% % plot(100*velocity_smooth);
% plot(400*accel);
% % % plot(200*abs(gradient(gradient(lever_smooth))));
% % % plot(accel_high, lever_smooth(accel_high), 'ob');
% % % plot(accel_high, 400*accel(accel_high), 'ob');
plot(accel_locs_1, lever_smooth(accel_locs_1), 'or');
plot(accel_locs_2, lever_smooth(accel_locs_2), 'ob');
% plot(accel_locs_1, 400*accel(accel_locs_1), 'or');


for i = 1:length(zero_crossings)
    xline(zero_crossings(i));
end
