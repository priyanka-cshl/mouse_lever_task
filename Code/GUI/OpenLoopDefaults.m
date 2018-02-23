function [handles] = OpenLoopDefaults(handles)
% rig specific settings
%handles.computername = textread('C:\Users\pgupta\Documents\hostname.txt','%s'); %#ok<*DTXTRD>
switch char(handles.computername)
    case {'marbprec', 'PRIYANKA-HP'}
        handles.file_names.Data(2) = {'C:\Data\OpenLoop'};
        handles.file_names.Data(3) = {'\\sonas-hs\Albeanu-Norepl\pgupta\OpenLoop'};
        handles.ManifoldOutlets = 16;
        % motor location settings
        handles.motor_params = 4;
        % Trial settings
        handles.TrialSettings.Data = [500 500 500 500 500]';
        % odor panel
        handles.Odor_list.Value = [1 2 3]';
        % target levels
        handles.MotorLocations = 120;
        handles.MotorLocationArduinoMax = 120;
        handles.MotorLocationsRange = 140;
        handles.fliphome = 0; 
        
    case {'PRIYANKA-PC','DESKTOP-05QAM9D'}
        {'C:\Data\OpenLoop'};
        handles.file_names.Data(3) = {'\\sonas-hs\Albeanu-Norepl\pgupta\OpenLoop'};
        handles.ManifoldOutlets = 16;
        % motor location settings
        handles.motor_params = 4;
        % Trial settings
        handles.TrialSettings.Data = [500 500 500 500 500]';
        % odor panel
        handles.Odor_list.Value = [1 2 3]';
        % target levels
        handles.MotorLocations = 120;
        handles.MotorLocationArduinoMax = 120;
        handles.MotorLocationsRange = 140;
        handles.fliphome = 1;         
end
end