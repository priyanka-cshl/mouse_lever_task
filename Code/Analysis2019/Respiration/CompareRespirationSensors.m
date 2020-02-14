%function [] = CompareRespirationSensors(FileName)
FileName = 'Therm3_20190928_r0.mat';
% run the code from the folder that contains the data dile

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


%% Process pressure sensor signals and detect inhalations

% settings
threshold = 0.2;

% rescale the data
RespData = RespData - median(RespData);

% invert: inhalations should be negative
RespData = -RespData;

% detect peaks and valleys
[pks,dep,pid,did] = peakdet(RespData,threshold);

% plot
figure;
plot(1:length(RespData),RespData);
hold on
plot(pid,pks,'ok');
plot(did,dep,'or');

InhStart = [dep did]; 

%% Process the Thermistor data

% filter the thermistor data
sr = 500;   % sampling rate
nqf = sr/2; % Nyquist freq.
[b,a] = butter(3,[1 30]/nqf,'bandpass');   % Butterworth filter
ThermistorFiltered = filter(b,a,Thermistor);  % filter

% detect peaks and valleys
threshold = 0.025;
[pks,dep,pid,did] = peakdet(ThermistorFiltered,threshold);

% plot
figure;
plot(1:length(ThermistorFiltered),ThermistorFiltered);
hold on
plot(pid,pks,'ok');
plot(did,dep,'or');

%end