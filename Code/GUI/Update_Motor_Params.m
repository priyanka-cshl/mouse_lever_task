function Update_Motor_Params(h)

% send stepsize to arduino
stepsize = h.motor_params + 70;
h.Arduino.write(stepsize,'uint16'); % fwrite(h.Arduino, char(stepsize));
pause(0.01);

while (sent == 0) && (sending_attempts <=8 )
    if h.Arduino.Port.BytesAvailable
        trash = h.Arduino.read(h.Arduino.Port.BytesAvailable/2,'uint16');
        clear trash;
    end
    h.Arduino.write(50,'uint16'); % handler code for motor params update
    h.Arduino.write(length(ParamArray),'uint16'); % tell Arduino the number of params being written
    % if the write fails, Arduino writes back -1
    if (h.Arduino.Port.BytesAvailable)==0 % Arduino did not write back
        % write the params
        ParamArray = uint16(ParamArray);
        h.Arduino.write(ParamArray, 'uint16');
        pause(.1);
        % for every param Arduino writes back the param value
        if (h.Arduino.Port.BytesAvailable)>1
            params_returned = h.Arduino.read(h.Arduino.Port.BytesAvailable/2,'uint16');
            if length(params_returned) >= length(ParamArray)
                if all(params_returned(1:end-1) == ParamArray) && params_returned(end) == 89
                    disp(['arduino: motor params updated: attempts = ' num2str(sending_attempts + 1)])
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
            sending_attempts = sending_attempts + 1';
        end
    else
        pause(.1)
        sending_attempts = sending_attempts + 1';
    end
end

if sending_attempts == 9
    error('arduino: failed to update motor params')
end
