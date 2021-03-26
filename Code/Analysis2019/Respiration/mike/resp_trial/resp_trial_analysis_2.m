filepath = "/Users/xizheng/Documents/florin/respiration/K1/K1_20191226_r0.mat";

[Traces, TrialInfo] = ParseBehaviorAndPhysiology(filepath);

idx = 3;

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
plot(respData_filtered, 'linewidth', 1);
hold on;
plot(locs_1,respData_filtered(locs_1),'or');
plot(locs_2,respData_filtered(locs_2),'ob');
plot(zero_crossings, respData_filtered(zero_crossings),'og');

%%

lever = Traces.Lever{idx};

% smooth lever
lever_smooth = smoothdata(lever, 'sgolay', 25, 'degree', 4);

% find peaks
[mov_pks_1,mov_locs_1,mov_w_1,mov_p_1] = findpeaks(lever_smooth, 'MinPeakProminence', 0.03, 'MinPeakDistance', 5);
[mov_pks_2,mov_locs_2,mov_w_2,mov_p_2] = findpeaks(-lever_smooth, 'MinPeakProminence', 0.03, 'MinPeakDistance', 5);

mov_locs = sort(cat(1, mov_locs_1,mov_locs_2));
mov_dists = abs(diff(lever_smooth(mov_locs)));

figure;
plot(lever_smooth, 'linewidth', 1);
hold on;
plot(mov_locs,lever_smooth(mov_locs),'or');

%% during trial

mov_locs_trial = mov_locs(ismember(mov_locs, find(trial_on~=0)));
zero_crosings_trial = zero_crossings(ismember(zero_crossings, find(trial_on~=0)));
mov_dists_trial = mov_dists(ismember(mov_locs(1:end-1), find(trial_on~=0)));

figure;
plot(lever_smooth, 'linewidth', 1);
hold on;
plot(5*(trial_on~=0));
plot(mov_locs_trial, lever_smooth(mov_locs_trial), 'or');
for i = 1:length(zero_crosings_trial)
    xline(zero_crosings_trial(i));
end

%% for each move, find if there's a sniff close by

closest_neighbor_move = zeros(1, length(mov_locs_trial));
for i = 1:length(mov_locs_trial)
    dist = zeros(1, length(zero_crosings_trial));
    for j = 1:length(zero_crosings_trial)
        dist(j) = abs(mov_locs_trial(i)-zero_crosings_trial(j));
    end
    [minval, argmin] = min(dist);
    closest_neighbor_move(i) = (zero_crosings_trial(argmin))-mov_locs_trial(i);
end

figure;
histogram(closest_neighbor_move, 20);
title(sprintf('for each move, closest sniff (mean:%.2f, median:%.2f, sd:%.2f)\n', mean(closest_neighbor_move), median(closest_neighbor_move), std(closest_neighbor_move)));

%% separate into large and small movement

threshold = 0.8;

mov_locs_trial_large = mov_locs_trial(mov_dists_trial > threshold);
mov_dists_trial_large = mov_dists_trial(mov_dists_trial > threshold);
mov_locs_trial_small = mov_locs_trial(mov_dists_trial <= threshold);
mov_dists_trial_small = mov_dists_trial(mov_dists_trial <= threshold);

figure;
plot(lever_smooth, 'linewidth', 1);
hold on;
plot(5*(trial_on~=0));
plot(mov_locs_trial_large, lever_smooth(mov_locs_trial_large), 'or');
plot(mov_locs_trial_small, lever_smooth(mov_locs_trial_small), 'ob');
for i = 1:length(zero_crosings_trial)
    xline(zero_crosings_trial(i));
end

closest_neighbor_move_large = zeros(1, length(mov_locs_trial_large));
for i = 1:length(mov_locs_trial_large)
    dist = zeros(1, length(zero_crosings_trial));
    for j = 1:length(zero_crosings_trial)
        dist(j) = abs(mov_locs_trial_large(i)-zero_crosings_trial(j));
    end
    [minval, argmin] = min(dist);
    closest_neighbor_move_large(i) = (zero_crosings_trial(argmin))-mov_locs_trial_large(i);
end

closest_neighbor_move_small = zeros(1, length(mov_locs_trial_small));
for i = 1:length(mov_locs_trial_small)
    dist = zeros(1, length(zero_crosings_trial));
    for j = 1:length(zero_crosings_trial)
        dist(j) = abs(mov_locs_trial_small(i)-zero_crosings_trial(j));
    end
    [minval, argmin] = min(dist);
    closest_neighbor_move_small(i) = (zero_crosings_trial(argmin))-mov_locs_trial_small(i);
end

figure;
histogram(closest_neighbor_move_large, 'binwidth', 5);
hold on;
histogram(closest_neighbor_move_small, 'binwidth', 5);

