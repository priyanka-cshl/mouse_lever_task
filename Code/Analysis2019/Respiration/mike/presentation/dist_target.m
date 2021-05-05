
% K1
% filepath = "/Users/xizheng/Documents/florin/respiration/K1/K1_20191215_r0.mat";
% name = "K1_20191215_r0";
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
filepath = "/Users/xizheng/Documents/florin/respiration/K4/K4_20200120_r0.mat";
name = "K4_20200120_r0";

% filepath = "/Users/xizheng/Documents/florin/respiration/PCX3/PCX3_20210309_r0.mat";
% name = "PCX3_20210309_r0";

save = 1;

[Traces, TrialInfo] = ParseBehaviorAndPhysiology(filepath);

%%

average_lever_trace = NaN(13, length(Traces.Lever), 3501);
distance_odor_start_all = NaN(length(Traces.Lever), 3501);

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
    
    targetzonetype = TrialInfo.TargetZoneType(idx);
    
    sr = 500;
    odor_start_offset = TrialInfo.OdorStart(idx,2)*sr;
    if odor_start_offset > 0
        odor_start_offset = 0;
    end
   

    lever = Traces.Lever{idx};
    lever_smooth = smoothdata(lever, 'sgolay', 25, 'degree', 4);

    distance = Traces.Motor{idx};
    distance_abs = abs(distance);

    average_lever_trace(targetzonetype, idx, -odor_start_offset+1:-odor_start_offset+trial_end) = lever_smooth(1:trial_end);
    distance_odor_start_all(idx, -odor_start_offset+1:-odor_start_offset+trial_end) = distance_abs(1:trial_end);

end


%%

for i = 1:12

    amean = nanmean(squeeze(average_lever_trace(i,:,:)), 1);
    astd = nanstd(squeeze(average_lever_trace(i,:,:)),[],1);
    first_not_nan = find(~isnan(amean), 1);
    last_not_nan = find(~isnan(amean), 1, 'last');
    amean_notnan = amean(first_not_nan:last_not_nan);
    astd_notnan = astd(first_not_nan:last_not_nan);
    F1 = 2*(first_not_nan:last_not_nan);

    figure; hold on;
    rectangle('Position', [1000,0.45+i*0.25, 4000, 0.6], 'FaceColor', 'y', 'EdgeColor', 'y');
    plot(2*first_not_nan:2:2*last_not_nan, amean_notnan, 'color', 'k','linewidth', 1.5);
    fill([F1 fliplr(F1)],[amean_notnan+astd_notnan fliplr(amean_notnan-astd_notnan)], 'k', 'FaceAlpha', 0.5,'linestyle','none');
    xline(1001, 'linewidth', 2);
    xlim([0, 4000]);

    ylim([-0.1, 5.1]);
    xlabel('time (ms)');
    ylabel('lever position');
    title("average lever trace aligned to odor start; target: " + int2str(i));
    if save > 0
        f = gcf;
        exportgraphics(f,name + '_'+ int2str(i) + '_trace_.png','Resolution',300);
    end
end


%%

amean = nanmean(distance_odor_start_all, 1);
astd = nanstd(distance_odor_start_all,[],1);
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
xlim([0, 4000]);
% xline(1082, 'linewidth', 2, 'linestyle', ':', 'color', 'r');
% xline(1246, 'linewidth', 2, 'linestyle', ':', 'color', 'r');
% ylim([-0.1, 5.1]);
ylim([0, 110]);
xlabel('time (ms)');
ylabel('average distance to center');
title("average distance aligned to odor start");
if save > 0
    f = gcf;
    exportgraphics(f,name + '_dist.png','Resolution',300);
end
