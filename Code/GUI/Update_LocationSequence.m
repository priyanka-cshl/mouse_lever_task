function Update_LocationSequence(h)

% get current transfer function
target_limits = [h.TrialSettings.Data(2) h.TargetDefinition.Data(3:-1:1)' h.TrialSettings.Data(1)];
DAC_limits = h.DAC_levels.Data;
Zone_limits = h.locations_per_zone.Data;
[TF] = LeverTransferFunction_discrete(target_limits,DAC_limits,Zone_limits,...
    h.TransferFunction.Data(1));

TF_to_write = 0*(TF);

TF = unique(TF);
TF = TF'+101;
TF = TF(randperm(length(TF)));

if h.location_update_params(2) == 0
    TF = sort(TF);
    %TF = TF(length(TF):-1:1);
    %TF = mod(TF,20);
end

TF_to_write(1:length(TF)) = TF-101;
TF_to_write = [length(TF) TF_to_write];

sent = 0;
sending_attempts = 0;

%% send Location sequence to Arduino
while (sent == 0) && (sending_attempts <=8 )
    if h.Arduino.Port.BytesAvailable
        trash = h.Arduino.read(h.Arduino.Port.BytesAvailable/2,'uint16');
        clear trash;
    end
    h.Arduino.write(20,'uint16'); % handler code for location sequence update
    h.Arduino.write(length(TF),'uint16'); % tell Arduino the size of the TF vector
    h.Arduino.write(h.location_update_params(1),'uint16'); % tell Arduino the time to stop between locations
    % if the write fails, Arduino writes back -1
    if (h.Arduino.Port.BytesAvailable)==0 % Arduino did not write back
        % write the TF
        TF = uint16(TF);
        h.Arduino.write(TF, 'uint16');
        pause(.05);
        % for every param Arduino writes back the param value
         if (h.Arduino.Port.BytesAvailable)>1
            TF_returned = h.Arduino.read(h.Arduino.Port.BytesAvailable/2,'uint16');
            if length(TF_returned) >= length(TF)
                if all(TF_returned(1:end-1) == TF) && TF_returned(end) == 83
                    disp(['arduino: location sequence updated: attempts = ' num2str(sending_attempts+1)])
                    sent = 1;
                else
                    pause(.1);
                    sending_attempts = sending_attempts + 1';
                end
            else
                pause(.1)
                sending_attempts = sending_attempts + 1';
            end
        else
            pause(.1)
            sending_attempts = sending_attempts+1';
        end
    else
        pause(.1)
        sending_attempts = sending_attempts+1';
    end
end

if sending_attempts == 9
         error('arduino: failed to update location sequence')
end

%% if acquisition is Running and TF was sent - update TF log file
if get(h.startAcquisition,'value') && (sent == 1)
    fwrite(h.TransferFunctionfileID, [h.timestamp.Data h.location_update_params(1) TF_to_write] ,'double');
end
