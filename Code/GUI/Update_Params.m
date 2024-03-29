function Update_Params(h)
%% pull all params
[~, params1, not_ints1] = Current_Settings(h,0);
[~, params2, not_ints2] = Current_Settings(h,1);
%% send params to Arduino
sent = 0;
sending_attempts = 0;
ParamArray = [params1 mod(h.current_trial_block.Data(4),4) params2(2:end)]; % replace timestamp with odor vial number
ParamArray(1) = h.RewardControls.Data(2); % trial OFF lag - cheat
ParamArray(2) = h.grab_camera.Value; % another cheat to trigger point grey camera
%% convert voltage values to int16 range before sending
not_ints = [not_ints1 (length(params1) + not_ints2)];
voltage_to_int = round(inv(h.DAC_levels.Data(2)/(2^16)));
ParamArray(not_ints) = round(ParamArray(not_ints)*voltage_to_int);
ParamArray(ParamArray>2^16-1) = 2^16-1;

while (sent == 0) && (sending_attempts <=8 )
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
        params_returned = h.Arduino.read(h.Arduino.Port.BytesAvailable/2,'uint16');
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

%% if acquisition is Running and params were sent - update settings file
if get(h.startAcquisition,'value') && (sent == 1)
    % replace last three values in params1 to store Stay Time min and Stay
    % Time Max
    params1(1) = h.ZoneLimitSettings.Data(1); % MinWidth
    %params1(2) = h.ZoneLimitSettings.Data(2); % PropWidth
    params1(2) = h.RewardControls.Data(2); % IRI - when multirewards is off
    params1(end-4) = h.MultiRewards.Value*h.RewardControls.Data(2); % IRI
    params1(end-2) = h.TargetHold.Data(1); % StayMean
    params1(end-1) = h.TargetHold.Data(2); % StayMin
    params1(end) = h.TargetHold.Data(3); % StayMax
    params2(1) = h.grab_camera.Value; % camera on or not
    fwrite(h.settingsfileID,[h.timestamp.Data params1 params2],'double');
end