function Update_Motor_Params(h)

% send stepsize to arduino
stepsize = h.motor_params + 70;
fwrite(h.Arduino, char(stepsize));
pause(0.01);

while (sent == 0) && (sending_attempts <=8 )
    if h.Arduino.BytesAvailable
        trash = fread(h.Arduino, h.Arduino.BytesAvailable);
        clear trash;
    end
    fwrite(h.Arduino, char(50)); % tell Arduino how many params are going to be written
    fwrite(h.Arduino,length(ParamArray),'uint16'); % if the write fails, Arduino writes back -1
    if (h.Arduino.BytesAvailable)==0 % Arduino did not write back
        % write the params
        fwrite(h.Arduino,ParamArray,'uint16');
        pause(.1);
        % for every param Arduino writes back the param value
        if (h.Arduino.BytesAvailable)>1
            params_returned = fread(h.Arduino,h.Arduino.BytesAvailable/2,'uint16');
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
