filepath = "/Users/xizheng/Documents/florin/respiration/K1/K1_20191226_r0.mat";

%% read data

Temp = load(filepath,'session_data');
MyTraces = Temp.session_data.trace;
    
% get pressure sensor data
if find(ismember(Temp.session_data.trace_legend,'respiration'))
    whichcol = find(ismember(Temp.session_data.trace_legend,'respiration'));
    RespData = MyTraces(:,whichcol);
end

% get lever
if find(ismember(Temp.session_data.trace_legend,'lever_DAC'))
    whichcol = find(ismember(Temp.session_data.trace_legend,'lever_DAC'));
    lever = MyTraces(:,whichcol);
end

% get trial
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


%% lever

lever_smooth = smoothdata(lever, 'sgolay', 25, 'degree', 4);

velocity = gradient(lever_smooth);
velocity_smooth = smoothdata(velocity, 'sgolay', 25, 'degree', 4);

abs_velocity_smooth = abs(velocity_smooth);

figure;
hold on;
plot(respData_filtered);
plot(100*abs_velocity_smooth);
plot(trial_on);


%% parse movement by sniff

sniff_intervals = diff(locs_2);

move_sniff_trial = NaN(length(locs_2)-1, max(sniff_intervals)+50);
move_sniff_intertrial = NaN(length(locs_2)-1, max(sniff_intervals)+50);


for start_idx = 1:length(locs_2)-1
    if trial_on(locs_2(start_idx)) ~= 0
        move_sniff_trial(start_idx,1:sniff_intervals(start_idx)+50) = abs_velocity_smooth(locs_2(start_idx)-50:locs_2(start_idx+1)-1);
    else
        move_sniff_intertrial(start_idx,1:sniff_intervals(start_idx)+50) = abs_velocity_smooth(locs_2(start_idx)-50:locs_2(start_idx+1)-1);
    end
end

%% sort sniffs by duration

sniff_trial_lengths = sum(~isnan(move_sniff_trial), 2);
[a_sorted_trial, a_order_trial] = sort(sniff_trial_lengths);
move_sniff_trial_sorted = move_sniff_trial(a_order_trial,:);
move_sniff_trial_sorted_valid = move_sniff_trial_sorted(~all(isnan(move_sniff_trial_sorted),2),:);
sniff_trial_lengths_valid = sniff_trial_lengths(sniff_trial_lengths ~= 0) - 50;

sniff_intertrial_lengths = sum(~isnan(move_sniff_intertrial), 2);
[a_sorted_intertrial, a_order_intertrial] = sort(sniff_intertrial_lengths);
move_sniff_intertrial_sorted = move_sniff_intertrial(a_order_intertrial,:);
move_sniff_intertrial_sorted_valid = move_sniff_intertrial_sorted(~all(isnan(move_sniff_intertrial_sorted),2),:);
sniff_intertrial_lengths_valid = sniff_intertrial_lengths(sniff_intertrial_lengths ~= 0) - 50;

%% histogram of sniff duration in trial and intertrial

figure;
hold on;
histogram(sniff_trial_lengths_valid, 'binwidth', 5, 'normalization', 'probability', 'facecolor', 'b');
histogram(sniff_intertrial_lengths_valid, 'binwidth', 5, 'normalization', 'probability', 'facecolor','r');

%%

figure;
histogram(abs_velocity_smooth, 'BinWidth', 0.0001);


%% color plot of movement aligned to sniff

figure;
sc = imagesc(move_sniff_trial_sorted_valid, [0.01 0.03]);
colorbar
set(sc,'AlphaData',~isnan(move_sniff_trial_sorted_valid))
hold on;
xline(51, 'linewidth', 1);
title("during trial");

figure;
sc = imagesc(move_sniff_intertrial_sorted_valid, [0.01 0.03]);
colorbar
set(sc,'AlphaData',~isnan(move_sniff_intertrial_sorted_valid))
hold on;
xline(51, 'linewidth', 1);
title("inter trial");

%%

amean1_short = nanmean(move_sniff_trial_sorted_valid(1:200,:), 1);
astd_short = nanstd(move_sniff_trial_sorted_valid(1:200,:),[],1);
first_nan_1_short = find(isnan(amean1_short), 1);
amean1_notnan_short = amean1_short(1:first_nan_1_short-1);
astd1_notnan_short = astd_short(1:first_nan_1_short-1);
F1_short = 1:first_nan_1_short-1;

figure; hold on;
plot(amean1_notnan_short, 'color', 'b','linewidth', 1.5);
fill([F1_short fliplr(F1_short)],[amean1_notnan_short+astd1_notnan_short fliplr(amean1_notnan_short-astd1_notnan_short)], 'b', 'FaceAlpha', 0.5,'linestyle','none');
xline(51, 'linewidth', 2);

%% mean and std aligned to sniff
 
amean1 = nanmean(move_sniff_trial_sorted_valid, 1);
astd1 = nanstd(move_sniff_trial_sorted_valid,[],1);
first_nan_1 = find(isnan(amean1), 1);
amean1_notnan = amean1(1:first_nan_1-1);
astd1_notnan = astd1(1:first_nan_1-1);
F1 = 1:first_nan_1-1;

amean2 = nanmean(move_sniff_intertrial_sorted_valid, 1);
astd2 = nanstd(move_sniff_intertrial_sorted_valid,[],1);
F2 = 1:size(move_sniff_intertrial_sorted_valid,2);

