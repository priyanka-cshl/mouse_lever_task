function Send2Arduino(h)

sent = 0;
sending_attempts = 0;

[~, ParamArray, not_ints] = GetSettings4Arduino(h);
Params2Write = ParamArray;

% convert voltage values to int16 range before sending
voltage_to_int = round(inv(h.DAC_levels.Data(2)/(2^16)));
ParamArray(not_ints) = round(ParamArray(not_ints)*voltage_to_int);
ParamArray(ParamArray>2^16-1) = 2^16-1;

while (sent == 0) && (sending_attempts <= 8)
    if h.Arduino.Port.BytesAvailable
        trash = h.Arduino.read(h.Arduino.Port.BytesAvailable/2,'uint16');
        clear trash;
    end
    
    h.Arduino.write(20,'uint16'); % handler code for parameter update
    h.Arduino.write(length(ParamArray),'uint16'); % tell Arduino how many params are going to be written
    
    % write the params
    ParamArray = uint16(ParamArray);
    h.Arduino.write(ParamArray, 'uint16');
    
    tic;
    while toc<0.5 && h.Arduino.Port.BytesAvailable<2*(length(ParamArray)+1)
    end
    
    % for every param Arduino writes back the param value
    if (h.Arduino.Port.BytesAvailable)==2*(length(ParamArray)+1)
        
        % read back the params that Arduino sent back
        params_returned = h.Arduino.read(h.Arduino.Port.BytesAvailable/2,'uint16');
        % extract params that were meant to be updated by the Arduino
        ParamsBack = params_returned(32:33);
        % replace the above params with zeros to match what was sent in
        params_returned(32:33) = ParamArray(32:33);
        
        if all(params_returned(1:end-1) == ParamArray') && params_returned(end) == 89
            
            disp(['arduino: params updated: attempts = ' num2str(sending_attempts+1),'; time = ',num2str(toc),' seconds'])
            sent = 1;
            h.TargetHold.ForegroundColor = 'k';
            
        else
            
            pause(.1);
            sending_attempts = sending_attempts + 1';
            
        end
        
    else
        
        pause(.1)
        sending_attempts = sending_attempts+1';
        
    end
end

if sending_attempts == 9
    error('arduino: failed to update values')
end

% update water per drop
h.waterperdrop.Data(1) = WaterPerDrop(h);

%% if acquisition is Running and params were sent - update settings file
if get(h.startAcquisition,'value') && (sent == 1)
    if (h.current_trial_block.Data(2)-1>0)
        h.hold_times.Data(h.current_trial_block.Data(2)-1,1) = h.which_target.Data;
        if ParamsBack(1) < 7000
            h.hold_times.Data(h.current_trial_block.Data(2)-1,3) = ParamsBack(1);
            h.hold_times.Data(h.current_trial_block.Data(2)-1,4) = h.LastTrialSettings.Data(end);
        else
            h.hold_times.Data(h.current_trial_block.Data(2)-1,3) = NaN;
            h.hold_times.Data(h.current_trial_block.Data(2)-1,4) = NaN;
            which_target = h.LastTrialSettings.Data(1);
            % decrement trial counts for failed trials
            h.ProgressReport.Data(which_target,1) = h.ProgressReport.Data(which_target,1) - 1;
            h.ProgressReport.Data(end,1) = h.ProgressReport.Data(end,1) - 1;
        end        
    end
    
    % Update Open loop flags
    % Open Loop Recording is about to start on next trial
    if h.OpenLoopSettings.Value==2 && (strcmp(h.ReplayState.String,'Close loop')||strcmp(h.ReplayState.String,'Passive replay Recorded')) && params_returned(31) == 1
        h.ReplayState.String = 'Recording Open Loop';
    end
    
    % Open Loop Recording is about to stop on next trial
    if h.OpenLoopSettings.Value == 1 && strcmp(h.ReplayState.String,'Recording Open Loop') && params_returned(31) == 0
        if h.AutoReplay.Value
            h.ReplayState.String = 'Open Loop Recorded';
        else
            h.ReplayState.String = 'Passive replay Recorded';
            h.OpenLoopProgress.Data(:,1) = [NaN 0 0 0]';
            h.OpenLoopProgress.Data(:,2) = [0 0 0 0];
        end
        h.PassiveRecorded.Value = 1;
    end
    
    % Replay is about to start on next trial
    if h.OpenLoopSettings.Value==3 && strcmp(h.ReplayState.String,'Open Loop Recorded') && params_returned(31) == 2
        h.ReplayState.String = 'Replaying Open Loop';
    end
    
    if h.OpenLoopSettings.Value==3 && strcmp(h.ReplayState.String,'Recovery close loop') && params_returned(31) == 2
        h.ReplayState.String = 'Replaying Open Loop';
    end
    
    % Update Halt Flip recording flags
    % Halt Flip Recording is about to start on next trial - first time - Arduino makes a new file 
    if h.OpenLoopSettings.Value==4 && strcmp(h.ReplayState.String,'Close loop') && params_returned(31) == 1
        h.ReplayState.String = 'Recording Halt Flip';
    end
    
    % Halt Flip Recording is about to start on next trial - not first time - Arduino appends to file
    if h.OpenLoopSettings.Value==4 && (strcmp(h.ReplayState.String,'Close loop')||strcmp(h.ReplayState.String,'Halt Flip Recorded')) && params_returned(31) == 11
        h.ReplayState.String = 'Recording Halt Flip';
    end
    
    % Halt Flip Recording is about to stop on next trial
    if h.OpenLoopSettings.Value == 5 && strcmp(h.ReplayState.String,'Recording Halt Flip') && params_returned(31) == 12
        h.ReplayState.String = 'Halt Flip Recorded';
        h.OpenLoopProgress.Data(:,1) = [NaN 0 0 0]';
        h.OpenLoopProgress.Data(:,2) = [0 0 0 0];
        h.PassiveRecorded.Value = 1;
    end
    
    % replace last three values in params1 to store Stay Time min and Stay
    % Time Max
%     params(1) = h.ZoneLimitSettings.Data(1); % MinWidth
%     %params1(2) = h.ZoneLimitSettings.Data(2); % PropWidth
%     params1(2) = h.RewardControls.Data(2); % IRI - when multirewards is off
%     params1(end-4) = h.MultiRewards.Value*h.RewardControls.Data(2); % IRI
%     params1(end-2) = h.TargetHold.Data(2); % StayMean
%     params1(end-1) = h.TargetHold.Data(1); % StayMin
%     params1(end) = h.TargetHold.Data(3); % StayMax
%     params2(1) = h.trigger_ext_camera.Value; % camera on or not
    fwrite(h.settingsfileID,[h.timestamp.Data Params2Write],'double');
end