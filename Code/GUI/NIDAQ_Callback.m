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
global TimeSinceOL;
global RecordStretch;
global sessionStart;

fid1 = varargin{3}; % C:\temp_data_files\log.bin
h = varargin{1}; % handles
h.timestamp.Data = event.TimeStamps(end);

num_new_samples = length(event.TimeStamps);
lastsample = samplenum + num_new_samples - 1;

% flags for event calls
trial_just_ended = 0;
callreward = 0;
UpdateOpenLoop = 0;

%% populate TotalTime with newly available timestamps
TotalTime = [ TotalTime(num_new_samples+1:end); event.TimeStamps ];
if h.which_perturbation.Value == 11 && mod(floor(h.current_trial_block.Data(2)/h.PerturbationSettings.Data(2)),2)
    if h.TFtype.Value
        TargetLevel = [TargetLevel(num_new_samples+1:end,:); ...
            h.blockshiftfactor.Data(1)*h.ZoneLimitSettings.Data(1) + h.TargetDefinition.Data(3) + 0*event.Data(:,1) ...
            h.blockshiftfactor.Data(1)*h.ZoneLimitSettings.Data(1) + h.TargetDefinition.Data(1) + 0*event.Data(:,1)];
    else
        TargetLevel = [TargetLevel(num_new_samples+1:end,:); ...
            -h.blockshiftfactor.Data(1)*h.ZoneLimitSettings.Data(1) + h.TargetDefinition.Data(3) + 0*event.Data(:,1) ...
            -h.blockshiftfactor.Data(1)*h.ZoneLimitSettings.Data(1) + h.TargetDefinition.Data(1) + 0*event.Data(:,1)];
    end
else
    TargetLevel = [TargetLevel(num_new_samples+1:end,:); h.TargetDefinition.Data(3)+0*event.Data(:,1) h.TargetDefinition.Data(1)+0*event.Data(:,1)];
end

% variables used later for plotting etc
which_target = h.which_target.Data;
which_fake_target = h.which_fake_target.Data;

% hack for changing trial ON plot colors
switch h.current_trial_block.Data(3)
    case {0, -1}
        odorID = h.current_trial_block.Data(4);
    case 1 % perturbation trials
        if (h.which_perturbation.Value == 3) || ...
            strcmp(h.ReplayState.String, 'Replaying Open Loop') % No Odor trials or open loop replay
            odorID = 4;
        else
            odorID = h.current_trial_block.Data(4);
        end
    case 2
        odorID = h.current_trial_block.Data(4);
end
% if h.current_trial_block.Data(3)
%     if (h.which_perturbation.Value == 3) || ...
%         strcmp(h.ReplayState.String, 'Replaying Open Loop') || ...
%              h.VisualAirTrials.Value || h.VisualOnlyTrials.Value
%         odorID = 4;
%     else
%        odorID = h.current_trial_block.Data(4); 
%     end
% else
%     odorID = h.current_trial_block.Data(4);  
% end

%% update MFC setpoints
if ~isempty(h.MFC)
    h.MFC_setpoints_IN.Data = round(mean(event.Data(:,h.NIchannels+1:h.NIchannels+2)),2,'significant')';
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
            samples_new = h.trigger_ext_camera.Value * samples_new;
    end
    
    TotalData(:,i) = [ TotalData(num_new_samples+1:end,i); samples_new ];
end

