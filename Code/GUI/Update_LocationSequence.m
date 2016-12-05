function Update_LocationSequence(h)
%Update_TransferFunction(h);
%pause(1);

% % get current transfer function
% target_limits = [h.TrialSettings.Data(2) h.TargetDefinition.Data(3:-1:1)' h.TrialSettings.Data(1)];
% [TF, TF_plot] = LeverTransferFunction(target_limits,h.TransferFunction.Data(1),h.TransferFunction.Data(2));

% get current transfer function
target_limits = [h.TrialSettings.Data(2) h.TargetDefinition.Data(3:-1:1)' h.TrialSettings.Data(1)];
DAC_limits = h.DAC_levels.Data;
Zone_limits = h.locations_per_zone.Data;
[TF] = LeverTransferFunction_discrete(target_limits,DAC_limits,Zone_limits,...
    h.TransferFunction.Data(1));

TF = TF'+101;
TF = randperm(length(TF));


if h.location_update_params(2) == 0
    TF = sort(TF);
    %TF = TF(length(TF):-1:1);
    %TF = mod(TF,20);
end

sent = 0;
sending_attempts = 0;

%% send Location sequence to Arduino
while (sent == 0) && (sending_attempts <=8 )
    if h.Arduino.BytesAvailable
        trash = fread(h.Arduino, h.Arduino.BytesAvailable);
        clear trash;
    end
    fwrite(h.Arduino, char(31)); % tell Arduino how many locations are being written
    fwrite(h.Arduino,h.location_update_params(1),'uint16'); % if the write fails, Arduino writes back -1
    if (h.Arduino.BytesAvailable)==0 % Arduino did not write back
        % write the params
        fwrite(h.Arduino,TF,'uint16');
        pause(.05);
        % for every param Arduino writes back the param value
        if (h.Arduino.BytesAvailable)>1
            TF_returned = fread(h.Arduino,h.Arduino.BytesAvailable/2,'uint16');
            if length(TF_returned) >= length(TF)
                if all(TF_returned(1:end-1) == TF') && TF_returned(end) == 83
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
