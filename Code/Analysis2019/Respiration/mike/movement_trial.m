filepath = "/Users/xizheng/Documents/florin/respiration/K1/K1_20191226_r0.mat";

[Traces, TrialInfo] = ParseBehaviorAndPhysiology(filepath);

idx = 3;

%% lever

trial_on = Traces.Trial{idx};
lever = Traces.Lever{idx};

% smooth lever
lever_smooth = smoothdata(lever, 'sgolay', 25, 'degree', 4);

% find peaks
[mov_pks_1,mov_locs_1,mov_w_1,mov_p_1] = findpeaks(lever_smooth, 'MinPeakProminence', 0.03, 'MinPeakDistance', 5);
[mov_pks_2,mov_locs_2,mov_w_2,mov_p_2] = findpeaks(-lever_smooth, 'MinPeakProminence', 0.03, 'MinPeakDistance', 5);

mov_locs = sort(cat(1, mov_locs_1,mov_locs_2));
mov_dists = abs(diff(lever_smooth(mov_locs)));

% figure;
% plot(lever_smooth, 'linewidth', 1);
% hold on;
% plot(mov_locs,lever_smooth(mov_locs),'or');

%% during trial

mov_locs_trial = mov_locs(ismember(mov_locs, find(trial_on~=0)));
mov_dists_trial = mov_dists(ismember(mov_locs(1:end-1), find(trial_on~=0)));

figure;
plot(lever_smooth, 'linewidth', 1);
hold on;
plot(5*(trial_on~=0));
plot(mov_locs_trial, lever_smooth(mov_locs_trial), 'or');

%% distance from target

motor = Traces.Encoder{idx};

figure;
plot(motor);