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
% used this session, idx 31 for an example

save = 0;

[Traces, TrialInfo] = ParseBehaviorAndPhysiology(filepath);

%%

peri_move_sniffs = zeros(1,201);

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
    
    trial_start = find(diff(trial_on)>0, 1);
    
    for start_idx = 1:length(mov_locs)-1
        if trial_on(mov_locs(start_idx))~=0 && mov_locs(start_idx) > trial_start-1 && movement_signal(mov_locs(start_idx)) > 0
            peri_move_sniffs = vertcat(peri_move_sniffs, sniffs(mov_locs(start_idx)-100:mov_locs(start_idx)+100));
        end
    end
    
%     figure; hold on;
%     plot(lever_smooth, 'linewidth', 1);
%     plot(5*(trial_on~=0), 'linewidth', 1)
%     plot(Traces.Licks{idx}, 'linewidth', 1)
%     plot(mov_locs, lever_smooth(mov_locs), 'or');
%     set(gcf,'position',[0,0,1200,400])
%     
%     figure; hold on;
% % %     plot(respData_filtered);
%     plot(lever_smooth, 'linewidth', 1);
%     plot(5*(trial_on~=0), 'linewidth', 1)
%     plot(Traces.Licks{idx}, 'linewidth', 1)
%     for i = 1:length(locs_2)
%         xline(locs_2(i), 'linewidth', 1)
%     end
%     plot(501, lever_smooth(501), 'ob', 'linewidth', 1)
%     plot(mov_locs_2(find(mov_locs_2 > 501, 1)), lever_smooth(mov_locs_2(find(mov_locs_2 > 501, 1))), 'oc', 'linewidth', 1)
%     plot(intersect(find(movement_signal > 0), find(trial_on ~= 0)), lever_smooth(intersect(find(movement_signal > 0), find(trial_on ~= 0))), '+r', 'linewidth', 1);
%     set(gcf,'position',[0,0,1200,400])
%     break
    
end

peri_move_sniffs = peri_move_sniffs(2:end, :);

%%

figure;
hold on;
for i = 1:size(peri_move_sniffs, 1)
    sniff = find(peri_move_sniffs(i,:) == 1);
    for j = 1:length(sniff)
        line([sniff(j)*2 sniff(j)*2], [i-1 i],'Color','k', 'linewidth', 2);
    end
end
xline(201, 'linewidth', 2);
xlabel('time (ms)');
ylabel('large move');
xlim([0 401]);
title("sniffs aligned to large move");
if save > 0
    f = gcf;
    exportgraphics(f,name + '_sniff_to_large_move_raster.png','Resolution',300);
end

%%

amean = nanmean(peri_move_sniffs, 1);
astd = nanstd(peri_move_sniffs,[],1);
first_not_nan = find(~isnan(amean), 1);
last_not_nan = find(~isnan(amean), 1, 'last');
amean_notnan = amean(first_not_nan:last_not_nan);

figure;
plot(2*first_not_nan:2:2*last_not_nan, smoothdata(amean_notnan, 'movmean', 11), 'color', 'k','linewidth', 1.5);
hold on;
xline(201, 'linewidth', 2);
xlim([0 401]);
ylim([0 0.03]);
xlabel('time (ms)');
ylabel('smoothed sniff probability');
title("sniffs aligned to large move");
if save > 0
    f = gcf;
    exportgraphics(f,name + '_sniff_to_large_move_raster_rate.png','Resolution',300);
end