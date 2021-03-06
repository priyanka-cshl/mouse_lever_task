function [h] = Update_TransferFunctions(h)

[h] = My_Transfer_Functions(h);

% get all transfer functions
TF1 = h.TF1' + 101;
TF2 = h.TF2' + 101;
TF3 = h.TF3' + 101;

sent = 0;
sending_attempts = 0;

%% send TF to Arduino
while (sent == 0) && (sending_attempts <=8 )
    if h.Arduino.Port.BytesAvailable
        trash = h.Arduino.read(h.Arduino.Port.BytesAvailable/2,'uint16');
        clear trash;
    end
    h.Arduino.write(30,'uint16'); % handler code for transfer function update
    h.Arduino.write(length(TF1),'uint16'); % tell Arduino the size of the TF vector
    pause(0.1);
    %if the write fails, Arduino writes back -1
    if (h.Arduino.Port.BytesAvailable)==0 % Arduino did not write back
        % write the TF
        TF = uint16(TF1);
        h.Arduino.write(TF', 'uint16');
        TF = uint16(TF2);
        h.Arduino.write(TF', 'uint16');
        TF = uint16(TF3);
        h.Arduino.write(TF', 'uint16');
        pause(.2);
        % for every param Arduino writes back the param value
        if (h.Arduino.Port.BytesAvailable)>1
            TF_returned = h.Arduino.read(h.Arduino.Port.BytesAvailable/2,'uint16');
            if length(TF_returned) >= length(TF)
                if all(TF_returned(1:end-1) == [TF1; TF2; TF3]) && TF_returned(end) == 83
                    disp(['arduino: transfer functions updated: attempts = ' num2str(sending_attempts+1)])
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
    error('arduino: failed to update transfer functions')
end

