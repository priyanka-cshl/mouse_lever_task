function [handles] = CalibrateRotaryEncoder(handles)

% Take Motor to Home
% Fake a home interrupt signal

pause(0.5);
% read the rotary encoder output while motor is homed
temp_duration = handles.NI.DurationInSeconds;
handles.NI.DurationInSeconds = 0.5;
if isfield(handles,'lis')
    delete(handles.lis);
end
%guidata(hObject, handles);
data = startForeground(handles.NI);
handles.Rotary.Home = mean(data(:,3));
handles.NI.DurationInSeconds = temp_duration;

% set clearpath motor control to manual override 
handles.Arduino.write(61, 'uint16');
pause(0.5);

% Move motor to one extreme and then the other
contents = cellstr(get(handles.all_locations,'String'));
my_location = [str2num(char(contents(end))) 0 str2num(char(contents(1)))];
    
for i = 1:3    
    handles.Arduino.write(62, 'uint16'); % handler - move motor to specific location
    % get chosen location
    handles.Arduino.write(my_location(i)+101, 'uint16'); % which location
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
    handles.NI.DurationInSeconds = temp_duration;
end

% set clearpath motor control back to close loop
handles.Arduino.write(60, 'uint16');
end