filepath = "/Users/xizheng/Documents/florin/respiration/K1/K1_20191226_r0.mat";

[Traces, TrialInfo] = ParseBehaviorAndPhysiology(filepath);

idx = 3;

%% lever

trial_on = Traces.Trial{idx};
lever = Traces.Lever{idx};

% smooth lever
lever_smooth = smoothdata(lever, 'sgolay', 25, 'degree', 4);

figure; hold on;
plot(lever);
plot(lever_smooth);
plot(trial_on ~= 0);

%% discretize lever

step = 0.2;

edges = -1:step:6;
lever_bins = discretize(lever_smooth,edges);

lever_discretized = lever_bins*step - 1 - 0.5*step;

figure; hold on;
plot(lever_smooth);
plot(lever_discretized);

%% 

velocity = diff(lever_discretized);
velocity_peaks = find(velocity ~= 0);

velocity_smooth = zeros(1, length(lever_smooth));
for i = 1:length(velocity_peaks)-1
    velocity_smooth(velocity_peaks(i):velocity_peaks(i+1)-1) = velocity(velocity_peaks(i))/(velocity_peaks(i+1)-velocity_peaks(i));
end

acc = gradient(velocity_smooth);

[pks_1,locs_1,w_1,p_1] = findpeaks(abs(acc), 'MinPeakHeight', 0.008, 'MinPeakDistance', 10);

figure;hold on;
plot(lever_smooth, 'linewidth', 1);
plot(acc*50, 'linewidth', 1);
plot(locs_1, lever_smooth(locs_1), 'or');

