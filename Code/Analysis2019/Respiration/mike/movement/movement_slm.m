filepath = "/Users/xizheng/Documents/florin/respiration/K1/K1_20191226_r0.mat";

[Traces, TrialInfo] = ParseBehaviorAndPhysiology(filepath);

idx = 2;

%% lever

trial_on = Traces.Trial{idx};
lever = Traces.Lever{idx};

% lever = lever(trial_on~=0);

% smooth lever
lever_smooth = smoothdata(lever, 'sgolay', 25, 'degree', 4);
% 
% figure; hold on;
% plot(lever);
% plot(lever_smooth);
% plot(trial_on ~= 0);

%%

x = 1:length(lever_smooth);

prescription = slmset('order', 2, 'interiorknots', 'free', 'knots', 50); % piecewise linear
slm = slmengine(x,lever_smooth,prescription); % create model
fitLine = slmeval(x,slm); % evaluate model

%%

figure;
plot(lever_smooth);
hold on;
plot(fitLine);
plot(round(slm.knots), fitLine(round(slm.knots)), 'or');

%%

vel = gradient(fitLine);
acc = gradient(vel);

threshold = 0.005;

[pks_1,locs_1,w_1,p_1] = findpeaks(abs(acc), 'MinPeakHeight', threshold, 'MinPeakDistance', 10);

figure;hold on;
plot(lever_smooth, 'linewidth', 1);
plot(fitLine, 'linewidth', 1);
plot(10*vel, 'linewidth', 1);
plot(acc*50, 'linewidth', 1);
plot(locs_1, lever_smooth(locs_1), 'or');

plot(locs_1, 50*acc(locs_1), 'or');

%%

% figure; hold on;
% plot(lever_smooth, 'linewidth', 1);
% plot(10*vel, 'linewidth', 1);

