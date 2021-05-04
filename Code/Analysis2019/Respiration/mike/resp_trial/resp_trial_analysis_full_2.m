filepath = "/Users/xizheng/Documents/florin/respiration/K1/K1_20191226_r0.mat";

[Traces, TrialInfo] = ParseBehaviorAndPhysiology(filepath);

sniff_intervals = [];
move_intervals = [];
sniff_intervals_null = [];
move_intervals_null = [];

for idx = 1:length(Traces.Lever)
    RespData = Traces.Sniffs{idx};
    if(isempty(RespData))
        continue
    end
    
    trial_on = Traces.Trial{idx};

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
    
    lever = Traces.Lever{idx};

    % smooth lever
    lever_smooth = smoothdata(lever, 'sgolay', 25, 'degree', 4);

    % find peaks
    [mov_pks_1,mov_locs_1,mov_w_1,mov_p_1] = findpeaks(lever_smooth, 'MinPeakProminence', 0.03, 'MinPeakDistance', 5);
    [mov_pks_2,mov_locs_2,mov_w_2,mov_p_2] = findpeaks(-lever_smooth, 'MinPeakProminence', 0.03, 'MinPeakDistance', 5);

    mov_locs = sort(cat(1, mov_locs_1,mov_locs_2));

    
    mov_locs_trial = mov_locs(ismember(mov_locs, find(trial_on~=0)));
    zero_crossings_trial = zero_crossings(ismember(zero_crossings, find(trial_on~=0)));

    null_sniff = sort(randsample(find(trial_on~=0),length(zero_crossings_trial)));
    null_move = sort(randsample(find(trial_on~=0),length(mov_locs_trial)));
    
    sniff_interval = diff(zero_crossings_trial);
    sniff_intervals(end+1:end+length(sniff_interval)) = sniff_interval;
    move_interval = diff(mov_locs_trial);
    move_intervals(end+1:end+length(move_interval)) = move_interval;
    
    sniff_interval_null = diff(null_sniff);
    sniff_intervals_null(end+1:end+length(sniff_interval_null)) = sniff_interval_null;
    move_interval_null = diff(null_move);
    move_intervals_null(end+1:end+length(move_interval_null)) = move_interval_null;
    
end

figure;
h1 = histogram(sniff_intervals);
hold on;
h2 = histogram(sniff_intervals_null);
h1.BinWidth = 5;
h2.BinWidth = 5;
title(sprintf("sniff interval (mean:%.2f, median:%.2f, sd:%.2f)\n", mean(sniff_intervals), median(sniff_intervals), std(sniff_intervals)));

figure;
h1 = histogram(move_intervals);
hold on;
h2 = histogram(move_intervals_null);
h1.BinWidth = 2;
h2.BinWidth = 2;
title(sprintf("move interval (mean:%.2f, median:%.2f, sd:%.2f)\n", mean(move_intervals), median(move_intervals), std(move_intervals)));
