clear all;

%%
% K1
% filepath = "/Users/xizheng/Documents/florin/respiration/K1/K1_20191215_r0.mat";
% name = "K1_20191215_r0";

% filepath = "/Users/xizheng/Documents/florin/respiration/K1/K1_20191217_r0.mat";
% name = "K1_20191217_r0";
% 
% filepath = "/Users/xizheng/Documents/florin/respiration/K1/K1_20191226_r0.mat";
% name = "K1_20191226_r0";
% 
% filepath = "/Users/xizheng/Documents/florin/respiration/K1/K1_20191227_r0.mat";
% name = "K1_20191227_r0";
% 
% % K4
% filepath = "/Users/xizheng/Documents/florin/respiration/K4/K4_20191217_r0.mat";
% name = "K4_20191217_r0";
% 
% filepath = "/Users/xizheng/Documents/florin/respiration/K4/K4_20191229_r1.mat";
% name = "K4_20191229_r1";
% 
filepath = "/Users/xizheng/Documents/florin/respiration/K4/K4_20200120_r0.mat";
name = "K4_20200120_r0";

% filepath = "/Users/xizheng/Documents/florin/respiration/PCX3/PCX3_20210316_r0.mat";
% name = "PCX3_20210316_r0";

save = 0;

[Traces, TrialInfo] = ParseBehaviorAndPhysiology(filepath);

%%

frequency_start = NaN(length(Traces.Lever), 3001);
frequency_reward_end = NaN(length(Traces.Lever), 3001);
rewards_trials = NaN(length(Traces.Lever), 1);

sniff_start = NaN(length(Traces.Lever), 3001);
sniff_reward_end = NaN(length(Traces.Lever), 3001);

frequency_odor_start = NaN(length(Traces.Lever), 3501);
sniff_odor_start = NaN(length(Traces.Lever), 3501);

for idx = 1:length(Traces.Lever)
    RespData = Traces.Sniffs{idx};
    if(isempty(RespData))
        continue
    end
    if(isnan(TrialInfo.OdorStart(idx,2)))
        continue
    end

    trial_on = Traces.Trial{idx};
    
    trial_start = find(diff(trial_on~=0) == 1, 1);
    trial_end = find(diff(trial_on~=0) == -1, 1, 'last');
    trial_duration = trial_end-trial_start+1;
    if trial_duration > 2500
        continue
    end
    
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
        frequency(locs_2(i):locs_2(i+1)-1) = 500/zci_interval_length(i);
    end
    
    sniffs = zeros(1, length(RespData));
    sniffs(locs_2) = 1;
    
    % align to trial start and rewards
    
    frequency_start(idx, 1:trial_end) = frequency(1:trial_end);
    sniff_start(idx, 1:trial_end) = sniffs(1:trial_end);
    
    odor_start_offset = TrialInfo.OdorStart(idx,2)*sr;
    
    frequency_odor_start(idx, -odor_start_offset+1:-odor_start_offset+trial_end) = frequency(1:trial_end);
    sniff_odor_start(idx, -odor_start_offset+1:-odor_start_offset+trial_end) = sniffs(1:trial_end);
    
    rewards_idx = find(rewards == 1);
    if TrialInfo.Success(idx)
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

amean = nanmean(frequency_start, 1);
astd = nanstd(frequency_start,[],1);
first_not_nan = find(~isnan(amean), 1);
last_not_nan = find(~isnan(amean), 1, 'last');
amean_notnan = amean(first_not_nan:last_not_nan);
astd_notnan = astd(first_not_nan:last_not_nan);
F1 = 2*(first_not_nan:last_not_nan);

figure;
plot(2*first_not_nan:2:2*last_not_nan, amean_notnan, 'color', 'k','linewidth', 1.5);
hold on;
fill([F1 fliplr(F1)],[amean_notnan+astd_notnan fliplr(amean_notnan-astd_notnan)], 'k', 'FaceAlpha', 0.5,'linestyle','none');
xline(1001, 'linewidth', 2);
xlim([0, 6000]);
ylim([0,15]);
xlabel('time (ms)');
ylabel('frequency (hz)');
title("sniffs aligned to trial start");
if save > 0
    f = gcf;
    exportgraphics(f,name + '_sniff_trial_start_rate.png','Resolution',300);
end

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
        line([sniff(j)*2 sniff(j)*2], [i-1 i],'Color','k', 'linewidth', 1.5);
    end
end
xline(1001, 'linewidth', 2);
xlim([0, 6000]);
xlabel('time (ms)');
ylabel('trial');
title("sniffs aligned to trial start");
if save > 0
    f = gcf;
    exportgraphics(f,name + '_sniff_trial_start_raster.png','Resolution',300);
end

%% sniff rate aligned to odor start

amean = nanmean(sniff_start, 1);
astd = nanstd(sniff_start,[],1);
first_not_nan = find(~isnan(amean), 1);
last_not_nan = find(~isnan(amean), 1, 'last');
amean_notnan = amean(first_not_nan:last_not_nan);

figure;
plot(2*first_not_nan:2:2*last_not_nan, smoothdata(amean_notnan, 'movmean', 11), 'color', 'k','linewidth', 1.5);
hold on;
xline(1001, 'linewidth', 2);
ylim([0,0.03]);
xlim([0, 6000]);
xlabel('time (ms)');
ylabel('smoothed sniff probability');
title("sniffs aligned to trial start");
if save > 0
    f = gcf;
    exportgraphics(f,name + '_sniff_trial_start_rate2.png','Resolution',300);
