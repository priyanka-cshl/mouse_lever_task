function [handles] = OpenLoopDefaults(handles)
% rig specific settings
%handles.computername = textread('C:\Users\pgupta\Documents\hostname.txt','%s'); %#ok<*DTXTRD>
switch char(handles.computername)
    case {'marbprec', 'PRIYANKA-HP'}
        % files and paths
        handles.file_names.Data(2) = {'C:\Data\OpenLoop'};
        handles.file_names.Data(3) = {'\\grid-hs\albeanu_nlsas_norepl_data\pgupta\OpenLoop'};
        
        % Rates
        handles.DAQrates.Data = [500 20]';
        
        % sensors and scaling
        handles.DAC_settings.Data = [1.75 2.10]';
        handles.RS_scaling.Data = [-1 5.5]';
        handles.fliphome = 0;
        
        % default params
        handles.TrialSettings.Data = [50 500 500 50 500 500]'; % motor-settle, pre-odor, odor, purge, post-odor, ITI
        handles.Odor_list.Value = 1 + [1 2 3]'; % active odors
        handles.openloop = 1; % Run in open-loop mode
        
        % Transfer function
        handles.TFtype.Value = 1; % 1 = fix speed, 0 = fixed start
        handles.TFtype.Enable = 'on';
        
        % manifold and motor
        handles.MotorLocations = 115; % currently used for variable gain
        handles.MotorLocationArduinoMax = 120;
        handles.MotorLocationsFixSpeed = 100; % for fix speed
        handles.ManifoldOutlets = 24; % 32 in total - out of which only 24 are used
        handles.motor_params = 4; % motor step size
        
    case {'PRIYANKA-PC','DESKTOP-05QAM9D'}
        {'C:\Data\OpenLoop'};
        handles.file_names.Data(3) = {'\\sonas-hs\Albeanu-Norepl\pgupta\OpenLoop'};
        handles.ManifoldOutlets = 16;
        % motor location settings
        handles.motor_params = 4;
        % Trial settings
        handles.TrialSettings.Data = [50 500 500 50 500 500]';
        % odor panel
        handles.Odor_list.Value = [1 2 3]';
        % target levels
        handles.MotorLocations = 120;
        handles.MotorLocationArduinoMax = 120;
        handles.MotorLocationsRange = 140;
        handles.fliphome = 1;         
end
end