%% detect significant events - trial transitions and rewards
if TotalTime(end)>=2
    %% REWARDS
    %     % append new sampples and take diff to get events
    %     TotalData(:,h.Channels.reward_channel) = [ TotalData(num_new_samples+1:end,h.Channels.reward_channel); ...
    %         diff([last_data_value(h.Channels.reward_channel); event.Data(:,h.Channels.reward_channel)])==1 ];
    
    % any rewards?
    if any(TotalData(end-num_new_samples+1:end,h.Channels.reward_channel))
        
        % First reward in the current trial?
        if ~IsRewardedTrial
            
            % raise rewarded flag
            IsRewardedTrial = 1;
            % Update reward table (#s and uL)
            h.Reward_Report.Data(2) = h.Reward_Report.Data(2) + 1;
            h.rewardgiven.Data(1) = (h.rewardgiven.Data(1) + WaterPerDrop(h));
            h.Reward_Report.Data(1) = floor(h.rewardgiven.Data(1));
            %h.Reward_Report.Data(1) = (h.Reward_Report.Data(1) + WaterPerDrop(h));
            % Update # correct trials in performance plots
            if h.current_trial_block.Data(3) ~= 1 % not a perturbed trial
                if h.which_perturbation.Value == 11 && mod(floor(h.current_trial_block.Data(2)/h.PerturbationSettings.Data(2)),2)
                    h.ProgressReportPerturbed.Data(which_target,2) = h.ProgressReportPerturbed.Data(which_target,2) + 1;
                    h.ProgressReportPerturbed.Data(end,2) = h.ProgressReportPerturbed.Data(end,2) + 1;
                    h.hold_times.Data(h.current_trial_block.Data(2)-1,2) = 1;
                elseif h.which_perturbation.Value == 14 && h.current_trial_block.Data(3) == -1
                    h.ProgressReportPerturbed.Data(which_target,2) = h.ProgressReportPerturbed.Data(which_target,2) + 1;
                    h.ProgressReportPerturbed.Data(end,2) = h.ProgressReportPerturbed.Data(end,2) + 1;
                    h.hold_times.Data(h.current_trial_block.Data(2)-1,2) = 1;
                else
                    h.ProgressReport.Data(which_target,2) = h.ProgressReport.Data(which_target,2) + 1;
                    h.ProgressReport.Data(end,2) = h.ProgressReport.Data(end,2) + 1;
                    h.hold_times.Data(h.current_trial_block.Data(2)-1,2) = 1;
                end
            else
                switch h.which_perturbation.Value
                    case 2
                        foo = which_fake_target;
                    case 3
                        foo = which_target;
                    case {5,6,7}
                        foo = 5 - (h.OffsetParams.Data(3)/abs(h.OffsetParams.Data(3)));
%                         if abs(h.PerturbationSettings.Data(3))>40
%                             foo = foo - (h.PerturbationSettings.Data(3)>abs(h.PerturbationSettings.Data(3)));
%                         end
                    case 8
                        foo = 5 + h.OffsetParams.Data(3);
                    case {9,10}
                        foo = which_target;
                    otherwise
                        foo = which_target;
                end
                h.ProgressReportPerturbed.Data(foo,2) = h.ProgressReportPerturbed.Data(foo,2) + 1;
                h.ProgressReportPerturbed.Data(end,2) = h.ProgressReportPerturbed.Data(end,2) + 1;
            end
            
            % secondary rewards within a trial (IsRewarded is already true)
        else
            
            % Update reward table (#reward-IIs and uL)
            h.Reward_Report.Data(4) = h.Reward_Report.Data(4) + 1;
            h.rewardgiven.Data(1) = (h.rewardgiven.Data(1) + WaterPerDrop(h));
            h.Reward_Report.Data(1) = floor(h.rewardgiven.Data(1));
            
        end
    end
    
    %% trial just turned ON or OFF
    % trial OFF
    if any(diff(TotalData(end-num_new_samples:end,h.Channels.trial_channel)) < 0)
        
        trial_just_ended = 1;
        
        % handle Open loop and Replay
        switch h.ReplayState.String
            
            case {'Replaying Open Loop'} % Replay session just ended
               h.OpenLoopProgress.Data(3,1) = h.OpenLoopProgress.Data(3,1) + 1; 
               h.OpenLoopSettings.Value = 1;
               
               if h.OpenLoopProgress.Data(3,1) < h.OpenLoopParams.Data(3)
                   h.ReplayState.String = 'Recovery close loop';
                   TimeSinceOL = tic;
                   h.OpenLoopProgress.Data(1,1) = 0;
               else
                   h.OpenLoopSettings.Value = 1;
                   h.ReplayState.String = 'Close loop';
                   h.OpenLoopProgress.Data(:,1) = [NaN 0 0 0]';
                   h.OpenLoopProgress.Data(:,2) = [0 0 0 0];
               end
               
            case {'Recovery close loop'}
               %h.OpenLoopProgress.Data(1,1) = h.OpenLoopProgress.Data(1,1) + toc(TimeSinceOL);
                    
        end
        
        % trial ON
    elseif any(diff(TotalData(end-num_new_samples:end,h.Channels.trial_channel)) > 0)
        
        % pull down rewarded flag
        IsRewardedTrial = 0;
        
        % update Open Loop Progress (if needed)
        switch h.ReplayState.String
            
            case {'Recording Open Loop'}
                
                % if first trial start after open loop recording
                % - Zero the time and trials elapsed
                if isnan(h.OpenLoopProgress.Data(1,1))
                    h.OpenLoopProgress.Data(1,1:2) = 0;
                    h.OpenLoopProgress.Data(2,1:2) = [1 0];
                    TimeSinceOL = tic;
                    
                    % store which TF type and odor it is
                    h.MyReplaySettings.Data(1:2,1) = [h.current_trial_block.Data(4), ...
                                                h.TargetDefinition.Data(2)];
                else % not the first trial
                    h.OpenLoopProgress.Data(1,1) = toc(TimeSinceOL);
                    h.OpenLoopProgress.Data(2,1) = h.OpenLoopProgress.Data(2,1) + 1;
                    
                    % check if time or trial criterion has passed already
                    if h.OpenLoopProgress.Data(2,1) >= h.OpenLoopParams.Data(1) % Trial Mode
                        h.OpenLoopSettings.Value = 1;
                    end
                end
                
            case {'Recording Halt Flip'}
                
                % if first trial start after open loop recording
                % - Zero the time and trials elapsed
                if isnan(h.OpenLoopProgress.Data(1,1))
                    h.OpenLoopProgress.Data(1,1:2) = 0;
                    h.OpenLoopProgress.Data(2,1:2) = [1 0];
                    TimeSinceOL = tic;
                    
                else % not the first trial
                    h.OpenLoopProgress.Data(1,1) = toc(TimeSinceOL);
                    h.OpenLoopProgress.Data(2,1) = h.OpenLoopProgress.Data(2,1) + 1;
                    
                    if ~isempty(RecordStretch)
                        % check if time or trial criterion has passed already
                        if h.OpenLoopProgress.Data(2,1) >= (diff(RecordStretch)+1) % Trial Mode
                            h.OpenLoopSettings.Value = 5;
                        end
                    end
                end
                
            case {'Open Loop Recorded'}
                
                if h.OpenLoopProgress.Data(1,2) == 0 % open loop recording has just finished
                    h.OpenLoopProgress.Data(1,1) = toc(TimeSinceOL);
                    h.OpenLoopProgress.Data(1:2,2) = h.OpenLoopProgress.Data(1:2,1);
                    h.OpenLoopProgress.Data(1:2,1) = [0 0]'; % reset for Recovery period
                    TimeSinceOL = tic; % reset clock
                    h.PassiveRecorded.Value = 1;
                else
                    % update time and trials elapsed
                    h.OpenLoopProgress.Data(1,1) = toc(TimeSinceOL);
                    h.OpenLoopProgress.Data(2,1) = h.OpenLoopProgress.Data(2,1) + 1;
                    
                    % check if time or trial criterion has passed already
                    if h.OpenLoopProgress.Data(1,1) >= h.OpenLoopParams.Data(2) 
                        h.OpenLoopSettings.Value = 3; % trigger replay
                        if ~h.replayflag.Value
                            h.replayflag.Value = 1;
                        end
                    end
                    
                end
                
            case {'Halt Flip Recorded'}
                h.OpenLoopProgress.Data(1,1) = NaN;
%                 if h.OpenLoopProgress.Data(1,2) == 0 % open loop recording has just finished
%                     h.OpenLoopProgress.Data(1,1) = toc(TimeSinceOL);
%                     h.OpenLoopProgress.Data(1:2,2) = h.OpenLoopProgress.Data(1:2,1);
%                     h.OpenLoopProgress.Data(1:2,1) = [0 0]'; % reset for Recovery period
%                     TimeSinceOL = tic; % reset clock
%                     h.PassiveRecorded.Value = 1;
%                 else
%                     % update time and trials elapsed
%                     h.OpenLoopProgress.Data(1,1) = toc(TimeSinceOL);
%                     h.OpenLoopProgress.Data(2,1) = h.OpenLoopProgress.Data(2,1) + 1;
%                     
%                     % check if time or trial criterion has passed already
%                     if h.OpenLoopProgress.Data(1,1) >= h.OpenLoopParams.Data(2) 
%                         h.OpenLoopSettings.Value = 3; % trigger replay
%                     end
%                     
%                 end
                
            case {'Replaying Open Loop'}
                    % only one trial per replay
                    h.OpenLoopProgress.Data(4,1) = h.OpenLoopProgress.Data(4,1) + 1;
                    
                
        end
        
        % increment 'trial number'
        h.current_trial_block.Data(2) = h.current_trial_block.Data(2) + 1;
        if ~isempty(RecordStretch)
            if (h.which_perturbation.Value == 10 || h.which_perturbation.Value == 6) ...
                    && h.current_trial_block.Data(2) == RecordStretch(1)
                h.OpenLoopSettings.Value = 4; % flag for halt flip recording
            end
        end
        % increment trials done in the progress report
        if h.current_trial_block.Data(3) ~= 1 % not a perturbed trial
            if h.which_perturbation.Value == 11 && mod(floor(h.current_trial_block.Data(2)/h.PerturbationSettings.Data(2)),2)
                h.ProgressReportPerturbed.Data(which_target,1) = h.ProgressReportPerturbed.Data(which_target,1) + 1;
                h.ProgressReportPerturbed.Data(end,1) = h.ProgressReportPerturbed.Data(end,1) + 1;
            elseif h.which_perturbation.Value == 14 && h.current_trial_block.Data(3) == -1
                h.ProgressReportPerturbed.Data(which_target,1) = h.ProgressReportPerturbed.Data(which_target,1) + 1;
                h.ProgressReportPerturbed.Data(end,1) = h.ProgressReportPerturbed.Data(end,1) + 1;
            else
                h.ProgressReport.Data(which_target,1) = h.ProgressReport.Data(which_target,1) + 1;
                h.ProgressReport.Data(end,1) = h.ProgressReport.Data(end,1) + 1;
            end
        else
            switch h.which_perturbation.Value
                case 2
                    foo = which_fake_target;
                case 3
                    foo = which_target;
                case {5,6,7}
                    foo = 5 - (h.OffsetParams.Data(3)/abs(h.OffsetParams.Data(3)));
%                     if abs(h.PerturbationSettings.Data(3))>40
%                         foo = foo - 2*(h.PerturbationSettings.Data(3)>abs(h.PerturbationSettings.Data(3)));
%                     end
                case 8
                    foo = 5 + h.OffsetParams.Data(3);
                case {9,10}
                    foo = which_target;
                otherwise
                    foo = which_target;
            end
            h.ProgressReportPerturbed.Data(foo,1) = h.ProgressReportPerturbed.Data(foo,1) + 1;
            h.ProgressReportPerturbed.Data(end,1) = h.ProgressReportPerturbed.Data(end,1) + 1;
            
        end
        
    end
    
    if strcmp(h.ReplayState.String, 'Recovery close loop')
        h.OpenLoopProgress.Data(1,1) = toc(TimeSinceOL);
        
        if h.OpenLoopProgress.Data(1,1) >= h.OpenLoopParams.Data(2)
            if h.OpenLoopProgress.Data(3,1) < h.OpenLoopParams.Data(3)
                h.OpenLoopSettings.Value = 3; % trigger replay again
                if ~any(TotalData(end-num_new_samples:end,h.Channels.trial_channel)>0)
                    UpdateOpenLoop = 1;
                    if ~h.replayflag.Value
                        h.replayflag.Value = 1;
                    end
                end
            else
                h.OpenLoopSettings.Value = 1;
                h.ReplayState.String = 'Close loop';
                h.OpenLoopProgress.Data(:,1) = [NaN 0 0 0]';
                h.OpenLoopProgress.Data(:,2) = [0 0 0 0];
                
            end
        end
    end
    
    if strcmp(h.ReplayState.String, 'Open Loop Recorded') 
        if h.OpenLoopProgress.Data(1,2) > 0
            h.OpenLoopProgress.Data(1,1) = toc(TimeSinceOL);
            if (h.OpenLoopProgress.Data(1,1) >= h.OpenLoopParams.Data(2)) && ...
                    ~any(TotalData(end-num_new_samples:end,h.Channels.trial_channel)>0)
                % force call arduino param update if in ITI mode
                h.OpenLoopSettings.Value = 3; % trigger replay
                UpdateOpenLoop = 1;
                if ~h.replayflag.Value
                    h.replayflag.Value = 1;
                end
            end
        end
    end
    
    
    %% LICKS
    %     if h.NIchannels >= h.Channels.lick_channel
    %         TotalData(:,h.Channels.lick_channel) = [ TotalData(num_new_samples+1:end,h.Channels.lick_channel); ...
    %         diff([last_data_value(h.Channels.lick_channel); event.Data(:,h.Channels.lick_channel)])==1 ];
    %     end
    
    %% In early training - give water when animal licks
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
%YTick_Locations = linspace(h.Plot_YLim.Data(1),h.Plot_YLim.Data(2),9)';
indices_to_plot = find( TotalTime>TotalTime(end)-xwin & TotalTime>=0 );

% lever positions, motor locations
set(h.lever_DAC_plot,'XData',TotalTime(indices_to_plot),'YData',TotalData(indices_to_plot,1));
set(h.lever_raw_plot,'XData',TotalTime(indices_to_plot),'YData',TotalData(indices_to_plot,2));
set(h.stimulus_plot,'XData',TotalTime(indices_to_plot),'YData',...
    h.PlotSettings.Data(2,1)*(TotalData(indices_to_plot,3) - h.PlotSettings.Data(2,2)) );

h.motor_location.YData = MapRotaryEncoderToTFColorMap(h,mean(event.Data(:,3)));

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
[h] = PlotToPatch_Trial_GUI(h, TotalData(:,h.Channels.trial_channel), TotalTime, [0 5]);
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
    tick_y = repmat( [6.5; 7; NaN],...
        numel(tick_timestamps),1); % creates y1 y2 NaN y1 timestamp2..
    set(h.lick_plot,'XData',tick_x,'YData',tick_y);
end

% target zone demarcation plots
set(h.minlim,'XData',TotalTime(indices_to_plot),'YData',...
    h.TrialSettings.Data(2) + 0*TotalTime(indices_to_plot));
set(h.maxlim,'XData',TotalTime(indices_to_plot),'YData',...
    h.TrialSettings.Data(1) + 0*TotalTime(indices_to_plot));
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

if trial_just_ended
    NextTrial_Callback(h);
end

%% write data to disk
data = [TotalTime(end-num_new_samples+1:end) TotalData(end-num_new_samples+1:end,:)]';
data(h.Channels.trial_channel+1,:) = odorID*data(h.Channels.trial_channel+1,:);
% rescale stimulus position plot (save it in stimulus_location_scaled column)
data(5,:) = MapRotaryEncoderToTFColorMap(h,data(4,:),1);
fwrite(fid1,data,'double');

%% for next round
samplenum = samplenum + num_new_samples;
last_data_value = event.Data(end,:);
if callreward
    OdorLocatorTabbed('reward_now_Callback',h.hObject,[],h);
end
if UpdateOpenLoop
    %OdorLocatorTabbed('RewardControls_CellEditCallback',h.hObject,[],h); % cheat to update Arduino params
    %OdorLocatorTabbed('OpenLoopSettings_Callback',h.hObject,[],h);
end
if sessionStart && toc(sessionStart)>=h.StartDelay.Data(1)
    sessionStart = 0;
    h.PauseSession.Value = 0;
    OdorLocatorTabbed('PauseSession_Callback',h.hObject,[],h);
end

