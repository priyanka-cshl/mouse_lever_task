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
        h.hold_times.Data(h.current_trial_block.Data(2)-1,3) = ParamsBack(1);
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