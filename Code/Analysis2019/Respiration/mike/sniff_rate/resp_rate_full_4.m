filepath = "/Users/xizheng/Documents/florin/respiration/K1/K1_20191226_r0.mat";

[Traces, TrialInfo] = ParseBehaviorAndPhysiology(filepath);

%%

frequency_odor_start = NaN(length(Traces.Lever), 3501);
sniff_odor_start = NaN(length(Traces.Lever), 3501);

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
    
    odor_start_offset = TrialInfo.OdorStart(idx,2)*sr;
    
    % align to trial start and rewards
    trial_start = find(diff(trial_on~=0) == 1, 1);
    trial_end = find(diff(trial_on~=0) == -1, 1, 'last');
    trial_duration = trial_end-trial_start+1;

    frequency_odor_start(idx, -odor_start_offset:-odor_start_offset+trial_end-1) = frequency(1:trial_end);
    sniff_odor_start(idx, -odor_start_offset:-odor_start_offset+trial_end-1) = sniffs(1:trial_end);
    
%     figure; hold on;
%     plot(frequency);
%     plot(501+odor_start_offset, frequency(501+odor_start_offset), 'or');
%     plot(frequency_odor_start(idx,:));
%     plot(501, frequency_odor_start(idx, 501), 'ob');
%     
end

%% sniff rate aligned to odor start

amean1 = nanmean(frequency_odor_start, 1);
astd1 = nanstd(frequency_odor_start,[],1);
first_not_nan = find(~isnan(amean1), 1);
last_not_nan = find(~isnan(amean1), 1, 'last');
amean1_notnan = amean1(first_not_nan:last_not_nan);
astd1_notnan = astd1(first_not_nan:last_not_nan);
F1 = first_not_nan:last_not_nan;

figure;
plot(amean1_notnan, 'color', 'k','linewidth', 1.5);
hold on;
fill([F1 fliplr(F1)],[amean1_notnan+astd1_notnan fliplr(amean1_notnan-astd1_notnan)], 'k', 'FaceAlpha', 0.5,'linestyle','none');
xline(501, 'linewidth', 2);
ylim([0,10]);
title("aligned to odor start");

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
        line([sniff(j) sniff(j)], [i-1 i],'Color','k', 'linewidth', 2);
    end
end
xline(501, 'linewidth', 2);
title("aligned to odor start");

