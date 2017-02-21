function Update_MultiRewards(h)

%% send params to Arduino
sent = 0;
sending_attempts = 0;
ParamArray = h.RewardControls.Data(3:4)'; % replace timestamp with 0

while (sent == 0) && (sending_attempts <=8 )
    if h.Arduino.Port.BytesAvailable
        trash = h.Arduino.read(h.Arduino.Port.BytesAvailable/2,'uint16');
        clear trash;
    end
    h.Arduino.write(84,'uint16'); % handler code for parameter update
    ParamArray = uint16(ParamArray);
    h.Arduino.write(ParamArray, 'uint16');
    pause(.1);
    % for every param Arduino writes back the param value
    if (h.Arduino.Port.BytesAvailable)>1
        params_returned = h.Arduino.read(h.Arduino.Port.BytesAvailable/2,'uint16');
        if length(params_returned) >= length(ParamArray)
            if all(params_returned(1:end) == ParamArray')
                disp(['arduino: params MultiReward updated: attempts = ' num2str(sending_attempts+1)])
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
end

if sending_attempts == 9
    error('arduino: failed to update MultiReward params')
end
