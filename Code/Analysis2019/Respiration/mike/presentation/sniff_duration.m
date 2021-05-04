filepath = "/Users/xizheng/Documents/florin/respiration/K1/K1_20191215_r0.mat";
name = "K1_20191215_r0";

%% read data

Temp = load(filepath,'session_data');
MyTraces = Temp.session_data.trace;
    
% get pressure sensor data
if find(ismember(Temp.session_data.trace_legend,'respiration'))
    whichcol = find(ismember(Temp.session_data.trace_legend,'respiration'));
    RespData = MyTraces(:,whichcol);
end

% get pressure sensor data
if find(ismember(Temp.session_data.trace_legend,'trial_on'))
    whichcol = find(ismember(Temp.session_data.trace_legend,'trial_on'));
    trial_on = MyTraces(:,whichcol);
end

%%

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

%%

sniff_duration_trial = NaN(1, length(locs_2)-1);
sniff_duration_iti = NaN(1, length(locs_2)-1);

for start_idx = 1:length(locs_2)-1
    if trial_on(locs_2(start_idx))>0
        sniff_duration_trial(start_idx) = zci_interval_length(start_idx);
    else
        sniff_duration_iti(start_idx) = zci_interval_length(start_idx);
    end
end

sniff_duration_trial_valid = sniff_duration_trial(~isnan(sniff_duration_trial));
sniff_duration_trial_valid = 2*sniff_duration_trial_valid;

sniff_duration_iti_valid = sniff_duration_iti(~isnan(sniff_duration_iti));
sniff_duration_iti_valid = 2*sniff_duration_iti_valid;

%%

figure; hold on;
histogram(sniff_duration_trial_valid, 'binwidth', 10, 'normalization', 'probability', 'facecolor', '[0, 0.4470, 0.7410]');
histogram(sniff_duration_iti_valid, 'binwidth', 10, 'normalization', 'probability', 'facecolor', '[0.8500, 0.3250, 0.0980]');
xlabel('time (ms)');
ylabel('probability');
title('sniff duration');
f = gcf;
exportgraphics(f,name + '_sniff_duration.png','Resolution',300);