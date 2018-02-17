function varout = OpenLoopNI_Callback(src,event,varargin) %#ok<*STOUT>
% called at refresh step - when DataAvailable == number of samples per refresh
% as set by User-determined Matlab refresh rate (typically 20 Hz)
% most recent samples and timestamps will be in event.TimeStamps and
% event.Data

global samplenum; % #samples read in the current session
global TotalData; % matrix containing data from the current callback (refreshed at 20Hz (or Refresh rate))
global TotalTime; % matrix containing timestamps from the current callback
persistent last_data_value; % event.Data(end,:) from last call

fid1 = varargin{3}; % C:\temp_data_files\log.bin
h = varargin{1}; % handles
h.timestamp.Data = event.TimeStamps(end);

num_new_samples = length(event.TimeStamps);
lastsample = samplenum + num_new_samples - 1;

% flags for event calls
trial_just_ended = 0;

%% populate TotalTime with newly available timestamps
TotalTime = [ TotalTime(num_new_samples+1:end); event.TimeStamps ];

% multiply trial_channel by odor value
odorID = h.current_trial_block.Data(6);

%% populate TotalData with newly available data
for i = 1:h.Channels.reward_channel-1
    samples_new = event.Data(:,i);
    if i == h.Channels.trial_channel
        samples_new = samples_new*odorID;
    end
    TotalData(:,i) = [ TotalData(num_new_samples+1:end,i); samples_new ];
end

for i = h.Channels.homesensor_channel
    samples_new = event.Data(:,i);
    if h.fliphome
        samples_new = 1 - samples_new;
    end
    TotalData(:,i) = [ TotalData(num_new_samples+1:end,i); samples_new ];
end
             
if TotalTime(end)>2 

    % register if the trial was turned ON or OFF
    if any(diff(TotalData(end-num_new_samples:end,h.Channels.trial_channel)) < 0)
        trial_just_ended = 1;
    end
    
    % reward channel
    TotalData(:,h.Channels.reward_channel) = [ TotalData(num_new_samples+1:end,h.Channels.reward_channel); ...
        diff([last_data_value(h.Channels.reward_channel); event.Data(:,h.Channels.reward_channel)])==1 ];
    
    % lick channel
    if h.NIchannels >= h.Channels.lick_channel
        TotalData(:,h.Channels.lick_channel) = [ TotalData(num_new_samples+1:end,h.Channels.lick_channel); ...
        diff([last_data_value(h.Channels.lick_channel); event.Data(:,h.Channels.lick_channel)])==1 ];
    end

else % for calls to function earlier than 2 seconds from session start
    TotalData(samplenum:lastsample,5:h.NIchannels) = 0;
end
    
%% Update plots
xwin = h.Xwin.Data;
YTick_Locations = linspace(h.Plot_YLim.Data(1),h.Plot_YLim.Data(2),9)';
indices_to_plot = find( TotalTime>TotalTime(end)-xwin & TotalTime>=0 );

% lever positions, motor locations 
set(h.lever_DAC_plot,'XData',TotalTime(indices_to_plot),'YData',TotalData(indices_to_plot,1));
%set(h.lever_raw_plot,'XData',TotalTime(indices_to_plot),'YData',TotalData(indices_to_plot,2));
set(h.stimulus_plot,'XData',TotalTime(indices_to_plot),'YData',...
    -1*h.RE_scaling.Data(1)*(TotalData(indices_to_plot,3) - h.RE_scaling.Data(2)) );

h.motor_location.YData = MapRotaryEncoderToTFColorMapOpenLoop(h,mean(event.Data(:,3)));

% respiration sensors
set(h.respiration_1_plot,'XData',TotalTime(indices_to_plot),'YData',...
    -1*h.RS_scaling.Data(1)*TotalData(indices_to_plot,5) + h.RS_scaling.Data(2) );
set(h.respiration_2_plot,'XData',TotalTime(indices_to_plot),'YData',...
    -1*h.RS_scaling.Data(1)*TotalData(indices_to_plot,6) + h.RS_scaling.Data(2) );
set(h.homesensor_plot,'XData',TotalTime(indices_to_plot),'YData', 5 + 0.5*TotalData(indices_to_plot,h.Channels.homesensor_channel));

% trial_on
[h] = PlotToPatch_Trial(h, TotalData(:,h.Channels.trial_channel), TotalTime, [0 5]);

% licks
if h.Channels.lick_channel<=size(TotalData,2)
    tick_timestamps = TotalTime(TotalData(:,h.Channels.lick_channel)==1);
    tick_x = [tick_timestamps'; tick_timestamps'; ...
        NaN(1,numel(tick_timestamps))]; % creates timestamp1 timestamp1 NaN timestamp2 timestamp2..
    tick_x = tick_x(:);
    tick_y = repmat( [5.5; 6; NaN],...
        numel(tick_timestamps),1); % creates y1 y2 NaN y1 timestamp2..
    set(h.lick_plot,'XData',tick_x,'YData',tick_y);
end

% set axes limits
set(h.axes1,'XLim',[TotalTime(indices_to_plot(1)) TotalTime(indices_to_plot(end))]);

%% call trial/block updates, stop acquisition if required
if get(h.startAcquisition,'value') == 0
    src.stop();
end

if trial_just_ended
    NewOpenLoopTrial_Callback(h);
end

%% write data to disk
data = [TotalTime(end-num_new_samples+1:end) TotalData(end-num_new_samples+1:end,:)]';
data(h.Channels.trial_channel+1,:) = h.current_trial_block.Data(4)*data(h.Channels.trial_channel+1,:);
% rescale stimulus position plot (save it in distractor location column
data(5,:) = MapRotaryEncoderToTFColorMapOpenLoop(h,data(4,:));
fwrite(fid1,data,'double');

%% for next round
samplenum = samplenum + num_new_samples;
last_data_value = event.Data(end,:);

