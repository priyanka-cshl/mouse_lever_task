FileName = '/Users/xizheng/Documents/florin/respiration/Therm3/Therm3_20190927_r0.mat';

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

%% find points in the thermistor that correspond to the valley and zci for the pressure data

% filter the thermistor data
sr = 500;   % sampling rate
nqf = sr/2; % Nyquist freq.
[b,a] = butter(3,[0.1 30]/nqf,'bandpass');   % Butterworth filter
ThermistorFiltered = filter(b,a,Thermistor);  % filtez

ThermistorFiltered = smoothdata(ThermistorFiltered, 'movmean', 13);

[therm_pks_1,therm_locs_1,therm_w_1,therm_p_1] = findpeaks(ThermistorFiltered, 'MinPeakProminence', 0.04, 'MinPeakDistance', 20);
[therm_pks_2,therm_locs_2,therm_w_2,therm_p_2] = findpeaks(-ThermistorFiltered, 'MinPeakProminence', 0.04, 'MinPeakDistance', 20);

% therm_locs_2 = therm_locs_1;

valley_interval_length = diff(therm_locs_2);
% figure;
% histogram(valley_interval_length, 100);
% title("valley interval");

%% fit gaussian mixture model

gm = fitgmdist(valley_interval_length,2);
gmPDF = @(x) arrayfun(@(x0) pdf(gm,x0),x);

l = 1:600;
figure;
histogram(valley_interval_length, 100, 'Normalization','pdf');
hold on;
plot(l, gmPDF(l));
title("valley interval");

%% use gm model to cluster

clusterX = cluster(gm,valley_interval_length);

figure;
plot(ThermistorFiltered);
hold on;
plot(therm_locs_2,ThermistorFiltered(therm_locs_2),'ob');

for i = 1:length(therm_locs_2)-1
    r = rectangle('Position',[therm_locs_2(i) -0.01 valley_interval_length(i) 0.01]);
    if clusterX(i) == 1
        r.FaceColor = 'cyan';
    else
        r.FaceColor = 'magenta';
    end
end

%% try time streching to get example waveform

mean1 = 90;
mean2 = 250;

count1 = sum(clusterX == 1);
count2 = sum(clusterX == 2);

waveforms1 = zeros(count1, mean1);
waveforms2 = zeros(count2, mean2);

j1 = 1;
j2 = 1;

for i = 1:length(therm_locs_2)-1
    waveform = ThermistorFiltered(therm_locs_2(i):therm_locs_2(i+1));
    if clusterX(i) == 1
        timevec = 1:mean1;
        tsin = timeseries(waveform',(1:length(waveform)) * (mean1/length(waveform)));
        tsout = resample(tsin,timevec);
        waveforms1(j1,:) = tsout.Data;
        j1 = j1 + 1;
    else
        timevec = 1:mean2;
        tsin = timeseries(waveform',(1:length(waveform)) * (mean2/length(waveform)));
        tsout = resample(tsin,timevec);
        waveforms2(j2,:) = tsout.Data;
        j2 = j2 + 1;
    end
end

 %% plot both types of breath 
        
figure;
plot(waveforms1(1,:), 'linewidth', 0.5);
hold on;
for i = 2:count1
    plot(waveforms1(i,:), 'linewidth', 0.5);
end
amean1 = nanmean(waveforms1, 1);
astd1 = nanstd(waveforms1,[],1);
F1 = 1:size(waveforms1,2);

plot(amean1, 'color', 'k','linewidth', 1.5);
fill([F1 fliplr(F1)],[amean1+astd1 fliplr(amean1-astd1)], 'k', 'FaceAlpha', 0.5,'linestyle','none');


figure;
plot(waveforms2(1,:), 'linewidth', 0.5);
hold on;
for i = 2:count2
    plot(waveforms2(i,:), 'linewidth', 0.5);
end

amean2 = nanmean(waveforms2, 1);
astd2 = nanstd(waveforms2,[],1);
F2 = 1:size(waveforms2,2);

plot(amean2, 'color', 'k','linewidth', 1.5);
fill([F2 fliplr(F2)],[amean2+astd2 fliplr(amean2-astd2)], 'k', 'FaceAlpha', 0.5,'linestyle','none');


