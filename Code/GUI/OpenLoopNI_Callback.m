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
if h.current_trial_block.Data(6)>0
    odorID = h.current_trial_block.Data(6);
else
    odorID = 4;
end

%% populate TotalData with newly available data
for i = 1:h.NIchannels
    samples_new = event.Data(:,i);
    switch i
        case (h.Channels.trial_channel) % trial channel
            samples_new = samples_new*odorID;
        case (h.Channels.reward_channel)
            if TotalTime(end)>2 
                samples_new = diff([last_data_value(i); samples_new])==1 ;
            end
        case (h.Channels.lick_channel)
            if TotalTime(end)>2 
                samples_new = diff([last_data_value(i); samples_new])==1 ;
            end
        case (h.Channels.homesensor_channel) % homesensor channel
            if h.fliphome
                samples_new = 1 - samples_new;
            end
        case {h.Channels.camerasync_channel,h.Channels.camerasync_channel + 1}
            %samples_new = h.trigger_ext_camera.Value * samples_new;
            samples_new = 1 * samples_new;
    end
    TotalData(:,i) = [ TotalData(num_new_samples+1:end,i); samples_new ];
end
             
if TotalTime(end)>2 
    
    % register if the trial was turned ON or OFF
    if any(diff(TotalData(end-num_new_samples:end,h.Channels.trial_channel)) < 0)
        trial_just_ended = 1;
    elseif any(diff(TotalData(end-num_new_samples:end,h.Channels.trial_channel)) > 0)
        % increment 'trial number'
        h.current_trial_block.Data(2) = h.current_trial_block.Data(2) + 1; 
    end

else % for calls to function earlier than 2 seconds from session start
    TotalData(samplenum:lastsample,5:h.NIchannels) = 0;
end
    
%% Update plots
xwin = h.Xwin.Data;
%YTick_Locations = linspace(h.Plot_YLim.Data(1),h.Plot_YLim.Data(2),9)';
indices_to_plot = find( TotalTime>TotalTime(end)-xwin & TotalTime>=0 );

% lever positions, motor locations 
set(h.lever_DAC_plot,'XData',TotalTime(indices_to_plot),'YData',TotalData(indices_to_plot,1));
%set(h.lever_raw_plot,'XData',TotalTime(indices_to_plot),'YData',TotalData(indices_to_plot,2));
set(h.stimulus_plot,'XData',TotalTime(indices_to_plot),'YData',...
    h.PlotSettings.Data(2,1)*(TotalData(indices_to_plot,3) - h.PlotSettings.Data(2,2)) );

h.motor_location.YData = MapRotaryEncoderToTFColorMapOpenLoop(h,mean(event.Data(:,3)));

% respiration sensors
% respiration sensors
set(h.thermistor_plot,'XData',TotalTime(indices_to_plot),'YData',...
    h.PlotSettings.Data(4,1)*TotalData(indices_to_plot,5) + h.PlotSettings.Data(4,2) );
% set(h.respiration_plot,'XData',TotalTime(indices_to_plot),'YData',...
%     h.PlotSettings.Data(3,1)*TotalData(indices_to_plot,5) + h.PlotSettings.Data(3,2) );
set(h.lickpiezo_plot,'XData',TotalTime(indices_to_plot),'YData',...
    h.PlotSettings.Data(5,1)*TotalData(indices_to_plot,6) + h.PlotSettings.Data(5,2) );
set(h.homesensor_plot,'XData',TotalTime(indices_to_plot),'YData', 5 + 0.5*TotalData(indices_to_plot,h.Channels.homesensor_channel));
set(h.camerasync_plot,'XData',TotalTime(indices_to_plot),'YData',...
    6.5 + 0.5*TotalData(indices_to_plot,h.Channels.camerasync_channel));
set(h.camerasync2_plot,'XData',TotalTime(indices_to_plot),'YData',...
    7.2 + 0.5*TotalData(indices_to_plot,h.Channels.camerasync_channel+1));

% trial_on
[h] = PlotToPatch_Trial(h, TotalData(:,h.Channels.trial_channel), TotalTime, [0 5]);

% odor valve ON
[h.in_reward_zone_plot] = PlotToPatch(h.in_reward_zone_plot, TotalData(:,h.Channels.trial_channel+2), TotalTime, [-1 -0.2]);

% rewards
if h.Channels.reward_channel<=size(TotalData,2)
    tick_timestamps = TotalTime(TotalData(:,h.Channels.reward_channel)==1);
    tick_x = [tick_timestamps'; tick_timestamps'; ...
        NaN(1,numel(tick_timestamps))]; % creates timestamp1 timestamp1 NaN timestamp2 timestamp2..
    tick_x = tick_x(:);
    tick_y = repmat( [0; 6.5; NaN],...
        numel(tick_timestamps),1); % creates y1 y2 NaN y1 timestamp2..
    set(h.reward_plot,'XData',tick_x,'YData',tick_y);
end

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
    if h.current_trial_block.Data(2)<=h.current_trial_block.Data(1)
        NewOpenLoopTrial_Callback(h);
    else
        set(h.startAcquisition,'value',0);
        OpenLoopOdorLocator('startAcquisition_Callback',h.hObject,[],h);
        OpenLoopOdorLocator('SaveFile_Callback',h.hObject,[],h);
    end
end

%% write data to disk
data = [TotalTime(end-num_new_samples+1:end) TotalData(end-num_new_samples+1:end,:)]';
data(h.Channels.trial_channel+1,:) = h.current_trial_block.Data(4)*data(h.Channels.trial_channel+1,:);
% rescale stimulus position plot (save it in distractor location column
data(5,:) = MapRotaryEncoderToTFColorMapOpenLoop(h,data(4,:),1);
fwrite(fid1,data,'double');

%% for next round
samplenum = samplenum + num_new_samples;
last_data_value = event.Data(end,:);

