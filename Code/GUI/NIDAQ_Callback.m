function varout = NIDAQ_Callback(src,event,varargin) %#ok<*STOUT>
% called at refresh step - when DataAvailable == number of samples per refresh
% as set by User-determined Matlab refresh rate (typically 20 Hz)
% most recent samples and timestamps will be in event.TimeStamps and
% event.Data

global samplenum; % #samples read in the current session
global TotalData; % matrix containing data from the current callback (refreshed at 20Hz (or Refresh rate))
global TotalTime; % matrix containing timestamps from the current callback
persistent last_data_value; % event.Data(end,:) from last call
global TargetLevel;
global IsRewardedTrial;

fid1 = varargin{3}; % C:\temp_data_files\log.bin
h = varargin{1}; % handles
h.timestamp.Data = event.TimeStamps(end);

num_new_samples = length(event.TimeStamps);
lastsample = samplenum + num_new_samples - 1;

% flags for event calls
trial_just_ended = 0;
call_new_block = 0;
callreward = 0;

%% populate TotalTime with newly available timestamps
TotalTime = [ TotalTime(num_new_samples+1:end); event.TimeStamps ];
TargetLevel = [TargetLevel(num_new_samples+1:end,:); h.TargetDefinition.Data(3)+0*event.Data(:,1) h.TargetDefinition.Data(1)+0*event.Data(:,1)];
% which_target = floor(h.TargetDefinition.Data(2));
% which_fake_target = floor(h.fake_target_zone.Data(2));
which_target = find(h.all_targets == h.TargetDefinition.Data(2));
which_fake_target = find(h.all_targets == h.fake_target_zone.Data(2));

%% update MFC setpoints
if ~isempty(h.MFC)
    h.MFC_setpoints_IN.Data = round(mean(event.Data(:,h.NIchannels+1:h.NIchannels+2)),2,'significant')';
end

% multiply trial_channel by odor value
odorID = h.current_trial_block.Data(4);

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
        if mod(h.current_trial_block.Data(2),h.TransferFunction.Data(2)) == 0
            call_new_block = 1;
        end
    elseif any(diff(TotalData(end-num_new_samples:end,h.Channels.trial_channel)) > 0) % trial just turned ON
        h.current_trial_block.Data(2) = h.current_trial_block.Data(2) + 1; % increment 'trial number'
        if ~h.current_trial_block.Data(3) % not a perturbed trial
            h.ProgressReport.Data(4-which_target,1) = h.ProgressReport.Data(4-which_target,1) + 1;
            h.ProgressReport.Data(4,1) = h.ProgressReport.Data(4,1) + 1;
%             if h.current_trial_block.Data(1)
%                 h.ProgressReportLeft.Data(4-which_target,1) = h.ProgressReportLeft.Data(4-which_target,1) + 1;
%                 h.ProgressReportLeft.Data(4,1) = h.ProgressReportLeft.Data(4,1) + 1;
%             else
%                 h.ProgressReportRight.Data(4-which_target,1) = h.ProgressReportRight.Data(4-which_target,1) + 1;
%                 h.ProgressReportRight.Data(4,1) = h.ProgressReportRight.Data(4,1) + 1;
%             end
        else
            h.ProgressReportPerturbed.Data(4-which_fake_target,1) = h.ProgressReportPerturbed.Data(4-which_fake_target,1) + 1;
            h.ProgressReportPerturbed.Data(4,1) = h.ProgressReportPerturbed.Data(4,1) + 1;
        end
        IsRewardedTrial = 0;
    end
    
    % reward channel
    TotalData(:,h.Channels.reward_channel) = [ TotalData(num_new_samples+1:end,h.Channels.reward_channel); ...
        diff([last_data_value(h.Channels.reward_channel); event.Data(:,h.Channels.reward_channel)])==1 ];
    % check if there were any rewards and update block accordingly
    if any(TotalData(end-num_new_samples+1:end,h.Channels.reward_channel))
        % increment 'total rewards' and 'rewards in block'
        if ~IsRewardedTrial
            h.Reward_Report.Data(2) = h.Reward_Report.Data(2) + 1;
            h.Reward_Report.Data(1) = h.Reward_Report.Data(1) + 10*(h.RewardControls.Data(1)*h.watercoeffs(1) + h.watercoeffs(2));
            IsRewardedTrial = 1;
            
            if ~h.current_trial_block.Data(3) % not a perturbed trial
                h.ProgressReport.Data(4-which_target,2) = h.ProgressReport.Data(4-which_target,2) + 1;
                h.ProgressReport.Data(4,2) = h.ProgressReport.Data(4,2) + 1;
