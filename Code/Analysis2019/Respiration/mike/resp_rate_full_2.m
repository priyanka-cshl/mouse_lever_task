filepath = "/Users/xizheng/Documents/florin/respiration/K1/K1_20191226_r0.mat";

[Traces, TrialInfo] = ParseBehaviorAndPhysiology(filepath);

frequency_trials = NaN(length(Traces.Lever), 3001);
rewards_trials = NaN(length(Traces.Lever), 1);

for idx = 1:length(Traces.Lever)
    RespData = Traces.Sniffs{idx};
    if(isempty(RespData))
        continue
    end

    trial_on = Traces.Trial{idx};
    rewards = Traces.Rewards{idx};

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

    zci_interval_length = diff(locs_2);

    sr = 500;

    frequency = zeros(1, length(RespData));
    for i = 1:length(locs_2)-1
        frequency(locs_2(i):locs_2(i+1)) = 500/zci_interval_length(i);
    end

    frequency_trial = frequency(1:find(diff(trial_on~=0)==-1));
    % figure;
    % plot(respData_filtered);
    % hold on;
    % plot(locs_2, respData_filtered(locs_2),'ob');
    % plot(frequency_trial);
    % plot(trial_on ~= 0);
    
%     frequency_trial = smoothdata(frequency_trial);
    
    frequency_trials(idx,1:length(frequency_trial)) = frequency_trial;
    
    rewards_idx = find(rewards == 1);
    if ~isempty(rewards_idx)
        rewards_trials(idx) = rewards_idx(1);
    end
    
end

%%
figure;
plot(frequency_trials(1,:), 'linewidth', 0.5);
hold on;
for i = 2:length(Traces.Lever)
    plot(frequency_trials(i,:), 'linewidth', 0.5);
end

amean1 = nanmean(frequency_trials, 1);
astd1 = nanstd(frequency_trials,[],1);
F1 = 1:size(frequency_trials,2);

plot(amean1, 'color', 'k','linewidth', 1.5);
fill([F1 fliplr(F1)],[amean1+astd1 fliplr(amean1-astd1)], 'k', 'FaceAlpha', 0.5,'linestyle','none');
xline(501, 'linewidth', 2);
xline(nanmean(rewards_trials), 'linewidth', 2);
title("two lines are trial onset and average point of reward");