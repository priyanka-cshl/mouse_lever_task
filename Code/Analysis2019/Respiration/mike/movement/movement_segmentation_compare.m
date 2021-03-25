filepath = "/Users/xizheng/Documents/florin/respiration/K1/K1_20191226_r0.mat";

[Traces, TrialInfo] = ParseBehaviorAndPhysiology(filepath);

idx = 3;

%% lever

trial_on = Traces.Trial{idx};
lever = Traces.Lever{idx};

lever = lever(trial_on~=0);

% smooth lever
lever_smooth = smoothdata(lever, 'sgolay', 25, 'degree', 4);

%% acceleration after double smoothing

vel_1 = gradient(lever_smooth);
vel_1_smooth = smoothdata(vel_1, 'sgolay', 25, 'degree', 4);

acc_1 = gradient(vel_1_smooth);
% accel = smoothdata(accel, 'sgolay', 25);

[acc_pks_1,acc_locs_1,acc_w_1,acc_p_1] = findpeaks(abs(acc_1), 'MinPeakProminence', 0.0005, 'MinPeakDistance', 10);


%% get acceleration by segmented linear fit

[acc_pks_2,acc_locs_2,acc_w_2,acc_p_2,vel_2,acc_2] = MovementSLM(lever_smooth);


%% get acceleration by discretization

[acc_pks_3,acc_locs_3,acc_w_3,acc_p_3,vel_3,acc_3] = MovementDiscretized(lever_smooth);


%% 

figure; hold on;
plot(lever_smooth, 'linewidth', 1, 'color', 'k');
plot(acc_locs_1, lever_smooth(acc_locs_1), 'DisplayName', 'smooth', 'color', '#0072BD', 'linestyle', 'none', 'marker', 'o', 'markersize', 8, 'linewidth', 2);
plot(acc_locs_2, lever_smooth(acc_locs_2), 'DisplayName', 'linear segment', 'color', '#D95319', 'linestyle', 'none', 'marker', 'o', 'markersize', 8, 'linewidth', 2);
% plot(acc_locs_3, lever_smooth(acc_locs_3), 'DisplayName', 'discretize linear', 'color', '#EDB120', 'linestyle', 'none', 'marker', 'o', 'markersize', 8, 'linewidth', 2);

% plot(10*vel_1_smooth, 'linewidth', 1, 'DisplayName', 'smooth','color', '#0072BD');
% plot(10*vel_2, 'linewidth', 1, 'DisplayName', 'linear segment', 'color', '#D95319');
% plot(10*vel_3, 'linewidth', 1, 'DisplayName', 'discretize linear','color', '#EDB120');

plot(50*acc_1, 'linewidth', 1, 'DisplayName', 'smooth','color', '#0072BD');
plot(50*acc_2, 'linewidth', 1, 'DisplayName', 'linear segment', 'color', '#D95319');
% plot(50*acc_3, 'linewidth', 1, 'DisplayName', 'discretize linear','color', '#EDB120');
legend;
