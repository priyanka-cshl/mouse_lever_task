filepath = "/Users/xizheng/Documents/florin/respiration/K1/K1_20191226_r0.mat";

[Traces, TrialInfo] = ParseBehaviorAndPhysiology(filepath);

idx = 2;

%% Pressure sensor preprocessing

RespData = Traces.Sniffs{idx};
trial_on = Traces.Trial{idx};

% rescale the data
RespData = RespData - median(RespData);

% invert: inhalations should be negative
RespData = -RespData;

% smooth pressure data by moving mean filter
respData_filtered = smoothdata(RespData);

%% find zero crossings

zci = @(v) find(diff(sign(v))<0 & diff(v) < -0.001);
zero_crossings = zci(respData_filtered);

locs_2 = zero_crossings;

zci_interval_length = diff(locs_2);

%% convert time to frequency

sr = 500;

figure;
histogram(sr./zci_interval_length, 10);

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
        
    
