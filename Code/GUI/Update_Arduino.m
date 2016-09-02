function Update_Arduino(h)
%% pull all params
[~, params1, not_ints1] = Current_Settings(h,0);
[~, params2, not_ints2] = Current_Settings(h,1);

%% send params to Arduino
sent = 0;
sending_attempts = 0;
ParamArray = [params1 0 params2(2:end)]; % replace timestamp with 0

%% convert voltage values to int16 range before sending
not_ints = [not_ints1 (length(params1) + not_ints2)];
voltage_to_int = round(inv(h.DAC_levels.Data(2)/(2^16)));
ParamArray(not_ints) = round(ParamArray(not_ints)*voltage_to_int);
ParamArray(ParamArray>2^16-1) = 2^16-1;
while (sent == 0) && (sending_attempts <=8 )
    if h.Arduino.BytesAvailable
        trash = fread(h.Arduino, h.Arduino.BytesAvailable);
        clear trash;
    end
    fwrite(h.Arduino, char(60)); % tell Arduino how many params are going to be written
    fwrite(h.Arduino,length(ParamArray),'uint16'); % if the write fails, Arduino writes back -1
    if (h.Arduino.BytesAvailable)==0 % Arduino did not write back
        % write the params
        fwrite(h.Arduino,ParamArray,'uint16');
        pause(.1);
        % for every param Arduino writes back the param value
        if (h.Arduino.BytesAvailable)>1
            params_returned = fread(h.Arduino,h.Arduino.BytesAvailable/2,'uint16');
            if length(params_returned) >= length(ParamArray)
                if all(params_returned(1:end-1) == ParamArray') && params_returned(end) == 89
                    disp(['arduino: params updated: attempts = ' num2str(sending_attempts+1)])
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
         error('arduino: failed to update values')
end

%% if acquisition is Running and params were sent - update settings file
if get(h.startAcquisition,'value') && (sent == 1)
    fwrite(h.settingsfileID,params2,'double');
end