function [h] = CalibrateTransferFunction(h)

[TF, h] = GetTransferFunction(h);
TF = linspace(-h.MotorLocationArduinoMax, h.MotorLocationArduinoMax, length(TF));
TF_4_plot = TF; % use later for colormap update
TF = TF'+ h.MotorLocationArduinoMax + 1; % get rid of negative values % transform to a column vector

if h.location_update_params(2)
    TF = TF(randperm(length(TF)));
end

sent = 0;
sending_attempts = 0;

%% send TF to Arduino
while (sent == 0) && (sending_attempts <=8 )
    if h.Arduino.Port.BytesAvailable
        trash = h.Arduino.read(h.Arduino.Port.BytesAvailable/2,'uint16');
        clear trash;
    end
    h.Arduino.write(31,'uint16'); % handler code for transfer function calibration
    h.Arduino.write(length(TF),'uint16'); % tell Arduino the size of the TF vector
    h.Arduino.write(h.location_update_params(1),'uint16'); % tell Arduino the time to stop between locations
    % write the TF
    TF = uint16(TF);
    h.Arduino.write(TF', 'uint16');
    tic;
    while toc<0.5 && h.Arduino.Port.BytesAvailable<2*(length(TF)+1)
    end
    % for every param Arduino writes back the param value
    if (h.Arduino.Port.BytesAvailable)==2*(length(TF)+1)
        TF_returned = h.Arduino.read(h.Arduino.Port.BytesAvailable/2,'uint16');
        if all(TF_returned(1:end-1) == TF) && TF_returned(end) == 83
            disp(['arduino: calibration TF uploaded: attempts = ' num2str(sending_attempts+1),'; time = ',num2str(toc),' seconds'])
            sent = 1;
            h.TFupdate = 1;
            
            %update transfer function colormap
            TF = TF_4_plot;
            h.TF_plot.CData = (TF')/h.MotorLocations;
            %h.TF_plot.CData = flipud(TF')/h.MotorLocations;
            h.all_locations.String = num2str((-h.MotorLocations:1:h.MotorLocations)');
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
    error('arduino: failed to update transfer function')
end

end