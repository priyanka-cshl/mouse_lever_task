filepath = "/Users/xizheng/Documents/florin/respiration/K1/K1_20191226_r0.mat";

[Traces, TrialInfo] = ParseBehaviorAndPhysiology(filepath);

frequency_start = NaN(length(Traces.Lever), 3001);
frequency_reward_end = NaN(length(Traces.Lever), 3001);
rewards_trials = NaN(length(Traces.Lever), 1);

sniff_start = NaN(length(Traces.Lever), 3001);
sniff_reward_end = NaN(length(Traces.Lever), 3001);

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

    frequency = NaN(1, length(RespData));
    for i = 1:length(locs_2)-1
        frequency(locs_2(i):locs_2(i+1)) = 500/zci_interval_length(i);
    end
    
    sniffs = zeros(1, length(RespData));
    sniffs(locs_2) = 1;
    
    % align to trial start and rewards
    trial_start = find(diff(trial_on~=0) == 1, 1);
    trial_end = find(diff(trial_on~=0) == -1, 1, 'last');
    trial_duration = trial_end-trial_start+1;
    
    frequency_start(idx, 1:trial_end) = frequency(1:trial_end);
    sniff_start(idx, 1:trial_end) = sniffs(1:trial_end);
    
    rewards_idx = find(rewards == 1);
    if ~isempty(rewards_idx)
        rewards_trials(idx) = rewards_idx(1);
        
        frequency_reward_end(idx, 2500-trial_duration+1:2500) = frequency(trial_start:trial_end);
        sniff_reward_end(idx, 2500-trial_duration+1:2500) = sniffs(trial_start:trial_end);
        
        if ((length(frequency) - trial_end) > 500)
            frequency_reward_end(idx, 2501:end) = frequency(trial_end+1:trial_end+501);
            sniff_reward_end(idx, 2501:end) = sniffs(trial_end+1:trial_end+501);
        else
            frequency_reward_end(idx, 2501:2500+length(frequency)-trial_end) = frequency(trial_end+1:end);
            sniff_reward_end(idx, 2501:2500+length(sniffs)-trial_end) = sniffs(trial_end+1:end);
        end
    end
end

%% sniff rate aligned to trial start

amean1 = nanmean(frequency_start, 1);
astd1 = nanstd(frequency_start,[],1);
first_not_nan = find(~isnan(amean1), 1);
amean1_notnan = amean1(first_not_nan:end);
astd1_notnan = astd1(first_not_nan:end);
F1 = first_not_nan:size(frequency_start,2);

figure;
plot(amean1_notnan, 'color', 'k','linewidth', 1.5);
hold on;
fill([F1 fliplr(F1)],[amean1_notnan+astd1_notnan fliplr(amean1_notnan-astd1_notnan)], 'k', 'FaceAlpha', 0.5,'linestyle','none');
xline(501, 'linewidth', 2);
ylim([0,10]);
title("aligned to trial start");

%% sniff raster plot aligned to trial start

trial_lengths = sum(~isnan(sniff_start), 2);
[a_sorted, a_order] = sort(trial_lengths, 'descend');
sniff_start_sorted = sniff_start(a_order,:);
sniff_start_sorted_valid = sniff_start_sorted(~all(isnan(sniff_start_sorted),2),:);

a_order_valid = a_order(~all(isnan(sniff_start_sorted),2));

figure;
hold on;
for i = 1:size(sniff_start_sorted_valid, 1)
%     trial_idx = a_order_valid(i);
%     inzone = TrialInfo.InZone{trial_idx}*500;
%     for j = 1:size(inzone, 1)
%         rectangle('Position',[inzone(j, 1) i-1 inzone(j, 2)-inzone(j, 1) 1] ,'FaceColor',[1. 1. 0. .3], 'EdgeColor', [1. 1. 0. .3]);
%     end
%     
    sniff = find(sniff_start_sorted_valid(i,:) == 1);
    for j = 1:length(sniff)
        line([sniff(j) sniff(j)], [i-1 i],'Color','k', 'linewidth', 2);
    end
end
xline(501, 'linewidth', 2);
title("aligned to trial start");

%% sniff rate aligned to reward

amean2 = nanmean(frequency_reward_end, 1);
astd2 = nanstd(frequency_reward_end,[],1);
first_not_nan = find(~isnan(amean2), 1);
amean2_notnan = amean2(first_not_nan:end);
astd2_notnan = astd2(first_not_nan:end);
F2 = first_not_nan:size(frequency_reward_end,2);
figure;
plot(amean2, 'color', 'k','linewidth', 1.5);
hold on;
fill([F2 fliplr(F2)],[amean2_notnan+astd2_notnan fliplr(amean2_notnan-astd2_notnan)], 'k', 'FaceAlpha', 0.5,'linestyle','none');
xline(2501, 'linewidth', 2);
ylim([0,10]);
title("aligned to reward");

%% sniff raster plot aligned to reward

trial_lengths_reward = sum(~isnan(sniff_reward_end), 2);
[a_sorted_reward, a_order_reward] = sort(trial_lengths_reward, 'descend');
sniff_reward_sorted = sniff_reward_end(a_order_reward,:);
sniff_reward_sorted_valid = sniff_reward_sorted(~all(isnan(sniff_reward_sorted),2),:);

figure;
hold on;
for i = 1:size(sniff_reward_sorted_valid, 1)
    sniff = find(sniff_reward_sorted_valid(i,:) == 1);
    for j = 1:length(sniff)
        line([sniff(j) sniff(j)], [i-1 i],'Color','k', 'linewidth', 2);
    end
end
xline(2501, 'linewidth', 2);
title("aligned to reward");

%%
% 
% idx = 226;
% 
% figure; hold on;
% plot(Traces.Lever{idx})
% plot(Traces.Trial{idx})
%  
% inzone = TrialInfo.InZone{idx}*500;
% for j = 1:size(inzone, 1)
%     rectangle('Position',[inzone(j, 1) 0 inzone(j, 2)-inzone(j, 1) 5] ,'FaceColor',[1. 1. 0. .3], 'EdgeColor', [1. 1. 0. .3]);
% end
