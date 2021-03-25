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

%%

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
histogram(closest_neighbor_move, 'binwidth', 5);
title(sprintf('for each move, closest sniff (mean:%.2f, median:%.2f, sd:%.2f)\n', mean(closest_neighbor_move), median(closest_neighbor_move), std(closest_neighbor_move)));


%% separate into large and small movement

threshold = 1;

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
plot(zero_crosings_trial, lever_smooth(zero_crosings_trial), '*g');

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
histogram(closest_neighbor_move_large, 'binwidth', 2, 'normalization', 'probability', 'facecolor', 'r');
hold on;
histogram(closest_neighbor_move_small, 'binwidth', 2, 'normalization', 'probability', 'facecolor', 'b');
xline(0, 'linewidth', 2);
title(sprintf('DATA\nfor each large move, closest sniff (mean:%.2f, median:%.2f, sd:%.2f)\nfor each small move, closest sniff (mean:%.2f, median:%.2f, sd:%.2f)\n', mean(closest_neighbor_move_large), median(closest_neighbor_move_large), std(closest_neighbor_move_large), mean(closest_neighbor_move_small), median(closest_neighbor_move_small), std(closest_neighbor_move_small)));


%% null move

null_mov_locs_trial_large = randsample(find(trial_on~=0),length(mov_locs_trial_large));
null_mov_locs_trial_small = randsample(find(trial_on~=0),length(mov_locs_trial_small));

null_closest_neighbor_move_large = zeros(1, length(null_mov_locs_trial_large));
for i = 1:length(null_mov_locs_trial_large)
    dist = zeros(1, length(zero_crosings_trial));
    for j = 1:length(zero_crosings_trial)
        dist(j) = abs(null_mov_locs_trial_large(i)-zero_crosings_trial(j));
    end
    [minval, argmin] = min(dist);
    null_closest_neighbor_move_large(i) = (zero_crosings_trial(argmin))-null_mov_locs_trial_large(i);
end

null_closest_neighbor_move_small = zeros(1, length(null_mov_locs_trial_small));
for i = 1:length(null_mov_locs_trial_small)
    dist = zeros(1, length(zero_crosings_trial));
    for j = 1:length(zero_crosings_trial)
        dist(j) = abs(null_mov_locs_trial_small(i)-zero_crosings_trial(j));
    end
    [minval, argmin] = min(dist);
    null_closest_neighbor_move_small(i) = (zero_crosings_trial(argmin))-null_mov_locs_trial_small(i);
end

figure;
histogram(null_closest_neighbor_move_large, 'binwidth', 2, 'normalization', 'probability', 'facecolor', 'r');
hold on;
histogram(null_closest_neighbor_move_small, 'binwidth', 2, 'normalization', 'probability', 'facecolor', 'b');
title(sprintf('NULL\nfor each large move, closest sniff (mean:%.2f, median:%.2f, sd:%.2f)\nfor each small move, closest sniff (mean:%.2f, median:%.2f, sd:%.2f)\n', mean(null_closest_neighbor_move_large), median(null_closest_neighbor_move_large), std(null_closest_neighbor_move_large), mean(null_closest_neighbor_move_small), median(null_closest_neighbor_move_small), std(null_closest_neighbor_move_small)));

[h,p,ci,stats] = ttest2(closest_neighbor_move_large, null_closest_neighbor_move_large)
[h,p,ci,stats] = ttest2(closest_neighbor_move_small, null_closest_neighbor_move_small)
