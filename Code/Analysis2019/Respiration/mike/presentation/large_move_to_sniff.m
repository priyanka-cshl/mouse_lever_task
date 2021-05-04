clear all;

%%
% K1
filepath = "/Users/xizheng/Documents/florin/respiration/K1/K1_20191215_r0.mat";
name = "K1_20191215_r0";

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
% filepath = "/Users/xizheng/Documents/florin/respiration/K4/K4_20200120_r0.mat";
% name = "K4_20200120_r0";

save = 0;

[Traces, TrialInfo] = ParseBehaviorAndPhysiology(filepath);

%%

sniff_large_move_full = zeros(1, 1000);

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
    
    % sniffs
    
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
    
    sniffs = zeros(1, length(RespData));
    sniffs(locs_2) = 1;
    
    % moves
    lever = Traces.Lever{idx};
    lever_smooth = smoothdata(lever, 'sgolay', 25, 'degree', 4);
    
    [mov_pks_1,mov_locs_1,mov_w_1,mov_p_1] = findpeaks(lever_smooth, 'MinPeakProminence', 0.01, 'MinPeakDistance', 5);
    [mov_pks_2,mov_locs_2,mov_w_2,mov_p_2] = findpeaks(-lever_smooth, 'MinPeakProminence', 0.01, 'MinPeakDistance', 5);
    mov_locs = sort(cat(1, mov_locs_1, mov_locs_2));
    
    movement = zeros(length(mov_locs)-1, 1);
    for i = 1:length(mov_locs)-1
        movement(i) = abs(lever(mov_locs(i+1)) - lever(mov_locs(i)));
    end
    movement_signal = zeros(length(lever), 1);
    movement_signal(mov_locs(1:end-1)) = movement;
    large_thresh = 1;
    movement_signal = movement_signal > large_thresh;
    
%     figure; hold on;
%     plot(respData_filtered);
%     plot(lever_smooth);
%     plot(mov_locs, lever_smooth(mov_locs), 'or');
%     plot(movement_signal*5)
%     plot(trial_on)
%     break

%     figure; hold on;
%     plot(lever_smooth);
%     plot(locs_2, lever_smooth(locs_2), 'ob');
%     plot(movement_signal*5)
%     plot(trial_on~=0)

    trial_start = find(diff(trial_on)>0, 1);

    sniff_intervals = diff(locs_2);
    sniff_large_moves = NaN(length(locs_2)-1, 1000);
    for start_idx = 1:length(locs_2)-1
        if trial_on(locs_2(start_idx)) ~= 0 && locs_2(start_idx) > trial_start-1
            sniff_large_moves(start_idx,1:sniff_intervals(start_idx)+50) = movement_signal(locs_2(start_idx)-50:locs_2(start_idx+1)-1);
        end
    end
    
    sniff_large_move_full = vertcat(sniff_large_move_full, sniff_large_moves);
%     break

end

%%

sniff_large_move_lengths = sum(~isnan(sniff_large_move_full), 2);
[a_sorted, a_order] = sort(sniff_large_move_lengths, 'descend');
sniff_large_move_sorted = sniff_large_move_full(a_order,:);
sniff_large_move_sorted_valid = sniff_large_move_sorted(~all(isnan(sniff_large_move_sorted),2),:);

sniff_large_move_sorted_valid_wmove = sniff_large_move_sorted_valid(nansum(sniff_large_move_sorted_valid, 2)~=0,:);

%%

figure;
hold on;
for i = 1:size(sniff_large_move_sorted_valid_wmove, 1)
    move = find(sniff_large_move_sorted_valid_wmove(i,:) == 1);
    for j = 1:length(move)
        line([move(j)*2 move(j)*2], [i-1 i],'Color','k', 'linewidth', 2);
    end
end
xline(101, 'linewidth', 2);
xlim([0 800]);
xlabel('time (ms)');
ylabel('sniff');
title("large moves aligned to sniff");
if save > 0
    f = gcf;
    exportgraphics(f,name + '_large_move_to_sniff_raster.png','Resolution',300);
end
%%

amean = nanmean(sniff_large_move_sorted_valid_wmove, 1);
astd = nanstd(sniff_large_move_sorted_valid_wmove,[],1);
first_not_nan = find(~isnan(amean), 1);
last_not_nan = find(~isnan(amean), 1, 'last');
amean_notnan = amean(first_not_nan:last_not_nan);

figure;
plot(2*first_not_nan:2:2*last_not_nan, smoothdata(amean_notnan, 'movmean', 5), 'color', 'k','linewidth', 1.5);
hold on;
xline(101, 'linewidth', 2);
xlim([0 800]);
ylim([0 0.02]);
xlabel('time (ms)');
ylabel('smoothed move probability');
title("large moves aligned to sniff");
if save > 0
    f = gcf;
    exportgraphics(f,name + '_large_move_to_sniff_rate.png','Resolution',300);
end
