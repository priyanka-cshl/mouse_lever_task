function [handles] = CalibrateRotaryEncoder(handles)

% Take Motor to Home
% Fake a home interrupt signal
handles.Arduino.write(72, 'uint16');
pause(2);

if ~handles.VisualVersion.Value
    % set clearpath motor control to manual override
    handles.Arduino.write(61, 'uint16');
    pause(2);
    
    % Move motor to one extreme and then the other
    if ~handles.openloop
        if handles.TFtype.Value
            my_location = [handles.MotorLocationsFixSpeed 0 -handles.MotorLocationsFixSpeed];
        else
            my_location = [handles.MotorLocations 0 -handles.MotorLocations];
        end
        
    else
        my_location = [handles.MotorLocationsFixSpeed 0 -handles.MotorLocationsFixSpeed];
    end
    
    my_location
    
    for i = 1:3
        handles.Arduino.write(62, 'uint16'); % handler - move motor to specific location
        % get chosen location
        pause(0.1);
        handles.Arduino.write(my_location(i)+handles.MotorLocationArduinoMax+1, 'uint16'); % which location
        pause(1);
        % read the rotary encoder output
        temp_duration = handles.NI.DurationInSeconds;
        handles.NI.DurationInSeconds = 0.5;
        if isfield(handles,'lis')
            delete(handles.lis);
        end
        %guidata(hObject, handles);
        data = startForeground(handles.NI);
        handles.Rotary.Limits(i) = mean(data(:,3));
        handles.Rotary.Locations(i) = my_location(i);
        handles.NI.DurationInSeconds = temp_duration;
    end
else
    handles.Rotary.Limits = [0 0 0];
end
handles.Rotary.Limits
end