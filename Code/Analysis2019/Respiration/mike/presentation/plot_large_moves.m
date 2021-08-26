filepath = "/Users/xizheng/Documents/florin/respiration/K4/K4_20200120_r0.mat";

%% read data

Temp = load(filepath,'session_data');
MyTraces = Temp.session_data.trace;
    
% get pressure sensor data
if find(ismember(Temp.session_data.trace_legend,'respiration'))
    whichcol = find(ismember(Temp.session_data.trace_legend,'respiration'));
    RespData = MyTraces(:,whichcol);
end

% get pressure sensor data
if find(ismember(Temp.session_data.trace_legend,'lever_DAC'))
    whichcol = find(ismember(Temp.session_data.trace_legend,'lever_DAC'));
    lever = MyTraces(:,whichcol);
end

% get pressure sensor data
if find(ismember(Temp.session_data.trace_legend,'trial_on'))
    whichcol = find(ismember(Temp.session_data.trace_legend,'trial_on'));
    trial_on = MyTraces(:,whichcol);
end

%% resp

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

% zero_crossings = locs_2;


%% moves
lever_smooth = smoothdata(lever, 'sgolay', 25, 'degree', 4);

[mov_pks_1,mov_locs_1,mov_w_1,mov_p_1] = findpeaks(lever_smooth, 'MinPeakProminence', 0.01, 'MinPeakDistance', 5);
[mov_pks_2,mov_locs_2,mov_w_2,mov_p_2] = findpeaks(-lever_smooth, 'MinPeakProminence', 0.01, 'MinPeakDistance', 5);
mov_locs = sort(cat(1, mov_locs_1, mov_locs_2));

movement = zeros(length(mov_locs)-1, 1);
for i = 1:length(mov_locs)-1
    movement(i) = abs(lever(mov_locs(i+1)) - lever(mov_locs(i)));
end
movement_signal = zeros(length(lever), 1);
movement_signal(mov_locs(1:end-1)) = movement;
large_thresh = 1;
movement_signal = movement_signal > large_thresh;

large_mov_locs = find(movement_signal > 0);

%%

figure; hold on;
plot(lever_smooth, 'linewidth', 1);
plot(large_mov_locs, lever_smooth(large_mov_locs), 'or');
plot(5*(trial_on~=0));
plot(locs_2, lever_smooth(locs_2), 'ob');

