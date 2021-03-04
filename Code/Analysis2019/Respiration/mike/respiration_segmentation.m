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

%% plot signal

respData_filtered_T = transpose(respData_filtered);
respData_filtered_T = respData_filtered_T(1:200000);
t = 0:length(respData_filtered_T)-1;
Fs = 500;
t = t/Fs;

figure;
plot(t, respData_filtered_T);

%% fourier

L = length(respData_filtered_T);
Y = fft(respData_filtered_T);
P2 = abs(Y/L);
P1 = P2(1:L/2+1);
P1(2:end-1) = 2*P1(2:end-1);

f = Fs*(0:(L/2))/L;
figure;
plot(f,P1) 
title('Single-Sided Amplitude Spectrum of X(t)')
xlabel('f (Hz)')
ylabel('|P1(f)|')

%% cwt

figure;
cwt(respData_filtered_T, Fs);
hold on;
yyaxis right
plot(t/60, respData_filtered_T);


