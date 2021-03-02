FileName = '/Users/xizheng/Documents/florin/Therm3/Therm3_20190928_r0.mat';

%% load the file
Temp = load(FileName,'session_data');
MyTraces = Temp.session_data.trace;

% get thermistor data
if find(ismember(Temp.session_data.trace_legend,'lickpiezo'))
    whichcol = find(ismember(Temp.session_data.trace_legend,'lickpiezo'));
    Thermistor = MyTraces(:,whichcol);
end
    
% get pressure sensor data
if find(ismember(Temp.session_data.trace_legend,'respiration'))
    whichcol = find(ismember(Temp.session_data.trace_legend,'respiration'));
    RespData = MyTraces(:,whichcol);
end

%% Pressure sensor preprocessing

% rescale the data
RespData = RespData - median(RespData);

% invert: inhalations should be negative
RespData = -RespData;

%% smooth pressure data by moving mean filter
respData_filtered = smoothdata(RespData);

%% Pressure sensor peaks

% % find prominence for peaks and valleys
% [pks_1,locs_1,w_1,p_1] = findpeaks(respData_filtered);
% figure;
% histogram(p_1, 5000);
% title("peaks");
% 
% [pks_2,locs_2,w_2,p_2] = findpeaks(-respData_filtered);
% figure;
% histogram(p_2, 5000);
% title("valleys");
% % 0.3 seems a good cutoff for both


%% find peaks and valleys

[pks_1,locs_1,w_1,p_1] = findpeaks(respData_filtered, 'MinPeakProminence', 0.3, 'MinPeakDistance', 20);

respData_filtered_inv = -respData_filtered;
[pks_2,locs_2,w_2,p_2] = findpeaks(respData_filtered_inv, 'MinPeakProminence', 0.3, 'MinPeakDistance', 20, 'MinPeakHeight', 0.1);

% peak interval distribution
peak_interval_length = diff(locs_1);
figure;
histogram(peak_interval_length, 100);
title("peak interval");

valley_interval_length = diff(locs_2);
figure;
histogram(valley_interval_length, 100);
title("valley interval");

%% zero crossing

zci = @(v) find(diff(sign(v))<0 & diff(v) < -0.001);

zero_crossings = zci(respData_filtered);

% interval distribution
inhale_interval_length = diff(zero_crossings);
figure;
histogram(inhale_interval_length, 100);
title("inhalation interval");

figure;
plot(respData_filtered);
hold on;
plot(RespData);
plot(locs_1,pks_1,'or');
plot(locs_2,-pks_2,'ob');
plot(zero_crossings, respData_filtered(zero_crossings),'og');


%% thermistor data

% filter the thermistor data
sr = 500;   % sampling rate
nqf = sr/2; % Nyquist freq.
[b,a] = butter(3,[1 30]/nqf,'bandpass');   % Butterworth filter
ThermistorFiltered = filter(b,a,Thermistor);  % filter

figure;
plot(ThermistorFiltered);
hold on;
plot(respData_filtered);
% plot(locs_1,pks_1,'or');
% plot(locs_2,-pks_2,'ob');
plot(locs_1,ThermistorFiltered(locs_1),'or');
plot(locs_2,ThermistorFiltered(locs_2),'ob');
plot(zero_crossings, ThermistorFiltered(zero_crossings),'og');

%% Thermistor data find peak

% % find prominence for peaks and valleys
% [pks_1,locs_1,w_1,p_1] = findpeaks(ThermistorFiltered);
% figure;
% histogram(p_1, 5000);
% title("peaks");
% 
% [pks_2,locs_2,w_2,p_2] = findpeaks(-ThermistorFiltered);
% figure;
% histogram(p_2, 5000);
% title("valleys");
% % 0.04 seems like a good choice

[therm_pks_1,therm_locs_1,therm_w_1,therm_p_1] = findpeaks(ThermistorFiltered, 'MinPeakProminence', 0.04, 'MinPeakDistance', 20);

ThermistorFiltered_inv = -ThermistorFiltered;
[therm_pks_2,therm_locs_2,therm_w_2,therm_p_2] = findpeaks(ThermistorFiltered_inv, 'MinPeakProminence', 0.04, 'MinPeakDistance', 20);

figure;
plot(ThermistorFiltered);
hold on;
plot(therm_locs_1,therm_pks_1,'+r');
plot(therm_locs_2,-therm_pks_2,'+b');
plot(locs_1,ThermistorFiltered(locs_1),'or');
plot(locs_2,ThermistorFiltered(locs_2),'ob');
plot(locs_2+16,ThermistorFiltered(locs_2+16),'*b');
plot(zero_crossings, ThermistorFiltered(zero_crossings),'og');


%% look at the valleys in the two signals
closest_neighbor = zeros(1, length(locs_2));
for i = 1:length(locs_2)
    dist = zeros(1, length(therm_locs_2));
    for j = 1:length(therm_locs_2)
        dist(j) = abs(locs_2(i)-therm_locs_2(j));
    end
    closest_neighbor(i) = min(dist);
end

figure;
histogram(closest_neighbor);
% 16 is the median offset

%% look at the inhalation start
% 
% therm_smoothed = smoothdata(ThermistorFiltered);
% 
% zci2 = @(v) find(diff(v) < -0.0005);
% therm_diff_zci = zci2(diff(therm_smoothed));
% 
% figure;
% plot(ThermistorFiltered);
% hold on;
% plot(diff(therm_smoothed));
% plot(therm_diff_zci, ThermistorFiltered(therm_diff_zci), '+g');
% plot(therm_locs_1,therm_pks_1,'+r');
% plot(therm_locs_2,-therm_pks_2,'+b');
% plot(zero_crossings, ThermistorFiltered(zero_crossings),'og');
