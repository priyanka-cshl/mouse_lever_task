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

%% Pressure sensor preprocessing

% rescale the data
RespData = RespData - median(RespData);

% invert: inhalations should be negative
RespData = -RespData;

%% smooth pressure data by moving mean filter
respData_filtered = smoothdata(RespData);

%% valley: peak of inhalation

[pks_2,locs_2,w_2,p_2] = findpeaks(-respData_filtered, 'MinPeakProminence', 0.3, 'MinPeakDistance', 20, 'MinPeakHeight', 0.1);

zci = @(v) find(diff(sign(v))<0 & diff(v) < -0.001);
zero_crossings = zci(respData_filtered);

locs_2 = zero_crossings;

valley_interval_length = diff(locs_2);
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
plot(respData_filtered);
hold on;
plot(locs_2,respData_filtered(locs_2),'ob');

for i = 1:length(locs_2)-1
    r = rectangle('Position',[locs_2(i) -0.05 valley_interval_length(i) 0.05]);
    if clusterX(i) == 1
        r.FaceColor = 'cyan';
    else
        r.FaceColor = 'magenta';
    end
end

%% try time streching to get example waveform

timevec = 1:250;
waveform = respData_filtered(locs_2(1):locs_2(2));
tsin = timeseries(waveform',(1:length(waveform)) * (250/length(waveform)));
tsout = resample(tsin,timevec);

figure;
plot(waveform);
hold on;
plot(tsout);

%% apply to all waveforms

mean1 = 90;
mean2 = 250;

count1 = sum(clusterX == 1);
count2 = sum(clusterX == 2);

waveforms1 = zeros(count1, mean1);
waveforms2 = zeros(count2, mean2);

j1 = 1;
j2 = 1;

for i = 1:length(locs_2)-1
    waveform = respData_filtered(locs_2(i):locs_2(i+1));
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
