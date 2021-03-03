FileName = '/Users/xizheng/Documents/florin/Therm3/Therm3_20190927_r0.mat';

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

%% find peak, valley, zci for pressure data

[pks_1,locs_1,w_1,p_1] = findpeaks(respData_filtered, 'MinPeakProminence', 0.3, 'MinPeakDistance', 20);
[pks_2,locs_2,w_2,p_2] = findpeaks(-respData_filtered, 'MinPeakProminence', 0.3, 'MinPeakDistance', 20, 'MinPeakHeight', 0.1);

zci = @(v) find(diff(sign(v))<0 & diff(v) < -0.001);
zero_crossings = zci(respData_filtered);

figure;
plot(respData_filtered);
hold on;
plot(locs_1,respData_filtered(locs_1),'or');
plot(locs_2,respData_filtered(locs_2),'ob');
plot(zero_crossings, respData_filtered(zero_crossings),'og');

%% find points in the thermistor that correspond to the valley and zci for the pressure data

% filter the thermistor data
sr = 500;   % sampling rate
nqf = sr/2; % Nyquist freq.
[b,a] = butter(3,[0.1 30]/nqf,'bandpass');   % Butterworth filter
ThermistorFiltered = filter(b,a,Thermistor);  % filtez

[therm_pks_1,therm_locs_1,therm_w_1,therm_p_1] = findpeaks(ThermistorFiltered, 'MinPeakProminence', 0.04, 'MinPeakDistance', 20);
[therm_pks_2,therm_locs_2,therm_w_2,therm_p_2] = findpeaks(-ThermistorFiltered, 'MinPeakProminence', 0.04, 'MinPeakDistance', 20);

figure;
plot(respData_filtered,'DisplayName','pressure filtered');
hold on;
plot(ThermistorFiltered,'DisplayName','therm filtered');
plot(locs_1,respData_filtered(locs_1),'or', 'DisplayName','peak pressure');
plot(locs_2,respData_filtered(locs_2),'ob', 'DisplayName','valley pressure');
plot(zero_crossings, respData_filtered(zero_crossings),'og', 'DisplayName','zci pressure');
plot(therm_locs_2-21, respData_filtered(therm_locs_2-21),'*b', 'DisplayName','valley therm infer');
plot(therm_locs_1-6, respData_filtered(therm_locs_1-6),'*g', 'DisplayName','zci therm infer');
legend;



%% evaluate the prediction

closest_neighbor_valley = zeros(1, length(locs_2));
for i = 1:length(locs_2)
    dist = zeros(1, length(therm_locs_2));
    for j = 1:length(therm_locs_2)
        dist(j) = abs(locs_2(i)-(therm_locs_2(j)-21));
    end
    [minval, argmin] = min(dist);
    closest_neighbor_valley(i) = locs_2(i)-(therm_locs_2(argmin)-21);
end

figure;
title('valley pressure vs. therm infer');
histogram(closest_neighbor_valley, 100);

closest_neighbor_zci = zeros(1, length(zero_crossings));
for i = 1:length(zero_crossings)
    dist = zeros(1, length(therm_locs_1));
    for j = 1:length(therm_locs_1)
        dist(j) = abs(zero_crossings(i)-(therm_locs_1(j)-6));
    end
    [minval, argmin] = min(dist);
    closest_neighbor_zci(i) = zero_crossings(i)-(therm_locs_1(argmin)-6);
end

figure;
title('zci pressure vs. therm infer');
histogram(closest_neighbor_zci, 100);


