filepath = "/Users/xizheng/Documents/florin/respiration/K1/K1_20191226_r0.mat";

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

% locs_2 = zero_crossings;

zci_interval_length = diff(locs_2);

%% convert time to frequency

sr = 500;

figure;
histogram(sr./zci_interval_length, 100);

%%

frequency = zeros(1, length(RespData));
for i = 1:length(locs_2)-1
    frequency(locs_2(i):locs_2(i+1)) = 500/zci_interval_length(i);
end

figure;
plot(respData_filtered);
hold on;
plot(zero_crossings, respData_filtered(zero_crossings),'og');
plot(frequency);
plot(trial_on ~= 0);