figure; hold on;
plot(amean1_notnan, 'color', 'b','linewidth', 1.5);
fill([F1 fliplr(F1)],[amean1_notnan+astd1_notnan fliplr(amean1_notnan-astd1_notnan)], 'b', 'FaceAlpha', 0.5,'linestyle','none');
plot(amean2, 'color', 'r','linewidth', 1.5);
fill([F2 fliplr(F2)],[amean2+astd2 fliplr(amean2-astd2)], 'r', 'FaceAlpha', 0.5,'linestyle','none');
xline(51, 'linewidth', 2);

%%

% normalized cross correlation and coherence

% sniff_intervals = diff(locs_2);
% 
% move_sniff_trial_noextra = NaN(length(locs_2)-1, max(sniff_intervals));
% move_sniff_intertrial_noextra = NaN(length(locs_2)-1, max(sniff_intervals));
% sniff_trial = NaN(length(locs_2)-1, max(sniff_intervals));
% sniff_intertrial = NaN(length(locs_2)-1, max(sniff_intervals));
% 
% for start_idx = 1:length(locs_2)-1
%     if trial_on(locs_2(start_idx)) ~= 0
%         move_sniff_trial_noextra(start_idx,1:sniff_intervals(start_idx)) = abs_velocity_smooth(locs_2(start_idx):locs_2(start_idx+1)-1);
%         sniff_trial(start_idx,1:sniff_intervals(start_idx)) = respData_filtered(locs_2(start_idx):locs_2(start_idx+1)-1);
%     else
%         move_sniff_intertrial_noextra(start_idx,1:sniff_intervals(start_idx)) = abs_velocity_smooth(locs_2(start_idx):locs_2(start_idx+1)-1);
%         sniff_intertrial(start_idx,1:sniff_intervals(start_idx)) = respData_filtered(locs_2(start_idx):locs_2(start_idx+1)-1);
%     end
% end
% 
% move_sniff_trial_noextra_valid = move_sniff_trial_noextra(~all(isnan(move_sniff_trial_noextra),2),:);
% sniff_trial_valid = sniff_trial(~all(isnan(sniff_trial),2),:);
% 
% move_sniff_intertrial_noextra_valid = move_sniff_intertrial_noextra(~all(isnan(move_sniff_intertrial_noextra),2),:);
% sniff_intertrial_valid = sniff_intertrial(~all(isnan(move_sniff_intertrial_noextra),2),:);
% 
% minduration = min(sniff_intervals);
% 
% lags = -minduration:minduration;


%%

% % normalized_coh_trial = zeros(length(move_sniff_trial_noextra_valid), 2*minduration+1);
% i = 1;
%     
% sniff_trial = sniff_trial_valid(i, ~isnan(sniff_trial_valid(i,:)));
% move_trial = move_sniff_trial_noextra_valid(i, ~isnan(move_sniff_trial_noextra_valid(i,:)));
% 
% figure;
% plot(sniff_trial);
% hold on;
% plot(100*move_trial);
% 
% figure;
% plot(lags, xcorr(sniff_trial, move_trial, minduration, 'normalized'));
% 
% figure;
% mscohere(sniff_trial,move_trial);

%%
% 
% % cross correlation
% normalized_xcorrs_trial = zeros(length(move_sniff_trial_noextra_valid), 2*minduration+1);
% for i = 1:length(move_sniff_trial_noextra_valid)
%     
%     sniff_trial = sniff_trial_valid(i, ~isnan(sniff_trial_valid(i,:)));
%     move_trial = move_sniff_trial_noextra_valid(i, ~isnan(move_sniff_trial_noextra_valid(i,:)));
%     
%     normalized_xcorrs_trial(i,:) = xcorr(sniff_trial, move_trial, minduration, 'normalized');
% end
% 
% normalized_xcorrs_intertrial = zeros(length(move_sniff_intertrial_noextra_valid), 2*minduration+1);
% for i = 1:length(move_sniff_intertrial_noextra_valid)
%     
%     sniff_intertrial = sniff_intertrial_valid(i, ~isnan(sniff_intertrial_valid(i,:)));
%     move_intertrial = move_sniff_intertrial_noextra_valid(i, ~isnan(move_sniff_intertrial_noextra_valid(i,:)));
%     
%     normalized_xcorrs_intertrial(i,:) = xcorr(sniff_intertrial, move_intertrial, minduration, 'normalized');
% end
% 
% amean1 = nanmean(normalized_xcorrs_trial, 1);
% astd1 = nanstd(normalized_xcorrs_trial,[],1);
% amean2 = nanmean(normalized_xcorrs_intertrial, 1);
% astd2 = nanstd(normalized_xcorrs_intertrial,[],1);
% 
% figure;
% hold on;
% plot(lags, amean1, 'color', 'b','linewidth', 1.5);
% fill([lags fliplr(lags)],[amean1+astd1 fliplr(amean1-astd1)], 'b', 'FaceAlpha', 0.5,'linestyle','none');
% plot(lags, amean2, 'color', 'r','linewidth', 1.5);
% fill([lags fliplr(lags)],[amean2+astd2 fliplr(amean2-astd2)], 'r', 'FaceAlpha', 0.5,'linestyle','none');
% 