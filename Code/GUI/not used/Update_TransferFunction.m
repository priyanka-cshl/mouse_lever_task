function Update_TransferFunction(h)

% get current transfer function
target_limits = [h.TrialSettings.Data(2) h.TargetDefinition.Data(3:-1:1)' h.TrialSettings.Data(1)];
[TF, TF_plot] = LeverTransferFunction(target_limits,h.TransferFunction.Data(1),h.TransferFunction.Data(2));
TF = TF';

sent = 0;
sending_attempts = 0;
% lever positions, motor locations
l = length(TF_plot);
set(h.TF_left_plot,'XData',TF_plot(1:floor(l/2)+mod(l,2),2),'YData',TF_plot(1:floor(l/2)+mod(l,2),1));
set(h.TF_right_plot,'XData',TF_plot(floor(l/2)+1:end,2),'YData',TF_plot(floor(l/2)+1:end,1));

%% send TF to Arduino
while (sent == 0) && (sending_attempts <=8 )
    if h.Arduino.BytesAvailable
        trash = fread(h.Arduino, h.Arduino.BytesAvailable);
        clear trash;
    end
    fwrite(h.Arduino, char(30)); % tell Arduino how many locations are being written
    fwrite(h.Arduino,length(TF),'uint16'); % if the write fails, Arduino writes back -1
    if (h.Arduino.BytesAvailable)==0 % Arduino did not write back
        % write the params
        fwrite(h.Arduino,TF,'uint16');
        pause(.05);
        % for every param Arduino writes back the param value
        if (h.Arduino.BytesAvailable)>1
            TF_returned = fread(h.Arduino,h.Arduino.BytesAvailable/2,'uint16');
            if length(TF_returned) >= length(TF)
                if all(TF_returned(1:end-1) == TF') && TF_returned(end) == 83
                    disp(['arduino: transfer function updated: attempts = ' num2str(sending_attempts+1)])
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
         error('arduino: failed to update transfer function')
end
