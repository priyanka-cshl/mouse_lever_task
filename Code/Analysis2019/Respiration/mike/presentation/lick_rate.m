filepath = "/Users/xizheng/Documents/florin/respiration/K1/K1_20191226_r0.mat";
name = "K1_20191226_r0";
% 
% filepath = "/Users/xizheng/Documents/florin/respiration/K1/K1_20191217_r0.mat";
% name = "K1_20191217_r0";
% 
% filepath = "/Users/xizheng/Documents/florin/respiration/K4/K4_20200120_r0.mat";
% name = "K4_20200120_r0";

save = 0;

[Traces, TrialInfo] = ParseBehaviorAndPhysiology(filepath);

%%

frequency_start = NaN(length(Traces.Lever), 3001);
frequency_reward_end = NaN(length(Traces.Lever), 3001);
rewards_trials = NaN(length(Traces.Lever), 1);

lick_start = NaN(length(Traces.Lever), 3001);
lick_reward_end = NaN(length(Traces.Lever), 3001);

frequency_odor_start = NaN(length(Traces.Lever), 3501);
lick_odor_start = NaN(length(Traces.Lever), 3501);

for idx = 1:length(Traces.Lever)
    licks = Traces.Licks{idx};
    if(isempty(licks))
        continue
    end

    trial_on = Traces.Trial{idx};
    rewards = Traces.Rewards{idx};

    locs_2 = find(licks ~= 0);

    lick_interval_length = diff(locs_2);

    sr = 500;

    frequency = NaN(1, length(licks));
    for i = 1:length(locs_2)-1
        frequency(locs_2(i):locs_2(i+1)-1) = 500/lick_interval_length(i);
    end
    
    % align to trial start and rewards
    trial_start = find(diff(trial_on~=0) == 1, 1);
    trial_end = find(diff(trial_on~=0) == -1, 1, 'last');
    trial_duration = trial_end-trial_start+1;
    
    frequency_start(idx, 1:trial_end) = frequency(1:trial_end);
    lick_start(idx, 1:trial_end) = licks(1:trial_end);
    
    odor_start_offset = TrialInfo.OdorStart(idx,2)*sr;
    
    frequency_odor_start(idx, -odor_start_offset+1:-odor_start_offset+trial_end) = frequency(1:trial_end);
    lick_odor_start(idx, -odor_start_offset+1:-odor_start_offset+trial_end) = licks(1:trial_end);
    
    rewards_idx = find(rewards == 1);
    if TrialInfo.Success(idx)
        rewards_trials(idx) = rewards_idx(1);
        
        frequency_reward_end(idx, 2500-trial_duration+1:2500) = frequency(trial_start:trial_end);
        lick_reward_end(idx, 2500-trial_duration+1:2500) = licks(trial_start:trial_end);
        
        if ((length(frequency) - trial_end) > 500)
            frequency_reward_end(idx, 2501:end) = frequency(trial_end+1:trial_end+501);
            lick_reward_end(idx, 2501:end) = licks(trial_end+1:trial_end+501);
        else
            frequency_reward_end(idx, 2501:2500+length(frequency)-trial_end) = frequency(trial_end+1:end);
            lick_reward_end(idx, 2501:2500+length(licks)-trial_end) = licks(trial_end+1:end);
        end
    end
    
%     figure; hold on;
%     plot(Traces.Lever{idx});
%     plot(Traces.Sniffs{idx});
%     plot(Traces.Licks{idx});
%     
%     break
    
end

%% lick rate aligned to trial start

amean = nanmean(lick_start, 1);
astd = nanstd(lick_start,[],1);
first_not_nan = find(~isnan(amean), 1);
last_not_nan = find(~isnan(amean), 1, 'last');
amean_notnan = amean(first_not_nan:last_not_nan);
astd_notnan = astd(first_not_nan:last_not_nan);
F1 = 2*(first_not_nan:last_not_nan);

figure;
plot(2*first_not_nan:2:2*last_not_nan, smoothdata(amean_notnan, 'movmean', 15), 'color', 'k','linewidth', 1.5);hold on;
% fill([F1 fliplr(F1)],[amean_notnan+astd_notnan fliplr(amean_notnan-astd_notnan)], 'k', 'FaceAlpha', 0.5,'linestyle','none');
xline(1001, 'linewidth', 2);
ylim([0,0.05]);
xlabel('time (ms)');
ylabel('smoothed lick probability');
title("licks aligned to trial start");
if save > 0
    f = gcf;
    exportgraphics(f,name + '_lick_trial_start_rate.png','Resolution',300);
end

%% lick raster plot aligned to trial start

trial_lengths = sum(~isnan(lick_start), 2);
[a_sorted, a_order] = sort(trial_lengths, 'descend');
lick_start_sorted = lick_start(a_order,:);
lick_start_sorted_valid = lick_start_sorted(~all(isnan(lick_start_sorted),2),:);

a_order_valid = a_order(~all(isnan(lick_start_sorted),2));

