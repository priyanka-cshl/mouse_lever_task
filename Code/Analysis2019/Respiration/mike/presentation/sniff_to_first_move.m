clear all;

%%
% K1
filepath = "/Users/xizheng/Documents/florin/respiration/K1/K1_20191215_r0.mat";
name = "K1_20191215_r0";
% 
% filepath = "/Users/xizheng/Documents/florin/respiration/K1/K1_20191217_r0.mat";
% name = "K1_20191217_r0";
% 
% filepath = "/Users/xizheng/Documents/florin/respiration/K1/K1_20191226_r0.mat";
% name = "K1_20191226_r0";
% 
% filepath = "/Users/xizheng/Documents/florin/respiration/K1/K1_20191227_r0.mat";
% name = "K1_20191227_r0";
% % 
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

peri_first_move_start_sniffs = zeros(1,201);
peri_first_move_end_sniffs = zeros(1,201);
first_move_length = NaN(length(Traces.Lever), 1);

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
    
    first_move_start = find(diff(trial_on)>0, 1);
    first_move_end = mov_locs_2(find(mov_locs_2 > first_move_start, 1));
    large_thresh = 1;
    
    if abs(lever_smooth(first_move_end) - lever_smooth(first_move_start)) > large_thresh
        peri_first_move_start_sniffs = vertcat(peri_first_move_start_sniffs, sniffs(first_move_start-100:first_move_start+100));
        peri_first_move_end_sniffs = vertcat(peri_first_move_end_sniffs, sniffs(first_move_end-100:first_move_end+100));
        first_move_length(idx) = first_move_end-first_move_start;
    end
    
    
%     figure; hold on;
%     plot(respData_filtered);
%     plot(lever_smooth);
%     plot(first_move_start, lever_smooth(first_move_start), 'or');
%     plot(first_move_end, lever_smooth(first_move_end), 'ob');
% %     plot(movement_signal*5)
%     plot(trial_on)
%     break
end

peri_first_move_start_sniffs = peri_first_move_start_sniffs(2:end,:);
peri_first_move_end_sniffs = peri_first_move_end_sniffs(2:end,:);

%% histogram of first move duration

first_move_length=(first_move_length(~isnan(first_move_length)));

figure;
histogram(first_move_length, 'binwidth', 2);

%% sniff aligned to first large move start, raster

figure;
hold on;
for i = 1:size(peri_first_move_start_sniffs, 1)
    sniff = find(peri_first_move_start_sniffs(i,:) == 1);
    for j = 1:length(sniff)
        line([sniff(j)*2 sniff(j)*2], [i-1 i],'Color','k', 'linewidth', 2);
    end
end
xline(201, 'linewidth', 2);
xlabel('time (ms)');
ylabel('first large move');
xlim([0 401]);
title("sniffs aligned to first move start");
if save > 0
    f = gcf;
    exportgraphics(f,name + '_sniff_to_first_move_start_raster.png','Resolution',300);
end

%% sniff aligned to first large move start, rate

amean = nanmean(peri_first_move_start_sniffs, 1);
astd = nanstd(peri_first_move_start_sniffs,[],1);
first_not_nan = find(~isnan(amean), 1);
last_not_nan = find(~isnan(amean), 1, 'last');
amean_notnan = amean(first_not_nan:last_not_nan);

figure;
plot(2*first_not_nan:2:2*last_not_nan, smoothdata(amean_notnan, 'movmean', 11), 'color', 'k','linewidth', 1.5);
hold on;
xline(201, 'linewidth', 2);
xlim([0 401]);
xlabel('time (ms)');
ylabel('smoothed sniff probability');
title("sniffs aligned to first move start");
if save > 0
    f = gcf;
    exportgraphics(f,name + '_sniff_to_first_move_start_rate.png','Resolution',300);
end

%% sniff aligned to first large move end, raster

figure;
hold on;
for i = 1:size(peri_first_move_end_sniffs, 1)
    sniff = find(peri_first_move_end_sniffs(i,:) == 1);
    for j = 1:length(sniff)
        line([sniff(j)*2 sniff(j)*2], [i-1 i],'Color','k', 'linewidth', 2);
    end
end
xline(201, 'linewidth', 2);
xlabel('time (ms)');
ylabel('first large move');
xlim([0 401]);
title("sniffs aligned to first move end");
if save > 0
    f = gcf;
    exportgraphics(f,name + '_sniff_to_first_move_end_raster.png','Resolution',300);
end

%% sniff aligned to first large move end, rate

amean = nanmean(peri_first_move_end_sniffs, 1);
astd = nanstd(peri_first_move_end_sniffs,[],1);
first_not_nan = find(~isnan(amean), 1);
last_not_nan = find(~isnan(amean), 1, 'last');
amean_notnan = amean(first_not_nan:last_not_nan);

figure;
plot(2*first_not_nan:2:2*last_not_nan, smoothdata(amean_notnan, 'movmean', 11), 'color', 'k','linewidth', 1.5);
hold on;
xline(201, 'linewidth', 2);
xlim([0 401]);
xlabel('time (ms)');
ylabel('smoothed sniff probability');
title("sniffs aligned to first move end");
if save > 0
    f = gcf;
    exportgraphics(f,name + '_sniff_to_first_move_end_rate.png','Resolution',300);
end
