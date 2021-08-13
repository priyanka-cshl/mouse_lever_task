FileName = '/Users/xizheng/Documents/florin/respiration/Therm3/Therm3_20190928_r0.mat';

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

%% thermistor

% filter the thermistor data
sr = 500;   % sampling rate
nqf = sr/2; % Nyquist freq.
[b,a] = butter(3,[0.1 30]/nqf,'bandpass');   % Butterworth filter
ThermistorFiltered = filter(b,a,Thermistor);  % filtez

ThermistorFiltered = smoothdata(ThermistorFiltered, 'movmean', 13);

%% 

figure; hold on;
plot(respData_filtered);
plot(ThermistorFiltered);
title("data");

%% cross correlation

[r,lags] = xcorr(respData_filtered, ThermistorFiltered, 'normalized', 250);

figure;
plot(lags, r);
title("cross correlation");

% %%
% 
% figure; hold on;
% plot(respData_filtered);
% plot(circshift(ThermistorFiltered, -21));
% title("shifted");

%% coherence

% figure;
% mscohere(respData_filtered,ThermistorFiltered);