figure;
hold on;
for i = 1:size(lick_start_sorted_valid, 1)
%     trial_idx = a_order_valid(i);
%     inzone = TrialInfo.InZone{trial_idx}*500;
%     for j = 1:size(inzone, 1)
%         rectangle('Position',[inzone(j, 1)*2 i-1 2*(inzone(j, 2)-inzone(j, 1)) 1] ,'FaceColor',[1. 1. 0. .3], 'EdgeColor', [1. 1. 0. .3]);
%     end
%     
    lick = find(lick_start_sorted_valid(i,:) == 1);
    for j = 1:length(lick)
        line([lick(j)*2 lick(j)*2], [i-1 i],'Color','k', 'linewidth', 1.5);
    end
end
xline(1001, 'linewidth', 2);
xlabel('time (ms)');
ylabel('trial');
title("licks aligned to trial start");
if save > 0
    f = gcf;
    exportgraphics(f,name + '_lick_trial_start_raster.png','Resolution',300);
end
%% lick rate aligned to reward

amean = nanmean(lick_reward_end, 1);
astd = nanstd(lick_reward_end,[],1);
first_not_nan = find(~isnan(amean), 1);
last_not_nan = find(~isnan(amean), 1, 'last');
amean_notnan = amean(first_not_nan:last_not_nan);
astd_notnan = astd(first_not_nan:last_not_nan);
F1 = 2*(first_not_nan:last_not_nan);

figure;
plot(2*first_not_nan:2:2*last_not_nan, smoothdata(amean_notnan, 'movmean', 15), 'color', 'k','linewidth', 1.5);
hold on;
% fill([F1 fliplr(F1)],[amean_notnan+astd_notnan fliplr(amean_notnan-astd_notnan)], 'k', 'FaceAlpha', 0.5,'linestyle','none');
xline(5001, 'linewidth', 2);
ylim([0,0.05]);
xlabel('time (ms)');
ylabel('smoothed lick probability');
title("licks aligned to reward");
if save > 0
    f = gcf;
    exportgraphics(f,name + '_lick_reward_rate.png','Resolution',300);
end

%% lick raster plot aligned to reward

trial_lengths_reward = sum(~isnan(lick_reward_end(:,1:2500)), 2);
[a_sorted_reward, a_order_reward] = sort(trial_lengths_reward, 'descend');
lick_reward_sorted = lick_reward_end(a_order_reward,:);
lick_reward_sorted_valid = lick_reward_sorted(~all(isnan(lick_reward_sorted),2),:);

figure;
hold on;
for i = 1:size(lick_reward_sorted_valid, 1)
    lick = find(lick_reward_sorted_valid(i,:) == 1);
    for j = 1:length(lick)
        line([lick(j)*2 lick(j)*2], [i-1 i],'Color','k', 'linewidth', 1.5);
    end
end
xline(5001, 'linewidth', 2);
xlabel('time (ms)');
ylabel('trial');
title("licks aligned to reward");
if save > 0
    f = gcf;
    exportgraphics(f,name + '_lick_reward_raster.png','Resolution',300);
end
%% lick rate aligned to odor start

amean = nanmean(lick_odor_start, 1);
astd = nanstd(lick_odor_start,[],1);
first_not_nan = find(~isnan(amean), 1);
last_not_nan = find(~isnan(amean), 1, 'last');
amean_notnan = amean(first_not_nan:last_not_nan);
astd_notnan = astd(first_not_nan:last_not_nan);
F1 = 2*(first_not_nan:last_not_nan);

figure;
plot(2*first_not_nan:2:2*last_not_nan, smoothdata(amean_notnan, 'movmean', 15), 'color', 'k','linewidth', 1.5);
hold on;
% fill([F1 fliplr(F1)],[amean_notnan+astd_notnan fliplr(amean_notnan-astd_notnan)], 'k', 'FaceAlpha', 0.5,'linestyle','none');
xline(1001, 'linewidth', 2);
ylim([0,0.05]);
xlabel('time (ms)');
ylabel('smoothed lick probability');
title("licks aligned to odor start");
if save > 0
    f = gcf;
    exportgraphics(f,name + '_lick_odor_start_rate.png','Resolution',300);
end
%% lick raster plot aligned to odor start

trial_lengths = sum(~isnan(lick_odor_start(:,501:end)), 2);
[a_sorted, a_order] = sort(trial_lengths, 'descend');
lick_start_sorted = lick_odor_start(a_order,:);
lick_start_sorted_valid = lick_start_sorted(~all(isnan(lick_start_sorted),2),:);

figure;
hold on;
for i = 1:size(lick_start_sorted_valid, 1)
    lick = find(lick_start_sorted_valid(i,:) == 1);
    for j = 1:length(lick)
        line([lick(j)*2 lick(j)*2], [i-1 i],'Color','k', 'linewidth', 1.5);
    end
end
xline(1001, 'linewidth', 2);
xlabel('time (ms)');
ylabel('trial');
title("licks aligned to odor start");
if save > 0
    f = gcf;
    exportgraphics(f,name + '_lick_odor_start_raster.png','Resolution',300);
end