%                 if h.current_trial_block.Data(1)
%                     h.ProgressReportLeft.Data(4-which_target,2) = h.ProgressReportLeft.Data(4-which_target,2) + 1;
%                     h.ProgressReportLeft.Data(4,2) = h.ProgressReportLeft.Data(4,2) + 1;
%                 else
%                     h.ProgressReportRight.Data(4-which_target,2) = h.ProgressReportRight.Data(4-which_target,2) + 1;
%                     h.ProgressReportRight.Data(4,2) = h.ProgressReportRight.Data(4,2) + 1;
%                 end
            else
                h.ProgressReportPerturbed.Data(4-which_fake_target,2) = h.ProgressReportPerturbed.Data(4-which_fake_target,2) + 1;
                h.ProgressReportPerturbed.Data(4,2) = h.ProgressReportPerturbed.Data(4,2) + 1;
            end
            
        else
            h.Reward_Report.Data(4) = h.Reward_Report.Data(4) + 1;
            h.Reward_Report.Data(1) = h.Reward_Report.Data(1) + 10*(h.RewardControls.Data(2)*h.watercoeffs(1) + h.watercoeffs(2));
        end
    end
    
    % lick channel
    if h.NIchannels >= h.Channels.lick_channel
        TotalData(:,h.Channels.lick_channel) = [ TotalData(num_new_samples+1:end,h.Channels.lick_channel); ...
        diff([last_data_value(h.Channels.lick_channel); event.Data(:,h.Channels.lick_channel)])==1 ];
    end
    
    if ~isempty(find(diff([last_data_value(h.Channels.lick_channel); event.Data(:,h.Channels.lick_channel)])==1,1))
        if h.which_stage.Value==1
                callreward = 1;
        end
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
set(h.lever_raw_plot,'XData',TotalTime(indices_to_plot),'YData',TotalData(indices_to_plot,2));
set(h.stimulus_plot,'XData',TotalTime(indices_to_plot),'YData',...
    -1*h.RE_scaling.Data(1)*(TotalData(indices_to_plot,3) - h.RE_scaling.Data(2)) );

h.motor_location.YData = MapRotaryEncoderToTFColorMap(h,mean(event.Data(:,3)));

% respiration sensors
set(h.respiration_1_plot,'XData',TotalTime(indices_to_plot),'YData',...
    -1*h.RS_scaling.Data(1)*TotalData(indices_to_plot,5) + h.RS_scaling.Data(2) );
set(h.respiration_2_plot,'XData',TotalTime(indices_to_plot),'YData',...
    -1*h.RS_scaling.Data(1)*TotalData(indices_to_plot,6) + h.RS_scaling.Data(2) );
set(h.homesensor_plot,'XData',TotalTime(indices_to_plot),'YData', 5 + 0.5*TotalData(indices_to_plot,h.Channels.homesensor_channel));

% trial_on
[h] = PlotToPatch_Trial(h, TotalData(:,h.Channels.trial_channel), TotalTime, [0 5]);
[h.targetzone] = PlotToPatch_TargetZone(h.targetzone, TargetLevel, TotalTime);

% in_target_zone, in_reward_zone
[h.in_target_zone_plot] = PlotToPatch(h.in_target_zone_plot, TotalData(:,h.Channels.trial_channel+1), TotalTime, [-1 0]);
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


% target zone demarcation plots
set(h.minlim,'XData',TotalTime(indices_to_plot),'YData',...
    h.TrialSettings.Data(2) + 0*TotalTime(indices_to_plot));
if h.current_trial_block.Data(3) == 1 && h.which_perturbation.Value == 2
    set(h.fake_target_plot,'XData',TotalTime(indices_to_plot),'YData',...
        h.fake_target_zone.Data(2) + 0*TotalTime(indices_to_plot));
else
    set(h.fake_target_plot,'XData',TotalTime(indices_to_plot),'YData',...
        NaN + TotalTime(indices_to_plot));
end

% set axes limits
set(h.axes1,'XLim',[TotalTime(indices_to_plot(1)) TotalTime(indices_to_plot(end))]);

%% call trial/block updates, stop acquisition if required
if get(h.startAcquisition,'value') == 0
    src.stop();
end

if call_new_block && trial_just_ended
    NextTrial_Callback(h);
elseif call_new_block
    %NewBlock_Callback(h);
elseif trial_just_ended
    %NewTrial_Callback(h);
end

%% write data to disk
data = [TotalTime(end-num_new_samples+1:end) TotalData(end-num_new_samples+1:end,:)]';
data(h.Channels.trial_channel+1,:) = h.current_trial_block.Data(4)*data(h.Channels.trial_channel+1,:);
% rescale stimulus position plot (save it in distractor location column
data(5,:) = MapRotaryEncoderToTFColorMap(h,data(4,:),1);
fwrite(fid1,data,'double');

%% for next round
samplenum = samplenum + num_new_samples;
last_data_value = event.Data(end,:);
%disp(last_data_value);
if callreward
    OdorLocatorTabbed('reward_now_Callback',h.hObject,[],h);
end