end

%% sniff rate aligned to reward

amean = nanmean(frequency_reward_end, 1);
astd = nanstd(frequency_reward_end,[],1);
first_not_nan = find(~isnan(amean), 1);
last_not_nan = find(~isnan(amean), 1, 'last');
amean_notnan = amean(first_not_nan:last_not_nan);
astd_notnan = astd(first_not_nan:last_not_nan);
F1 = 2*(first_not_nan:last_not_nan);

figure;
plot(2*first_not_nan:2:2*last_not_nan, amean_notnan, 'color', 'k','linewidth', 1.5);
hold on;
fill([F1 fliplr(F1)],[amean_notnan+astd_notnan fliplr(amean_notnan-astd_notnan)], 'k', 'FaceAlpha', 0.5,'linestyle','none');
xline(5001, 'linewidth', 2);
xlim([0, 6000]);
ylim([0,15]);
xlabel('time (ms)');
ylabel('frequency (hz)');
title("sniffs aligned to reward");
if save > 0
    f = gcf;
    exportgraphics(f,name + '_sniff_reward_rate.png','Resolution',300);
end



%% sniff raster plot aligned to reward

trial_lengths_reward = sum(~isnan(sniff_reward_end(:,1:2500)), 2);
[a_sorted_reward, a_order_reward] = sort(trial_lengths_reward, 'descend');
sniff_reward_sorted = sniff_reward_end(a_order_reward,:);
sniff_reward_sorted_valid = sniff_reward_sorted(~all(isnan(sniff_reward_sorted),2),:);

figure;
hold on;
for i = 1:size(sniff_reward_sorted_valid, 1)
    sniff = find(sniff_reward_sorted_valid(i,:) == 1);
    for j = 1:length(sniff)
        line([sniff(j)*2 sniff(j)*2], [i-1 i],'Color','k', 'linewidth', 1.5);
    end
end
xline(5001, 'linewidth', 2);
xlim([0, 6000]);
xlabel('time (ms)');
ylabel('trial');
title("sniffs aligned to reward");
if save > 0
    f = gcf;
    exportgraphics(f,name + '_sniff_reward_raster.png','Resolution',300);
end
%% sniff rate aligned to odor start

amean = nanmean(frequency_odor_start, 1);
astd = nanstd(frequency_odor_start,[],1);
first_not_nan = find(~isnan(amean), 1);
last_not_nan = find(~isnan(amean), 1, 'last');
amean_notnan = amean(first_not_nan:last_not_nan);
astd_notnan = astd(first_not_nan:last_not_nan);
F1 = 2*(first_not_nan:last_not_nan);

figure;
plot(2*first_not_nan:2:2*last_not_nan, amean_notnan, 'color', 'k','linewidth', 1.5);
hold on;
fill([F1 fliplr(F1)],[amean_notnan+astd_notnan fliplr(amean_notnan-astd_notnan)], 'k', 'FaceAlpha', 0.5,'linestyle','none');
xline(1001, 'linewidth', 2);
xlim([0, 7000]);
ylim([0,15]);
xlabel('time (ms)');
ylabel('frequency (hz)');
title("sniffs aligned to odor start");
if save > 0
    f = gcf;
    exportgraphics(f,name + '_sniff_odor_start_rate.png','Resolution',300);
end
%% sniff raster plot aligned to odor start

trial_lengths = sum(~isnan(sniff_odor_start(:,501:end)), 2);
[a_sorted, a_order] = sort(trial_lengths, 'descend');
sniff_start_sorted = sniff_odor_start(a_order,:);
sniff_start_sorted_valid = sniff_start_sorted(~all(isnan(sniff_start_sorted),2),:);

figure;
hold on;
for i = 1:size(sniff_start_sorted_valid, 1)
    sniff = find(sniff_start_sorted_valid(i,:) == 1);
    for j = 1:length(sniff)
        line([sniff(j)*2 sniff(j)*2], [i-1 i],'Color','k', 'linewidth', 1.5);
    end
end
xline(1001, 'linewidth', 2);
xlabel('time (ms)');
ylabel('trial');
xlim([0, 7000]);
title("sniffs aligned to odor start");
if save > 0
    f = gcf;
    exportgraphics(f,name + '_sniff_odor_start_raster.png','Resolution',300);
end

%% sniff rate aligned to odor start

amean = nanmean(sniff_odor_start, 1);
astd = nanstd(sniff_odor_start,[],1);
first_not_nan = find(~isnan(amean), 1);
last_not_nan = find(~isnan(amean), 1, 'last');
amean_notnan = amean(first_not_nan:last_not_nan);

figure;
plot(2*first_not_nan:2:2*last_not_nan, smoothdata(amean_notnan, 'movmean', 11), 'color', 'k','linewidth', 1.5);
hold on;
xline(1001, 'linewidth', 2);
xlim([0, 7000]);
ylim([0,0.03]);
xlabel('time (ms)');
ylabel('smoothed sniff probability');
title("sniffs aligned to odor start");
if save > 0
    f = gcf;
    exportgraphics(f,name + '_sniff_odor_start_rate2.png','Resolution',300);
end