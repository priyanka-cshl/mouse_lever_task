function Update_OpenLoopParams(h)

%% pull all params
[~, myParams, LocationArray] = OpenLoop_Settings(h);
if myParams(2) == 800
    ParamArray = [myParams LocationArray];
else
    ParamArray = myParams;
end
%% send params to Arduino
sent = 0;
sending_attempts = 0;

while (sent == 0) && (sending_attempts <=8 )
    if h.Arduino.Port.BytesAvailable
        trash = h.Arduino.read(h.Arduino.Port.BytesAvailable/2,'uint16');
        clear trash;
    end
    
    if ParamArray(2) == 800
        h.Arduino.write(21,'uint16'); % handler code for parameter update
    else
        h.Arduino.write(21,'uint16'); % handler code for parameter update
    end
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
        if all(params_returned(1:end-1) == ParamArray') && params_returned(end) == 98
            disp(['arduino: params updated: attempts = ' num2str(sending_attempts+1),'; time = ',num2str(toc),' seconds'])
            sent = 1;
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
    fwrite(h.settingsfileID,[h.timestamp.Data myParams],'double');
end